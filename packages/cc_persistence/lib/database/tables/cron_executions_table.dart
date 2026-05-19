import 'package:drift/drift.dart';

/// Idempotency ledger for scheduled (cron) pipeline fires.
///
/// One row per `(trigger_id, planned_at)` slot. A partial-unique index on that
/// pair (created in the DB migration) makes a re-fire of the same slot — after
/// a restart, or from overlapping ticks — a no-op, so a cron trigger never
/// double-starts a run for the same instant.
@TableIndex(name: 'idx_cron_executions_workspace', columns: {#workspaceId})
class CronExecutionsTable extends Table {
  /// Unique identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The scheduled trigger that fired.
  TextColumn get triggerId => text()();

  /// The scheduled slot this fire was for (UTC) — the idempotency key.
  DateTimeColumn get plannedAt => dateTime()();

  /// Fire status: `fired` | `skipped` | `failed`.
  TextColumn get status => text().withDefault(const Constant('fired'))();

  /// When the row was recorded.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'cron_executions';

  @override
  Set<Column> get primaryKey => {id};
}
