import 'dart:io';

import 'package:control_center/core/domain/entities/isolated_repo.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/ports/repo_isolation_port.dart';
import 'package:control_center/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/isolated_repo_repository.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/core/domain/services/slugify.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/settings/domain/services/branch_template_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Concrete [RepoWorkspaceProvisionerPort]: sets up the per-conversation root
/// (AGENTS.md + .mcp.json + repos/) and provisions/destroys isolated CoW
/// worktrees via [RepoIsolationPort], persisting them in [IsolatedRepoRepository].
///
/// Idempotent: re-dispatching into the same conversation reuses existing
/// worktrees. Best-effort: a failure to provision one repo is logged and does
/// not block dispatch (the agent still gets a working directory).
class RepoWorkspaceProvisioner implements RepoWorkspaceProvisionerPort {
  /// Creates a [RepoWorkspaceProvisioner].
  RepoWorkspaceProvisioner({
    required WorkspaceFilesystemPort filesystem,
    required RepoIsolationPort isolation,
    required IsolatedRepoRepository registry,
    required WorkspaceRepository workspaces,
    required Future<String?> Function() githubToken,
    required String Function() branchTemplate,
  })  : _filesystem = filesystem,
        _isolation = isolation,
        _registry = registry,
        _workspaces = workspaces,
        _githubToken = githubToken,
        _branchTemplate = branchTemplate;

  final WorkspaceFilesystemPort _filesystem;
  final RepoIsolationPort _isolation;
  final IsolatedRepoRepository _registry;
  final WorkspaceRepository _workspaces;
  final Future<String?> Function() _githubToken;
  final String Function() _branchTemplate;
  final _uuid = const Uuid();

  static const _tag = 'RepoWorkspaceProvisioner';

  @override
  Future<String> ensureConversationWorkspace({
    required String workspaceId,
    required String channelId,
    required String fallbackDir,
    String? agentConfigDir,
    String? ticketId,
    String? ticketKey,
    String? ticketTitle,
    String branchType = 'feature',
  }) async {
    if (workspaceId.isEmpty || channelId.isEmpty) {
      return fallbackDir;
    }
    try {
      final repos = await _workspaces.watchReposForWorkspace(workspaceId).first;
      if (repos.isEmpty) {
        return fallbackDir;
      }

      final convRoot = await _filesystem.ensureConversationDir(
        workspaceId,
        channelId,
      );
      await _ensureConfigLinks(convRoot.path, agentConfigDir);

      final reposDir = Directory(p.join(convRoot.path, 'repos'));
      await reposDir.create(recursive: true);

      final token = await _safeToken();
      for (final repo in repos) {
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
          );
        } catch (e, st) {
          AppLog.e(_tag, 'provision failed for repo ${repo.id}: $e', e, st);
        }
      }
      return convRoot.path;
    } catch (e, st) {
      AppLog.e(_tag, 'ensureConversationWorkspace failed: $e', e, st);
      return fallbackDir;
    }
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
  }) async {
    final existing = await _registry.forUnitRepo(workspaceId, channelId, repo.id);
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
      await _registry.deleteById(existing.id);
    }

    final branch = (ticketKey != null && ticketKey.isNotEmpty) ||
            (ticketTitle != null && ticketTitle.isNotEmpty)
        ? BranchTemplateResolver(_branchTemplate()).resolve(
            type: branchType,
            ticketKey: ticketKey,
            title: ticketTitle,
          )
        : 'conv/${_short(channelId)}';

    final repoName = repo.githubRepoName.isNotEmpty
        ? repo.githubRepoName
        : repo.name;
    final name = slugify(repoName).isEmpty ? repo.id : slugify(repoName);

    final authUrl = (repo.hasGitHubRemote && token != null && token.isNotEmpty)
        ? 'https://x-access-token:$token@github.com/'
            '${repo.githubOwner}/${repo.githubRepoName}.git'
        : null;

    final result = await _isolation.provision(
      sourcePath: repo.path,
      destParentDir: reposDir,
      name: name,
      branch: branch,
      authUrl: authUrl,
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
  }

  @override
  Future<void> releaseConversationAnyWorkspace({
    required String channelId,
  }) async {
    await _destroyAll(await _registry.forChannelAcrossWorkspaces(channelId));
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
    for (final row in rows) {
      // A worktree whose on-disk copy still exists is in use (or healthy) —
      // leave it. Only rows pointing at a vanished directory are stale.
      if (Directory(row.path).existsSync()) {
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
        AppLog.w(_tag, 'sweepStale destroy failed for ${row.path}: $e');
      }
      await _registry.deleteById(row.id);
      reaped++;
    }
    return reaped;
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
        AppLog.w(_tag, 'destroy failed for ${row.path}: $e');
      }
      await _registry.deleteById(row.id);
    }
  }

  Future<void> _ensureConfigLinks(
    String convRootPath,
    String? agentConfigDir,
  ) async {
    final mcp = await mcpConfigFile();
    if (mcp.existsSync()) {
      await _ensureSymlink(p.join(convRootPath, '.mcp.json'), mcp.path);
    }
    if (agentConfigDir != null && agentConfigDir.isNotEmpty) {
      final agentMd = p.join(agentConfigDir, 'AGENTS.md');
      if (File(agentMd).existsSync()) {
        await _ensureSymlink(p.join(convRootPath, 'AGENTS.md'), agentMd);
      }
    }
  }

  /// Creates (or repoints) a symlink at [linkPath] → [target]. Mirrors
  /// `WorkspaceFilesystemService.ensureMcpSymlink`'s type-aware handling.
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

  static String _short(String id) =>
      id.length > 8 ? id.substring(0, 8) : id;
}
