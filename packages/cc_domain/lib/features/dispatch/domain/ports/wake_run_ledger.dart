import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';

/// Which run delivered which wakes, as the run log records it
/// (`agent_run_logs.wake_ids`).
///
/// The wake queue reads it after a restart (a claimed wake whose id is on a
/// run that took it was delivered) and appends to it when a run drains a
/// wake pushed into its lane, so the run's settlement names the wakes it
/// actually took. Separate from `AgentRunLogRepository` on purpose: two
/// methods only the queue needs.
abstract interface class WakeRunLedger {
  /// The newest run in [workspaceId] whose wake ids contain [wakeId], or
  /// null when no run carries it.
  Future<WakeLedgerRun?> runForWake(String workspaceId, String wakeId);

  /// Adds [wakeIds] to the run [runId]'s list, keeping its order and never
  /// repeating an id. A missing run is a no-op.
  Future<void> addWakeIds(
    String workspaceId,
    String runId,
    List<String> wakeIds,
  );
}

/// A run that carries a wake, as [WakeRunLedger.runForWake] reads it.
class WakeLedgerRun {
  /// Creates the record. [runId] must not be empty.
  WakeLedgerRun({
    required this.runId,
    required this.live,
    required this.endReason,
  }) {
    if (runId.isEmpty) {
      throw ArgumentError('WakeLedgerRun runId must not be empty');
    }
  }

  /// The run-log id.
  final String runId;

  /// Whether the run has not ended yet.
  final bool live;

  /// Why it ended; null while it is live.
  final RunEndReason? endReason;

  /// Whether the run took its wakes: it is live, or it ended for any reason
  /// but a server stop (whose wakes are delivered again by a new run).
  bool get tookItsWakes => live || endReason != RunEndReason.serverStopped;

  @override
  bool operator ==(Object other) =>
      other is WakeLedgerRun &&
      other.runId == runId &&
      other.live == live &&
      other.endReason == endReason;

  @override
  int get hashCode => Object.hash(runId, live, endReason);
}
