/// What a raise of an orchestration's cap changed: the cap before and after,
/// in micro-dollars.
typedef OrchestrationCapRaise = ({int oldMicros, int newMicros});

/// The highest cap a raise may set (1,000 USD), the server's ceiling for
/// `orchestration.raiseCap`; clients check it before sending.
const int kOrchestrationCapMaxMicros = 1000 * 1000000;

/// The client's way to raise a held pipeline run's orchestration cap
/// (`orchestration.raiseCap`).
///
/// The server decides who may raise it and to what; a refusal arrives as the
/// RPC error with its `data.kind` (`orchestration_not_yours`,
/// `orchestration_cap_invalid`, `orchestration_cap_changed` with the fresh
/// cap in `data.max_cost_micros`). On success the held run resumes by itself.
abstract interface class OrchestrationCapRaiser {
  /// Raises orchestration [orchestrationId]'s cap to [maxCostMicros].
  Future<OrchestrationCapRaise> raiseCap(
    String workspaceId,
    String orchestrationId,
    int maxCostMicros,
  );
}
