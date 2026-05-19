import 'package:cc_persistence/cc_persistence.dart' show RepoDao;
import 'package:cc_persistence/database/daos/daos.dart' show RepoDao;
import 'package:cc_persistence/database/daos/repo_dao.dart' show RepoDao;
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

part 'workspace_registry_dao.g.dart';

/// Data access object for the [WorkspacesTable] registry in `global.db`.
///
/// **CROSS-WORKSPACE BY DESIGN.** This is the one DAO whose whole job is to see
/// every workspace: the switcher, the phone picker and "manage workspaces" list
/// them all and the server enumerates them for per-workspace fan-out
/// (retention, reconcilers, backup). It holds only registry metadata — name,
/// logo, owner, manual order, soft-delete. A workspace's *content* lives in its
/// own database file and is reached through `WorkspaceDatabaseManager`.
///
/// This DAO is the former `WorkspaceDao` minus its repo-link half, which moved
/// to [RepoDao] when `repos` became workspace-scoped.
@DriftAccessor(tables: [WorkspacesTable])
class WorkspaceRegistryDao extends DatabaseAccessor<GlobalDatabase>
    with _$WorkspaceRegistryDaoMixin {
  /// Creates a [WorkspaceRegistryDao] for the global database.
  WorkspaceRegistryDao(super.attachedDatabase);

  /// Watches all workspaces in the operator's manual drag-to-reorder
  /// [WorkspacesTable.position] (creation time as a stable tiebreak). This is
  /// the single query every workspace list flows through — the switcher
  /// popover, "manage workspaces", the phone picker — so this ORDER BY is the
  /// app-wide workspace order.
  Stream<List<WorkspacesTableData>> watchAll() =>
      (select(workspacesTable)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([
              (t) => OrderingTerm.asc(t.position),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  /// Returns a workspace by [id], or null when it does not exist or has been
  /// soft-deleted. Soft-deleted rows are excluded so no fetch path can resolve
  /// a deleted workspace (e.g. the web boot landing on a removed workspace).
  Future<WorkspacesTableData?> getById(String id) => (select(
    workspacesTable,
  )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();

  /// Returns all live (non-soft-deleted) workspaces in the same manual order as
  /// [watchAll], so the one-shot readers (the phone's
  /// `session/list_workspaces` picker, startup resolvers) agree with the
  /// streaming lists.
  Future<List<WorkspacesTableData>> getAll() =>
      (select(workspacesTable)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([
              (t) => OrderingTerm.asc(t.position),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .get();

  /// Returns every workspace id INCLUDING soft-deleted ones.
  ///
  /// Maintenance fan-out (retention sweeps, backup, the schema upgrade pass)
  /// uses this: a soft-deleted workspace still has a database file on disk and
  /// skipping it would leave that file un-swept and un-backed-up.
  Future<List<String>> allIdsIncludingDeleted() async {
    final rows = await select(workspacesTable).get();
    return [for (final r in rows) r.id];
  }

  /// Returns every LIVE workspace id, in the app-wide manual order.
  ///
  /// What the read fan-outs want. A soft-deleted workspace is one a person
  /// removed: opening its file to answer "show me all my agents" pays a cold
  /// open + `quick_check` to contribute rows the operator asked to stop seeing.
  /// Maintenance still wants [allIdsIncludingDeleted] — the file is on disk
  /// either way and skipping it would leave it un-swept and un-backed-up.
  Future<List<String>> liveIds() async {
    final rows =
        await (select(workspacesTable)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm.asc(t.position),
                (t) => OrderingTerm.asc(t.createdAt),
              ]))
            .get();
    return [for (final r in rows) r.id];
  }

  /// Inserts or updates a workspace.
  ///
  /// A row being INSERTED with no explicit [WorkspacesTable.position] is
  /// appended to the end of the manual order rather than landing on the
  /// default `0` (which would silently jump every new workspace to the top of
  /// the switcher). An UPDATE never touches the stored position unless the
  /// caller passes one, so a rename/logo change can't reshuffle the list.
  Future<void> upsertWorkspace(WorkspacesTableCompanion entry) async {
    var toWrite = entry;
    if (!entry.position.present && entry.id.present) {
      final exists = await _exists(entry.id.value);
      if (!exists) {
        toWrite = entry.copyWith(
          position: Value(await _nextWorkspacePosition()),
        );
      }
    }
    await into(workspacesTable).insertOnConflictUpdate(toWrite);
  }

  /// Whether a workspace row with [id] exists, INCLUDING soft-deleted ones — a
  /// restore must keep its place in the manual order rather than be re-appended.
  Future<bool> _exists(String id) async {
    final row =
        await (select(workspacesTable)
              ..where((t) => t.id.equals(id))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// The next free [WorkspacesTable.position] (max + 1, or 0 when there are no
  /// workspaces yet). Soft-deleted rows count, so a restore can't collide with
  /// a workspace created after it was deleted.
  Future<int> _nextWorkspacePosition() async {
    final maxPos = workspacesTable.position.max();
    final row = await (selectOnly(
      workspacesTable,
    )..addColumns([maxPos])).getSingleOrNull();
    return (row?.read(maxPos) ?? -1) + 1;
  }

  /// Re-sequences the workspaces in [workspaceIds] so each row's
  /// [WorkspacesTable.position] is its index in the list. This is the
  /// drag-to-reorder write path; callers pass the full displayed list and rows
  /// not named here keep their stored position. Runs in one transaction so a
  /// partial write can never leave two workspaces claiming one slot.
  Future<void> reorderWorkspaces(List<String> workspaceIds) async {
    await transaction(() async {
      for (var i = 0; i < workspaceIds.length; i++) {
        await (update(workspacesTable)
              ..where((t) => t.id.equals(workspaceIds[i])))
            .write(WorkspacesTableCompanion(position: Value(i)));
      }
    });
  }

  /// Soft-deletes a workspace by [id] (sets deleted_at).
  ///
  /// The workspace's database file is NOT removed here — the caller
  /// (`WorkspaceDatabaseManager.dropAndClose`) owns that, so a soft-delete can
  /// still be undone until the file is dropped.
  Future<int> deleteWorkspace(String id) =>
      (update(workspacesTable)..where((t) => t.id.equals(id))).write(
        WorkspacesTableCompanion(deletedAt: Value(DateTime.now())),
      );
}
