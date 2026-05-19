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

  /// Atomically claims the `(triggerId, plannedAt)` slot. Returns `true` when
  /// this call recorded the slot (the caller should fire), `false` when the
  /// slot was already claimed (a duplicate fire to suppress).
  Future<bool> claimSlot({
    required String id,
    required String workspaceId,
    required String triggerId,
    required DateTime plannedAt,
  }) async {
    final slot = plannedAt.toUtc();
    final existing =
        await (select(cronExecutionsTable)
              ..where(
                (c) => c.triggerId.equals(triggerId) & c.plannedAt.equals(slot),
              )
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) {
      return false;
    }
    await into(cronExecutionsTable).insert(
      CronExecutionsTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        triggerId: triggerId,
        plannedAt: slot,
      ),
      mode: InsertMode.insertOrIgnore,
    );
    return true;
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
