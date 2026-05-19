import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/ports/repo_script_port.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/services/slugify.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/settings/domain/services/branch_template_resolver.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// What a space is supposed to have checked out: which of the workspace's repos
/// and, for a PR-review space, at which ref.
///
/// A space-level fact, not a call-level one — which is the point. It is
/// resolved from the space itself so that every provisioning entry point
/// (creation, a later agent dispatch, a retry) reaches the same answer.
class SpaceCheckoutScope {
  /// Creates a [SpaceCheckoutScope].
  const SpaceCheckoutScope({
    this.repoIds,
    this.prHeadRef,
    this.prHeadRepoFullName,
    this.prBranch,
    this.repoBranches = const {},
  });

  /// The repo ids the space checks out. Null means "no recorded selection" —
  /// every linked repo. An EMPTY set means the space deliberately checks out
  /// nothing, and is NOT the same as null.
  final Set<String>? repoIds;

  /// The ref the PR repo is pinned to (e.g. `refs/pull/42/head`), when this is
  /// a PR-review space.
  final String? prHeadRef;

  /// `owner/repo` of the repo under review, when this is a PR-review space.
  final String? prHeadRepoFullName;

  /// The local branch the PR head is checked out on (e.g. `pr/42`).
  final String? prBranch;

  /// The BASE branch each repo's worktree is cut from, keyed by repo id. A repo
  /// absent from the map takes its own default branch (`origin/HEAD`).
  ///
  /// Distinct from [prBranch], which is the branch a PR head is checked out ON.
  /// This one only moves the starting point: the worktree still gets its own
  /// `conv/<space>` branch, so nothing an agent commits lands on the base.
  final Map<String, String> repoBranches;
}

/// Concrete [RepoWorkspaceProvisionerPort]: sets up the per-SPACE root
/// (shared `repos/` + a per-agent overlay cwd) and provisions/destroys isolated
/// CoW worktrees via [RepoIsolationPort], persisting them in [IsolatedRepoRepository].
///
/// Idempotent: re-dispatching into the same space reuses existing worktrees and
/// the per-agent overlay, and every conversation in that space works in the one
/// checkout. Best-effort: a failure to provision one repo is logged and does not
/// block dispatch (the agent still gets a working directory).
class RepoWorkspaceProvisioner implements RepoWorkspaceProvisionerPort {
  /// Creates a [RepoWorkspaceProvisioner].
  RepoWorkspaceProvisioner({
    required WorkspaceFilesystemPort filesystem,
    required RepoIsolationPort isolation,
    required IsolatedRepoRepository registry,
    required WorkspaceRepository workspaces,
    required Future<String?> Function() githubToken,
    required Future<String> Function(String workspaceId) branchTemplate,
    Future<bool> Function(String workspaceId, String spaceId)? spaceExists,
    Future<SpaceCheckoutScope?> Function(String workspaceId, String spaceId)?
    spaceCheckoutScope,
    RepoScriptPort? scripts,
  }) : _filesystem = filesystem,
       _isolation = isolation,
       _registry = registry,
       _workspaces = workspaces,
       _githubToken = githubToken,
       _branchTemplate = branchTemplate,
       _spaceExists = spaceExists,
       _spaceCheckoutScope = spaceCheckoutScope,
       _scripts = scripts;

  final WorkspaceFilesystemPort _filesystem;
  final RepoIsolationPort _isolation;
  final IsolatedRepoRepository _registry;
  final WorkspaceRepository _workspaces;
  final Future<String?> Function() _githubToken;

  /// Runs the repos' configured lifecycle scripts (setup after a fresh
  /// worktree is materialized, archive before one is destroyed). Optional so
  /// hosts without the script feature (and tests) provision exactly as before.
  final RepoScriptPort? _scripts;

  /// Resolves the branch-name template for a workspace.
  ///
  /// Workspace-scoped and asynchronous because the template is workspace
  /// POLICY — everyone working in a workspace must produce the same branch
  /// shape — so it is read from that workspace's settings store rather than
  /// from a device-local preference. It used to be a synchronous no-arg
  /// callback that the server wired to the built-in default, which meant the
  /// setting in the UI had never had any effect at all.
  final Future<String> Function(String workspaceId) _branchTemplate;

  /// Resolves what a space is SUPPOSED to check out, when the caller did not
  /// say. Null callback (or a null result) keeps the historical behaviour: every
  /// linked repo, on its default branch.
  ///
  /// This closes the gap between "the space was provisioned correctly" and
  /// "every later dispatch into it re-provisions from scratch". Only
  /// `SpaceProvisioningService` ever passed a scope; `AgentDispatchService`
  /// calls this same method with none on EVERY dispatch, so a PR review space
  /// scoped to one repo grew a full clone of every other workspace repo the
  /// moment an agent was sent into it — once per agent. The space, not the call
  /// site, is the authority on its own checkout.
  final Future<SpaceCheckoutScope?> Function(
    String workspaceId,
    String spaceId,
  )?
  _spaceCheckoutScope;

  /// Whether a space still exists — the sweep's second staleness signal
  /// alongside "the directory vanished". Optional so a host that cannot answer
  /// it (or a test) simply keeps the directory-only behaviour.
  final Future<bool> Function(String workspaceId, String spaceId)? _spaceExists;

  final _uuid = const Uuid();

  /// Live cancellation sources, one per space with provisioning in flight,
  /// refcounted by how many runs share it.
  ///
  /// Keyed by space rather than held by the caller because a single space can
  /// be provisioning on two paths at once (the background provisioner off
  /// `SpaceCreated` and the inline call a dispatch makes to resolve its cwd),
  /// and stopping the work has to stop both — otherwise the clone the operator
  /// cancelled quietly finishes on the other path.
  final Map<String, _SpaceCancellation> _cancelSources = {};

  /// Per-`(workspace, space, repo)` lock chain serializing [_ensureRepo].
  ///
  /// A space is provisioned from more than one path at once — the background
  /// run off `SpaceCreated` and the inline call every `dispatchAgent` makes to
  /// resolve its cwd — and a fan-out sends several agents into one room within
  /// the same second. [_cancelSources] already accounts for that overlap; what
  /// it does not do is stop the two runs from materializing the SAME worktree.
  ///
  /// Unserialized, both read `forUnitRepo` as empty, both ask the backend for a
  /// copy at one destination, and the loser fails with `already_exists` — then
  /// runs its own failure cleanup, which reaps the directory the WINNER just
  /// created and registered. The registry is then left holding a row for a
  /// worktree that is gone, and the agent's overlay symlinks into nothing.
  ///
  /// Keyed per repo rather than per space so two different repos of one space
  /// still materialize in parallel; the second holder of a key finds the
  /// winner's registered row and reuses it.
  final Map<String, Future<void>> _repoLocks = {};

  /// Spaces whose last provisioning run was cancelled. Read by
  /// [isSpaceProvisioningCancelled] so a caller can report "stopped" rather
  /// than "failed", and consulted at the top of [ensureSpaceWorkspace] so a
  /// call that starts moments after the stop (a dispatch already past its own
  /// check) is refused instead of re-starting the clone.
  final Set<String> _cancelled = {};

  static String _key(String workspaceId, String spaceId) =>
      '$workspaceId/$spaceId';

  @override
  void cancelSpaceProvisioning(String workspaceId, String spaceId) {
    final key = _key(workspaceId, spaceId);
    _cancelled.add(key);
    _cancelSources[key]?.source.cancel('space provisioning cancelled');
  }

  @override
  void clearSpaceProvisioningCancellation(String workspaceId, String spaceId) {
    _cancelled.remove(_key(workspaceId, spaceId));
  }

  @override
  bool isSpaceProvisioningCancelled(String workspaceId, String spaceId) =>
      _cancelled.contains(_key(workspaceId, spaceId));

  @override
  Future<String> ensureSpaceWorkspace({
    required String workspaceId,
    required String spaceId,
    required String agentSlug,
    required String fallbackDir,
    String? agentConfigDir,
    String? ticketId,
    String? ticketKey,
    String? ticketTitle,
    String branchType = 'feature',
    String? prHeadRef,
    String? prHeadRepoFullName,
    String? prBranch,
    Set<String>? repoAllowlist,
    void Function(String repoName, {required bool prHead})? onRepoProvision,
    void Function(String repoName)? onRepoSetupScript,
    CancellationToken? cancel,
  }) async {
    if (workspaceId.isEmpty || spaceId.isEmpty) {
      return fallbackDir;
    }
    final key = _key(workspaceId, spaceId);
    // A stop stands until someone deliberately re-provisions (the banner's
    // Retry, which goes through `SpaceProvisioningService.provision` and clears
    // the mark). Without this, the dispatch path that was already mid-flight
    // when the operator pressed stop would simply start the clone again.
    if (_cancelled.contains(key)) {
      return fallbackDir;
    }
    // One source per space; concurrent callers share it, so cancelling once
    // interrupts every in-flight run for that space.
    final shared = _cancelSources.putIfAbsent(key, _SpaceCancellation.new)
      ..runs += 1;
    final cancelToken = cancel == null
        ? shared.source.token
        : CancellationToken.any([shared.source.token, cancel]);
    try {
      // The caller's scope wins when it named one; otherwise ask the SPACE what
      // it checks out. Only falling back to "every linked repo" when the space
      // itself has no opinion keeps a scoped space scoped no matter which entry
      // point provisions it.
      final scope = repoAllowlist == null
          ? await _resolveSpaceScope(workspaceId, spaceId)
          : null;
      final effectiveAllowlist = repoAllowlist ?? scope?.repoIds;
      final effectiveHeadRef = prHeadRef ?? scope?.prHeadRef;
      final effectiveHeadRepo = prHeadRepoFullName ?? scope?.prHeadRepoFullName;
      final effectiveBranch = prBranch ?? scope?.prBranch;
      final repoBranches = scope?.repoBranches ?? const <String, String>{};

      final allRepos = await _workspaces
          .watchReposForWorkspace(workspaceId)
          .first;
      // A PR space (or a space created with an explicit selection) provisions
      // only the allow-listed repos; null → every linked repo.
      final repos = effectiveAllowlist == null
          ? allRepos
          : allRepos.where((r) => effectiveAllowlist.contains(r.id)).toList();
      if (repos.isEmpty) {
        return fallbackDir;
      }
      cancelToken.throwIfCancelled();

      final spaceRoot = await _filesystem.ensureSpaceDir(workspaceId, spaceId);

      final reposDir = Directory(p.join(spaceRoot, 'repos'));
      await reposDir.create(recursive: true);

      final token = await _safeToken();
      for (final repo in repos) {
        // Checked per repo, not just per run: a cancel that lands during the
        // first clone must not be answered by starting the second.
        cancelToken.throwIfCancelled();
        // A PR-review space pins ONE repo to the PR head ref; others
        // provision on their default base branch.
        final isPrRepo =
            effectiveHeadRef != null &&
            effectiveHeadRepo != null &&
            '${repo.remoteOwner}/${repo.remoteName}' == effectiveHeadRepo;
        try {
          await _ensureRepo(
            workspaceId: workspaceId,
            spaceId: spaceId,
            ticketId: ticketId,
            repo: repo,
            reposDir: reposDir.path,
            token: token,
            ticketKey: ticketKey,
            ticketTitle: ticketTitle,
            branchType: branchType,
            headRef: isPrRepo ? effectiveHeadRef : null,
            prBranch: isPrRepo ? effectiveBranch : null,
            // Only for a repo that is NOT the PR's: a PR worktree is pinned to
            // the head ref, and a base would be read as a second answer to the
            // same question.
            baseRef: isPrRepo ? null : repoBranches[repo.id],
            onRepoProvision: onRepoProvision,
            onRepoSetupScript: onRepoSetupScript,
            cancel: cancelToken,
          );
        } on CancelledException {
          // Not a per-repo failure to log and move past: the whole run is over.
          rethrow;
        } catch (e, st) {
          CcInfraLog.error('provision failed for repo ${repo.id}: $e', e, st);
        }
      }

      // Build the per-agent overlay cwd (AGENTS.md + .agents + repos symlinks)
      // and return it. Two agents in the same space get distinct overlays
      // that share `repos/`. The derived `.mcp.json` is NOT created here —
      // cc_server writes it into the cwd at dispatch time.
      return await _ensureAgentOverlay(
        spaceRoot: spaceRoot,
        agentSlug: agentSlug,
        agentConfigDir: agentConfigDir,
      );
    } on CancelledException {
      // Expected, not a fault: the operator (or a stopped run) interrupted it.
      // Same return as any other unfinished provision — the caller reads
      // [isSpaceProvisioningCancelled] to tell the two apart.
      CcInfraLog.info('space provisioning for $spaceId was cancelled');
      return fallbackDir;
    } catch (e, st) {
      CcInfraLog.error('ensureSpaceWorkspace failed: $e', e, st);
      return fallbackDir;
    } finally {
      // Drop the shared source once the last run using it is done, so a space
      // provisioned again later starts from a fresh, un-cancelled token.
      if (--shared.runs <= 0) {
        _cancelSources.remove(key);
      }
    }
  }

  /// Builds (idempotently, type-aware) the per-agent overlay at
  /// `<spaceRoot>/agents/<agentSlug>/` and returns its path as the cwd. Creates
  /// three symlinks: `AGENTS.md` + `.agents` → the agent's global config dir
  /// (when known) and `repos → ../../repos` (the space's shared worktrees,
  /// resolved via the shared rw sandbox mount).
  Future<String> _ensureAgentOverlay({
    required String spaceRoot,
    required String agentSlug,
    String? agentConfigDir,
  }) async {
    final overlayDir = Directory(p.join(spaceRoot, 'agents', agentSlug));
    if (!overlayDir.existsSync()) {
      await overlayDir.create(recursive: true);
    }

    // Shared repos live at <spaceRoot>/repos; the cwd is nested two levels
    // under it (<spaceRoot>/agents/<slug>), so the link is `../../repos`.
    await _ensureSymlink(p.join(overlayDir.path, 'repos'), '../../repos');

    if (agentConfigDir != null && agentConfigDir.isNotEmpty) {
      final agentMd = p.join(agentConfigDir, 'AGENTS.md');
      if (File(agentMd).existsSync()) {
        await _ensureSymlink(p.join(overlayDir.path, 'AGENTS.md'), agentMd);
      }
      final agentSkills = Directory(p.join(agentConfigDir, '.agents'));
      if (agentSkills.existsSync()) {
        await _ensureSymlink(
          p.join(overlayDir.path, '.agents'),
          agentSkills.path,
        );
      }
    }

    return overlayDir.path;
  }

  /// Serializes [_ensureRepo] for `(workspaceId, spaceId, repoId)`. See
  /// [_repoLocks].
  Future<void> _ensureRepo({
    required String workspaceId,
    required String spaceId,
    required String? ticketId,
    required Repo repo,
    required String reposDir,
    required String? token,
    required String? ticketKey,
    required String? ticketTitle,
    required String branchType,
    String? headRef,
    String? prBranch,
    String? baseRef,
    void Function(String repoName, {required bool prHead})? onRepoProvision,
    void Function(String repoName)? onRepoSetupScript,
    CancellationToken? cancel,
  }) async {
    final lockKey = '$workspaceId/$spaceId/${repo.id}';
    final prev = _repoLocks[lockKey] ?? Future<void>.value();
    final gate = Completer<void>();
    _repoLocks[lockKey] = gate.future;
    try {
      // A failed holder must not fail its successors: the chain is a mutex, not
      // a dependency. Each waiter re-checks the registry for itself.
      await prev.catchError((Object _) {});
      // Re-checked after the wait, for the same reason the caller's loop checks
      // per repo: a stop that lands while we are queued behind another run must
      // not be answered by starting this copy. The reuse check inside covers
      // the other outcome — the run we waited on having provisioned it.
      cancel?.throwIfCancelled();
      await _ensureRepoLocked(
        workspaceId: workspaceId,
        spaceId: spaceId,
        ticketId: ticketId,
        repo: repo,
        reposDir: reposDir,
        token: token,
        ticketKey: ticketKey,
        ticketTitle: ticketTitle,
        branchType: branchType,
        headRef: headRef,
        prBranch: prBranch,
        baseRef: baseRef,
        onRepoProvision: onRepoProvision,
        onRepoSetupScript: onRepoSetupScript,
        cancel: cancel,
      );
    } finally {
      gate.complete();
      if (_repoLocks[lockKey] == gate.future) {
        unawaited(_repoLocks.remove(lockKey));
      }
    }
  }

  Future<void> _ensureRepoLocked({
    required String workspaceId,
    required String spaceId,
    required String? ticketId,
    required Repo repo,
    required String reposDir,
    required String? token,
    required String? ticketKey,
    required String? ticketTitle,
    required String branchType,
    String? headRef,
    String? prBranch,
    String? baseRef,
    void Function(String repoName, {required bool prHead})? onRepoProvision,
    void Function(String repoName)? onRepoSetupScript,
    CancellationToken? cancel,
  }) async {
    final existing = await _registry.forUnitRepo(workspaceId, spaceId, repo.id);
    if (existing != null) {
      // Reusable only when the worktree is still there AND still under THIS
      // space's `repos/`. The second half is what heals a row written before
      // worktrees moved from `conversations/<id>/` to `spaces/<id>/`: the
      // directory it names exists, so a plain existence check would report
      // "reuse" forever while the agent's overlay symlinks into an empty
      // `spaces/<id>/repos`.
      final stillHere = Directory(existing.path).existsSync();
      if (stillHere && p.isWithin(reposDir, existing.path)) {
        return; // reuse
      }
      // Row points at a vanished — or displaced — worktree. Tear down the
      // stale state and re-create it in the right place.
      await _isolation.destroy(
        path: existing.path,
        sourcePath: existing.sourcePath,
        backend: existing.backend,
        branch: existing.branch,
      );
      await _registry.deleteById(existing.workspaceId, existing.id);
    }
    // Past the reuse check — a worktree is actually being materialized.
    onRepoProvision?.call(
      repo.remoteName.isNotEmpty ? repo.remoteName : repo.name,
      prHead: headRef != null,
    );

    final branch = (headRef != null && (prBranch?.isNotEmpty ?? false))
        ? prBranch!
        : (ticketKey != null && ticketKey.isNotEmpty) ||
              (ticketTitle != null && ticketTitle.isNotEmpty)
        ? BranchTemplateResolver(
            await _branchTemplate(workspaceId),
          ).resolve(type: branchType, ticketKey: ticketKey, title: ticketTitle)
        : 'conv/${_short(spaceId)}';

    final repoName = repo.remoteName.isNotEmpty ? repo.remoteName : repo.name;
    final name = slugify(repoName).isEmpty ? repo.id : slugify(repoName);

    final authUrl = (repo.hasForgeRemote && token != null && token.isNotEmpty)
        ? 'https://x-access-token:$token@github.com/'
              '${repo.remoteOwner}/${repo.remoteName}.git'
        : null;

    // Past the reuse check, so ANY directory sitting at the destination is an
    // orphan: a copy whose registry row is gone (a deleted space, a reaped
    // conversation) or one a killed provision left behind. Neither backend can
    // build over it — rift refuses with `already_exists` and `git worktree add`
    // with `fatal: '<path>' already exists` — so leaving it there does not
    // degrade the attempt, it guarantees the attempt fails. It used to be
    // reaped only AFTER that doomed attempt had already flipped the whole
    // space to `failed`; reaping it here is the same teardown, one attempt
    // earlier, so the first press works instead of the second.
    await _reapPartialWorktree(
      destPath: p.join(reposDir, name),
      sourcePath: repo.path,
      branch: branch,
    );

    final RepoIsolationResult result;
    try {
      result = await _isolation.provision(
        sourcePath: repo.path,
        destParentDir: reposDir,
        name: name,
        branch: branch,
        // Where the worktree's own branch is cut from. Empty is the port's
        // "detect the default branch" default, so an unpinned repo behaves
        // exactly as before.
        baseRef: baseRef ?? '',
        authUrl: authUrl,
        // PR-review space: fetch + check out the PR head ref (e.g.
        // refs/pull/42/head) so the worktree is the PR's proposed tree.
        headRef: headRef,
        // Scrub the PR worktree to exactly the PR head — the CoW copy inherits the
        // source checkout's untracked/ignored cruft (`.bak`, private config) and
        // a plain checkout leaves it behind, polluting the review's source-control
        // view. Agent/ticket worktrees stay non-pristine (their scratch survives).
        pristine: headRef != null,
        cancel: cancel,
      );
    } on Object {
      // An interrupted (or failed) provision can leave a half-materialized copy
      // on disk with no registry row pointing at it — and the next attempt then
      // asks the backend to create a worktree at a path that already exists,
      // which fails forever. Reap it before letting the error out.
      await _reapPartialWorktree(
        destPath: p.join(reposDir, name),
        sourcePath: repo.path,
        branch: branch,
      );
      rethrow;
    }

    final entryId = _uuid.v4();
    await _registry.upsert(
      IsolatedRepo(
        id: entryId,
        workspaceId: workspaceId,
        spaceId: spaceId,
        repoId: repo.id,
        path: result.path,
        branch: branch,
        backend: result.backend,
        sourcePath: repo.path,
        ticketId: ticketId,
        createdAt: DateTime.now(),
      ),
    );

    // The worktree is registered — now the repo's configured setup script
    // (if any) makes it usable (install deps, generate files). Runs only on a
    // FRESH provision: the reuse path returned above, so a re-dispatch never
    // re-pays an install. A failure tears the unit back down and rethrows so
    // the space's post-hoc verification reports `failed`, exactly like a
    // failed clone would.
    final scripts = _scripts;
    if (scripts != null) {
      try {
        if (!await scripts.hasSetupScript(workspaceId, repo.id)) {
          return;
        }
      } on Object catch (e) {
        // A lookup failure must not read as "no script" and skip it silently,
        // nor as a provisioning failure — log and let the run itself decide.
        CcInfraLog.warning(
          'setup script lookup failed for repo ${repo.id}: $e',
        );
      }
      cancel?.throwIfCancelled();
      onRepoSetupScript?.call(
        repo.remoteName.isNotEmpty ? repo.remoteName : repo.name,
      );
      try {
        await scripts.runSetup(
          RepoScriptContext(
            workspaceId: workspaceId,
            spaceId: spaceId,
            repoId: repo.id,
            worktreePath: result.path,
            sourcePath: repo.path,
          ),
        );
      } on Object catch (e, st) {
        CcInfraLog.error(
          'setup script failed for repo ${repo.id}: $e',
          e,
          st,
        );
        try {
          await _isolation.destroy(
            path: result.path,
            sourcePath: repo.path,
            backend: result.backend,
            branch: branch,
          );
        } on Object catch (destroyError) {
          CcInfraLog.warning(
            'teardown after setup failure failed for ${result.path}: '
            '$destroyError',
          );
        }
        await _registry.deleteById(workspaceId, entryId);
        rethrow;
      }
    }
  }

  /// Best-effort teardown of a worktree that was never registered — before a
  /// provision, so an orphaned copy cannot block it, and after one that failed
  /// part-way.
  ///
  /// A no-op when nothing is there, which is the normal case.
  ///
  /// The backend is inferred rather than read back (there is no row to read):
  /// whichever one a provision would have used on this host. A guess that is
  /// wrong still ends with the directory gone, which is the part that matters —
  /// the rift adapter's destroy removes leftovers either way.
  Future<void> _reapPartialWorktree({
    required String destPath,
    required String sourcePath,
    required String branch,
  }) async {
    if (!Directory(destPath).existsSync()) {
      return;
    }
    try {
      await _isolation.destroy(
        path: destPath,
        sourcePath: sourcePath,
        backend: _isolation.isCowAvailable
            ? RepoIsolationBackend.rift
            : RepoIsolationBackend.gitWorktree,
        branch: branch,
      );
    } on Object catch (e) {
      CcInfraLog.warning('could not reap partial worktree $destPath: $e');
    }
  }

  @override
  Future<void> releaseSpace({
    required String workspaceId,
    required String spaceId,
  }) async {
    await _destroyAll(await _registry.forSpace(workspaceId, spaceId));
    await _removeSpaceDir(workspaceId, spaceId);
  }

  @override
  Future<void> releaseSpaceReposOutside({
    required String workspaceId,
    required String spaceId,
    required Set<String>? keepRepoIds,
  }) async {
    if (keepRepoIds == null) {
      return;
    }
    final rows = await _registry.forSpace(workspaceId, spaceId);
    await _destroyAll([
      for (final row in rows)
        if (!keepRepoIds.contains(row.repoId)) row,
    ]);
    // The space dir itself stays: agents/, the surviving repos/ and the
    // symlinks pointing at them are still live.
  }

  @override
  Future<void> releaseSpaceAnyWorkspace({required String spaceId}) async {
    final rows = await _registry.forSpaceAcrossWorkspaces(spaceId);
    await _destroyAll(rows);
    // Destroying the worktree rows leaves the space dir behind — the
    // per-agent overlays (with their token-bearing `.mcp.json`) and the empty
    // repos/ tree. Remove the whole space dir for every workspace the
    // space touched. The workspaceId isn't a parameter here, so source it
    // from the rows we just tore down.
    for (final workspaceId in rows.map((r) => r.workspaceId).toSet()) {
      await _removeSpaceDir(workspaceId, spaceId);
    }
  }

  /// Removes the space working dir (`<ws>/spaces/<spaceId>/`)
  /// after its worktrees are destroyed, so the per-agent overlays and their
  /// token-bearing `.mcp.json` files don't linger on disk (secret hygiene +
  /// unbounded disk growth across deleted spaces). Best-effort.
  Future<void> _removeSpaceDir(String workspaceId, String spaceId) async {
    if (workspaceId.isEmpty || spaceId.isEmpty) {
      return;
    }
    try {
      final dir = Directory(await _filesystem.spaceDir(workspaceId, spaceId));
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      CcInfraLog.warning('space dir cleanup failed for $spaceId: $e');
    }
  }

  @override
  Future<void> releaseTicket({required String ticketId}) async {
    await _destroyAll(await _registry.forTicketAcrossWorkspaces(ticketId));
  }

  @override
  Future<int> releaseTicketInWorkspace({
    required String workspaceId,
    required String ticketId,
  }) async {
    if (workspaceId.isEmpty || ticketId.isEmpty) {
      return 0;
    }
    final rows = await _registry.forTicket(workspaceId, ticketId);
    await _destroyAll(rows);
    return rows.length;
  }

  @override
  Future<int> sweepStale({required String workspaceId}) async {
    if (workspaceId.isEmpty) {
      return 0;
    }
    final rows = await _registry.watchForWorkspace(workspaceId).first;
    // Reap the pre-rename `conversations/` tree first, THROUGH the ordinary
    // teardown so its uncommitted work is rescued rather than deleted from
    // under an operator. Rows destroyed here are gone from `rows` below by the
    // time the staleness loop reads them (it re-checks the directory).
    await _reapLegacyConversationsDir(workspaceId, rows);
    var reaped = 0;
    // Spaces whose worktrees we tore down here — their space dir (the
    // per-agent overlays and their token-bearing `.mcp.json`) goes with them.
    final orphanedSpaces = <String>{};
    for (final row in rows) {
      // Two staleness signals. The directory vanishing is the original one.
      // The space being gone is the one that matters in practice: deleting a
      // space fires `SpaceDeleted` → `releaseSpace`, but an
      // event missed while the server was down (or a row deleted straight from
      // the DB) leaves a fully-intact worktree nothing will ever reclaim — and
      // now also a code-graph partition hanging off it.
      final directoryGone = !Directory(row.path).existsSync();
      final spaceGone = !directoryGone && await _isSpaceGone(row);
      if (!directoryGone && !spaceGone) {
        continue;
      }
      try {
        await _isolation.destroy(
          path: row.path,
          sourcePath: row.sourcePath,
          backend: row.backend,
          branch: row.branch,
        );
      } catch (e) {
        CcInfraLog.warning('sweepStale destroy failed for ${row.path}: $e');
      }
      await _registry.deleteById(row.workspaceId, row.id);
      if (spaceGone) {
        orphanedSpaces.add(row.spaceId);
      }
      reaped++;
    }
    for (final spaceId in orphanedSpaces) {
      await _removeSpaceDir(workspaceId, spaceId);
    }
    reaped += await _sweepOrphanSpaceDirs(workspaceId);
    return reaped;
  }

  /// Deletes the workspace's obsolete `conversations/` tree.
  ///
  /// Worktrees are keyed by SPACE and now live under `spaces/<spaceId>/`. The
  /// old tree is not a second copy anyone reads: nothing resolves paths into it
  /// any more, so left alone it is a directory of full repo checkouts that
  /// nothing will ever reclaim — while the registry rows pointing into it would
  /// keep reporting "reuse" and hand agents a repos/ symlink into an empty
  /// directory. Removing it makes those rows self-heal through the ordinary
  /// vanished-directory path.
  Future<void> _reapLegacyConversationsDir(
    String workspaceId,
    List<IsolatedRepo> rows,
  ) async {
    try {
      final ws = await _filesystem.workspaceDir(workspaceId);
      final legacy = Directory(p.join(ws, 'conversations'));
      if (!legacy.existsSync()) {
        return;
      }
      // Through `_destroyAll`, never a bare recursive delete: those worktrees
      // are real checkouts an agent may have left uncommitted work in, and the
      // destroy path is what commits it to a `rescue/…` branch first.
      final displaced = rows
          .where((r) => p.isWithin(legacy.path, r.path))
          .toList();
      if (displaced.isNotEmpty) {
        await _destroyAll(displaced);
      }
      if (legacy.existsSync()) {
        await legacy.delete(recursive: true);
      }
      CcInfraLog.info(
        'sweepStale: removed the obsolete conversations/ tree in $workspaceId '
        '(${displaced.length} worktree(s) released; they live under spaces/ now)',
      );
    } on Object catch (e) {
      CcInfraLog.warning('sweepStale: legacy conversations cleanup failed: $e');
    }
  }

  /// Whether [row]'s space is gone. Unknown (no predicate wired, or the
  /// lookup threw) counts as PRESENT: a sweep must never destroy a live
  /// worktree because a check was unavailable.
  Future<bool> _isSpaceGone(IsolatedRepo row) async {
    final exists = _spaceExists;
    if (exists == null || row.spaceId.isEmpty) {
      return false;
    }
    try {
      return !await exists(row.workspaceId, row.spaceId);
    } catch (e) {
      CcInfraLog.warning('sweepStale channel check failed for ${row.id}: $e');
      return false;
    }
  }

  /// Removes space directories whose space no longer exists.
  ///
  /// The registry sweep above only sees spaces that still have worktree rows.
  /// A space whose rows were already reaped (or that never provisioned a
  /// repo) leaves its folder behind — per-agent overlays, `.mcp.json` secrets,
  /// an empty `repos/` — with nothing pointing at it. Returns the count removed.
  Future<int> _sweepOrphanSpaceDirs(String workspaceId) async {
    final exists = _spaceExists;
    if (exists == null) {
      return 0;
    }
    final Directory root;
    try {
      root = Directory(await _filesystem.spacesDir(workspaceId));
    } catch (e) {
      CcInfraLog.warning('sweepStale: spaces dir unavailable: $e');
      return 0;
    }
    if (!root.existsSync()) {
      return 0;
    }
    var removed = 0;
    for (final entity in root.listSync(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final spaceId = p.basename(entity.path);
      // Anything that isn't a space id (stray files, `.DS_Store` dirs) is
      // left alone — this only reclaims folders it can positively attribute.
      if (spaceId.isEmpty || spaceId.startsWith('.')) {
        continue;
      }
      bool gone;
      try {
        gone = !await exists(workspaceId, spaceId);
      } catch (e) {
        CcInfraLog.warning('sweepStale: channel check failed for $spaceId: $e');
        continue;
      }
      if (!gone) {
        continue;
      }
      // Any worktree row still pointing inside must be torn down first, or the
      // registry keeps a row for a directory that no longer exists.
      final rows = await _registry.forSpace(workspaceId, spaceId);
      if (rows.isNotEmpty) {
        await _destroyAll(rows);
      }
      await _removeSpaceDir(workspaceId, spaceId);
      removed++;
      CcInfraLog.info(
        'sweepStale: removed orphan space dir for deleted space '
        '$spaceId',
      );
    }
    return removed;
  }

  Future<void> _destroyAll(List<IsolatedRepo> rows) async {
    for (final row in rows) {
      // The repo's archive script (when configured) runs while the worktree is
      // still on disk — its whole job is cleaning up resources OUTSIDE the
      // worktree, which only makes sense before the copy goes away. It is
      // best-effort by contract (never throws, bounded by its own timeout) and
      // belt-and-braces here: a GC path must never be blocked by a script.
      final scripts = _scripts;
      if (scripts != null) {
        try {
          await scripts.runArchive(
            RepoScriptContext(
              workspaceId: row.workspaceId,
              spaceId: row.spaceId,
              repoId: row.repoId,
              worktreePath: row.path,
              sourcePath: row.sourcePath,
            ),
          );
        } catch (e) {
          CcInfraLog.warning('archive script failed for ${row.path}: $e');
        }
      }
      try {
        await _isolation.destroy(
          path: row.path,
          sourcePath: row.sourcePath,
          backend: row.backend,
          branch: row.branch,
        );
      } catch (e) {
        CcInfraLog.warning('destroy failed for ${row.path}: $e');
      }
      await _registry.deleteById(row.workspaceId, row.id);
    }
  }

  Future<void> _ensureSymlink(String linkPath, String target) async {
    final type = FileSystemEntity.typeSync(linkPath, followLinks: false);
    switch (type) {
      case FileSystemEntityType.link:
        final existing = Link(linkPath);
        if (await existing.target() == target) {
          return;
        }
        await existing.delete();
      case FileSystemEntityType.file:
        await File(linkPath).delete();
      case FileSystemEntityType.directory:
        return; // unexpected; don't clobber a directory
      case FileSystemEntityType.notFound:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        break;
    }
    await Link(linkPath).create(target);
  }

  /// The space's own checkout scope, or null when none is wired / it throws.
  ///
  /// Best-effort by design: a resolver failure must not fail a dispatch. It
  /// degrades to the historical every-repo behaviour, which is wasteful but
  /// correct — the opposite trade (refusing to provision) would strand the
  /// agent with no worktree at all.
  Future<SpaceCheckoutScope?> _resolveSpaceScope(
    String workspaceId,
    String spaceId,
  ) async {
    final resolve = _spaceCheckoutScope;
    if (resolve == null) {
      return null;
    }
    try {
      return await resolve(workspaceId, spaceId);
    } catch (e) {
      CcInfraLog.warning('space checkout scope lookup failed for $spaceId: $e');
      return null;
    }
  }

  Future<String?> _safeToken() async {
    try {
      return await _githubToken();
    } catch (_) {
      return null;
    }
  }

  static String _short(String id) => id.length > 8 ? id.substring(0, 8) : id;
}

/// One space's cancellation source plus how many provisioning runs share it.
///
/// The count is what lets the entry be dropped when the LAST run finishes: a
/// source removed while a sibling run still holds it would leave that run
/// uncancellable, and one kept forever would make the next provision of that
/// space start already-cancelled.
class _SpaceCancellation {
  final CancellationTokenSource source = CancellationTokenSource();

  /// In-flight `ensureSpaceWorkspace` calls sharing [source].
  int runs = 0;
}
