/// Idempotency ledger for scheduled (cron) pipeline fires.
///
/// Backed by the `cron_executions` table: one row per `(triggerId, plannedAt)`
/// slot, with a unique index so a re-fire of the same instant is a no-op.
abstract interface class CronExecutionLedger {
  /// Atomically claims the `(triggerId, plannedAt)` slot for [workspaceId].
  /// Returns `true` when the slot was newly recorded (the caller should fire),
  /// `false` when it was already claimed (a duplicate fire to suppress).
  Future<bool> claimSlot({
    required String id,
    required String workspaceId,
    required String triggerId,
    required DateTime plannedAt,
  });
}
