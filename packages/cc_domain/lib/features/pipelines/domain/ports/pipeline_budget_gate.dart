import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';

/// The reason a run is held when its orchestration reached its cost cap.
const String kOrchestrationBudgetHoldReason = 'orchestration_budget';

/// The reserved state key a held run carries while it is held: the
/// [PipelineBudgetHold] as JSON (`reason`, `cap_micros`, `spent_micros`,
/// `orchestration_id`, `held_at`). Written and removed only by the engine.
const String kBudgetHoldStateKey = '__hold__';

/// Why the engine holds the remaining steps of a run: what it may spend and
/// what it has spent.
class PipelineBudgetHold {
  /// Creates a hold. Throws [ArgumentError] for an empty [reason] or
  /// [orchestrationId], or a negative amount.
  PipelineBudgetHold({
    required this.reason,
    required this.orchestrationId,
    required this.capMicros,
    required this.spentMicros,
    required this.heldAt,
  }) {
    if (reason.isEmpty || orchestrationId.isEmpty) {
      throw ArgumentError('A hold needs a reason and an orchestration');
    }
    if (capMicros < 0 || spentMicros < 0) {
      throw ArgumentError('A hold has no negative amounts');
    }
  }

  /// [kOrchestrationBudgetHoldReason].
  final String reason;

  /// The orchestration whose cap holds the run.
  final String orchestrationId;

  /// The orchestration's `maxCostMicros`.
  final int capMicros;

  /// What the run has spent, in micro-dollars.
  final int spentMicros;

  /// When the hold was found.
  final DateTime heldAt;

  /// The state value under [kBudgetHoldStateKey].
  Map<String, Object?> toJson() => {
    'reason': reason,
    'orchestration_id': orchestrationId,
    'cap_micros': capMicros,
    'spent_micros': spentMicros,
    'held_at': heldAt.toUtc().toIso8601String(),
  };
}

/// Decides, before the engine dispatches a step, whether the run must hold
/// its remaining steps. Bound on the server to the orchestration that owns
/// the run; pipelines never import orchestration.
abstract interface class PipelineBudgetGate {
  /// The hold for [run] now, or null when it may continue.
  Future<PipelineBudgetHold?> check(PipelineRun run);

  /// Called once per hold, after the engine suspended [run] and recorded
  /// [hold]: the person is told here.
  Future<void> onHeld(PipelineRun run, PipelineBudgetHold hold);
}
