import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_stack_entry.dart';
import 'package:cc_domain/features/messaging/domain/ports/space_stack_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_stack_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/stack_branch_names.dart';
import 'package:uuid/uuid.dart';

/// Runs `git` in a checkout. Tests pass a stand-in; production uses [Process].
typedef StackGit =
    Future<({int exitCode, String stdout, String stderr})> Function(
      String workingDirectory,
      List<String> args, {
      Map<String, String>? environment,
    });

/// The base branch pinned on the space for one repo, or null.
typedef StackPinnedBase =
    Future<String?> Function(
      String workspaceId,
      String spaceId,
      String repoId,
    );

/// A token for [forge], attributed to [actingUserId] when the call has one.
typedef StackForgeToken =
    Future<String?> Function(
      ForgeHost forge,
      String? actingUserId,
      String workspaceId,
    );

/// Opens one pull request. The service never writes a review-space row.
typedef OpenStackPullRequest =
    Future<({int number, String externalId})> Function({
      required Repo repo,
      required String workspaceId,
      required String title,
      required String body,
      required String head,
      required String base,
      required bool draft,
      String? actingUserId,
    });

/// Groups [prNumbers] (bottom to top) on a forge that has _stacks.
typedef GroupStackPullRequests =
    Future<void> Function({
      required Repo repo,
      required String workspaceId,
      required List<int> prNumbers,
      String? actingUserId,
    });

/// Cuts, checks out, and publishes the branches inside one space's checkout.
///
/// Git runs in the isolated copy. This is the only writer of stack rows and
/// of [IsolatedRepo.branch] for a stack move. A dirty worktree refuses cut
/// and checkout; the caller commits first.
class SpaceStackService implements SpaceStackPort {
  /// Creates a [SpaceStackService].
  SpaceStackService({
    required IsolatedRepoRepository isolatedRepos,
    required SpaceStackRepository stacks,
    required RepoRepository repos,
    required StackPinnedBase pinnedBase,
    required StackForgeToken tokenFor,
    required OpenStackPullRequest openPullRequest,
    required GroupStackPullRequests groupStack,
    required bool Function(Repo repo) stacksSupported,
    StackGit? git,
    String Function()? newId,
    DateTime Function()? now,
  }) : _isolated = isolatedRepos,
       // Public names: a private initializing formal is invisible to callers
       // in other libraries.
       // ignore: prefer_initializing_formals
       _stacks = stacks,
       // ignore: prefer_initializing_formals
       _repos = repos,
       // ignore: prefer_initializing_formals
       _pinnedBase = pinnedBase,
       // ignore: prefer_initializing_formals
       _tokenFor = tokenFor,
       // ignore: prefer_initializing_formals
       _openPullRequest = openPullRequest,
       // ignore: prefer_initializing_formals
       _groupStack = groupStack,
       // ignore: prefer_initializing_formals
       _stacksSupported = stacksSupported,
       _git = git ?? _processGit,
       _newId = newId ?? const Uuid().v4,
       _now = now ?? DateTime.now;

  final IsolatedRepoRepository _isolated;
  final SpaceStackRepository _stacks;
  final RepoRepository _repos;
  final StackPinnedBase _pinnedBase;
  final StackForgeToken _tokenFor;
  final OpenStackPullRequest _openPullRequest;
  final GroupStackPullRequests _groupStack;
  final bool Function(Repo repo) _stacksSupported;
  final StackGit _git;
  final String Function() _newId;
  final DateTime Function() _now;

  @override
  Future<SpaceStackView> list({
    required String workspaceId,
    required String spaceId,
  }) async {
    if (workspaceId.isEmpty || spaceId.isEmpty) {
      return const SpaceStackView(ok: false, error: 'missing workspace or space');
    }
    final entries = await _stacks.forSpace(workspaceId, spaceId);
    final checkedOut = await _checkedOut(workspaceId, spaceId);
    return SpaceStackView(ok: true, entries: entries, checkedOut: checkedOut);
  }

  @override
  Future<SpaceStackView> cut({
    required String workspaceId,
    required String spaceId,
    required String name,
    String? repoId,
    String? at,
  }) async {
    final worktree = await _resolveWorktree(
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: repoId,
    );
    if (worktree == null) {
      return _missingCheckout(workspaceId, spaceId);
    }
    final root = worktree.path;
    if (await _isDirty(root)) {
      return _dirty(workspaceId, spaceId);
    }
    final slug = normalizeStackSlug(name);
    if (slug == null) {
      return _fail(workspaceId, spaceId, 'part name is invalid');
    }
    final entries = await _stacks.forRepo(
      workspaceId,
      spaceId,
      worktree.repoId,
    );
    final head = await _headBranch(root);
    if (head.isEmpty || head == 'HEAD') {
      return _fail(workspaceId, spaceId, 'the checkout has no branch');
    }
    if (entries.isNotEmpty && head != entries.last.branch) {
      return _fail(
        workspaceId,
        spaceId,
        'check out the top of the stack before starting the next part',
      );
    }
    final bottom = entries.isEmpty ? head : entries.first.branch;
    final newBranch = stackLayerBranch(bottom, slug);
    if (entries.any((entry) => entry.branch == newBranch)) {
      return _fail(workspaceId, spaceId, 'that part already exists');
    }
    final format = await _git(root, ['check-ref-format', '--branch', newBranch]);
    if (format.exitCode != 0) {
      return _fail(workspaceId, spaceId, 'part name is invalid');
    }

    final headSha = await _sha(root, 'HEAD');
    if (headSha == null) {
      return _fail(workspaceId, spaceId, 'the checkout has no commit');
    }
    String? splitAt;
    final rawAt = at?.trim() ?? '';
    if (rawAt.isNotEmpty) {
      if (rawAt.startsWith('-')) {
        return _fail(workspaceId, spaceId, 'that commit is not an ancestor of HEAD');
      }
      if (!await _isAncestor(root, rawAt, 'HEAD')) {
        return _fail(
          workspaceId,
          spaceId,
          'that commit is not an ancestor of HEAD',
        );
      }
      final atSha = await _sha(root, rawAt);
      if (atSha == null) {
        return _fail(
          workspaceId,
          spaceId,
          'that commit is not an ancestor of HEAD',
        );
      }
      if (atSha != headSha) {
        splitAt = atSha;
      }
    }

    final created = await _createBranch(
      root: root,
      newBranch: newBranch,
      parentBranch: head,
      parentSha: headSha,
      splitAt: splitAt,
    );
    if (created != null) {
      return _fail(workspaceId, spaceId, created);
    }

    final inserted = <String>[];
    SpaceStackEntry? previousTip;
    try {
      if (entries.isEmpty) {
        final base = await _defaultBase(
          root,
          await _pinnedBase(workspaceId, spaceId, worktree.repoId),
        );
        final bottomEntry = SpaceStackEntry(
          id: _newId(),
          workspaceId: workspaceId,
          spaceId: spaceId,
          repoId: worktree.repoId,
          position: 0,
          branch: head,
          baseBranch: base,
          createdAt: _now().toUtc(),
          rewritten: splitAt != null && await _hasOrigin(root, head),
        );
        await _stacks.upsert(bottomEntry);
        inserted.add(bottomEntry.id);
      } else if (splitAt != null) {
        previousTip = entries.last;
        final mark =
            previousTip.prNumber != null || await _hasOrigin(root, head);
        if (mark && !previousTip.rewritten) {
          await _stacks.upsert(previousTip.copyWith(rewritten: true));
        }
      }
      final layer = SpaceStackEntry(
        id: _newId(),
        workspaceId: workspaceId,
        spaceId: spaceId,
        repoId: worktree.repoId,
        position: entries.isEmpty ? 1 : entries.last.position + 1,
        branch: newBranch,
        baseBranch: head,
        createdAt: _now().toUtc(),
      );
      await _stacks.upsert(layer);
      inserted.add(layer.id);
      await _isolated.upsert(worktree.copyWith(branch: newBranch));
    } on Object {
      await _undoBranch(
        root: root,
        parentBranch: head,
        parentSha: headSha,
        newBranch: newBranch,
        rewroteParent: splitAt != null,
      );
      for (final id in inserted) {
        await _stacks.deleteById(workspaceId, id);
      }
      if (previousTip != null) {
        await _stacks.upsert(previousTip);
      }
      await _isolated.upsert(worktree);
      return _fail(workspaceId, spaceId, 'could not record the new part');
    }

    return list(workspaceId: workspaceId, spaceId: spaceId);
  }

  @override
  Future<SpaceStackView> checkout({
    required String workspaceId,
    required String spaceId,
    required String branch,
    String? repoId,
  }) async {
    final name = branch.trim();
    if (name.isEmpty || name.startsWith('-')) {
      return _fail(workspaceId, spaceId, 'that part is not in this stack');
    }
    final worktree = await _resolveWorktree(
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: repoId,
      branch: repoId == null || repoId.trim().isEmpty ? name : null,
    );
    if (worktree == null) {
      final matches = (await _stacks.forSpace(workspaceId, spaceId))
          .where((entry) => entry.branch == name)
          .length;
      if (matches == 0) {
        return _fail(workspaceId, spaceId, 'that part is not in this stack');
      }
      return _fail(
        workspaceId,
        spaceId,
        'name the repo; this space has more than one',
      );
    }
    final entries = await _stacks.forRepo(
      workspaceId,
      spaceId,
      worktree.repoId,
    );
    if (!entries.any((entry) => entry.branch == name)) {
      return _fail(workspaceId, spaceId, 'that part is not in this stack');
    }
    final root = worktree.path;
    final head = await _headBranch(root);
    if (head == name) {
      if (worktree.branch != name) {
        await _isolated.upsert(worktree.copyWith(branch: name));
      }
      return list(workspaceId: workspaceId, spaceId: spaceId);
    }
    if (await _isDirty(root)) {
      return _dirty(workspaceId, spaceId);
    }
    final previousSha = await _sha(root, 'HEAD');
    final switched = await _git(root, ['switch', '--', name]);
    if (switched.exitCode != 0) {
      return _fail(workspaceId, spaceId, _gitError(switched));
    }
    try {
      await _isolated.upsert(worktree.copyWith(branch: name));
    } on Object {
      if (head.isNotEmpty && head != 'HEAD') {
        await _git(root, ['switch', '--', head]);
      } else if (previousSha != null) {
        await _git(root, ['switch', '--detach', previousSha]);
      }
      return _fail(workspaceId, spaceId, 'could not record the checkout');
    }
    return list(workspaceId: workspaceId, spaceId: spaceId);
  }

  @override
  Future<SpaceStackView> publish({
    required String workspaceId,
    required String spaceId,
    String? repoId,
    String? actingUserId,
    bool draft = true,
  }) async {
    if (workspaceId.isEmpty || spaceId.isEmpty) {
      return const SpaceStackView(ok: false, error: 'missing workspace or space');
    }
    final wanted = repoId?.trim() ?? '';
    final byRepo = <String, List<SpaceStackEntry>>{};
    for (final entry in await _stacks.forSpace(workspaceId, spaceId)) {
      if (wanted.isNotEmpty && entry.repoId != wanted) {
        continue;
      }
      byRepo.putIfAbsent(entry.repoId, () => []).add(entry);
    }
    if (byRepo.isEmpty) {
      return _fail(workspaceId, spaceId, 'this space has no stack yet');
    }
    var opened = 0;
    var grouped = false;
    String? stackError;
    for (final repoEntries in byRepo.values) {
      final outcome = await _publishRepo(
        workspaceId: workspaceId,
        spaceId: spaceId,
        entries: repoEntries,
        actingUserId: actingUserId,
        draft: draft,
      );
      if (!outcome.ok) {
        final listed = await list(workspaceId: workspaceId, spaceId: spaceId);
        return SpaceStackView(
          ok: false,
          error: outcome.error,
          entries: listed.entries,
          checkedOut: listed.checkedOut,
          opened: opened + outcome.opened,
          grouped: grouped,
          stackError: stackError,
        );
      }
      opened += outcome.opened;
      grouped = grouped || outcome.grouped;
      stackError ??= outcome.stackError;
    }
    final listed = await list(workspaceId: workspaceId, spaceId: spaceId);
    return SpaceStackView(
      ok: true,
      entries: listed.entries,
      checkedOut: listed.checkedOut,
      opened: opened,
      grouped: grouped,
      stackError: stackError,
    );
  }

  Future<({bool ok, String? error, int opened, bool grouped, String? stackError})>
  _publishRepo({
    required String workspaceId,
    required String spaceId,
    required List<SpaceStackEntry> entries,
    required String? actingUserId,
    required bool draft,
  }) async {
    final repo = await _repos.getById(workspaceId, entries.first.repoId);
    if (repo == null || !repo.hasForgeRemote) {
      return (
        ok: false,
        error: 'no forge is connected for this repo',
        opened: 0,
        grouped: false,
        stackError: null,
      );
    }
    final worktree = await _isolated.forUnitRepo(
      workspaceId,
      spaceId,
      repo.id,
    );
    if (worktree == null) {
      return (
        ok: false,
        error: 'no checkout for this space',
        opened: 0,
        grouped: false,
        stackError: null,
      );
    }
    final root = worktree.path;
    var lastNeeded = -1;
    final ahead = <String, int>{};
    for (var i = 0; i < entries.length; i++) {
      final count = entries[i].prNumber != null
          ? 1
          : await _ahead(root, entries[i].baseBranch, entries[i].branch);
      ahead[entries[i].id] = count;
      if (count > 0) {
        lastNeeded = i;
      }
    }
    if (lastNeeded < 0) {
      return (
        ok: false,
        error: 'nothing to publish yet',
        opened: 0,
        grouped: false,
        stackError: null,
      );
    }

    final env = await _authEnv(repo, actingUserId, workspaceId);
    for (var i = 0; i <= lastNeeded; i++) {
      final entry = entries[i];
      final args = <String>[
        '-c',
        'credential.helper=',
        'push',
        '-u',
        if (entry.rewritten) '--force-with-lease',
        'origin',
        '${entry.branch}:refs/heads/${entry.branch}',
      ];
      final pushed = await _git(root, args, environment: env);
      if (pushed.exitCode != 0) {
        return (
          ok: false,
          error: _gitError(pushed),
          opened: 0,
          grouped: false,
          stackError: null,
        );
      }
      if (entry.rewritten) {
        final cleared = entry.copyWith(rewritten: false);
        await _stacks.upsert(cleared);
        entries[i] = cleared;
      }
    }

    var opened = 0;
    for (var i = 0; i <= lastNeeded; i++) {
      final entry = entries[i];
      if (entry.prNumber != null || (ahead[entry.id] ?? 0) == 0) {
        continue;
      }
      try {
        final pr = await _openPullRequest(
          repo: repo,
          workspaceId: workspaceId,
          title: entry.branch,
          body: 'Base: ${entry.baseBranch}\nHead: ${entry.branch}',
          head: entry.branch,
          base: entry.baseBranch,
          draft: draft,
          actingUserId: actingUserId,
        );
        final recorded = entry.copyWith(
          prNumber: pr.number,
          prExternalId: pr.externalId,
        );
        await _stacks.upsert(recorded);
        entries[i] = recorded;
        opened++;
      } on Object catch (e) {
        return (
          ok: false,
          error: '$e',
          opened: opened,
          grouped: false,
          stackError: null,
        );
      }
    }

    final numbers = <int>[];
    for (final entry in entries) {
      final number = entry.prNumber;
      if (number == null) {
        break;
      }
      numbers.add(number);
    }
    var grouped = false;
    String? stackError;
    if (numbers.length >= 2 && _stacksSupported(repo)) {
      try {
        await _groupStack(
          repo: repo,
          workspaceId: workspaceId,
          prNumbers: numbers,
          actingUserId: actingUserId,
        );
        grouped = true;
      } on Object catch (e) {
        stackError = '$e';
      }
    }
    return (
      ok: true,
      error: null,
      opened: opened,
      grouped: grouped,
      stackError: stackError,
    );
  }

  /// Creates [newBranch]. Returns an error string, or null on success.
  ///
  /// With [splitAt], the parent branch is reset to that commit and the new
  /// branch keeps the commits that were above it.
  Future<String?> _createBranch({
    required String root,
    required String newBranch,
    required String parentBranch,
    required String parentSha,
    required String? splitAt,
  }) async {
    if (splitAt == null) {
      final created = await _git(root, ['switch', '-c', newBranch]);
      if (created.exitCode != 0) {
        return _gitError(created);
      }
      return null;
    }
    final branched = await _git(root, ['branch', newBranch, parentSha]);
    if (branched.exitCode != 0) {
      return _gitError(branched);
    }
    final reset = await _git(root, ['reset', '--hard', splitAt]);
    if (reset.exitCode != 0) {
      await _git(root, ['branch', '-D', newBranch]);
      return _gitError(reset);
    }
    final switched = await _git(root, ['switch', '--', newBranch]);
    if (switched.exitCode != 0) {
      await _git(root, ['reset', '--hard', parentSha]);
      await _git(root, ['branch', '-D', newBranch]);
      return _gitError(switched);
    }
    return null;
  }

  Future<void> _undoBranch({
    required String root,
    required String parentBranch,
    required String parentSha,
    required String newBranch,
    required bool rewroteParent,
  }) async {
    await _git(root, ['switch', '--', parentBranch]);
    if (rewroteParent) {
      await _git(root, ['reset', '--hard', parentSha]);
    }
    await _git(root, ['branch', '-D', newBranch]);
  }

  Future<IsolatedRepo?> _resolveWorktree({
    required String workspaceId,
    required String spaceId,
    String? repoId,
    String? branch,
  }) async {
    if (workspaceId.isEmpty || spaceId.isEmpty) {
      return null;
    }
    final rows = await _isolated.forSpace(workspaceId, spaceId);
    if (rows.isEmpty) {
      return null;
    }
    final id = repoId?.trim() ?? '';
    if (id.isNotEmpty) {
      for (final row in rows) {
        if (row.repoId == id) {
          return row;
        }
      }
      return null;
    }
    if (branch != null) {
      final hits = <IsolatedRepo>[];
      for (final row in rows) {
        final layers = await _stacks.forRepo(workspaceId, spaceId, row.repoId);
        if (layers.any((entry) => entry.branch == branch)) {
          hits.add(row);
        }
      }
      if (hits.length == 1) {
        return hits.single;
      }
      if (hits.length > 1) {
        return null;
      }
    }
    if (rows.length == 1) {
      return rows.single;
    }
    return null;
  }

  Future<Map<String, String>> _checkedOut(
    String workspaceId,
    String spaceId,
  ) async {
    final out = <String, String>{};
    for (final worktree in await _isolated.forSpace(workspaceId, spaceId)) {
      final head = await _headBranch(worktree.path);
      out[worktree.repoId] = head.isEmpty ? worktree.branch : head;
    }
    return out;
  }

  Future<SpaceStackView> _missingCheckout(
    String workspaceId,
    String spaceId,
  ) async {
    final rows = await _isolated.forSpace(workspaceId, spaceId);
    final error = rows.length > 1
        ? 'name the repo; this space has more than one'
        : 'no checkout for this space';
    return _fail(workspaceId, spaceId, error);
  }

  Future<SpaceStackView> _dirty(String workspaceId, String spaceId) async {
    final listed = await list(workspaceId: workspaceId, spaceId: spaceId);
    return SpaceStackView(
      ok: false,
      dirty: true,
      error: 'commit or discard changes before cutting or switching a stack part',
      entries: listed.entries,
      checkedOut: listed.checkedOut,
    );
  }

  Future<SpaceStackView> _fail(
    String workspaceId,
    String spaceId,
    String error,
  ) async {
    if (workspaceId.isEmpty || spaceId.isEmpty) {
      return SpaceStackView(ok: false, error: error);
    }
    final listed = await list(workspaceId: workspaceId, spaceId: spaceId);
    return SpaceStackView(
      ok: false,
      error: error,
      entries: listed.entries,
      checkedOut: listed.checkedOut,
    );
  }

  Future<bool> _isDirty(String root) async {
    final status = await _git(root, ['status', '--porcelain']);
    if (status.exitCode != 0) {
      return true;
    }
    return status.stdout.trim().isNotEmpty;
  }

  Future<String> _headBranch(String root) async {
    final res = await _git(root, ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (res.exitCode != 0) {
      return '';
    }
    return res.stdout.trim();
  }

  Future<String?> _sha(String root, String rev) async {
    if (rev.isEmpty || rev.startsWith('-')) {
      return null;
    }
    final res = await _git(root, ['rev-parse', '--verify', '$rev^{commit}']);
    if (res.exitCode != 0) {
      return null;
    }
    final sha = res.stdout.trim();
    return sha.isEmpty ? null : sha;
  }

  Future<bool> _isAncestor(String root, String ancestor, String head) async {
    final res = await _git(root, [
      'merge-base',
      '--is-ancestor',
      ancestor,
      head,
    ]);
    return res.exitCode == 0;
  }

  Future<bool> _hasOrigin(String root, String branch) async {
    final res = await _git(root, [
      'show-ref',
      '--verify',
      '--quiet',
      'refs/remotes/origin/$branch',
    ]);
    return res.exitCode == 0;
  }

  Future<String> _defaultBase(String root, String? pinned) async {
    final pin = pinned?.trim() ?? '';
    if (pin.isNotEmpty) {
      return pin;
    }
    final res = await _git(root, [
      'symbolic-ref',
      '--short',
      'refs/remotes/origin/HEAD',
    ]);
    if (res.exitCode == 0) {
      final name = res.stdout.trim();
      final slash = name.indexOf('/');
      if (slash >= 0 && slash < name.length - 1) {
        return name.substring(slash + 1);
      }
      if (name.isNotEmpty) {
        return name;
      }
    }
    return 'main';
  }

  Future<int> _ahead(String root, String base, String head) async {
    String? resolved;
    for (final candidate in [base, 'origin/$base']) {
      final res = await _git(root, [
        'rev-parse',
        '--verify',
        '--quiet',
        '$candidate^{commit}',
      ]);
      if (res.exitCode == 0 && res.stdout.trim().isNotEmpty) {
        resolved = candidate;
        break;
      }
    }
    if (resolved == null) {
      return 1;
    }
    final count = await _git(root, [
      'rev-list',
      '--count',
      '$resolved..$head',
    ]);
    if (count.exitCode != 0) {
      return 1;
    }
    return int.tryParse(count.stdout.trim()) ?? 0;
  }

  Future<Map<String, String>> _authEnv(
    Repo repo,
    String? actingUserId,
    String workspaceId,
  ) async {
    final token = await _tokenFor(repo.forge, actingUserId, workspaceId);
    if (token == null || token.isEmpty || repo.forge.gitHost.isEmpty) {
      return const {};
    }
    final user = switch (repo.forge) {
      ForgeHost.github => 'x-access-token',
      ForgeHost.gitlab => 'oauth2',
      ForgeHost.bitbucket => 'x-token-auth',
      ForgeHost.local => 'x-access-token',
    };
    final encoded = base64Encode(utf8.encode('$user:$token'));
    final host = repo.forge.gitHost;
    return {
      'GIT_CONFIG_PARAMETERS':
          "'http.https://$host/.extraHeader=Authorization: Basic $encoded'",
    };
  }

  static Future<({int exitCode, String stdout, String stderr})> _processGit(
    String workingDirectory,
    List<String> args, {
    Map<String, String>? environment,
  }) async {
    final result = await Process.run(
      'git',
      args,
      workingDirectory: workingDirectory,
      environment: {
        'GIT_TERMINAL_PROMPT': '0',
        'GIT_CONFIG_NOSYSTEM': '1',
        ...?environment,
      },
    );
    return (
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }
}

String _gitError(({int exitCode, String stdout, String stderr}) result) {
  final err = result.stderr.trim();
  if (err.isNotEmpty) {
    return err;
  }
  final out = result.stdout.trim();
  if (out.isNotEmpty) {
    return out;
  }
  return 'git failed';
}
