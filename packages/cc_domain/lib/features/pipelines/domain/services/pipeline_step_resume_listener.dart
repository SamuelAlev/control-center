import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';

/// Resumes a suspended pipeline step once every agent run it dispatched has
/// reached a terminal state. Replaces the ticket-based `TicketResumeListener`:
/// the work surface is now a hidden conversation and the output contract lives
/// on the `AgentRunLog`, so step completion keys off runs, not tickets.
///
/// Listens to [AgentRunCompleted], resolves the finished run's pipeline
/// coupling, groups runs by `(pipelineRunId, pipelineStepRunId)`, and — once
/// all of them are terminal — asks the engine to harvest their `outputJson`
/// and advance the step.
class PipelineStepResumeListener {
  /// Creates a [PipelineStepResumeListener].
  PipelineStepResumeListener({
    required DomainEventBus eventBus,
    required AgentRunLogRepository runLogRepository,
    required PipelineEngine engine,
  })  : _eventBus = eventBus,
        _runLogs = runLogRepository,
        _engine = engine;

  final DomainEventBus _eventBus;
  final AgentRunLogRepository _runLogs;
  final PipelineEngine _engine;

  StreamSubscription<AgentRunCompleted>? _sub;

  /// Start listening for terminal agent-run events.
  void start() {
    _sub = _eventBus.on<AgentRunCompleted>().listen(_onCompleted);
  }

  /// Stop listening.
  void dispose() {
    _sub?.cancel();
  }

  Future<void> _onCompleted(AgentRunCompleted event) async {
    final runId = event.runId;
    final workspaceId = event.workspaceId;
    if (runId == null || workspaceId == null) {
      return;
    }
    try {
      final run = await _runLogs.getById(runId);
      if (run == null) {
        return;
      }
      final pipelineRunId = run.pipelineRunId;
      final stepId = run.pipelineStepRunId;
      // Only pipeline-dispatched runs drive step resume.
      if (pipelineRunId == null || stepId == null) {
        return;
      }
      final runs = await _runLogs.forPipelineStep(
        workspaceId,
        pipelineRunId,
        stepId,
      );
      if (runs.isEmpty) {
        return;
      }
      // Advance only when every run the step dispatched is terminal.
      if (!runs.every((r) =>
          r.status == RunStatus.completed || r.status == RunStatus.error)) {
        return;
      }
      await _engine.resumeStep(
        pipelineRunId: pipelineRunId,
        stepId: stepId,
      );
    } on Object catch (e, st) {
      CcDomainLog.error('PipelineStepResumeListener: Failed to resume step', e, st);
    }
  }
}
