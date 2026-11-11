import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';
import 'package:cc_persistence/database/daos/audit_filter_sql.dart';
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

  /// Matching rows strictly older than [olderThan] (from the newest when
  /// null), newest first, at most [limit].
  Future<List<UserActivityTableData>> pageRows(
    String workspaceId, {
    ActivityCursor? olderThan,
    required int limit,
    AuditLogFilter filter = const AuditLogFilter(),
  }) =>
      (select(userActivityTable)
            ..where(
              (t) =>
                  _predicate(t, workspaceId, filter) &
                  (olderThan == null
                      ? const Constant(true)
                      : auditOlderThan(t.createdAt, t.id, olderThan)),
            )
            ..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(limit))
          .get();

  /// Matching rows strictly newer than [newerThan], oldest first (the
  /// reverse of the page order), at most [limit].
  Future<List<UserActivityTableData>> newerRows(
    String workspaceId, {
    required ActivityCursor newerThan,
    required int limit,
    AuditLogFilter filter = const AuditLogFilter(),
  }) =>
      (select(userActivityTable)
            ..where(
              (t) =>
                  _predicate(t, workspaceId, filter) &
                  auditNewerThan(t.createdAt, t.id, newerThan),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ])
            ..limit(limit))
          .get();

  /// How many rows match, or only those strictly newer than [newerThan].
  Future<int> count(
    String workspaceId, {
    AuditLogFilter filter = const AuditLogFilter(),
    ActivityCursor? newerThan,
  }) async {
    final t = userActivityTable;
    final count = t.id.count();
    final row =
        await (selectOnly(t)
              ..addColumns([count])
              ..where(
                _predicate(t, workspaceId, filter) &
                    (newerThan == null
                        ? const Constant(true)
                        : auditNewerThan(t.createdAt, t.id, newerThan)),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Matching rows per actor id.
  Future<Map<String, int>> countByActor(
    String workspaceId, {
    AuditLogFilter filter = const AuditLogFilter(),
  }) async {
    final t = userActivityTable;
    final count = t.id.count();
    final rows =
        await (selectOnly(t)
              ..addColumns([t.userId, count])
              ..where(_predicate(t, workspaceId, filter))
              ..groupBy([t.userId]))
            .get();
    return {for (final r in rows) r.read(t.userId)!: r.read(count) ?? 0};
  }

  /// Emits whenever a row is appended or pruned.
  Stream<void> watchChanges() => attachedDatabase.tableUpdates(
    TableUpdateQuery.onTable(userActivityTable),
  );

  Expression<bool> _predicate(
    $UserActivityTableTable t,
    String workspaceId,
    AuditLogFilter filter,
  ) =>
      t.workspaceId.equals(workspaceId) &
      auditFilterPredicate(
        filter,
        userId: t.userId,
        ip: t.ip,
        createdAt: t.createdAt,
        countryCode: t.countryCode,
        searchColumns: [t.action, t.targetType, t.targetId, t.ip, t.details],
      );

  /// Deletes entries older than [cutoff]; returns the number removed.
  ///
  /// Retention: drops this workspace's old rows. The nightly sweep runs it once
  /// per workspace.
  Future<int> deleteOlderThan(DateTime cutoff) => (delete(
    userActivityTable,
  )..where((t) => t.createdAt.isSmallerThanValue(cutoff))).go();
}
