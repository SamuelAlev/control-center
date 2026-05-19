import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/repos.dart';
import 'package:control_center/core/database/tables/workspace_repos.dart';
import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

part 'workspace_dao.g.dart';

/// Data access object for the [WorkspacesTable] and its repo links.
@DriftAccessor(tables: [WorkspacesTable, WorkspaceReposTable, ReposTable])
class WorkspaceDao extends DatabaseAccessor<AppDatabase>
    with _$WorkspaceDaoMixin {
  /// Creates a [WorkspaceDao] for the given database.
  WorkspaceDao(super.attachedDatabase);

  /// Watches all workspaces ordered by updated time.
  Stream<List<WorkspacesTableData>> watchAll() => (select(
    workspacesTable,
  )..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  /// Returns a workspace by [id] or null.
  Future<WorkspacesTableData?> getById(String id) => (select(
    workspacesTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Returns all workspaces.
  Future<List<WorkspacesTableData>> getAll() => select(workspacesTable).get();

  /// Inserts or updates a workspace.
  Future<void> upsertWorkspace(WorkspacesTableCompanion entry) =>
      into(workspacesTable).insertOnConflictUpdate(entry);

  /// Soft-deletes a workspace by [id] (sets deleted_at). Linked data remains intact.
  Future<int> deleteWorkspace(String id) =>
      (update(workspacesTable)..where((t) => t.id.equals(id))).write(
        WorkspacesTableCompanion(deletedAt: Value(DateTime.now())),
      );

  /// Watches the repos linked to the given [workspaceId], ordered by link
  /// creation time.
  Stream<List<ReposTableData>> watchReposForWorkspace(String workspaceId) {
    final query =
        select(reposTable).join([
            innerJoin(
              workspaceReposTable,
              workspaceReposTable.repoId.equalsExp(reposTable.id),
            ),
          ])
          ..where(workspaceReposTable.workspaceId.equals(workspaceId))
          ..orderBy([OrderingTerm.asc(workspaceReposTable.createdAt)]);
    return query.watch().map(
      (rows) =>
          rows.map((r) => r.readTable(reposTable)).toList(growable: false),
    );
  }

  /// Whether [repoId] is currently linked to [workspaceId]. Used to enforce
  /// workspace isolation on repo-scoped operations (e.g. the code-graph tools)
  /// before exposing a repo's data to an agent that supplied a workspace id.
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) async {
    final row = await (select(workspaceReposTable)
          ..where(
            (t) => t.workspaceId.equals(workspaceId) & t.repoId.equals(repoId),
          )
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Links [repoId] to [workspaceId] if not already linked. Idempotent.
  Future<void> linkRepoToWorkspace(String workspaceId, String repoId) async {
    await into(workspaceReposTable).insert(
      WorkspaceReposTableCompanion.insert(
        workspaceId: workspaceId,
        repoId: repoId,
        createdAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Removes the link between [workspaceId] and [repoId], if any.
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async {
    await (delete(workspaceReposTable)..where(
          (t) => t.workspaceId.equals(workspaceId) & t.repoId.equals(repoId),
        ))
        .go();
  }

  /// Replaces the repos linked to [workspaceId] with [repoIds] atomically.
  Future<void> setReposForWorkspace(
    String workspaceId,
    List<String> repoIds,
  ) async {
    await transaction(() async {
      await (delete(
        workspaceReposTable,
      )..where((t) => t.workspaceId.equals(workspaceId))).go();
      final now = DateTime.now();
      for (final repoId in repoIds) {
        await into(workspaceReposTable).insert(
          WorkspaceReposTableCompanion.insert(
            workspaceId: workspaceId,
            repoId: repoId,
            createdAt: Value(now),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }
}
