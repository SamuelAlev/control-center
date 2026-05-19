import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/orchestration_events.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';

/// Cancels an orchestration: stops its run (if executing), cancels the parent
/// ticket, and marks the orchestration cancelled. Idempotent on terminal rows.
class CancelOrchestrationUseCase {
  /// Creates a [CancelOrchestrationUseCase].
  CancelOrchestrationUseCase({
    required OrchestrationRepository orchestrations,
    required PipelineEngine engine,
    required TicketWorkflowService ticketWorkflow,
    required DomainEventBus eventBus,
  })  : _orchestrations = orchestrations,
        _engine = engine,
        _ticketWorkflow = ticketWorkflow,
        _eventBus = eventBus;

  final OrchestrationRepository _orchestrations;
  final PipelineEngine _engine;
  final TicketWorkflowService _ticketWorkflow;
  final DomainEventBus _eventBus;

  /// Cancels [orchestrationId] in [workspaceId].
  Future<void> cancel({
    required String workspaceId,
    required String orchestrationId,
  }) async {
    final o = await _orchestrations.getById(workspaceId, orchestrationId);
    if (o == null || o.status.isTerminal) {
      return;
    }
    final runId = o.pipelineRunId;
    if (runId != null && runId.isNotEmpty) {
      await _engine.cancel(runId);
    }
    final now = DateTime.now();
    await _orchestrations.update(o.copyWith(
      status: OrchestrationStatus.cancelled,
      completedAt: now,
      updatedAt: now,
    ));
    final parentTicketId = o.parentTicketId;
    if (parentTicketId != null && parentTicketId.isNotEmpty) {
      await _ticketWorkflow.transitionStatus(
        parentTicketId,
        TicketStatus.cancelled,
        workspaceId: workspaceId,
        force: true,
      );
    }
    _eventBus.publish(OrchestrationCancelled(
      orchestrationId: o.id,
      workspaceId: workspaceId,
      occurredAt: now,
    ));
  }
}
