import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';

/// Resumes a suspended pipeline step once every agent run it dispatched has
/// reached a terminal state. Replaces the ticket-based `TicketResumeListener`:
/// the work surface is now a hidden conversation and the output contract lives
/// on the `AgentRunLog`, so step completion keys off runs, not tickets.
///
/// Listens to [AgentRunSettled] (published after the run's terminal write),
/// resolves the finished run's pipeline
/// coupling, groups runs by `(pipelineRunId, pipelineStepId)` and — once
/// all of them are terminal — asks the engine to harvest their `outputJson`
/// and advance the step.
class PipelineStepResumeListener {
  /// Creates a [PipelineStepResumeListener].
  ///
  /// [_driftGate] (PRD 17 §6) runs after every run of a step is terminal and
  /// BEFORE the engine harvests/advances. Returning true HOLDS the step —
  /// used by plan-drift stop-and-ask: the node's divergence is surfaced and
  /// the operator explicitly resumes (`orchestration.continueNode`) or
  /// cancels. Null / false → today's behavior.
  PipelineStepResumeListener({
    required this._eventBus,
    required AgentRunLogRepository runLogRepository,
    required this._engine,
    this._driftGate,
  }) : _runLogs = runLogRepository;

  final DomainEventBus _eventBus;
  final AgentRunLogRepository _runLogs;
  final PipelineEngine _engine;
  final Future<bool> Function({
    required String workspaceId,
    required String pipelineRunId,
    required String stepId,
  })?
  _driftGate;

  StreamSubscription<AgentRunSettled>? _sub;

  /// Start listening for settled agent runs.
  void start() {
    _sub = _eventBus.on<AgentRunSettled>().listen(_onCompleted);
  }

  /// Stop listening.
  void dispose() {
    _sub?.cancel();
  }

  Future<void> _onCompleted(AgentRunSettled event) async {
    // The server went away under the run (a shutdown, or the reaper at the
    // next boot): not the step's outcome. The step stays `running`, and boot
    // recovery (`resumeAll`) fires it again as a new attempt.
    if (event.endReason == RunEndReason.serverStopped) {
      return;
    }
    final runId = event.runId;
    final workspaceId = event.workspaceId;
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
      // Advance only when every run the step dispatched is terminal. The
      // event is published after this run's terminal write, so its row is
      // terminal; it is still counted as such by id, which costs nothing.
      // Sibling runs are gated on their persisted status; each settlement
      // fires its own event, so the last one resumes the step.
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
