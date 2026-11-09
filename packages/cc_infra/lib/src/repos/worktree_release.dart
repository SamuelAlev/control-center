import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/environments/domain/ports/worktree_task_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_stack_repository.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// What releasing a set of worktrees does to the spaces they belong to.
enum WorktreeReleaseMode {
  /// The spaces are going away: their environments are torn down first, so
  /// nothing keeps running against a directory that is about to disappear.
  teardownEnvironment,

  /// Only these worktrees go, and their spaces live on. An environment still
  /// running there reconciles against the repos it has left (a degraded
  /// state, or a teardown when a required role went), which is its own
  /// decision, not this one's.
  releaseRowsOnly,
}

/// The one way a worktree is released.
///
/// Every route that takes a worktree away (a deleted space, a finished
/// ticket, a deselected repo, the stale sweep, a rolled-back provision, a
/// PR's editor worktree) comes through here, in this order: the space's
/// environment when [WorktreeReleaseMode.teardownEnvironment] says so, the
/// repo's `archive` tasks while the copy is still on disk, the copy itself,
/// then its stack rows and registry row. A release path around this skips
/// one of those steps.
///
/// Nothing here runs git against the source checkout beyond what
/// [RepoIsolationPort.destroy] does for its backend, and nothing commits,
/// stashes or checks out anywhere.
class WorktreeReleaser {
  /// Creates a [WorktreeReleaser].
  WorktreeReleaser({
    required this._isolation,
    required this._registry,
    this._worktreeTasks,
    this._stacks,
  });

  final RepoIsolationPort _isolation;
  final IsolatedRepoRepository _registry;

  /// Environment teardown and `archive` tasks, or null on a host without
  /// environments.
  final WorktreeTaskPort? _worktreeTasks;

  /// Stack layers whose branches go with the worktree on the Windows
  /// `git worktree` backend.
  final SpaceStackRepository? _stacks;

  /// Releases registered [rows].
  ///
  /// With [WorktreeReleaseMode.teardownEnvironment], every space of [rows]
  /// and of [spaces] has its environment torn down first; [spaces] covers a
  /// space whose environment runs on no worktree row (the source checkout).
  /// Each step is best-effort: a GC path has nobody to answer, so a failure
  /// is logged and the release carries on. With [strict], a copy that could
  /// not be destroyed throws instead and keeps its row: the caller is about
  /// to build in its place, and building over it would collide.
  Future<void> release(
    List<IsolatedRepo> rows, {
    required WorktreeReleaseMode mode,
    Iterable<(String, String)> spaces = const [],
    bool strict = false,
  }) async {
    final tasks = _worktreeTasks;
    if (tasks != null && mode == WorktreeReleaseMode.teardownEnvironment) {
      final owners = <(String, String)>{
        for (final row in rows)
          if (row.spaceId.isNotEmpty && !isPrEditorUnit(row.spaceId))
            (row.workspaceId, row.spaceId),
        ...spaces,
      };
      for (final (workspaceId, spaceId) in owners) {
        try {
          await tasks.beforeRelease(workspaceId, spaceId);
        } on Object catch (e) {
          CcInfraLog.warning('environment teardown failed for $spaceId: $e');
        }
      }
    }
    for (final row in rows) {
      // `archive` tasks run while the worktree is still on disk: their job is
      // cleaning up what lives OUTSIDE it, which only makes sense before the
      // copy goes. A copy that already vanished has nothing to run them in.
      if (tasks != null && Directory(row.path).existsSync()) {
        try {
          await tasks.runArchive(_archiveContext(row));
        } on Object catch (e) {
          CcInfraLog.warning('archive task failed for ${row.path}: $e');
        }
      }
      try {
        await _isolation.destroy(
          path: row.path,
          sourcePath: row.sourcePath,
          backend: row.backend,
          branch: row.branch,
          branches: await _stackBranchNames(row),
        );
      } on Object catch (e) {
        if (strict) {
          rethrow;
        }
        CcInfraLog.warning('destroy failed for ${row.path}: $e');
      }
      try {
        await _stacks?.deleteForRepo(row.workspaceId, row.spaceId, row.repoId);
      } on Object catch (e) {
        CcInfraLog.warning('stack rows of ${row.path} not removed: $e');
      }
      await _registry.deleteById(row.workspaceId, row.id);
    }
  }

  /// Removes a copy at [destPath] that no registry row names: an orphan that
  /// would block a provision, or what a failed provision left behind. No
  /// tasks run, because nothing provisioned it as far as anyone recorded.
  ///
  /// The backend is inferred rather than read back: whichever one a provision
  /// would have used on this host. A wrong guess still ends with the
  /// directory gone, which is the part that matters. A no-op when nothing is
  /// there, which is the normal case.
  Future<void> reapUnregistered({
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

  /// What a row's `archive` tasks see.
  ///
  /// A PR editor worktree belongs to no space, and nothing recorded whether
  /// its head is a fork's, so it counts as one: its tasks then run only
  /// where fork code may run, which with no space is nowhere.
  WorktreeTaskContext _archiveContext(IsolatedRepo row) {
    final editor = isPrEditorUnit(row.spaceId);
    return WorktreeTaskContext(
      workspaceId: row.workspaceId,
      spaceId: editor || row.spaceId.isEmpty ? null : row.spaceId,
      repoId: row.repoId,
      worktreePath: row.path,
      sourcePath: row.sourcePath,
      isForkPr: editor,
      isPrWorktree: editor || row.branch.startsWith('pr/'),
    );
  }

  Future<List<String>> _stackBranchNames(IsolatedRepo row) async {
    final stacks = _stacks;
    if (stacks == null) {
      return const [];
    }
    try {
      final entries = await stacks.forRepo(
        row.workspaceId,
        row.spaceId,
        row.repoId,
      );
      return [for (final entry in entries) entry.branch];
    } on Object catch (e) {
      CcInfraLog.warning('stack branches of ${row.path} unknown: $e');
      return const [];
    }
  }
}

/// Whether [spaceId] is the synthetic unit of a PR editor worktree
/// (`pr:<owner>/<repo>#<number>`) rather than a space.
bool isPrEditorUnit(String spaceId) => spaceId.startsWith('pr:');
