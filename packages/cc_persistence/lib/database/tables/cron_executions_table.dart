import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/pipeline_triggers_table.dart';
import 'package:drift/drift.dart';

/// Idempotency ledger for scheduled (cron) pipeline fires.
///
/// One row per `(trigger_id, planned_at)` slot. The unique index on that pair
/// (`idx_cron_executions_slot`, the target of `CronExecutionDao.claimSlot`)
/// makes a re-fire of the same slot — after a restart, or from overlapping
/// ticks — a no-op insert, so a cron trigger never double-starts a run for the
/// same instant. A trigger's ledger goes with the trigger.
@TableIndex(
  name: 'idx_cron_executions_slot',
  columns: {#triggerId, #plannedAt},
  unique: true,
)
@TableIndex(name: 'idx_cron_executions_created', columns: {#createdAt})
class CronExecutionsTable extends Table {
  /// Unique identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The scheduled trigger that fired.
  TextColumn get triggerId => text().references(
    PipelineTriggersTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The scheduled slot this fire was for (UTC) — the idempotency key.
  DateTimeColumn get plannedAt => dateTime()();

  /// Fire status: a `CronFireStatus` name.
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(AgentsStoredValues.cronFireStatus),
      )
      .withDefault(const Constant('fired'))();

  /// When the row was recorded. The retention sweep deletes by it
  /// (`idx_cron_executions_created`).
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'cron_executions';

  @override
  Set<Column> get primaryKey => {id};
}
