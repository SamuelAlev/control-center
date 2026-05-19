import 'dart:io';

import 'package:control_center/core/domain/entities/isolated_repo.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/events/pr_events.dart';
import 'package:control_center/core/domain/ports/pr_worktree_port.dart';
import 'package:control_center/core/domain/ports/repo_isolation_port.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/isolated_repo_repository.dart';
import 'package:control_center/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Default [PrWorktreePort]: provisions a CoW worktree of the registered local
/// repo checked out at a PR's head via [RepoIsolationPort], tracks it in
/// [IsolatedRepoRepository] (keyed by a synthetic `pr:<owner/repo>#<number>`
/// channel id so no schema change is needed), and tears it down on release.
class PrWorktreeService implements PrWorktreePort {
  /// Creates a [PrWorktreeService].
  PrWorktreeService({
    required WorkspaceFilesystemPort filesystem,
    required RepoIsolationPort isolation,
    required IsolatedRepoRepository registry,
    required Future<String?> Function() githubToken,
  }) : _filesystem = filesystem,
       _isolation = isolation,
       _registry = registry,
       _githubToken = githubToken;

  final WorkspaceFilesystemPort _filesystem;
  final RepoIsolationPort _isolation;
  final IsolatedRepoRepository _registry;
  final Future<String?> Function() _githubToken;
  final _uuid = const Uuid();

  static const _tag = 'PrWorktreeService';

  /// The registry "unit" key for a PR worktree. Encodes the repo full name and
  /// PR number so the GC listener can release it from a
  /// [PullRequestStatusChanged] event (which carries `repoFullName` + number,
  /// not the PR node id).
  static String _unitKey(String repoFullName, int prNumber) =>
      'pr:$repoFullName#$prNumber';

  @override
  Future<String> ensureWorktree({
    required String workspaceId,
    required Repo repo,
    required int prNumber,
    required String prHeadRef,
  }) async {
    final owner = repo.githubOwner;
    final repoName = repo.githubRepoName;
    final repoFullName = '$owner/$repoName';
    final channelId = _unitKey(repoFullName, prNumber);

    final existing = await _registry.forUnitRepo(
      workspaceId,
      channelId,
      repo.id,
    );
    if (existing != null) {
      if (Directory(existing.path).existsSync()) {
        return existing.path; // reuse the already-materialized worktree
      }
      // Row points at a vanished worktree — tear down stale state and re-create.
      await _safeDestroy(existing);
      await _registry.deleteById(existing.id);
    }

    final token = await _safeToken();
    final authUrl = (repo.hasGitHubRemote && token != null && token.isNotEmpty)
        ? 'https://x-access-token:$token@github.com/$owner/$repoName.git'
        : null;
    if (authUrl == null) {
      throw const PrWorktreeException(
        'Connect GitHub to open a pull request branch in an editor.',
      );
    }

    final workspaceDir = await _filesystem.workspaceDir(workspaceId);
    final parentDir = p.join(
      workspaceDir.path,
      'pr_worktrees',
      '${_sanitize(owner)}__${_sanitize(repoName)}',
    );
    // Directory stays stable + filesystem-safe per PR; the git branch carries
    // the PR's real head-ref name so the checkout reads as the PR's branch.
    final dirName = 'pr-$prNumber';
    final branch = prHeadRef.isNotEmpty ? prHeadRef : dirName;

    final RepoIsolationResult result;
    try {
      result = await _isolation.provision(
        sourcePath: repo.path,
        destParentDir: parentDir,
        name: dirName,
        branch: branch,
        authUrl: authUrl,
        headRef: 'refs/pull/$prNumber/head',
      );
    } catch (e) {
      throw PrWorktreeException('Could not check out PR #$prNumber: $e');
    }

    await _registry.upsert(
      IsolatedRepo(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        channelId: channelId,
        repoId: repo.id,
        path: result.path,
        // The git-worktree fallback checks out detached (no branch created in
        // the source), so record no branch — teardown must not `git branch -D`
        // a branch we didn't create. The rift copy owns its branch in isolation.
        branch: result.backend == RepoIsolationBackend.gitWorktree
            ? ''
            : branch,
        backend: result.backend,
        sourcePath: repo.path,
        createdAt: DateTime.now(),
      ),
    );
    return result.path;
  }

  @override
  Future<void> release({
    required String repoFullName,
    required int prNumber,
  }) async {
    final channelId = _unitKey(repoFullName, prNumber);
    final rows = await _registry.forChannelAcrossWorkspaces(channelId);
    for (final row in rows) {
      await _safeDestroy(row);
      await _registry.deleteById(row.id);
    }
  }

  Future<void> _safeDestroy(IsolatedRepo row) async {
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
  }

  Future<String?> _safeToken() async {
    try {
      return await _githubToken();
    } catch (_) {
      return null;
    }
  }

  /// Mirrors `WorkspaceFilesystemService`: replace anything other than
  /// alphanumerics, `-`, `.` with `_` to keep the path safe.
  static String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^a-zA-Z0-9\-.]'), '_');
}
