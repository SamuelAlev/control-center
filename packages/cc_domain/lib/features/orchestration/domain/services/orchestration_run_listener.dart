import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/orchestration_events.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';

/// Maps a generated orchestration pipeline's terminal run state onto the
/// orchestration aggregate + its parent ticket. The success path is owned by
/// the `orchestration.persistDeliverable` body; this listener owns the
/// failed / cancelled paths. Mirrors `MeetingSummaryReconciler`.
class OrchestrationRunListener {
  /// Creates an [OrchestrationRunListener].
  OrchestrationRunListener({
    required DomainEventBus eventBus,
    required OrchestrationRepository orchestrations,
    required TicketWorkflowService ticketWorkflow,
  })  : _eventBus = eventBus,
        _orchestrations = orchestrations,
        _ticketWorkflow = ticketWorkflow;

  final DomainEventBus _eventBus;
  final OrchestrationRepository _orchestrations;
  final TicketWorkflowService _ticketWorkflow;

  final List<StreamSubscription<dynamic>> _subs = [];

  /// Starts listening.
  void start() {
    _subs
      ..add(_eventBus.on<PipelineRunFailed>().listen(
            (e) => _onTerminal(e.pipelineRunId, failed: true, error: e.errorMessage),
          ))
      ..add(_eventBus.on<PipelineRunCancelled>().listen(
            (e) => _onTerminal(e.pipelineRunId, cancelled: true),
          ));
  }

  /// Stops listening.
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  Future<void> _onTerminal(
    String pipelineRunId, {
    bool failed = false,
    bool cancelled = false,
    String? error,
  }) async {
    try {
      final o = await _orchestrations.forPipelineRunAnyWorkspace(pipelineRunId);
      if (o == null || o.status.isTerminal) {
        return;
      }
      final now = DateTime.now();
      final status = cancelled
          ? OrchestrationStatus.cancelled
          : OrchestrationStatus.failed;
      final message = error ??
          (cancelled ? 'Orchestration run cancelled.' : 'Orchestration run failed.');
      await _orchestrations.update(o.copyWith(
        status: status,
        errorMessage: failed ? message : null,
        completedAt: now,
        updatedAt: now,
      ));
      await _failParentTicket(o, cancelled: cancelled, message: message);
      _eventBus.publish(cancelled
          ? OrchestrationCancelled(
              orchestrationId: o.id,
              workspaceId: o.workspaceId,
              occurredAt: now,
            )
          : OrchestrationFailed(
              orchestrationId: o.id,
              workspaceId: o.workspaceId,
              errorMessage: message,
              occurredAt: now,
            ));
    } on Object catch (e, st) {
      CcDomainLog.error('OrchestrationRunListener: terminal handling failed', e, st);
    }
  }

  Future<void> _failParentTicket(
    Orchestration o, {
    required bool cancelled,
    required String message,
  }) async {
    final parentTicketId = o.parentTicketId;
    if (parentTicketId == null || parentTicketId.isEmpty) {
      return;
    }
    if (cancelled) {
      await _ticketWorkflow.cancelTicket(
        parentTicketId,
        workspaceId: o.workspaceId,
        force: true,
      );
    } else {
      await _ticketWorkflow.failTicket(
        parentTicketId,
        message,
        workspaceId: o.workspaceId,
        force: true,
      );
    }
  }
}
