import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';

/// Aggregates agent cost/token usage onto the pipeline run that dispatched the
/// agent, so a run carries a per-run cost rollup (e.g. for fan-out reviews).
///
/// On [AgentRunSettled] (published after the run's terminal write, so the
/// final cost is on the row) it reads the run log directly by its `runId` and, when that log belongs to a pipeline run (`pipelineRunId`),
/// adds its cost to that run's total. This is exact: no ticket fan-out, no
/// "most recent run" heuristic — the event names the precise run.
class PipelineCostRollupListener {
  /// Creates a [PipelineCostRollupListener].
  PipelineCostRollupListener({
    required this.eventBus,
    required this.runLogRepository,
    required this.runRepository,
  });

  /// Bus carrying [AgentRunSettled].
  final DomainEventBus eventBus;

  /// Source of the agent's cost/token usage (read by the event's `runId`).
  final AgentRunLogRepository runLogRepository;

  /// Target for the cost increment.
  final PipelineRunRepository runRepository;

  StreamSubscription<AgentRunSettled>? _sub;

  /// Starts listening.
  void start() {
    _sub = eventBus.on<AgentRunSettled>().listen(_onEvent);
  }

  Future<void> _onEvent(AgentRunSettled event) async {
    final runId = event.runId;
    final workspaceId = event.workspaceId;
    try {
      final log = await runLogRepository.getById(workspaceId, runId);
      final pipelineRunId = log?.pipelineRunId;
      if (log == null || pipelineRunId == null) {
        return;
      }
      final micros = log.cost.costMicros;
      final tokens = log.cost.totalTokens;
      if (micros == 0 && tokens == 0) {
        return;
      }
      await runRepository.incrementCost(pipelineRunId, micros, tokens);
    } on DeletedWorkspaceException {
      // The run outlived its workspace: there is no pipeline run to add to.
    } on Object catch (e, st) {
      CcDomainLog.error('PipelineCostRollup: cost rollup failed', e, st);
    }
  }

  /// Stops listening.
  void dispose() {
    _sub?.cancel();
  }
}
