import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/session_diff_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/dispatch/domain/ports/commit_signing_port.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
// Narrow on purpose: this service needs two cc_infra pieces. The
// package-wide barrel would drag the whole dispatch/chat/infra surface into
// every compile of this file (and everything that tests it).
// ignore: implementation_imports
import 'package:cc_infra/src/git/process_session_diff_adapter.dart';
// ignore: implementation_imports
import 'package:cc_infra/src/network/forge_git_auth.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:cc_server_core/src/commit_resigner.dart';
import 'package:cc_server_core/src/fs_confinement.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

part 'repo_ide_change_gate.dart';
part 'repo_ide_commit_identity.dart';
part 'repo_ide_content_search.dart';
part 'repo_ide_push.dart';
part 'repo_ide_refs.dart';

/// Result of writing a draft into a conversation worktree.
class WorktreeWriteResult {
  /// Creates a successful write result for [repoId] at [path].
  const WorktreeWriteResult({required this.repoId, required this.path});

  /// The repo whose worktree the file landed in.
  final String repoId;

  /// The repo-relative path actually written (normalized, confined).
  final String path;
}

/// Head commit of an open pull request for [branch] in [repoId], from the
/// local open-PR snapshot, as [viewerId] may see it. Null when this branch
/// has no open pull request, or [viewerId] may not see the repo's pull
/// requests (PR visibility: their grant AND their own forge sign-in).
///
/// Must not hit the network: [RepoIdeDataService.repoChangesGrouped] runs on
/// the source-control poll, every few seconds.
typedef PublishedBranchHead =
    Future<String?> Function({
      required String workspaceId,
      required String repoId,
      required String branch,
      required String viewerId,
    });

/// Result of reverting one or more working-tree files in a conversation
/// worktree to HEAD. [reverted] counts files restored; [skipped] lists paths
/// that could not be reverted (untracked/new files — `git checkout-index` is a
/// no-op on them).
class WorktreeRevertResult {
  /// Creates a revert result with [reverted] files restored and [skipped] paths.
  const WorktreeRevertResult({
    required this.repoId,
    required this.reverted,
    required this.skipped,
  });

  /// The repo whose worktree was reverted.
  final String repoId;

  /// Number of files restored to HEAD.
  final int reverted;

  /// Paths that were not reverted (untracked files).
  final List<String> skipped;
}

/// A repo's changes split into staged and unstaged buckets, plus how its
/// branch sits against its upstream (see
/// [RepoIdeDataService.repoChangesGrouped]).
typedef RepoChangeGroups = ({
  List<PrFile> staged,
  List<PrFile> unstaged,
  bool hasUpstream,
  int ahead,
  int behind,
  int aheadOfBase,
});

/// A GitHub token for git against one linked repository: `actingUserId`'s
/// own when given (a push a person clicked), else a one-repository token
/// (`write` for pushes).
typedef GitHubRepoGitToken =
    Future<String?> Function({
      required String workspaceId,
      required String owner,
      required String repo,
      String? actingUserId,
      bool write,
    });

/// Server-side data for the messaging IDE (Explorer, Source Control, file viewer) over `repos.*` /
/// `conversation.changes`. Clients are thin; the server owns checkouts and CoW worktrees.
///
/// Every method requires `workspaceId`; unlinked repos/worktrees are not found (no cross-workspace leak).
class RepoIdeDataService with _WorktreeChangeGate {
  /// Creates a [RepoIdeDataService].
  ///
  /// [_fileSearch] is REQUIRED: the server injects its shared [FffFileSearch] so
  /// the Explorer shares fff's per-root scan caches with the harness tools. It
  /// used to default to [DartFileSearch], which quietly turned a missing
  /// `libfff_c` into a slow pure-Dart walk — exactly the degrade the native
  /// preflight now refuses to boot on. Tests pass [DartFileSearch] explicitly.
  ///
  /// [diff] defaults to the pure-Dart `git`-shelling adapter and is injectable
  /// for tests.
  ///
  /// [_autoFetchInterval] is how often [repoChangesGrouped] refreshes a
  /// published worktree branch from its remote in the background. Null turns
  /// that off, and behind then only moves when Sync fetches.
  RepoIdeDataService({
    required RepoRepository repoRepository,
    required WorkspaceRepository workspaceRepository,
    required IsolatedRepoRepository isolatedRepoRepository,
    required this._fileSearch,
    SessionDiffPort? diff,
    this._githubToken,
    this._publishedBranchHead,
    this._autoFetchInterval,
    this._commitIdentity,
    CommitSigningPort? signing,
  }) : _repos = repoRepository,
       _workspaces = workspaceRepository,
       _isolated = isolatedRepoRepository,
       _diff = diff ?? const ProcessSessionDiffAdapter(),
       _resigner = signing == null ? null : CommitResigner(signing);

  final RepoRepository _repos;
  final WorkspaceRepository _workspaces;
  final IsolatedRepoRepository _isolated;
  final SessionDiffPort _diff;
  final FileSearch _fileSearch;

  /// Resolves the GitHub credential a network-touching git command rides,
  /// for one linked repository. `actingUserId` names the human whose click
  /// drove the operation, so their push is theirs on GitHub; without one it
  /// is a one-repository read token. The repository always comes from the
  /// workspace's linked repo record, never from a worktree's git remote.
  final GitHubRepoGitToken? _githubToken;

  /// Open pull request head for a branch this checkout has never fetched.
  /// Null leaves publication entirely to local git refs.
  final PublishedBranchHead? _publishedBranchHead;

  final Duration? _autoFetchInterval;

  /// Who a person's own commits name, credit and are signed by. Null commits
  /// under the caller's profile identity alone, uncredited and unsigned.
  final PersonCommitIdentity? _commitIdentity;

  /// Signs a person's commits with their own signing key. Null signs
  /// nothing.
  final CommitResigner? _resigner;

  /// When each worktree root last started a background fetch, and the fetch
  /// still running there. Keyed by normalized root, so every client polling
  /// the same worktree shares one schedule.
  final _autoFetchedAt = <String, DateTime>{};
  final _autoFetches = <String, Future<void>>{};

  /// A background fetch that has not finished by then is killed. The next
  /// interval tries again.
  static const _autoFetchTimeout = Duration(seconds: 60);

  /// Reads no more than this many bytes when sniffing a file for a NUL byte.
  static const _binarySniffBytes = 8000;

  /// Cap on fuzzy-search results per request. Requests page through the ranked
  /// list with [searchFiles]'s `offset`, so this bounds a single response, not
  /// the reachable set.
  static const _searchLimit = 200;

  /// Default page size for the Explorer's per-directory listing. Bounds one
  /// `repos.listDirectory` response; the client keeps pulling cursor pages
  /// until the directory is exhausted, so nothing is truncated.
  static const _dirListingPageSize = 500;

  /// Resolved directory listings, keyed by absolute directory path and held
  /// while the directory's mtime is unchanged (see [_resolvedEntries]).
  /// Insertion order IS recency order: a hit reinserts, and the trim drops
  /// from the front.
  final _dirListings =
      <
        String,
        ({
          List<Map<String, dynamic>> entries,
          DateTime mtime,
          DateTime storedAt,
        })
      >{};

  /// How long a listing may be served on an unchanged mtime. Bounds the one
  /// change mtime cannot report: an ignore rule that reclassifies entries the
  /// directory itself never saw touched.
  static const _dirCacheTtl = Duration(seconds: 60);

  /// Directories held at once, and the largest listing worth holding.
  static const _dirCacheMax = 512;
  static const _dirCacheMaxEntries = 4000;

  /// Bounds for content search so a broad query can't blow up the payload.
  static const _contentMaxMatches = 2000; // total matching lines across repos
  static const _contentMaxPerFile = 50; // matching lines kept per file
  static const _contentMaxLineChars = 400; // window kept per matching line

  /// Cap on the number of pathspecs (`include`/`exclude` globs) we forward to
  /// `git grep` — a defensive bound so a huge glob list can't overflow argv.
  static const _contentMaxPathspecs = 256;

  /// Caps a single `worktree.writeFile` payload (4 MB) so a client can't stream
  /// unbounded bytes into a conversation worktree.
  static const _writeMaxBytes = 4 * 1024 * 1024;

  @override
  Future<List<PrFile>> _repoChanges(
    String workspaceId,
    String repoId, {
    String? spaceId,
  }) async {
    if (spaceId != null) {
      final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
      if (worktree == null) {
        return const [];
      }
      return _diff.changedFiles(worktree.path, 'HEAD');
    }
    final repo = await _linkedRepo(workspaceId, repoId);
    if (repo == null) {
      return const [];
    }
    return _diff.changedFiles(repo.path, 'HEAD');
  }

  @override
  Future<RepoChangeGroups> _repoChangesGrouped(
    String workspaceId,
    String repoId, {
    String? spaceId,
    String? viewerId,
  }) async {
    Future<
      ({
        List<PrFile> staged,
        List<PrFile> unstaged,
        bool hasUpstream,
        int ahead,
        int behind,
        int aheadOfBase,
      })
    >
    pack(String root, {bool autoFetch = false}) async {
      // Forge-derived state only for a named viewer; without one, local refs
      // alone decide (fail closed).
      final published = viewerId == null ? null : _publishedBranchHead;
      // Independent reads of one worktree; the panel polls this, so run them
      // side by side.
      final (grouped, sync) = await (
        _diff.groupedChanges(root),
        _branchSync(
          p.normalize(root),
          publishedHeadSha: published == null
              ? null
              : (branch) => published(
                  workspaceId: workspaceId,
                  repoId: repoId,
                  branch: branch,
                  viewerId: viewerId!,
                ),
        ),
      ).wait;
      // Behind is counted against local refs, which only a fetch moves. A
      // branch that was never published has nothing upstream to fetch. The
      // fetch runs as the viewer, so a panel nobody named fetches nothing.
      if (autoFetch && sync.hasUpstream && viewerId != null) {
        _scheduleAutoFetch(p.normalize(root), workspaceId, repoId, viewerId);
      }
      return (
        staged: grouped.staged,
        unstaged: grouped.unstaged,
        hasUpstream: sync.hasUpstream,
        ahead: sync.ahead,
        behind: sync.behind,
        aheadOfBase: sync.aheadOfBase,
      );
    }

    if (spaceId != null) {
      final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
      if (worktree == null) {
        return _emptyGrouped();
      }
      return pack(worktree.path, autoFetch: true);
    }
    final repo = await _linkedRepo(workspaceId, repoId);
    if (repo == null) {
      return _emptyGrouped();
    }
    return pack(repo.path);
  }

  ({
    List<PrFile> staged,
    List<PrFile> unstaged,
    bool hasUpstream,
    int ahead,
    int behind,
    int aheadOfBase,
  })
  _emptyGrouped() => (
    staged: const <PrFile>[],
    unstaged: const <PrFile>[],
    hasUpstream: false,
    ahead: 0,
    behind: 0,
    aheadOfBase: 0,
  );

  /// Ahead/behind from local refs. No network: the poll that reads this runs
  /// every few seconds, and a fetch belongs on [syncBranch].
  ///
  /// `ahead`/`behind` are against the tracking branch. With no tracking config
  /// but an `origin/<branch>` ref (a push that never ran `-u`), they are
  /// against that ref, so commits already on the remote are not counted as
  /// unpushed. A pull request opened outside this checkout leaves no such
  /// ref; [publishedHeadSha] supplies that branch's head from the open-PR
  /// snapshot and the comparison stays local. Only a branch neither git nor
  /// that snapshot has falls back to commits the default branch does not
  /// contain. `aheadOfBase` is always against the default branch and skips
  /// that branch itself, so a published feature branch still counts as a
  /// pull request after it is in sync with upstream.
  Future<({bool hasUpstream, int ahead, int behind, int aheadOfBase})>
  _branchSync(
    String root, {
    Future<String?> Function(String branch)? publishedHeadSha,
  }) async {
    const env = {'GIT_TERMINAL_PROMPT': '0', 'GIT_ASKPASS': 'echo'};
    Future<ProcessResult> git(List<String> args) =>
        _hostGit(root, args, environment: env);

    final headBranch =
        ((await git(['rev-parse', '--abbrev-ref', 'HEAD'])).stdout as String)
            .trim();
    final bases = <String>[
      'origin/HEAD',
      'origin/main',
      'origin/master',
      if (headBranch != 'main') 'main',
      if (headBranch != 'master') 'master',
    ];
    int? unpushed;
    int? aheadOfBase;
    for (final base in bases) {
      final abbrev = await git(['rev-parse', '--abbrev-ref', base]);
      if (abbrev.exitCode != 0) {
        continue;
      }
      final name = (abbrev.stdout as String).trim();
      if (name.isEmpty) {
        continue;
      }
      final n = await git(['rev-list', '--count', '$base..HEAD']);
      if (n.exitCode != 0) {
        continue;
      }
      final count = int.tryParse((n.stdout as String).trim()) ?? 0;
      unpushed ??= count;
      final short = name.startsWith('origin/')
          ? name.substring('origin/'.length)
          : name;
      if (short != headBranch) {
        aheadOfBase ??= count;
      }
      if (aheadOfBase != null) {
        break;
      }
    }

    final upstream = await git([
      'rev-parse',
      '--abbrev-ref',
      '--symbolic-full-name',
      '@{upstream}',
    ]);
    if (upstream.exitCode == 0 &&
        (upstream.stdout as String).trim().isNotEmpty) {
      final counts = await git([
        'rev-list',
        '--left-right',
        '--count',
        'HEAD...@{upstream}',
      ]);
      final parts = (counts.stdout as String).trim().split(RegExp(r'\s+'));
      if (counts.exitCode == 0 && parts.length >= 2) {
        return (
          hasUpstream: true,
          ahead: int.tryParse(parts[0]) ?? 0,
          behind: int.tryParse(parts[1]) ?? 0,
          aheadOfBase: aheadOfBase ?? 0,
        );
      }
      return (
        hasUpstream: true,
        ahead: 0,
        behind: 0,
        aheadOfBase: aheadOfBase ?? 0,
      );
    }

    // A publish that did not set tracking still updates
    // refs/remotes/origin/<branch>. Comparing to the default branch would
    // report those pushed commits as outgoing.
    if (headBranch.isNotEmpty && headBranch != 'HEAD') {
      final remoteBranch = 'origin/$headBranch';
      final remote = await git([
        'rev-parse',
        '--verify',
        '--quiet',
        remoteBranch,
      ]);
      if (remote.exitCode == 0) {
        final counts = await git([
          'rev-list',
          '--left-right',
          '--count',
          'HEAD...$remoteBranch',
        ]);
        final parts = (counts.stdout as String).trim().split(RegExp(r'\s+'));
        if (counts.exitCode == 0 && parts.length >= 2) {
          return (
            hasUpstream: true,
            ahead: int.tryParse(parts[0]) ?? 0,
            behind: int.tryParse(parts[1]) ?? 0,
            aheadOfBase: aheadOfBase ?? 0,
          );
        }
      }
    }

    // A pull request opened from another checkout (or the forge UI) publishes
    // the branch without writing `refs/remotes/origin/<branch>` here. The
    // snapshot head is that remote tip. Counting against the default branch
    // would report those commits as still needing a first push.
    if (publishedHeadSha != null &&
        headBranch.isNotEmpty &&
        headBranch != 'HEAD') {
      final raw = (await publishedHeadSha(headBranch))?.trim() ?? '';
      if (_isCommitSha(raw)) {
        final exists = await git(['cat-file', '-e', '$raw^{commit}']);
        if (exists.exitCode == 0) {
          final counts = await git([
            'rev-list',
            '--left-right',
            '--count',
            'HEAD...$raw',
          ]);
          final parts = (counts.stdout as String).trim().split(RegExp(r'\s+'));
          if (counts.exitCode == 0 && parts.length >= 2) {
            return (
              hasUpstream: true,
              ahead: int.tryParse(parts[0]) ?? 0,
              behind: int.tryParse(parts[1]) ?? 0,
              aheadOfBase: aheadOfBase ?? 0,
            );
          }
        } else {
          // The forge moved and this checkout has not fetched that commit.
          // Still published: Sync fetches it. Publish would claim the branch
          // had never left the machine.
          return (
            hasUpstream: true,
            ahead: 0,
            behind: 1,
            aheadOfBase: aheadOfBase ?? 0,
          );
        }
      }
    }

    return (
      hasUpstream: false,
      ahead: unpushed ?? 0,
      behind: 0,
      aheadOfBase: aheadOfBase ?? 0,
    );
  }

  /// Starts [_fetchUpstream] for [root] unless one is running or the last one
  /// started within [_autoFetchInterval]. A failed fetch still waits out the
  /// interval, so an unreachable remote is not retried on every poll.
  void _scheduleAutoFetch(
    String root,
    String workspaceId,
    String repoId,
    String viewerId,
  ) {
    final interval = _autoFetchInterval;
    if (interval == null || _autoFetches.containsKey(root)) {
      return;
    }
    final now = DateTime.now();
    final last = _autoFetchedAt[root];
    if (last != null && now.difference(last) < interval) {
      return;
    }
    if (_autoFetchedAt.length >= 512) {
      _autoFetchedAt.removeWhere((_, at) => now.difference(at) >= interval);
    }
    _autoFetchedAt[root] = now;
    final run = _fetchUpstream(
      root,
      workspaceId,
      repoId,
      viewerId,
    ).catchError((Object _) {});
    _autoFetches[root] = run;
    unawaited(run.whenComplete(() => _autoFetches.remove(root)));
  }

  /// Completes once every background fetch that is running now has finished.
  @visibleForTesting
  Future<void> autoFetchesSettled() =>
      Future.wait(_autoFetches.values.toList());

  /// Fetches the branch [_branchSync] compares HEAD against into its
  /// remote-tracking ref: the configured upstream, else `origin/<branch>`.
  /// The explicit refspec writes that ref even when the remote's configured
  /// fetch refspec does not cover the branch. Only that one branch, no tags.
  ///
  /// A GitHub remote is fetched on [viewerId]'s own sign-in, never on the
  /// workspace's accountable person: a viewer without one fetches nothing.
  Future<void> _fetchUpstream(
    String root,
    String workspaceId,
    String repoId,
    String viewerId,
  ) async {
    const env = {
      'GIT_TERMINAL_PROMPT': '0',
      'GIT_ASKPASS': 'echo',
      'GIT_CONFIG_NOSYSTEM': '1',
    };
    Future<String> read(List<String> args) async {
      final res = await _hostGit(root, args, environment: env);
      return res.exitCode == 0 ? (res.stdout as String).trim() : '';
    }

    final branch = await read(['symbolic-ref', '--quiet', '--short', 'HEAD']);
    if (branch.isEmpty) {
      return;
    }
    var remote = 'origin';
    var remoteBranch = branch;
    final trackedRemote = await read([
      'config',
      '--get',
      'branch.$branch.remote',
    ]);
    final trackedMerge = await read([
      'config',
      '--get',
      'branch.$branch.merge',
    ]);
    if (trackedRemote.isNotEmpty && trackedMerge.startsWith('refs/heads/')) {
      remote = trackedRemote;
      remoteBranch = trackedMerge.substring('refs/heads/'.length);
    }
    // `.` tracks a local branch; a remote that is not a plain name (a URL
    // pasted into `branch.<name>.remote`) has no remote-tracking namespace.
    if (!_remoteName.hasMatch(remote)) {
      return;
    }
    final url = await read(['config', '--get', 'remote.$remote.url']);
    if (url.isEmpty) {
      return;
    }

    var authEnv = const <String, String>{};
    // SSH spellings count: server-run git rewrites them to HTTPS
    // ([IsolatedGit.githubHttpsRewrites]) and never uses the host's SSH.
    if (_isGitHubRemote(url)) {
      final token = await _githubTokenForRepo(
        workspaceId,
        repoId,
        actingUserId: viewerId,
      );
      if (token == null || token.isEmpty) {
        return;
      }
      authEnv = _githubAuthEnv(token);
    }

    final process = await IsolatedGit.start(
      RigWorktreeGuard.gitArgs([
        '-c',
        'credential.helper=',
        'fetch',
        '--quiet',
        '--no-tags',
        '--no-write-fetch-head',
        remote,
        '+refs/heads/$remoteBranch:refs/remotes/$remote/$remoteBranch',
      ], workingDirectory: root),
      workingDirectory: root,
      environment: {...env, ...authEnv},
    );
    unawaited(process.stdout.drain<void>());
    unawaited(process.stderr.drain<void>());
    await process.exitCode.timeout(
      _autoFetchTimeout,
      onTimeout: () {
        process.kill();
        return -1;
      },
    );
  }

  static final RegExp _remoteName = RegExp(r'^[A-Za-z0-9_][A-Za-z0-9._-]*$');

  static final RegExp _commitSha = RegExp(r'^[0-9a-fA-F]{7,64}$');

  static bool _isCommitSha(String sha) => _commitSha.hasMatch(sha);

  @override
  Future<bool> _stageFiles(
    String workspaceId,
    String spaceId,
    String repoId,
    List<String> paths,
  ) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return false;
    }
    final root = p.normalize(worktree.path);
    final ProcessResult res;
    if (paths.isEmpty) {
      res = await _hostGit(root, ['add', '-A']);
    } else {
      final safe = _confinePaths(root, paths);
      if (safe.isEmpty) {
        return true;
      }
      res = await _hostGit(root, ['add', '--', ...safe]);
    }
    return res.exitCode == 0;
  }

  @override
  Future<bool> _unstageFiles(
    String workspaceId,
    String spaceId,
    String repoId,
    List<String> paths,
  ) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return false;
    }
    final root = p.normalize(worktree.path);
    final ProcessResult res;
    if (paths.isEmpty) {
      res = await _hostGit(root, ['reset', '-q', 'HEAD']);
    } else {
      final safe = _confinePaths(root, paths);
      if (safe.isEmpty) {
        return true;
      }
      res = await _hostGit(root, ['reset', '-q', 'HEAD', '--', ...safe]);
    }
    return res.exitCode == 0;
  }

  /// Repo-relative, worktree-confined subset of [paths] (drops traversals and
  /// absolute escapes). Shared by stage/unstage/revert/commit.
  List<String> _confinePaths(String root, List<String> paths) {
    final safe = <String>[];
    for (final path in paths) {
      final resolved = p.normalize(p.join(root, path));
      if (resolved == root || !p.isWithin(root, resolved)) {
        continue;
      }
      // POSIX-canonical: these strings become git PATHSPECS and client-facing
      // ids; Windows separators are neither.
      final rel = p.relative(resolved, from: root);
      safe.add(Platform.isWindows ? rel.replaceAll('\\', '/') : rel);
    }
    return safe;
  }

  /// Reads a UTF-8 text file from a repo checkout, backing the IDE file
  /// viewer. Rejects traversal outside the repo root and non-linked repos (both
  /// → empty text). Binary files resolve to `(content: '', binary: true)` so the
  /// viewer can show a "binary file" placeholder instead of garbled text.
  ///
  /// [spaceId] scopes the read to that conversation's ISOLATED CoW worktree —
  /// the tree its agents/code-server edit, and the one the Explorer lists — with
  /// no fallback to the linked checkout (see [repoChanges] for why: a fallback
  /// would show a file whose contents the conversation never wrote).
  Future<({String content, bool binary})> readFile(
    String workspaceId,
    String repoId,
    String path, {
    String? spaceId,
  }) async {
    final repoRoot = await _readRoot(workspaceId, repoId, spaceId);
    if (repoRoot == null) {
      return (content: '', binary: false);
    }
    final root = p.normalize(repoRoot);
    final resolved = p.normalize(p.join(root, path));
    // Confine to the repo root — reject `..` traversal and absolute escapes,
    // and a symlink in the tree that points out of it.
    final real = confinedRealPath(root, resolved);
    if (real == null) {
      return (content: '', binary: false);
    }
    final file = File(real);
    if (!file.existsSync()) {
      return (content: '', binary: false);
    }
    final bytes = await file.readAsBytes();
    if (_looksBinary(bytes)) {
      return (content: '', binary: true);
    }
    try {
      return (content: utf8.decode(bytes), binary: false);
    } on FormatException {
      // Not valid UTF-8 → treat as binary rather than emit replacement chars.
      return (content: '', binary: true);
    }
  }

  /// Fuzzy file search across a workspace's repo roots, backing the
  /// Explorer's flat results list and the composer's `@` mentions. Pages
  /// through the ranked list: [offset] skips the first N ranked hits and
  /// [limit] bounds the returned page (the caller pages until satisfied, so
  /// the cap bounds a response, never the reachable set). Each hit carries
  /// the owning `repoId` (matched by its search root) so the client can
  /// group/open per repo.
  ///
  /// [spaceId] scopes the search to the conversation's isolated CoW worktrees
  /// (see [_readRoots]) — the same repos, and the same uncommitted/untracked
  /// files, the Explorer's tree shows.
  ///
  /// Returns raw wire maps (the [FileSearchHit] fields plus `repoId`) rather
  /// than the cc_natives type, keeping the wire contract free of that dependency
  /// — the client rebuilds `FileSearchHit` from the map.
  Future<List<Map<String, dynamic>>> searchFiles(
    String workspaceId,
    String query, {
    int offset = 0,
    int? limit,
    String? spaceId,
  }) async {
    final rootToRepoId = <String, String>{};
    final roots = <String>[];
    for (final entry in await _readRoots(workspaceId, spaceId)) {
      rootToRepoId[entry.root] = entry.repoId;
      roots.add(entry.root);
    }
    if (roots.isEmpty) {
      return const [];
    }
    final trimmed = query.trim();
    final page = (limit ?? _searchLimit).clamp(1, _searchLimit);
    final hits = await _fileSearch
        .search(
          roots: roots,
          query: trimmed,
          limit: page,
          offset: offset < 0 ? 0 : offset,
        )
        .first;
    return [
      for (final hit in hits)
        {
          'absolutePath': hit.absolutePath,
          'relativePath': hit.relativePath,
          'rootPath': hit.rootPath,
          'isDirectory': hit.isDirectory,
          'score': hit.score,
          'repoId': rootToRepoId[p.normalize(hit.rootPath)] ?? '',
        },
    ];
  }

  /// One directory level for the Explorer (lazy tree), cursor-paginated (`has_more`, snake_case — not `hasMore`).
  ///
  /// Uses the conversation CoW worktree when [spaceId] is set. Hides ignore-matched children and `.git`.
  /// Unlinked repo → empty page. Client owns dirs-first sorting/icons.
  Future<Map<String, dynamic>> listDirectory(
    String workspaceId,
    String repoId, {
    String path = '',
    String cursor = '',
    int? limit,
    String? spaceId,
  }) async {
    final repoRoot = await _readRoot(workspaceId, repoId, spaceId);
    if (repoRoot == null) {
      return const {'entries': <Map<String, dynamic>>[], 'has_more': false};
    }
    final root = p.normalize(repoRoot);
    final dir = p.normalize(p.join(root, path));
    // Confine to the repo root — reject `..` traversal and absolute escapes
    // (same rule as [readFile]). A file (not a dir) at `path` lists nothing.
    if (confinedRealPath(root, dir) == null || !Directory(dir).existsSync()) {
      return const {'entries': <Map<String, dynamic>>[], 'has_more': false};
    }
    final entries = await _resolvedEntries(root, dir);
    var page = entries;
    if (cursor.isNotEmpty) {
      page = entries
          .where((e) => (e['relativePath'] as String).compareTo(cursor) > 0)
          .toList();
    }
    final pageSize = (limit ?? _dirListingPageSize).clamp(1, 1000);
    final hasMore = page.length > pageSize;
    return {
      'entries': page.take(pageSize).toList(growable: false),
      'has_more': hasMore,
    };
  }

  /// One directory's children: ignore-filtered and in path order (the order
  /// the cursor pages through), served from [_dirListings] when the directory
  /// has not changed.
  ///
  /// Producing this is the expensive half of a listing — a full `readdir` plus
  /// a `git check-ignore` PROCESS — and it was paid per RESPONSE, so a
  /// directory of 3000 entries spawned git six times to hand back six pages of
  /// the same walk, and every return to the Explorer tab did it again for
  /// every folder on screen. The cache is keyed on the directory's own mtime,
  /// which the filesystem bumps whenever an entry is added, removed or
  /// renamed — exactly the set of changes a listing can show. It cannot see an
  /// edit to a `.gitignore` (which reclassifies entries without touching the
  /// directory), so validity is additionally capped at [_dirCacheTtl] rather
  /// than left to mtime alone.
  Future<List<Map<String, dynamic>>> _resolvedEntries(
    String root,
    String dir,
  ) async {
    final mtime = FileStat.statSync(dir).modified;
    final now = DateTime.now();
    final cached = _dirListings[dir];
    if (cached != null &&
        cached.mtime == mtime &&
        now.difference(cached.storedAt) < _dirCacheTtl) {
      // Reinsert: the map's key order is its recency order (see the trim).
      _dirListings
        ..remove(dir)
        ..[dir] = cached;
      return cached.entries;
    }

    final entries = <Map<String, dynamic>>[];
    await for (final entity in Directory(
      dir,
    ).list(recursive: false, followLinks: false)) {
      final name = p.basename(entity.path);
      // Never surface the git database itself, whatever ignore rules say.
      if (name == '.git') {
        continue;
      }
      // Links are listed as files: resolving them would need a per-entry stat
      // and a cycle story, and the tree opens files by path anyway.
      entries.add({
        'relativePath': _posixRelative(entity.path, root),
        'isDirectory': entity is Directory,
      });
    }
    await _dropIgnored(root, entries);
    entries.sort((a, b) {
      final byPath = (a['relativePath'] as String).compareTo(
        b['relativePath'] as String,
      );
      return byPath;
    });

    final resolved = List<Map<String, dynamic>>.unmodifiable(entries);
    // A directory big enough to matter as a cache entry is also the one a
    // reader is least likely to come back to; skip it rather than let one
    // pathological folder own the budget.
    if (resolved.length <= _dirCacheMaxEntries) {
      _dirListings
        ..remove(dir)
        ..[dir] = (entries: resolved, mtime: mtime, storedAt: now);
      while (_dirListings.length > _dirCacheMax) {
        _dirListings.remove(_dirListings.keys.first);
      }
    }
    return resolved;
  }

  /// Removes entries whose repo-relative paths `git` considers ignored, in
  /// place. One batched `git check-ignore --stdin -z` invocation for the whole
  /// directory (NUL-framed, so a pathological filename cannot corrupt the
  /// batch): exit 0 means some paths matched (printed on stdout), 1 means none
  /// matched, anything else (not a repo, git missing) keeps everything —
  /// matching how a non-git folder lists in full.
  Future<void> _dropIgnored(
    String root,
    List<Map<String, dynamic>> entries,
  ) async {
    if (entries.isEmpty) {
      return;
    }
    final List<String> arguments;
    try {
      arguments = RigWorktreeGuard.gitArgs(const [
        'check-ignore',
        '--stdin',
        '-z',
      ], workingDirectory: root);
    } on RigWorktreeTampered {
      // The listing stands without git: it just keeps what git would hide.
      return;
    }
    final process = await IsolatedGit.start(arguments, workingDirectory: root);
    final batch = StringBuffer();
    for (final entry in entries) {
      batch
        ..write(entry['relativePath'] as String)
        ..write('\u0000');
    }
    try {
      process.stdin.write(batch.toString());
    } catch (_) {
      // The process died early (not a repo); its exit code says so below.
    }
    // dart:io reports a broken pipe on the awaited close, not on the write,
    // so the close needs the same tolerance: git exiting 128 ("not a repo")
    // before reading stdin must keep the listing, not kill the request.
    try {
      await process.stdin.close();
    } catch (_) {}
    final output = await process.stdout.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    if (exitCode != 0 && exitCode != 1) {
      return;
    }
    final ignored = output.split('\u0000').where((l) => l.isNotEmpty).toSet();
    if (ignored.isEmpty) {
      return;
    }
    entries.removeWhere((e) => ignored.contains(e['relativePath']));
  }

  /// Repo-relative, `/`-separated path (Windows-safe), matching the
  /// `FileSearchHit.relativePath` form the rest of this service emits.
  static String _posixRelative(String path, String root) {
    final relative = p.relative(path, from: root);
    return Platform.isWindows ? relative.replaceAll('\\', '/') : relative;
  }

  /// Literal, case-insensitive content search across a workspace's repo roots
  /// (the conversation's isolated CoW worktrees when [spaceId] is given),
  /// backing the Explorer's "Content" mode. Runs `git grep` on each repo
  /// (tracked + untracked, skipping binary + ignored files) so it's fast and
  /// respects `.gitignore`.
  ///
  /// Returns raw wire maps grouped per file — `{repoId, relativePath, matches:
  /// [{line, text}]}` — bounded by [_contentMaxMatches] / [_contentMaxPerFile]
  /// and with each line windowed to [_contentMaxLineChars] around the match.
  /// Match ranges are computed client-side from `text` + the query (so
  /// highlighting stays a presentation concern). An empty query yields nothing.
  ///
  /// [options] toggles case-sensitivity, regex, whole-word and include/exclude
  /// pathspecs. Defaults to a case-insensitive literal search.
  Future<List<Map<String, dynamic>>> searchContent(
    String workspaceId,
    String query, {
    SearchContentOptions options = const SearchContentOptions(),
    String? spaceId,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final roots = await _readRoots(workspaceId, spaceId);
    final out = <Map<String, dynamic>>[];
    var total = 0;
    for (final entry in roots) {
      if (total >= _contentMaxMatches) {
        break;
      }
      final grouped = await _grepRootWithOptions(
        entry.root,
        entry.repoId,
        trimmed,
        options,
        _contentMaxMatches - total,
      );
      for (final group in grouped) {
        out.add(group);
        total += (group['matches'] as List).length;
      }
    }
    return out;
  }

  /// Literal/regex content search across a conversation's ISOLATED CoW worktree
  /// for [repoId] (e.g. the PR-head tree), backing the PR workbench sidebar's
  /// "search in files" mode. Resolves the worktree through the workspace-scoped
  /// registry ([_worktreeFor]); a foreign/unprovisioned space is simply not
  /// found (empty) and it NEVER falls back to the linked checkout — searching
  /// the original repo would surface files that aren't part of the PR's tree.
  /// Runs the same `git grep` (tracked + untracked) as [searchContent], so the
  /// user's uncommitted local edits and new files match too.
  ///
  /// Returns raw wire maps grouped per file — `{repoId, relativePath, matches:
  /// [{line, text}]}` — with the same bounds/truncation as [searchContent].
  Future<List<Map<String, dynamic>>> searchContentInWorktree(
    String workspaceId,
    String spaceId,
    String repoId,
    String query, {
    SearchContentOptions options = const SearchContentOptions(),
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return const [];
    }
    return _grepRootWithOptions(
      p.normalize(worktree.path),
      repoId,
      trimmed,
      options,
      _contentMaxMatches,
    );
  }

  /// Fuzzy file search across ONE conversation's isolated CoW worktree (e.g.
  /// the PR-head tree), backing the PR workbench sidebar's file finder.
  /// Resolves the worktree through the workspace-scoped registry
  /// ([_worktreeFor]); a foreign/unprovisioned space is simply not found
  /// (empty). Unlike [searchFiles] it NEVER falls back to the linked checkout —
  /// the finder lists the same tree the conversation edits (so untracked files
  /// created in the worktree list too).
  ///
  /// Pages through the ranked list exactly like [searchFiles] ([offset] +
  /// [limit] bound a response, never the reachable set). Every hit carries
  /// [repoId] so the client can attribute/open it. Returns raw wire maps
  /// (the [FileSearchHit] fields plus `repoId`), keeping the wire contract free
  /// of the cc_natives type — the client rebuilds `FileSearchHit`.
  Future<List<Map<String, dynamic>>> searchFilesInWorktree(
    String workspaceId,
    String spaceId,
    String repoId,
    String query, {
    int offset = 0,
    int? limit,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return const [];
    }
    final root = p.normalize(worktree.path);
    if (!Directory(root).existsSync()) {
      return const [];
    }
    final trimmed = query.trim();
    final page = (limit ?? _searchLimit).clamp(1, _searchLimit);
    final hits = await _fileSearch
        .search(
          roots: [root],
          query: trimmed,
          limit: page,
          offset: offset < 0 ? 0 : offset,
        )
        .first;
    return [
      for (final hit in hits)
        {
          'absolutePath': hit.absolutePath,
          'relativePath': hit.relativePath,
          'rootPath': hit.rootPath,
          'isDirectory': hit.isDirectory,
          'score': hit.score,
          'repoId': repoId,
        },
    ];
  }

  /// Resolves [options] into one or more `git grep` invocations against [root].
  ///
  /// When [SearchContentOptions.paths] is non-empty the search is restricted
  /// to those files: missing/deleted paths are dropped (so a deleted PR file
  /// cannot 128-exit the whole grep) and an empty remainder returns nothing
  /// rather than widening to the whole tree. Explicit paths are batched in
  /// chunks of [_contentMaxPathspecs] so a large PR does not overflow argv.
  Future<List<Map<String, dynamic>>> _grepRootWithOptions(
    String root,
    String repoId,
    String query,
    SearchContentOptions options,
    int remaining,
  ) async {
    if (remaining <= 0 || !Directory(root).existsSync()) {
      return const [];
    }
    final restricted = options.paths.isNotEmpty;
    var includes = _includePathspecs(options);
    if (restricted) {
      includes = [for (final rel in includes) ?_existingWorktreeRel(root, rel)];
      if (includes.isEmpty) {
        return const [];
      }
    }
    final excludeCount = options.exclude
        .where((raw) => raw.trim().isNotEmpty)
        .length;
    final chunkSize = excludeCount >= _contentMaxPathspecs
        ? 1
        : _contentMaxPathspecs - excludeCount;
    if (includes.isEmpty) {
      return _grepRoot(
        root,
        repoId,
        _buildGrepArgs(query, options),
        remaining,
        query: query,
        options: options,
      );
    }
    final out = <Map<String, dynamic>>[];
    var total = 0;
    for (var i = 0; i < includes.length; i += chunkSize) {
      if (total >= remaining) {
        break;
      }
      final end = i + chunkSize > includes.length
          ? includes.length
          : i + chunkSize;
      final grouped = await _grepRoot(
        root,
        repoId,
        _buildGrepArgs(
          query,
          options,
          includeOverride: includes.sublist(i, end),
        ),
        remaining - total,
        query: query,
        options: options,
      );
      for (final group in grouped) {
        out.add(group);
        total += (group['matches'] as List).length;
      }
    }
    return out;
  }

  /// Runs the prebuilt `git grep` [grepArgs] in [root] and groups the output
  /// per file (`{repoId, relativePath, matches: [{line, text}]}`), attributing
  /// each group to [repoId]. Bounded by [remaining] total matching lines and
  /// [_contentMaxPerFile] per file; each line is windowed to
  /// [_contentMaxLineChars] around the match ([_clipContentLine]). Returns
  /// empty when [root] is missing, `git grep` errors, or [remaining] is
  /// already exhausted — a broken checkout can't abort a multi-repo search.
  Future<List<Map<String, dynamic>>> _grepRoot(
    String root,
    String repoId,
    List<String> grepArgs,
    int remaining, {
    required String query,
    required SearchContentOptions options,
  }) async {
    if (remaining <= 0 || !Directory(root).existsSync()) {
      return const [];
    }
    // exit 0 = matches, 1 = no matches; anything else is a real error.
    final ProcessResult result;
    try {
      result = await _hostGit(root, grepArgs);
    } on RigWorktreeTampered {
      return const [];
    }
    if (result.exitCode != 0 && result.exitCode != 1) {
      return const [];
    }
    final byFile = <String, List<Map<String, dynamic>>>{};
    final order = <String>[];
    var added = 0;
    for (final line in (result.stdout as String).split('\n')) {
      if (line.isEmpty) {
        continue;
      }
      // `git grep -n` emits `<path>:<lineno>:<text>` (paths with colons are
      // pathological; split on the first two colons only).
      final firstColon = line.indexOf(':');
      if (firstColon <= 0) {
        continue;
      }
      final secondColon = line.indexOf(':', firstColon + 1);
      if (secondColon < 0) {
        continue;
      }
      final path = line.substring(0, firstColon);
      final lineNo = int.tryParse(line.substring(firstColon + 1, secondColon));
      if (lineNo == null) {
        continue;
      }
      final text = _clipContentLine(
        line.substring(secondColon + 1),
        query,
        options,
      );
      final matches = byFile.putIfAbsent(path, () {
        order.add(path);
        return [];
      });
      if (matches.length >= _contentMaxPerFile) {
        continue;
      }
      matches.add({'line': lineNo, 'text': text});
      added++;
      if (added >= remaining) {
        break;
      }
    }
    return [
      for (final path in order)
        {'repoId': repoId, 'relativePath': path, 'matches': byFile[path]},
    ];
  }

  /// Adapter that satisfies the RPC fetcher typedef: parses a raw options map
  /// (from the wire) into [SearchContentOptions] and delegates to
  /// [searchContent]. Unknown keys are ignored; missing keys take the
  /// [SearchContentOptions] defaults.
  Future<List<Map<String, dynamic>>> searchContentWithOptions(
    String workspaceId,
    String query, {
    Map<String, Object?> options = const <String, Object?>{},
    String? spaceId,
  }) {
    return searchContent(
      workspaceId,
      query,
      options: _parseSearchOptions(options),
      spaceId: spaceId,
    );
  }

  /// Adapter for the `worktree.searchContent` RPC fetcher: parses the raw wire
  /// options map and delegates to [searchContentInWorktree].
  Future<List<Map<String, dynamic>>> searchWorktreeContentWithOptions(
    String workspaceId,
    String spaceId,
    String repoId,
    String query, {
    Map<String, Object?> options = const <String, Object?>{},
  }) {
    return searchContentInWorktree(
      workspaceId,
      spaceId,
      repoId,
      query,
      options: _parseSearchOptions(options),
    );
  }

  @override
  Future<WorktreeWriteResult?> _writeFile(
    String workspaceId,
    String spaceId,
    String repoId,
    String path,
    String content,
  ) async {
    final bytes = utf8.encode(content);
    if (bytes.length > _writeMaxBytes) {
      return null;
    }
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    final normalized = p.normalize(p.join(root, path));
    final real = normalized == root ? null : confinedRealPath(root, normalized);
    if (real == null) {
      return null;
    }
    final file = File(real);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    // POSIX-canonical like every other wire-facing relative path in this
    // service (the file-search hits already are): the client compares them
    // as strings.
    final rel = p.relative(normalized, from: root);
    return WorktreeWriteResult(
      repoId: repoId,
      path: Platform.isWindows ? rel.replaceAll('\\', '/') : rel,
    );
  }

  @override
  Future<WorktreeRevertResult?> _revertFiles(
    String workspaceId,
    String spaceId,
    String repoId,
    List<String> paths,
  ) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    final safe = <String>[];
    for (final path in paths) {
      final resolved = p.normalize(p.join(root, path));
      if (resolved == root || !p.isWithin(root, resolved)) {
        continue;
      }
      // Repo-relative form for the pathspec argv.
      safe.add(p.relative(resolved, from: root));
    }
    if (safe.isEmpty) {
      return WorktreeRevertResult(
        repoId: repoId,
        reverted: 0,
        skipped: const [],
      );
    }
    var reverted = 0;
    final skipped = <String>[];
    for (final rel in safe) {
      final absolute = p.join(root, rel);
      // `ls-files --error-unmatch` exits non-zero for untracked files: those
      // can't be reverted by checkout-index (they have no index entry) and are
      // reported back so the client can show "untracked file".
      final tracked = await _hostGit(root, [
        'ls-files',
        '--error-unmatch',
        '--',
        rel,
      ]);
      if (tracked.exitCode != 0) {
        skipped.add(rel);
        continue;
      }
      final restore = await _hostGit(root, ['checkout-index', '-f', '--', rel]);
      if (restore.exitCode == 0) {
        reverted++;
        // checkout-index restores content but does not remove a file that was
        // deleted in the working tree only if it's already gone — make sure
        // the restored file actually exists on disk.
        if (!File(absolute).existsSync()) {
          // The file was deleted in the working tree; checkout-index writes it
          // back from the index. If for some reason it didn't, count as skip.
          skipped.add(rel);
          reverted--;
        }
      } else {
        skipped.add(rel);
      }
    }
    return WorktreeRevertResult(
      repoId: repoId,
      reverted: reverted,
      skipped: skipped,
    );
  }

  /// Reads a file from the conversation's isolated worktree (path-confined to
  /// the worktree root). Returns null when the space has no worktree for
  /// [repoId] (foreign / unprovisioned); `(content:'', binary:true)` for binary
  /// or non-UTF-8 files. Symmetric to [writeFile] — the PR/IDE file viewer reads
  /// the PR-head tree through this, not the linked-repo checkout.
  Future<({String content, bool binary})?> readFileFromWorktree(
    String workspaceId,
    String spaceId,
    String repoId,
    String path,
  ) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    final resolved = p.normalize(p.join(root, path));
    final real = confinedRealPath(root, resolved);
    if (real == null) {
      return null;
    }
    final file = File(real);
    if (!file.existsSync()) {
      return (content: '', binary: false);
    }
    final bytes = await file.readAsBytes();
    if (_looksBinary(bytes)) {
      return (content: '', binary: true);
    }
    try {
      return (content: utf8.decode(bytes), binary: false);
    } on FormatException {
      return (content: '', binary: true);
    }
  }

  @override
  Future<Map<String, dynamic>?> _commitAndPush({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    required String message,
    List<String> paths = const [],
    bool push = true,
    bool amend = false,
    bool sync = false,
    String? pushBranch,
    String? authorName,
    String? authorEmail,
    String? actingUserId,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    // Confine any explicit paths to the worktree.
    final safePaths = <String>[];
    for (final path in paths) {
      final resolved = p.normalize(p.join(root, path));
      if (resolved == root || !p.isWithin(root, resolved)) {
        continue;
      }
      safePaths.add(p.relative(resolved, from: root));
    }
    const baseEnv = {
      'GIT_TERMINAL_PROMPT': '0',
      'GIT_ASKPASS': 'echo',
      'GIT_CONFIG_NOSYSTEM': '1',
    };
    Future<ProcessResult> git(List<String> args, {Map<String, String>? env}) =>
        _hostGit(root, args, environment: {...baseEnv, ...?env});

    // Stage the explicit paths (if any). With real staging the client stages via
    // `repos.stage` and commits with NO paths — we then commit the index AS-IS
    // (crucially, no `git add -A`, which would sweep in unstaged changes). A
    // caller that passes explicit paths gets them staged here first.
    if (safePaths.isNotEmpty) {
      final add = await git(['add', '--', ...safePaths]);
      if (add.exitCode != 0) {
        return {
          'committed': false,
          'pushed': false,
          'error': add.stderr.toString(),
        };
      }
    }
    // Anything staged? An amend may only rewrite the previous commit's message
    // (no staged changes), so the guard applies to fresh commits only.
    if (!amend) {
      final staged = await git(['diff', '--cached', '--name-only']);
      if ((staged.stdout as String).trim().isEmpty) {
        return {
          'committed': false,
          'pushed': false,
          'error': 'nothing to commit',
        };
      }
    }
    // The commit is the person's own: their forge-verified address (their
    // profile's git identity where no forge vouches for one), Control
    // Center's credit when their attribution setting is on, and their
    // signing key. A per-invocation identity: no git config file is touched.
    final identity = await _personIdentity(
      workspaceId,
      repoId,
      actingUserId,
      profile:
          (authorName?.trim().isNotEmpty ?? false) &&
              (authorEmail?.trim().isNotEmpty ?? false)
          ? (name: authorName!.trim(), email: authorEmail!.trim())
          : null,
    );
    final author = identity?.author ?? AgentCommitIdentity.controlCenter;
    final name = author.name;
    final email = author.email;
    // `--amend` rewrites HEAD; with an empty message we keep the prior one
    // (`--no-edit`), otherwise the supplied message replaces it.
    final keepMessage = amend && message.trim().isEmpty;
    final commit = await git([
      ...CommitResigner.unsignedGitArgs,
      '-c',
      'user.name=$name',
      '-c',
      'user.email=$email',
      'commit',
      if (amend) '--amend',
      if (keepMessage) '--no-edit' else ...['-m', message],
      // git places each line as a trailer and skips one already there.
      for (final trailer in identity?.coAuthorTrailers ?? const <String>[]) ...[
        '--trailer',
        trailer,
      ],
    ]);
    if (commit.exitCode != 0) {
      return {
        'committed': false,
        'pushed': false,
        'error': commit.stderr.toString(),
      };
    }
    var headSha = ((await git(['rev-parse', 'HEAD'])).stdout as String).trim();
    final signError = await _signCommitted(root, actingUserId, identity);
    if (signError != null) {
      // Never push what should have been signed and is not.
      return {
        'committed': true,
        'pushed': false,
        'headSha': headSha,
        'error': signError,
      };
    }
    headSha = ((await git(['rev-parse', 'HEAD'])).stdout as String).trim();
    if (!push) {
      return {'committed': true, 'pushed': false, 'headSha': headSha};
    }
    // Push to the PR head branch on origin, token via env (not argv), on the
    // ACTING USER's credential so GitHub attributes the push to them.
    final branch = (pushBranch?.trim().isNotEmpty ?? false)
        ? pushBranch!.trim()
        : worktree.branch;
    final token = await _githubTokenForRepo(
      workspaceId,
      repoId,
      actingUserId: actingUserId,
      write: true,
    );
    final env = _githubAuthEnv(token);
    String? remoteTip;
    // "Commit & sync": integrate any remote commits before pushing so the push
    // fast-forwards (VS Code's Sync = pull --rebase then push). A missing remote
    // branch (first push) or a failed fetch just falls through to the push; a
    // rebase CONFLICT aborts and surfaces git's message verbatim.
    if (sync) {
      // `credential.helper=` pins auth to the header env: with no token the
      // fetch fails loudly instead of borrowing whatever account the host's
      // keychain helper happens to hold.
      final fetch = await git([
        '-c',
        'credential.helper=',
        'fetch',
        'origin',
        branch,
      ], env: env);
      remoteTip = fetch.exitCode == 0 ? 'FETCH_HEAD' : null;
      if (remoteTip != null) {
        final rebase = await git([
          ...CommitResigner.unsignedGitArgs,
          '-c',
          'user.name=$name',
          '-c',
          'user.email=$email',
          'rebase',
          'FETCH_HEAD',
        ]);
        if (rebase.exitCode != 0) {
          await git(['rebase', '--abort']);
          return {
            'committed': true,
            'pushed': false,
            'headSha': headSha,
            'error': (rebase.stderr as String).trim(),
          };
        }
      }
    }
    // Everything this push sends that is the person's own goes out signed.
    final outgoingError = await _signOutgoing(
      root,
      actingUserId,
      identity,
      remoteTip: remoteTip,
    );
    headSha = ((await git(['rev-parse', 'HEAD'])).stdout as String).trim();
    if (outgoingError != null) {
      return {
        'committed': true,
        'pushed': false,
        'headSha': headSha,
        'error': outgoingError,
      };
    }
    // An amended commit rewrites history, so its push leases-force; a fresh
    // commit (or a rebased sync) fast-forwards. `credential.helper=` keeps the
    // host's keychain out of it — the header env is the only credential.
    final pushRes = await git([
      '-c',
      'credential.helper=',
      'push',
      // Track the remote branch so the next status read can show ahead/behind
      // instead of offering Publish again for a branch that already exists.
      '-u',
      if (amend) '--force-with-lease',
      'origin',
      'HEAD:refs/heads/$branch',
    ], env: env);
    if (pushRes.exitCode != 0) {
      final reason = _pushRefusalText(pushRes);
      return {
        'committed': true,
        'pushed': false,
        'headSha': headSha,
        'error': ?reason,
      };
    }
    return {'committed': true, 'pushed': true, 'headSha': headSha};
  }

  @override
  Future<Map<String, dynamic>?> _publishBranch({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    String? branchOverride,
    String? actingUserId,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    const baseEnv = {
      'GIT_TERMINAL_PROMPT': '0',
      'GIT_ASKPASS': 'echo',
      'GIT_CONFIG_NOSYSTEM': '1',
    };
    Future<ProcessResult> git(List<String> args, {Map<String, String>? env}) =>
        _hostGit(root, args, environment: {...baseEnv, ...?env});

    final branch = (branchOverride?.trim().isNotEmpty ?? false)
        ? branchOverride!.trim()
        : worktree.branch.trim();
    if (branch.isEmpty) {
      return {
        'pushed': false,
        'error': 'the worktree has no branch to publish',
      };
    }
    // Report (never silently include) work the push leaves behind.
    final dirty = await git(['status', '--porcelain']);
    final uncommitted = (dirty.stdout as String)
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .length;

    // The ACTING USER's credential, so publishing the branch is attributed on
    // GitHub to the human who clicked, not to the server's App.
    final token = await _githubTokenForRepo(
      workspaceId,
      repoId,
      actingUserId: actingUserId,
      write: true,
    );
    final env = _githubAuthEnv(token);
    final signError = await _signOutgoing(
      root,
      actingUserId,
      await _personIdentity(workspaceId, repoId, actingUserId),
    );
    if (signError != null) {
      return {'branch': branch, 'pushed': false, 'error': signError};
    }
    // No lease-force: publishing must never overwrite someone else's commits on
    // a branch that already exists. A rejected push surfaces git's own message,
    // which is the actionable thing (diverged / protected / no permission).
    // `credential.helper=` keeps the host's keychain out of it.
    final headSha = ((await git(['rev-parse', 'HEAD'])).stdout as String)
        .trim();
    final pushRes = await git([
      '-c',
      'credential.helper=',
      'push',
      '-u',
      'origin',
      'HEAD:refs/heads/$branch',
    ], env: env);
    if (pushRes.exitCode != 0) {
      final reason = _pushRefusalText(pushRes);
      return {
        'branch': branch,
        'headSha': headSha,
        'pushed': false,
        'uncommitted': uncommitted,
        'error': ?reason,
      };
    }
    return {
      'branch': branch,
      'headSha': headSha,
      'pushed': true,
      'uncommitted': uncommitted,
    };
  }

  @override
  Future<Map<String, dynamic>?> _syncBranch({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    String? actingUserId,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    // Two fetches in one repository race for the ref locks. Sync fetches
    // itself, so the background one is not due again for a full interval.
    await _autoFetches[root];
    _autoFetchedAt[root] = DateTime.now();
    const baseEnv = {
      'GIT_TERMINAL_PROMPT': '0',
      'GIT_ASKPASS': 'echo',
      'GIT_CONFIG_NOSYSTEM': '1',
      // A conflicted rebase must not open an editor; we abort and report.
      'GIT_EDITOR': 'true',
    };
    Future<ProcessResult> git(List<String> args, {Map<String, String>? env}) =>
        _hostGit(root, args, environment: {...baseEnv, ...?env});

    var branch = worktree.branch.trim();
    if (branch.isEmpty) {
      branch =
          ((await git(['rev-parse', '--abbrev-ref', 'HEAD'])).stdout as String)
              .trim();
    }
    if (branch.isEmpty || branch == 'HEAD') {
      return {
        'pulled': false,
        'pushed': false,
        'dirty': false,
        'error': 'the worktree has no branch to sync',
      };
    }

    final token = await _githubTokenForRepo(
      workspaceId,
      repoId,
      actingUserId: actingUserId,
      write: true,
    );
    final env = _githubAuthEnv(token);
    final identity = await _personIdentity(workspaceId, repoId, actingUserId);

    // A missing remote branch (first publish) fails the fetch; the push below
    // creates it. Any other fetch failure falls through to the push, which
    // reports the network error if it is real.
    final fetch = await git([
      '-c',
      'credential.helper=',
      'fetch',
      'origin',
      branch,
    ], env: env);
    final fetched = fetch.exitCode == 0;
    var pulled = false;
    if (fetched) {
      final behindRes = await git(['rev-list', '--count', 'HEAD..FETCH_HEAD']);
      final behind = behindRes.exitCode == 0
          ? int.tryParse((behindRes.stdout as String).trim()) ?? 0
          : 0;
      if (behind > 0) {
        final status = await git(['status', '--porcelain', '-z']);
        final dirtyNames = status.exitCode == 0
            ? _porcelainPaths(status.stdout as String)
            : const <String>{};
        final dirty = dirtyNames.isNotEmpty;
        if (await _pullWouldConflict(git, dirtyNames)) {
          // Leave the worktree untouched. The client asks whether a person
          // or an agent should resolve it.
          return {
            'pulled': false,
            'pushed': false,
            'dirty': dirty,
            'conflict': true,
          };
        }
        if (dirty) {
          return {'pulled': false, 'pushed': false, 'dirty': true};
        }
        // The person who clicked re-commits their local commits onto the
        // remote's: under their verified identity when a forge vouches for
        // one (signed with their key before the push), else as Control Center.
        final rebase = await git([
          ...CommitResigner.unsignedGitArgs,
          if (identity != null) ...[
            '-c',
            'user.name=${identity.author.name}',
            '-c',
            'user.email=${identity.author.email}',
          ],
          'rebase',
          'FETCH_HEAD',
        ]);
        if (rebase.exitCode != 0) {
          await git(['rebase', '--abort']);
          final err = (rebase.stderr as String).trim();
          final conflict =
              err.contains('CONFLICT') || err.contains('could not apply');
          return {
            'pulled': false,
            'pushed': false,
            'dirty': false,
            'conflict': conflict,
            'error': conflict ? null : err,
          };
        }
        pulled = true;
      }
    }

    final aheadRes = fetched
        ? await git(['rev-list', '--count', 'FETCH_HEAD..HEAD'])
        : null;
    final ahead = aheadRes == null || aheadRes.exitCode != 0
        ? (fetched ? 0 : 1)
        : int.tryParse((aheadRes.stdout as String).trim()) ?? 0;
    if (fetched && ahead == 0) {
      return {'pulled': pulled, 'pushed': false, 'dirty': false};
    }
    final signError = await _signOutgoing(
      root,
      actingUserId,
      identity,
      remoteTip: fetched ? 'FETCH_HEAD' : null,
    );
    if (signError != null) {
      return {
        'pulled': pulled,
        'pushed': false,
        'dirty': false,
        'error': signError,
      };
    }
    final pushRes = await git([
      '-c',
      'credential.helper=',
      'push',
      '-u',
      'origin',
      'HEAD:refs/heads/$branch',
    ], env: env);
    if (pushRes.exitCode != 0) {
      // The pull, when there was one, already landed. Say so separately from
      // the refusal so a protected branch does not look like a failed fetch.
      return {
        'pulled': pulled,
        'pushed': false,
        'dirty': false,
        'pushRefused': true,
        'error': ?_pushRefusalText(pushRes),
      };
    }
    return {'pulled': pulled, 'pushed': true, 'dirty': false};
  }

  /// Local branches, remote-tracking refs and tags in the conversation
  /// worktree, newest commit first. No network: a fetch belongs on
  /// [syncBranch]. Null when the space has no worktree for [repoId].
  Future<Map<String, dynamic>?> listBranches({
    required String workspaceId,
    required String spaceId,
    required String repoId,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    final head =
        ((await _git(root, ['rev-parse', '--abbrev-ref', 'HEAD'])).stdout
                as String)
            .trim();
    final listed = await _git(root, const [
      'for-each-ref',
      '--count=400',
      '--sort=-committerdate',
      '--format=%(refname)\x1f%(objectname:short)\x1f%(committerdate:unix)\x1f%(subject)',
      'refs/heads',
      'refs/remotes',
      'refs/tags',
    ]);
    final refs = <Map<String, Object?>>[];
    if (listed.exitCode == 0) {
      for (final line in (listed.stdout as String).split('\n')) {
        if (line.isEmpty) {
          continue;
        }
        final parts = line.split('\x1f');
        if (parts.length < 4) {
          continue;
        }
        final refname = parts[0];
        if (refname == 'refs/remotes/origin/HEAD') {
          continue;
        }
        final parsed = _parseRefName(refname);
        if (parsed == null) {
          continue;
        }
        final (kind, name, localName) = parsed;
        refs.add({
          'name': name,
          'kind': kind,
          'sha': parts[1],
          'committedAt': int.tryParse(parts[2]) ?? 0,
          'subject': parts.sublist(3).join('\x1f'),
          'current': kind == 'branch' && name == head,
          'localName': localName,
        });
      }
    }
    return {'current': head, 'detached': head == 'HEAD', 'refs': refs};
  }

  @override
  Future<Map<String, dynamic>?> _checkoutBranch({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    String? branch,
    String? startPoint,
    bool create = false,
    bool detach = false,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    final previous =
        ((await _git(root, ['rev-parse', '--abbrev-ref', 'HEAD'])).stdout
                as String)
            .trim();
    final previousSha =
        ((await _git(root, ['rev-parse', 'HEAD'])).stdout as String).trim();

    if (detach) {
      final start = (startPoint?.trim().isNotEmpty ?? false)
          ? startPoint!.trim()
          : 'HEAD';
      if (!_isRefToken(start)) {
        return {'ok': false, 'error': 'invalid start point'};
      }
      final verified = await _verifyCommit(root, start);
      if (!verified) {
        return {'ok': false, 'error': 'unknown start point'};
      }
      final res = await _git(root, ['switch', '--detach', start]);
      if (res.exitCode != 0) {
        return _checkoutFailure(res);
      }
      final recorded = await _recordBranch(
        root,
        worktree,
        branch: '',
        previous: previous,
        previousSha: previousSha,
      );
      if (recorded != null) {
        return recorded;
      }
      return {'ok': true, 'branch': '', 'detached': true, 'dirty': false};
    }

    final name = branch?.trim() ?? '';
    if (!_isRefToken(name)) {
      return {'ok': false, 'error': 'invalid branch name'};
    }
    final format = await _git(root, ['check-ref-format', '--branch', name]);
    if (format.exitCode != 0) {
      return {'ok': false, 'error': 'invalid branch name'};
    }
    final start = startPoint?.trim() ?? '';
    if (start.isNotEmpty && !_isRefToken(start)) {
      return {'ok': false, 'error': 'invalid start point'};
    }

    final ProcessResult res;
    if (create) {
      final atHead = start.isEmpty || start == 'HEAD' || start == previous;
      if (atHead) {
        res = await _git(root, ['switch', '-c', name]);
      } else {
        if (!await _verifyCommit(root, start)) {
          return {'ok': false, 'error': 'unknown start point'};
        }
        final remote = await _git(root, [
          'show-ref',
          '--verify',
          '--quiet',
          'refs/remotes/$start',
        ]);
        res = remote.exitCode == 0
            ? await _git(root, ['switch', '--track', '-c', name, start])
            : await _git(root, ['switch', '-c', name, start]);
      }
    } else {
      final local = await _git(root, [
        'show-ref',
        '--verify',
        '--quiet',
        'refs/heads/$name',
      ]);
      if (local.exitCode == 0) {
        res = await _git(root, ['switch', '--', name]);
      } else {
        final remote = await _git(root, [
          'show-ref',
          '--verify',
          '--quiet',
          'refs/remotes/origin/$name',
        ]);
        if (remote.exitCode != 0) {
          return {'ok': false, 'error': 'no such branch'};
        }
        res = await _git(root, [
          'switch',
          '--track',
          '-c',
          name,
          'origin/$name',
        ]);
      }
    }
    if (res.exitCode != 0) {
      return _checkoutFailure(res);
    }
    final checked =
        ((await _git(root, ['rev-parse', '--abbrev-ref', 'HEAD'])).stdout
                as String)
            .trim();
    final recorded = await _recordBranch(
      root,
      worktree,
      branch: checked == 'HEAD' ? '' : checked,
      previous: previous,
      previousSha: previousSha,
      created: create ? name : null,
    );
    if (recorded != null) {
      return recorded;
    }
    return {
      'ok': true,
      'branch': checked == 'HEAD' ? '' : checked,
      'detached': checked == 'HEAD',
      'dirty': false,
    };
  }

  /// Writes [branch] onto the isolated-repo row. On failure, checks the
  /// previous commit back out (and deletes [created]) so the disk and the
  /// row cannot disagree about what a later push would publish.
  Future<Map<String, dynamic>?> _recordBranch(
    String root,
    IsolatedRepo worktree, {
    required String branch,
    required String previous,
    required String previousSha,
    String? created,
  }) async {
    try {
      await _isolated.upsert(worktree.copyWith(branch: branch));
    } on Object {
      if (previous == 'HEAD') {
        await _git(root, ['switch', '--detach', previousSha]);
      } else if (previous.isNotEmpty) {
        await _git(root, ['switch', '--', previous]);
      }
      if (created != null && created.isNotEmpty) {
        await _git(root, ['branch', '-D', created]);
      }
      return {'ok': false, 'error': 'could not record the checked-out branch'};
    }
    return null;
  }

  Future<bool> _verifyCommit(String root, String start) async {
    final verified = await _git(root, [
      'rev-parse',
      '--verify',
      '--end-of-options',
      '$start^{commit}',
    ]);
    return verified.exitCode == 0;
  }

  @override
  Future<Map<String, dynamic>?> _syncToPrHead(
    String workspaceId,
    String spaceId,
    String repoId, {
    required String headRef,
    required String branch,
    required String? actingUserId,
  }) async {
    final worktree = await _worktreeFor(workspaceId, spaceId, repoId);
    if (worktree == null) {
      return null;
    }
    final root = p.normalize(worktree.path);
    Future<ProcessResult> git(List<String> args, {Map<String, String>? env}) =>
        _hostGit(root, args, environment: env);

    // Never clobber uncommitted work — bail out and let the client warn.
    final status = await git(['status', '--porcelain']);
    if (status.exitCode == 0 && (status.stdout as String).trim().isNotEmpty) {
      return {'ok': true, 'synced': false, 'dirty': true};
    }

    final repo = await _linkedRepo(workspaceId, repoId);
    if (repo == null || !repo.hasForgeRemote) {
      return {'ok': false, 'error': 'no GitHub remote for repo'};
    }
    // The acting person's token (a missing sign-in throws before any fetch),
    // in the auth header env, never argv.
    final token = await _githubTokenForRepo(
      workspaceId,
      repoId,
      actingUserId: actingUserId,
    );
    if (token == null || token.isEmpty) {
      return {'ok': false, 'error': 'GitHub authentication required'};
    }
    final cleanUrl =
        'https://${repo.forge.gitHost}/${repo.remoteOwner}/${repo.remoteName}.git';
    final fetchEnv = {
      'GIT_TERMINAL_PROMPT': '0',
      'GIT_ASKPASS': 'echo',
      ..._githubAuthEnv(token),
    };

    final fetch = await git([
      '-c',
      'credential.helper=',
      'fetch',
      '--no-tags',
      '--force',
      cleanUrl,
      headRef,
    ], env: fetchEnv);
    if (fetch.exitCode != 0) {
      return {'ok': false, 'error': (fetch.stderr as String).trim()};
    }
    // `-B` (re)creates [branch] at FETCH_HEAD even if it's the current branch,
    // guaranteeing the working tree matches the PR head.
    final checkout = await git([
      'checkout',
      '--force',
      '-B',
      branch,
      'FETCH_HEAD',
    ]);
    if (checkout.exitCode != 0) {
      return {'ok': false, 'error': (checkout.stderr as String).trim()};
    }
    await git(['clean', '-ffdx']);
    final headSha = ((await git(['rev-parse', 'HEAD'])).stdout as String)
        .trim();
    return {'ok': true, 'synced': true, 'headSha': headSha};
  }

  /// Resolves the (workspace-owned) isolated worktree for one conversation +
  /// repo, or null when none exists / the space isn't owned by the workspace.
  /// The filesystem root ONE repo read should run against: the conversation's
  /// isolated CoW worktree when [spaceId] is given, else the linked checkout.
  ///
  /// Null when there is nothing to read — a repo not linked to the workspace, or
  /// a space that owns no worktree for it. There is deliberately no fallback
  /// from the second case to the first: the conversation's writes never touch
  /// the linked checkout, so serving it would show a tree that disagrees with
  /// what the operator (and every agent) is actually editing.
  Future<String?> _readRoot(
    String workspaceId,
    String repoId,
    String? spaceId,
  ) async {
    if (spaceId != null) {
      return (await _worktreeFor(workspaceId, spaceId, repoId))?.path;
    }
    return (await _linkedRepo(workspaceId, repoId))?.path;
  }

  /// The roots a WORKSPACE-WIDE repo read should run across, paired with the
  /// repo id each one belongs to: the conversation's isolated CoW worktrees
  /// when [spaceId] is given (so the Explorer's search sees exactly the repos
  /// its tree lists), else every linked checkout.
  ///
  /// Roots that no longer exist on disk are skipped rather than fatal, so one
  /// broken checkout cannot abort the whole search.
  Future<List<({String root, String repoId})>> _readRoots(
    String workspaceId,
    String? spaceId,
  ) async {
    final candidates = <({String root, String repoId})>[];
    if (spaceId != null) {
      for (final w in await _isolated.forSpace(workspaceId, spaceId)) {
        candidates.add((root: p.normalize(w.path), repoId: w.repoId));
      }
    } else {
      for (final repo in await _linkedRepos(workspaceId)) {
        candidates.add((root: p.normalize(repo.path), repoId: repo.id));
      }
    }
    return [
      for (final c in candidates)
        if (Directory(c.root).existsSync()) c,
    ];
  }

  Future<ProcessResult> _git(String root, List<String> args) => _hostGit(
    root,
    args,
    environment: const {
      'GIT_TERMINAL_PROMPT': '0',
      'GIT_ASKPASS': 'echo',
      'GIT_CONFIG_NOSYSTEM': '1',
    },
  );

  /// Host git in [root], which a rig may have mounted: hardened there, and
  /// throws [RigWorktreeTampered] when the rig changed its git metadata.
  ///
  /// Isolated like every server-run git ([IsolatedGit]): a space worktree is
  /// the server's copy, so the operator's global config, credential helpers,
  /// signing key and SSH agent never apply to a member's commit, fetch or
  /// push, and no repository hook runs: an agent or a pull request can write
  /// this tree, and git here runs on the host. A rebase needs a committer, which no global config supplies any more:
  /// [_serverIdentity] stands in, and a caller's own `-c user.*` (a commit's
  /// author) comes later and wins.
  Future<ProcessResult> _hostGit(
    String root,
    List<String> args, {
    Map<String, String>? environment,
  }) => IsolatedGit.run(
    RigWorktreeGuard.gitArgs([
      ..._serverIdentity,
      ...args,
    ], workingDirectory: root),
    workingDirectory: root,
    environment: environment,
  );

  /// Who a server-side history rewrite (a pull's rebase) is committed by when
  /// no person can be named: Control Center, never the operator's global
  /// identity.
  static const List<String> _serverIdentity = [
    '-c',
    'user.name=${AgentCommitIdentity.controlCenterName}',
    '-c',
    'user.email=${AgentCommitIdentity.controlCenterEmail}',
  ];

  /// Whether [url] names a github.com repository, over HTTPS or SSH.
  static bool _isGitHubRemote(String url) =>
      url.startsWith('https://github.com/') ||
      url.startsWith('git@github.com:') ||
      url.startsWith('ssh://git@github.com/');

  Future<IsolatedRepo?> _worktreeFor(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async {
    final worktrees = await _isolated.forSpace(workspaceId, spaceId);
    for (final w in worktrees) {
      if (w.repoId == repoId) {
        return w;
      }
    }
    return null;
  }

  /// Aggregate working-tree diff (vs HEAD, incl. untracked) across a
  /// conversation's isolated copy-on-write worktrees, backing the conversation
  /// changes view. Workspace-scoped via the registry lookup: only worktrees the
  /// caller's workspace owns are diffed.
  Future<List<PrFile>> conversationChanges(
    String workspaceId,
    String spaceId,
  ) async {
    final worktrees = await _isolated.forSpace(workspaceId, spaceId);
    final files = <PrFile>[];
    for (final worktree in worktrees) {
      files.addAll(await _diff.changedFiles(worktree.path, 'HEAD'));
    }
    return files;
  }

  Future<List<Repo>> _linkedRepos(String workspaceId) =>
      _workspaces.watchReposForWorkspace(workspaceId).first;

  /// The token for a linked GitHub repository, or null when [repoId] is not
  /// linked to [workspaceId] or not on GitHub.
  Future<String?> _githubTokenForRepo(
    String workspaceId,
    String repoId, {
    String? actingUserId,
    bool write = false,
  }) async {
    final lookup = _githubToken;
    if (lookup == null) {
      return null;
    }
    final repo = await _linkedRepo(workspaceId, repoId);
    if (repo == null ||
        repo.forge != ForgeHost.github ||
        !repo.hasForgeRemote) {
      return null;
    }
    return lookup(
      workspaceId: workspaceId,
      owner: repo.remoteOwner,
      repo: repo.remoteName,
      actingUserId: actingUserId,
      write: write,
    );
  }

  Future<Repo?> _linkedRepo(String workspaceId, String repoId) async {
    if (!await _workspaces.isRepoLinkedToWorkspace(workspaceId, repoId)) {
      return null;
    }
    return _repos.getById(workspaceId, repoId);
  }

  static bool _looksBinary(List<int> bytes) {
    final limit = bytes.length < _binarySniffBytes
        ? bytes.length
        : _binarySniffBytes;
    for (var i = 0; i < limit; i++) {
      if (bytes[i] == 0) {
        return true;
      }
    }
    return false;
  }
}
