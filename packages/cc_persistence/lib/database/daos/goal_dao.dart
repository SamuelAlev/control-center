import 'package:cc_persistence/database/tables/goals_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'goal_dao.g.dart';

/// Data access for the organizational goal hierarchy. Every read filters by
/// `workspaceId`.
@DriftAccessor(tables: [GoalsTable])
class GoalDao extends DatabaseAccessor<WorkspaceDatabase> with _$GoalDaoMixin {
  /// Creates a [GoalDao].
  GoalDao(super.db);

  /// Watches all goals for [workspaceId], newest first.
  Stream<List<GoalsTableData>> watchByWorkspace(String workspaceId) =>
      (select(goalsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Returns all goals for [workspaceId].
  Future<List<GoalsTableData>> getByWorkspace(String workspaceId) => (select(
    goalsTable,
  )..where((t) => t.workspaceId.equals(workspaceId))).get();

  /// Returns the direct children of [parentGoalId] within [workspaceId].
  Future<List<GoalsTableData>> childrenOf(
    String workspaceId,
    String parentGoalId,
  ) =>
      (select(goalsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.parentGoalId.equals(parentGoalId),
          ))
          .get();

  /// Returns a single goal by [id] within [workspaceId], or null. Scoping by
  /// workspace means a foreign row is simply not found.
  Future<GoalsTableData?> getById(String workspaceId, String id) =>
      (select(goalsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Inserts or updates a goal.
  Future<void> upsert(GoalsTableCompanion entry) =>
      into(goalsTable).insertOnConflictUpdate(entry);

  /// Deletes a goal by [id] within [workspaceId]. Returns rows deleted.
  Future<int> deleteById(String workspaceId, String id) => (delete(
    goalsTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();
}
