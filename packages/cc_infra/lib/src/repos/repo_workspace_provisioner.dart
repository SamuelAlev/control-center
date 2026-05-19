import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/services/slugify.dart';
import 'package:cc_domain/features/settings/domain/services/branch_template_resolver.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Concrete [RepoWorkspaceProvisionerPort]: sets up the per-conversation root
/// (shared `repos/` + a per-agent overlay cwd) and provisions/destroys isolated
/// CoW worktrees via [RepoIsolationPort], persisting them in [IsolatedRepoRepository].
///
/// Idempotent: re-dispatching into the same conversation reuses existing
/// worktrees and the per-agent overlay. Best-effort: a failure to provision one
/// repo is logged and does not block dispatch (the agent still gets a working
/// directory).
class RepoWorkspaceProvisioner implements RepoWorkspaceProvisionerPort {
  /// Creates a [RepoWorkspaceProvisioner].
  RepoWorkspaceProvisioner({
    required WorkspaceFilesystemPort filesystem,
    required RepoIsolationPort isolation,
    required IsolatedRepoRepository registry,
    required WorkspaceRepository workspaces,
    required Future<String?> Function() githubToken,
    required Future<String> Function(String workspaceId) branchTemplate,
    Future<bool> Function(String workspaceId, String channelId)? channelExists,
  }) : _filesystem = filesystem,
       _isolation = isolation,
       _registry = registry,
       _workspaces = workspaces,
       _githubToken = githubToken,
       _branchTemplate = branchTemplate,
       _channelExists = channelExists;

  final WorkspaceFilesystemPort _filesystem;
  final RepoIsolationPort _isolation;
  final IsolatedRepoRepository _registry;
  final WorkspaceRepository _workspaces;
  final Future<String?> Function() _githubToken;

  /// Resolves the branch-name template for a workspace.
  ///
  /// Workspace-scoped and asynchronous because the template is workspace
  /// POLICY — everyone working in a workspace must produce the same branch
  /// shape — so it is read from that workspace's settings store rather than
  /// from a device-local preference. It used to be a synchronous no-arg
  /// callback that the server wired to the built-in default, which meant the
  /// setting in the UI had never had any effect at all.
  final Future<String> Function(String workspaceId) _branchTemplate;

  /// Whether a channel still exists — the sweep's second staleness signal
  /// alongside "the directory vanished". Optional so a host that cannot answer
  /// it (or a test) simply keeps the directory-only behaviour.
  final Future<bool> Function(String workspaceId, String channelId)?
  _channelExists;

  final _uuid = const Uuid();

  @override
  Future<String> ensureConversationWorkspace({
    required String workspaceId,
    required String channelId,
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
  }) async {
    if (workspaceId.isEmpty || channelId.isEmpty) {
      return fallbackDir;
    }
    try {
      final allRepos = await _workspaces
          .watchReposForWorkspace(workspaceId)
          .first;
      // A PR channel (or a channel created with an explicit selection) provisions
      // only the allow-listed repos; null → every linked repo.
      final repos = repoAllowlist == null
          ? allRepos
          : allRepos.where((r) => repoAllowlist.contains(r.id)).toList();
      if (repos.isEmpty) {
        return fallbackDir;
      }

      final convRoot = await _filesystem.ensureConversationDir(
        workspaceId,
        channelId,
      );

      final reposDir = Directory(p.join(convRoot, 'repos'));
      await reposDir.create(recursive: true);

      final token = await _safeToken();
      for (final repo in repos) {
        // A PR-review conversation pins ONE repo to the PR head ref; others
        // provision on their default base branch.
        final isPrRepo =
            prHeadRef != null &&
            prHeadRepoFullName != null &&
            '${repo.remoteOwner}/${repo.remoteName}' == prHeadRepoFullName;
        try {
          await _ensureRepo(
            workspaceId: workspaceId,
            channelId: channelId,
            ticketId: ticketId,
            repo: repo,
            reposDir: reposDir.path,
            token: token,
            ticketKey: ticketKey,
            ticketTitle: ticketTitle,
            branchType: branchType,
            headRef: isPrRepo ? prHeadRef : null,
            prBranch: isPrRepo ? prBranch : null,
            onRepoProvision: onRepoProvision,
          );
        } catch (e, st) {
          CcInfraLog.error('provision failed for repo ${repo.id}: $e', e, st);
        }
      }

      // Build the per-agent overlay cwd (AGENTS.md + .agents + repos symlinks)
      // and return it. Two agents in the same channel get distinct overlays
      // that share `repos/`. The derived `.mcp.json` is NOT created here —
      // cc_server writes it into the cwd at dispatch time.
      return await _ensureAgentOverlay(
        convRoot: convRoot,
        agentSlug: agentSlug,
        agentConfigDir: agentConfigDir,
      );
    } catch (e, st) {
      CcInfraLog.error('ensureConversationWorkspace failed: $e', e, st);
      return fallbackDir;
    }
  }

  /// Builds (idempotently, type-aware) the per-agent overlay at
  /// `<convRoot>/agents/<agentSlug>/` and returns its path as the cwd. Creates
  /// three symlinks: `AGENTS.md` + `.agents` → the agent's global config dir
  /// (when known) and `repos → ../../repos` (the shared conversation worktrees,
  /// resolved via the shared rw sandbox mount).
  Future<String> _ensureAgentOverlay({
    required String convRoot,
    required String agentSlug,
    String? agentConfigDir,
  }) async {
    final overlayDir = Directory(p.join(convRoot, 'agents', agentSlug));
    if (!overlayDir.existsSync()) {
      await overlayDir.create(recursive: true);
    }

    // Shared repos live at <convRoot>/repos; the cwd is nested two levels under
    // convRoot (<convRoot>/agents/<slug>), so the relative link is `../../repos`.
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

  Future<void> _ensureRepo({
    required String workspaceId,
    required String channelId,
    required String? ticketId,
    required Repo repo,
    required String reposDir,
    required String? token,
    required String? ticketKey,
    required String? ticketTitle,
    required String branchType,
    String? headRef,
    String? prBranch,
    void Function(String repoName, {required bool prHead})? onRepoProvision,
  }) async {
    final existing = await _registry.forUnitRepo(
      workspaceId,
      channelId,
      repo.id,
    );
    if (existing != null) {
      if (Directory(existing.path).existsSync()) {
        return; // reuse
      }
      // Row points at a vanished worktree — tear down stale state and re-create.
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
        : 'conv/${_short(channelId)}';

    final repoName = repo.remoteName.isNotEmpty ? repo.remoteName : repo.name;
    final name = slugify(repoName).isEmpty ? repo.id : slugify(repoName);

    final authUrl = (repo.hasForgeRemote && token != null && token.isNotEmpty)
        ? 'https://x-access-token:$token@github.com/'
              '${repo.remoteOwner}/${repo.remoteName}.git'
        : null;

    final result = await _isolation.provision(
      sourcePath: repo.path,
      destParentDir: reposDir,
      name: name,
      branch: branch,
      authUrl: authUrl,
      // PR-review conversation: fetch + check out the PR head ref (e.g.
      // refs/pull/42/head) so the worktree is the PR's proposed tree.
      headRef: headRef,
      // Scrub the PR worktree to exactly the PR head — the CoW copy inherits the
      // source checkout's untracked/ignored cruft (`.bak`, private config) and
      // a plain checkout leaves it behind, polluting the review's source-control
      // view. Agent/ticket worktrees stay non-pristine (their scratch survives).
      pristine: headRef != null,
    );

    await _registry.upsert(
      IsolatedRepo(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        channelId: channelId,
        repoId: repo.id,
        path: result.path,
        branch: branch,
        backend: result.backend,
        sourcePath: repo.path,
        ticketId: ticketId,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> releaseConversation({
    required String workspaceId,
    required String channelId,
  }) async {
    await _destroyAll(await _registry.forChannel(workspaceId, channelId));
    await _removeConversationDir(workspaceId, channelId);
  }

  @override
  Future<void> releaseConversationAnyWorkspace({
    required String channelId,
  }) async {
    final rows = await _registry.forChannelAcrossWorkspaces(channelId);
    await _destroyAll(rows);
    // Destroying the worktree rows leaves the conversation dir behind — the
    // per-agent overlays (with their token-bearing `.mcp.json`) and the empty
    // repos/ tree. Remove the whole conversation dir for every workspace the
    // channel touched. The workspaceId isn't a parameter here, so source it
    // from the rows we just tore down.
    for (final workspaceId in rows.map((r) => r.workspaceId).toSet()) {
      await _removeConversationDir(workspaceId, channelId);
    }
  }

  /// Removes the conversation working dir (`<ws>/conversations/<channelId>/`)
  /// after its worktrees are destroyed, so the per-agent overlays and their
  /// token-bearing `.mcp.json` files don't linger on disk (secret hygiene +
  /// unbounded disk growth across deleted conversations). Best-effort.
  Future<void> _removeConversationDir(
    String workspaceId,
    String channelId,
  ) async {
    if (workspaceId.isEmpty || channelId.isEmpty) {
      return;
    }
    try {
      final dir = Directory(
        await _filesystem.conversationDir(workspaceId, channelId),
      );
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      CcInfraLog.warning('conversation dir cleanup failed for $channelId: $e');
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
    var reaped = 0;
    // Channels whose worktrees we tore down here — their conversation dir (the
    // per-agent overlays and their token-bearing `.mcp.json`) goes with them.
    final orphanedChannels = <String>{};
    for (final row in rows) {
      // Two staleness signals. The directory vanishing is the original one.
      // The channel being gone is the one that matters in practice: deleting a
      // conversation fires `ChannelDeleted` → `releaseConversation`, but an
      // event missed while the server was down (or a row deleted straight from
      // the DB) leaves a fully-intact worktree nothing will ever reclaim — and
      // now also a code-graph partition hanging off it.
      final directoryGone = !Directory(row.path).existsSync();
      final channelGone = !directoryGone && await _isChannelGone(row);
      if (!directoryGone && !channelGone) {
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
      if (channelGone) {
        orphanedChannels.add(row.channelId);
      }
      reaped++;
    }
    for (final channelId in orphanedChannels) {
      await _removeConversationDir(workspaceId, channelId);
    }
    reaped += await _sweepOrphanConversationDirs(workspaceId);
    return reaped;
  }

  /// Whether [row]'s channel is gone. Unknown (no predicate wired, or the
  /// lookup threw) counts as PRESENT: a sweep must never destroy a live
  /// worktree because a check was unavailable.
  Future<bool> _isChannelGone(IsolatedRepo row) async {
    final exists = _channelExists;
    if (exists == null || row.channelId.isEmpty) {
      return false;
    }
    try {
      return !await exists(row.workspaceId, row.channelId);
    } catch (e) {
      CcInfraLog.warning('sweepStale channel check failed for ${row.id}: $e');
      return false;
    }
  }

  /// Removes conversation directories whose channel no longer exists.
  ///
  /// The registry sweep above only sees channels that still have worktree rows.
  /// A conversation whose rows were already reaped (or that never provisioned a
  /// repo) leaves its folder behind — per-agent overlays, `.mcp.json` secrets,
  /// an empty `repos/` — with nothing pointing at it. Returns the count removed.
  Future<int> _sweepOrphanConversationDirs(String workspaceId) async {
    final exists = _channelExists;
    if (exists == null) {
      return 0;
    }
    final Directory root;
    try {
      root = Directory(await _filesystem.conversationsDir(workspaceId));
    } catch (e) {
      CcInfraLog.warning('sweepStale: conversations dir unavailable: $e');
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
      final channelId = p.basename(entity.path);
      // Anything that isn't a channel id (stray files, `.DS_Store` dirs) is
      // left alone — this only reclaims folders it can positively attribute.
      if (channelId.isEmpty || channelId.startsWith('.')) {
        continue;
      }
      bool gone;
      try {
        gone = !await exists(workspaceId, channelId);
      } catch (e) {
        CcInfraLog.warning(
          'sweepStale: channel check failed for $channelId: $e',
        );
        continue;
      }
      if (!gone) {
        continue;
      }
      // Any worktree row still pointing inside must be torn down first, or the
      // registry keeps a row for a directory that no longer exists.
      final rows = await _registry.forChannel(workspaceId, channelId);
      if (rows.isNotEmpty) {
        await _destroyAll(rows);
      }
      await _removeConversationDir(workspaceId, channelId);
      removed++;
      CcInfraLog.info(
        'sweepStale: removed orphan conversation dir for deleted channel '
        '$channelId',
      );
    }
    return removed;
  }

  Future<void> _destroyAll(List<IsolatedRepo> rows) async {
    for (final row in rows) {
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

  Future<String?> _safeToken() async {
    try {
      return await _githubToken();
    } catch (_) {
      return null;
    }
  }

  static String _short(String id) => id.length > 8 ? id.substring(0, 8) : id;
}
