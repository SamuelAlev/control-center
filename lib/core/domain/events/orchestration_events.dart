import 'package:control_center/core/domain/events/domain_event_bus.dart';

/// Base for orchestration lifecycle events. All carry the orchestration id and
/// workspace so listeners can re-scope safely.
abstract class OrchestrationEvent implements DomainEvent {
  /// Creates an [OrchestrationEvent].
  const OrchestrationEvent({
    required this.orchestrationId,
    required this.workspaceId,
    required this.occurredAt,
  });

  /// The orchestration this event concerns.
  final String orchestrationId;

  /// Workspace scope.
  final String workspaceId;

  @override
  final DateTime occurredAt;
}

/// Fired when an orchestrator proposes a plan (revision 1).
class OrchestrationProposed extends OrchestrationEvent {
  /// Creates an [OrchestrationProposed] event.
  const OrchestrationProposed({
    required super.orchestrationId,
    required super.workspaceId,
    required super.occurredAt,
  });
}

/// Fired when an orchestrator revises an existing proposal.
class OrchestrationRevised extends OrchestrationEvent {
  /// Creates an [OrchestrationRevised] event.
  const OrchestrationRevised({
    required super.orchestrationId,
    required super.workspaceId,
    required this.revision,
    required super.occurredAt,
  });

  /// The new revision number.
  final int revision;
}

/// Fired when the user approves a proposal.
class OrchestrationApproved extends OrchestrationEvent {
  /// Creates an [OrchestrationApproved] event.
  const OrchestrationApproved({
    required super.orchestrationId,
    required super.workspaceId,
    required super.occurredAt,
  });
}

/// Fired when deterministic execution (the generated pipeline) starts.
class OrchestrationExecutionStarted extends OrchestrationEvent {
  /// Creates an [OrchestrationExecutionStarted] event.
  const OrchestrationExecutionStarted({
    required super.orchestrationId,
    required super.workspaceId,
    required this.pipelineRunId,
    required super.occurredAt,
  });

  /// The pipeline run that drives execution.
  final String pipelineRunId;
}

/// Fired when the orchestration completes and the deliverable lands.
class OrchestrationCompleted extends OrchestrationEvent {
  /// Creates an [OrchestrationCompleted] event.
  const OrchestrationCompleted({
    required super.orchestrationId,
    required super.workspaceId,
    required super.occurredAt,
  });
}

/// Fired when the orchestration fails.
class OrchestrationFailed extends OrchestrationEvent {
  /// Creates an [OrchestrationFailed] event.
  const OrchestrationFailed({
    required super.orchestrationId,
    required super.workspaceId,
    required this.errorMessage,
    required super.occurredAt,
  });

  /// Why the orchestration failed.
  final String errorMessage;
}

/// Fired when the user cancels the orchestration.
class OrchestrationCancelled extends OrchestrationEvent {
  /// Creates an [OrchestrationCancelled] event.
  const OrchestrationCancelled({
    required super.orchestrationId,
    required super.workspaceId,
    required super.occurredAt,
  });
}
