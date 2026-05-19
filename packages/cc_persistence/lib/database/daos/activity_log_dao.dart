import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/activity_log_table.dart';
import 'package:drift/drift.dart';

part 'activity_log_dao.g.dart';

/// Data access for the activity log (audit trail). Every workspace-scoped read
/// filters by `workspaceId`.
@DriftAccessor(tables: [ActivityLogTable])
class ActivityLogDao extends DatabaseAccessor<AppDatabase>
    with _$ActivityLogDaoMixin {
  /// Creates an [ActivityLogDao].
  ActivityLogDao(super.db);

  /// Inserts a new audit row.
  Future<void> insertEntry(ActivityLogTableCompanion entry) =>
      into(activityLogTable).insert(entry);

  /// Watches audit rows for a specific entity within [workspaceId], newest
  /// first.
  Stream<List<ActivityLogTableData>> watchForEntity(
    String workspaceId,
    String entityType,
    String entityId,
  ) =>
      (select(activityLogTable)
            ..where((t) =>
                t.workspaceId.equals(workspaceId) &
                t.entityType.equals(entityType) &
                t.entityId.equals(entityId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Watches recent audit rows for [workspaceId], newest first.
  Stream<List<ActivityLogTableData>> watchRecent(
    String workspaceId, {
    int limit = 100,
  }) =>
      (select(activityLogTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  /// Deletes audit rows older than [cutoff] (retention). Returns rows deleted.
  Future<int> deleteOlderThan(DateTime cutoff) =>
      (delete(activityLogTable)..where((t) => t.createdAt.isSmallerThanValue(cutoff)))
          .go();
}
