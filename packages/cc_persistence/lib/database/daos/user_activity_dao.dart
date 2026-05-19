import 'package:cc_persistence/database/tables/user_activity_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'user_activity_dao.g.dart';

/// Data access object for [UserActivityTable] (the per-user audit trail).
///
/// Append-only and workspace-scoped; rows are pruned by the retention
/// service, never updated.
@DriftAccessor(tables: [UserActivityTable])
class UserActivityDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$UserActivityDaoMixin {
  /// Creates a [UserActivityDao] for the given database.
  UserActivityDao(super.attachedDatabase);

  /// Appends one audit record.
  Future<void> append(UserActivityTableCompanion entry) =>
      into(userActivityTable).insert(entry);

  /// Latest activity in [workspaceId], newest first, capped at [limit].
  Future<List<UserActivityTableData>> getForWorkspace(
    String workspaceId, {
    int limit = 200,
  }) =>
      (select(userActivityTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  /// Watches the latest activity in [workspaceId], newest first.
  Stream<List<UserActivityTableData>> watchForWorkspace(
    String workspaceId, {
    int limit = 200,
  }) =>
      (select(userActivityTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  /// Deletes entries older than [cutoff]; returns the number removed.
  ///
  /// Retention: drops this workspace's old rows. The nightly sweep runs it once
  /// per workspace.
  Future<int> deleteOlderThan(DateTime cutoff) => (delete(
    userActivityTable,
  )..where((t) => t.createdAt.isSmallerThanValue(cutoff))).go();
}
