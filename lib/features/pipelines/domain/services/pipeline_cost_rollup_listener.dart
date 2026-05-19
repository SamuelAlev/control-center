import 'dart:async';

import 'package:control_center/core/domain/events/agent_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_run_repository.dart';

/// Aggregates agent cost/token usage onto the pipeline run that dispatched the
/// agent, so a run carries a per-run cost rollup (e.g. for fan-out reviews).
///
/// On [AgentRunCompleted] it reads the completed run log directly by its
/// `runId` and, when that log belongs to a pipeline run (`pipelineRunId`),
/// adds its cost to that run's total. This is exact: no ticket fan-out, no
/// "most recent run" heuristic — the event names the precise run.
class PipelineCostRollupListener {
  /// Creates a [PipelineCostRollupListener].
  PipelineCostRollupListener({
    required this.eventBus,
    required this.runLogRepository,
    required this.runRepository,
  });

  /// Bus carrying [AgentRunCompleted].
  final DomainEventBus eventBus;

  /// Source of the agent's cost/token usage (read by the event's `runId`).
  final AgentRunLogRepository runLogRepository;

  /// Target for the cost increment.
  final PipelineRunRepository runRepository;

  StreamSubscription<DomainEvent>? _sub;

  /// Starts listening.
  void start() {
    _sub = eventBus.on<DomainEvent>().listen(_onEvent);
  }

  Future<void> _onEvent(DomainEvent event) async {
    if (event is! AgentRunCompleted) {
      return;
    }
    final runId = event.runId;
    if (runId == null) {
      return;
    }
    try {
      final log = await runLogRepository.getById(runId);
      final pipelineRunId = log?.pipelineRunId;
      if (log == null || pipelineRunId == null) {
        return;
      }
      final cents = log.cost.estimatedCostCents;
      final tokens = log.cost.totalTokens;
      if (cents == 0 && tokens == 0) {
        return;
      }
      await runRepository.incrementCost(pipelineRunId, cents, tokens);
    } on Object catch (e, st) {
      AppLog.e('PipelineCostRollup', 'cost rollup failed', e, st);
    }
  }

  /// Stops listening.
  void dispose() {
    _sub?.cancel();
  }
}
