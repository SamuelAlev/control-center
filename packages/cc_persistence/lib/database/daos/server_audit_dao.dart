import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';
import 'package:cc_persistence/database/daos/audit_filter_sql.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/server_audit_table.dart';
import 'package:drift/drift.dart';

part 'server_audit_dao.g.dart';

/// Data access object for [ServerAuditTable] in `global.db`.
@DriftAccessor(tables: [ServerAuditTable])
class ServerAuditDao extends DatabaseAccessor<GlobalDatabase>
    with _$ServerAuditDaoMixin {
  /// Creates a [ServerAuditDao] for the global database.
  ServerAuditDao(super.attachedDatabase);

  /// How many of the newest rows the table keeps. Server-scope mutations are
  /// settings changes, so this is years of history on a busy install while
  /// keeping `global.db` small.
  static const kept = 20000;

  /// How many appends share one prune. The table holds at most [kept] plus
  /// this many rows between prunes; pruning on every append would cost a
  /// delete statement per audited call.
  static const pruneEvery = 100;

  /// Appends left before the next prune. Zero at start, so the first append
  /// of a process trims whatever an earlier one left past the cap.
  int _appendsUntilPrune = 0;

  /// Appends [entry]; every [pruneEvery]th append also drops the rows past
  /// [kept], in the same transaction.
  ///
  /// The prune is bounded by rowid, which follows append order: everything at
  /// or below the newest rowid minus [kept] goes, an index range delete rather
  /// than a sort of the whole table.
  Future<void> append(ServerAuditTableCompanion entry) => transaction(() async {
    await into(serverAuditTable).insert(entry);
    if (_appendsUntilPrune > 0) {
      _appendsUntilPrune--;
      return;
    }
    _appendsUntilPrune = pruneEvery - 1;
    await customUpdate(
      'DELETE FROM server_audit WHERE rowid <= '
      '(SELECT MAX(rowid) FROM server_audit) - ?',
      variables: [Variable.withInt(kept)],
      updates: {serverAuditTable},
      updateKind: UpdateKind.delete,
    );
  });

  /// Matching rows strictly older than [olderThan] (from the newest when
  /// null), newest first, at most [limit].
  Future<List<ServerAuditTableData>> pageRows({
    ActivityCursor? olderThan,
    required int limit,
    AuditLogFilter filter = const AuditLogFilter(),
  }) =>
      (select(serverAuditTable)
            ..where(
              (t) =>
                  _predicate(t, filter) &
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

  /// Matching rows strictly newer than [newerThan], oldest first, at most
  /// [limit].
  Future<List<ServerAuditTableData>> newerRows({
    required ActivityCursor newerThan,
    required int limit,
    AuditLogFilter filter = const AuditLogFilter(),
  }) =>
      (select(serverAuditTable)
            ..where(
              (t) =>
                  _predicate(t, filter) &
                  auditNewerThan(t.createdAt, t.id, newerThan),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ])
            ..limit(limit))
          .get();

  /// How many rows match, or only those strictly newer than [newerThan].
  Future<int> count({
    AuditLogFilter filter = const AuditLogFilter(),
    ActivityCursor? newerThan,
  }) async {
    final t = serverAuditTable;
    final count = t.id.count();
    final row =
        await (selectOnly(t)
              ..addColumns([count])
              ..where(
                _predicate(t, filter) &
                    (newerThan == null
                        ? const Constant(true)
                        : auditNewerThan(t.createdAt, t.id, newerThan)),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Matching rows per value of [column] (`user_id`, `outcome`).
  Future<Map<String, int>> countBy(
    GeneratedColumn<String> Function($ServerAuditTableTable t) column, {
    AuditLogFilter filter = const AuditLogFilter(),
  }) async {
    final t = serverAuditTable;
    final key = column(t);
    final count = t.id.count();
    final rows =
        await (selectOnly(t)
              ..addColumns([key, count])
              ..where(_predicate(t, filter))
              ..groupBy([key]))
            .get();
    return {for (final r in rows) r.read(key)!: r.read(count) ?? 0};
  }

  /// Emits whenever a row is appended or pruned.
  Stream<void> watchChanges() =>
      attachedDatabase.tableUpdates(TableUpdateQuery.onTable(serverAuditTable));

  Expression<bool> _predicate(
    $ServerAuditTableTable t,
    AuditLogFilter filter,
  ) => auditFilterPredicate(
    filter,
    userId: t.userId,
    ip: t.ip,
    createdAt: t.createdAt,
    outcome: t.outcome,
    searchColumns: [t.op, t.argNames, t.ip],
  );
}
