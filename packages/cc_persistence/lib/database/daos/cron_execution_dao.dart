import 'package:cc_persistence/database/tables/cron_executions_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'cron_execution_dao.g.dart';

/// Data access for the cron idempotency ledger.
@DriftAccessor(tables: [CronExecutionsTable])
class CronExecutionDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$CronExecutionDaoMixin {
  /// Creates a [CronExecutionDao].
  CronExecutionDao(super.db);

  /// Atomically claims the `(triggerId, plannedAt)` slot. Returns `true` only
  /// when this call inserted the slot's row (the caller should fire), `false`
  /// when the slot was already claimed (a duplicate fire to suppress). The
  /// conflict target is the unique `(trigger_id, planned_at)` index
  /// (`idx_cron_executions_slot`) and nothing else, so two overlapping ticks
  /// cannot both win one slot while any other failure still throws.
  Future<bool> claimSlot({
    required String id,
    required String workspaceId,
    required String triggerId,
    required DateTime plannedAt,
  }) async =>
      await into(cronExecutionsTable).insertReturningOrNull(
        CronExecutionsTableCompanion.insert(
          id: id,
          workspaceId: workspaceId,
          triggerId: triggerId,
          plannedAt: plannedAt.toUtc(),
        ),
        onConflict: DoNothing(
          target: [
            cronExecutionsTable.triggerId,
            cronExecutionsTable.plannedAt,
          ],
        ),
      ) !=
      null;

  /// Removes the claim on the `(triggerId, plannedAt)` slot so it can be claimed
  /// again. Used when the claimed slot's run failed to start.
  Future<void> releaseSlot({
    required String triggerId,
    required DateTime plannedAt,
  }) async {
    final slot = plannedAt.toUtc();
    await (delete(cronExecutionsTable)..where(
          (c) => c.triggerId.equals(triggerId) & c.plannedAt.equals(slot),
        ))
        .go();
  }

  /// Recent executions for a trigger, newest slot first (workspace-scoped).
  Future<List<CronExecutionsTableData>> forTrigger(
    String workspaceId,
    String triggerId,
  ) =>
      (select(cronExecutionsTable)
            ..where(
              (c) =>
                  c.workspaceId.equals(workspaceId) &
                  c.triggerId.equals(triggerId),
            )
            ..orderBy([(c) => OrderingTerm.desc(c.plannedAt)]))
          .get();

  /// Deletes cron-fire ledger rows created before [cutoff] (retention). The
  /// ledger only needs recent history for idempotency; older rows accumulate
  /// forever otherwise. Returns the number of rows deleted.
  ///
  /// Retention: drops this workspace's old rows. The nightly sweep runs it once
  /// per workspace.
  Future<int> deleteOlderThan(DateTime cutoff) => (delete(
    cronExecutionsTable,
  )..where((c) => c.createdAt.isSmallerThanValue(cutoff))).go();
}
