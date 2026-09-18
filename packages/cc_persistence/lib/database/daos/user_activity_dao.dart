import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/user_activity_page.dart';
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

  /// Newest-first keyset page. Pass [limit] + 1 so the caller can see whether
  /// an older page remains. [cursor] is an exclusive older-than bound.
  Future<List<UserActivityTableData>> getPageRows(
    String workspaceId, {
    required int limit,
    ActivityCursor? cursor,
    UserActivityFilter filter = const UserActivityFilter(),
  }) => _pageQuery(
    workspaceId,
    limit: limit,
    cursor: cursor,
    filter: filter,
  ).get();

  /// Live counterpart of [getPageRows].
  Stream<List<UserActivityTableData>> watchPageRows(
    String workspaceId, {
    required int limit,
    ActivityCursor? cursor,
    UserActivityFilter filter = const UserActivityFilter(),
  }) => _pageQuery(
    workspaceId,
    limit: limit,
    cursor: cursor,
    filter: filter,
  ).watch();

  /// Rows strictly newer than [cursor], oldest-of-those first (the reverse
  /// of the page order). Used to compute `prev_cursor` and the 1-based start.
  Future<List<UserActivityTableData>> getNewerRows(
    String workspaceId, {
    required ActivityCursor cursor,
    required int limit,
    UserActivityFilter filter = const UserActivityFilter(),
  }) {
    final t = userActivityTable;
    return (select(t)
          ..where(
            (row) =>
                _predicate(row, workspaceId, filter) & _newerThan(row, cursor),
          )
          ..orderBy([
            (row) => OrderingTerm.asc(row.createdAt),
            (row) => OrderingTerm.asc(row.id),
          ])
          ..limit(limit))
        .get();
  }

  /// How many rows match [filter] in [workspaceId].
  Future<int> countForWorkspace(
    String workspaceId, {
    UserActivityFilter filter = const UserActivityFilter(),
  }) async {
    final count = userActivityTable.id.count();
    final row =
        await (selectOnly(userActivityTable)
              ..addColumns([count])
              ..where(_predicate(userActivityTable, workspaceId, filter)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// How many matching rows sort strictly newer than [cursor].
  Future<int> countNewerThan(
    String workspaceId,
    ActivityCursor cursor, {
    UserActivityFilter filter = const UserActivityFilter(),
  }) async {
    final count = userActivityTable.id.count();
    final row =
        await (selectOnly(userActivityTable)
              ..addColumns([count])
              ..where(
                _predicate(userActivityTable, workspaceId, filter) &
                    _newerThan(userActivityTable, cursor),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  SimpleSelectStatement<$UserActivityTableTable, UserActivityTableData>
  _pageQuery(
    String workspaceId, {
    required int limit,
    ActivityCursor? cursor,
    UserActivityFilter filter = const UserActivityFilter(),
  }) {
    final query = select(userActivityTable)
      ..where(
        (t) =>
            _predicate(t, workspaceId, filter) &
            (cursor == null ? const Constant(true) : _olderThan(t, cursor)),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(limit);
    return query;
  }

  Expression<bool> _predicate(
    $UserActivityTableTable t,
    String workspaceId,
    UserActivityFilter filter,
  ) {
    var expr = t.workspaceId.equals(workspaceId);
    final ip = filter.ip;
    if (ip != null && ip.isNotEmpty) {
      expr = expr & t.ip.equals(ip);
    }
    final country = filter.countryCode;
    if (country != null && country.isNotEmpty) {
      expr = expr & t.countryCode.equals(country);
    }
    if (filter.localNetwork) {
      expr = expr & t.ip.isNotNull() & t.countryCode.isNull();
    }
    final needle = _searchNeedle(filter.query);
    final userIds = filter.userIds.where((id) => id.isNotEmpty).toList();
    if (needle != null || userIds.isNotEmpty) {
      Expression<bool>? text;
      if (needle != null) {
        final pattern = '%$needle%';
        text =
            t.action.lower().like(pattern) |
            t.targetId.lower().like(pattern) |
            t.targetType.lower().like(pattern) |
            t.ip.lower().like(pattern) |
            t.details.lower().like(pattern);
      }
      if (userIds.isNotEmpty) {
        final users = t.userId.isIn(userIds);
        text = text == null ? users : text | users;
      }
      expr = expr & text!;
    }
    return expr;
  }

  Expression<bool> _olderThan(
    $UserActivityTableTable t,
    ActivityCursor cursor,
  ) {
    final at = cursor.createdAt;
    return t.createdAt.isSmallerThanValue(at) |
        (t.createdAt.equals(at) & t.id.isSmallerThanValue(cursor.id));
  }

  Expression<bool> _newerThan(
    $UserActivityTableTable t,
    ActivityCursor cursor,
  ) {
    final at = cursor.createdAt;
    return t.createdAt.isBiggerThanValue(at) |
        (t.createdAt.equals(at) & t.id.isBiggerThanValue(cursor.id));
  }

  /// Deletes entries older than [cutoff]; returns the number removed.
  ///
  /// Retention: drops this workspace's old rows. The nightly sweep runs it once
  /// per workspace.
  Future<int> deleteOlderThan(DateTime cutoff) => (delete(
    userActivityTable,
  )..where((t) => t.createdAt.isSmallerThanValue(cutoff))).go();
}

/// Lowercased LIKE needle with SQL wildcards stripped so a typed `%` cannot
/// widen the scan.
String? _searchNeedle(String? query) {
  if (query == null) {
    return null;
  }
  final needle = query
      .toLowerCase()
      .replaceAll('%', '')
      .replaceAll('_', '')
      .trim();
  return needle.isEmpty ? null : needle;
}
