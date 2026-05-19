import 'dart:async';

import 'package:control_center/core/domain/events/agent_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';

/// Aggregates agent cost/token usage onto the pipeline run that dispatched the
/// agent, so a run carries a per-run cost rollup (e.g. for fan-out reviews).
///
/// On [AgentRunCompleted] it finds the agent's pipeline-tracked tickets, reads
/// the agent's most recent run-log cost, and adds it to those runs' totals.
class PipelineCostRollupListener {
  /// Creates a [PipelineCostRollupListener].
  PipelineCostRollupListener({
    required this.eventBus,
    required this.ticketRepository,
    required this.runLogRepository,
    required this.runRepository,
  });

  /// Bus carrying [AgentRunCompleted].
  final DomainEventBus eventBus;

  /// Used to map an agent run to its pipeline run(s).
  final TicketRepository ticketRepository;

  /// Source of the agent's cost/token usage.
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
    // Cost rollup is keyed on pipeline runs, which always carry a workspace; a
    // workspace-less run has nothing to roll up. Bailing keeps the
    // workspace-scoped `forAgent` query from fanning out across workspaces.
    final workspaceId = event.workspaceId;
    if (workspaceId == null) {
      return;
    }
    try {
      final tickets = await ticketRepository.forAgent(workspaceId, event.agentId);
      final runIds = tickets
          .where((t) => t.pipelineRunId != null)
          .map((t) => t.pipelineRunId!)
          .toSet();
      if (runIds.isEmpty) {
        return;
      }

      final logs = await runLogRepository.watchByAgent(event.agentId).first;
      final completed = logs.where((l) => l.completedAt != null).toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
      final log = completed.isEmpty ? null : completed.first;
      if (log == null) {
        return;
      }
      final cents = log.cost.estimatedCostCents;
      final tokens = log.cost.totalTokens;
      if (cents == 0 && tokens == 0) {
        return;
      }

      for (final runId in runIds) {
        await runRepository.incrementCost(runId, cents, tokens);
      }
    } on Object catch (e, st) {
      AppLog.e('PipelineCostRollup', 'cost rollup failed', e, st);
    }
  }

  /// Stops listening.
  void dispose() {
    _sub?.cancel();
  }
}
