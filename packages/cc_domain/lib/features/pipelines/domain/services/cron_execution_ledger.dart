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

  /// Gives a claimed slot back after its run failed to start, so the next tick
  /// can claim it again. A slot only counts as spent once a run exists for it.
  Future<void> releaseSlot({
    required String workspaceId,
    required String triggerId,
    required DateTime plannedAt,
  });
}
