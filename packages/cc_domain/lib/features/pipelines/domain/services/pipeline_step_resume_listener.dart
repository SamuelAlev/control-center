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
/// coupling, groups runs by `(pipelineRunId, pipelineStepId)` and — once
/// all of them are terminal — asks the engine to harvest their `outputJson`
/// and advance the step.
class PipelineStepResumeListener {
  /// Creates a [PipelineStepResumeListener].
  ///
  /// [driftGate] (PRD 17 §6) runs after every run of a step is terminal and
  /// BEFORE the engine harvests/advances. Returning true HOLDS the step —
  /// used by plan-drift stop-and-ask: the node's divergence is surfaced and
  /// the operator explicitly resumes (`orchestration.continueNode`) or
  /// cancels. Null / false → today's behavior.
  PipelineStepResumeListener({
    required DomainEventBus eventBus,
    required AgentRunLogRepository runLogRepository,
    required PipelineEngine engine,
    Future<bool> Function({
      required String workspaceId,
      required String pipelineRunId,
      required String stepId,
    })?
    driftGate,
  }) : _eventBus = eventBus,
       _runLogs = runLogRepository,
       _engine = engine,
       _driftGate = driftGate;

  final DomainEventBus _eventBus;
  final AgentRunLogRepository _runLogs;
  final PipelineEngine _engine;
  final Future<bool> Function({
    required String workspaceId,
    required String pipelineRunId,
    required String stepId,
  })?
  _driftGate;

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
      final run = await _runLogs.getById(workspaceId, runId);
      if (run == null) {
        return;
      }
      final pipelineRunId = run.pipelineRunId;
      final stepId = run.pipelineStepId;
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
      // Advance only when every run the step dispatched is terminal. The run
      // named by THIS event is terminal by definition, but the DB write that
      // flips its status to `completed` (agent_stream_processor._onDone →
      // AgentDispatchService.completeRun) races the event publish and usually
      // lands *after* it — both the CLI-session and process data-source paths
      // publish AgentRunCompleted, then close the stream and only the ensuing
      // `onDone` persists the status. Without treating the event's own run as
      // terminal here, a lone-agent step reads its still-`running` row, bails,
      // and is stranded forever (nothing re-fires). Sibling runs stay gated on
      // their persisted status; each completion fires its own event, so the
      // last one resumes once the earlier writes have landed.
      final allTerminal = runs.every(
        (r) =>
            r.id == runId ||
            r.status == RunStatus.completed ||
            r.status == RunStatus.error,
      );
      if (!allTerminal) {
        return;
      }
      final gate = _driftGate;
      if (gate != null &&
          await gate(
            workspaceId: workspaceId,
            pipelineRunId: pipelineRunId,
            stepId: stepId,
          )) {
        // Held by plan-drift stop-and-ask: the divergence is on the canvas
        // and in the space; the operator resumes or cancels explicitly.
        return;
      }
      await _engine.resumeStep(pipelineRunId: pipelineRunId, stepId: stepId);
    } on Object catch (e, st) {
      CcDomainLog.error(
        'PipelineStepResumeListener: Failed to resume step',
        e,
        st,
      );
    }
  }
}
