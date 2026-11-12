/// Writes a run's `submit_output` result without touching the rest of the run.
///
/// A narrow port of its own, like `AgentRunCostHistoryPort`, rather than more
/// methods on `AgentRunLogRepository`: both writers (the `submit_output` tool
/// and the pipeline's fallback harvest) run in the server next to the store,
/// and each used to re-upsert the whole run it had read just to set one field.
/// That rewrote the run's status, summary and counters from a snapshot taken
/// before the terminal write that races them, and rewrote the run's payload to
/// bump a counter. Each method here writes exactly one thing.
///
/// Only the persistence-backed run-log repository implements it.
abstract class AgentRunOutputPort {
  /// Stores [output] as the `submit_output` payload of run [runId] in
  /// [workspaceId]. Nothing else about the run is written. A run that is not
  /// in [workspaceId] is left alone.
  Future<void> recordOutput(
    String workspaceId,
    String runId,
    Map<String, dynamic> output,
  );

  /// Counts one rejected `submit_output` call on run [runId] in one atomic
  /// step and returns the new count, or null when the run is not in
  /// [workspaceId].
  Future<int?> addOutputRejection(String workspaceId, String runId);
}
