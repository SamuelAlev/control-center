import 'package:control_center/core/domain/events/domain_event_bus.dart';

/// Fired when a pipeline run starts.
class PipelineRunStarted implements DomainEvent {
  /// Creates a [PipelineRunStarted].
  const PipelineRunStarted({
    required this.pipelineRunId,
    required this.templateId,
    required this.occurredAt,
  });

  /// Pipeline run identifier.
  final String pipelineRunId;

  /// Template that was instantiated.
  final String templateId;

  @override
  final DateTime occurredAt;
}

/// Fired when a pipeline step starts executing.
class PipelineStepStarted implements DomainEvent {
  /// Creates a [PipelineStepStarted].
  const PipelineStepStarted({
    required this.pipelineRunId,
    required this.stepRunId,
    required this.stepId,
    required this.occurredAt,
  });

  /// Pipeline run identifier.
  final String pipelineRunId;

  /// Step run identifier.
  final String stepRunId;

  /// Step definition ID.
  final String stepId;

  @override
  final DateTime occurredAt;
}

/// Fired when a pipeline step completes successfully.
class PipelineStepCompleted implements DomainEvent {
  /// Creates a [PipelineStepCompleted].
  const PipelineStepCompleted({
    required this.pipelineRunId,
    required this.stepRunId,
    required this.stepId,
    required this.occurredAt,
  });

  /// Pipeline run identifier.
  final String pipelineRunId;

  /// Step run identifier.
  final String stepRunId;

  /// Step definition ID.
  final String stepId;

  @override
  final DateTime occurredAt;
}

/// Fired when a pipeline step fails.
class PipelineStepFailed implements DomainEvent {
  /// Creates a [PipelineStepFailed].
  const PipelineStepFailed({
    required this.pipelineRunId,
    required this.stepRunId,
    required this.stepId,
    required this.errorMessage,
    required this.occurredAt,
  });

  /// Pipeline run identifier.
  final String pipelineRunId;

  /// Step run identifier.
  final String stepRunId;

  /// Step definition ID.
  final String stepId;

  /// What went wrong.
  final String errorMessage;

  @override
  final DateTime occurredAt;
}

/// Fired when a pipeline run completes.
class PipelineRunCompleted implements DomainEvent {
  /// Creates a [PipelineRunCompleted].
  const PipelineRunCompleted({
    required this.pipelineRunId,
    required this.templateId,
    required this.occurredAt,
  });

  /// Pipeline run identifier.
  final String pipelineRunId;

  /// Template that was instantiated.
  final String templateId;

  @override
  final DateTime occurredAt;
}

/// Fired when a pipeline run fails.
class PipelineRunFailed implements DomainEvent {
  /// Creates a [PipelineRunFailed].
  const PipelineRunFailed({
    required this.pipelineRunId,
    required this.templateId,
    required this.errorMessage,
    required this.occurredAt,
  });

  /// Pipeline run identifier.
  final String pipelineRunId;

  /// Template that was instantiated.
  final String templateId;

  /// What went wrong.
  final String errorMessage;

  @override
  final DateTime occurredAt;
}
