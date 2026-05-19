import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// Fired when a pipeline run completes.
class PipelineRunCompleted implements DomainEvent {
  /// Creates a [PipelineRunCompleted].
  const PipelineRunCompleted({
    required this.workspaceId,
    required this.pipelineRunId,
    required this.templateId,
    required this.occurredAt,
  });

  /// The workspace the run belongs to. Required, never optional: pipeline
  /// runs and step runs live in a per-workspace database file, so a listener
  /// that cannot scope the event cannot route or filter it.
  final String workspaceId;

  /// Pipeline run identifier.
  final String pipelineRunId;

  /// Template that was instantiated.
  final String templateId;

  @override
  final DateTime occurredAt;
}

/// Fired when a pipeline run is cancelled (by the user or the system).
///
/// Distinct from [PipelineRunFailed]: cancellation is a deliberate stop, not an
/// error. Emitted so listeners that finalize work tied to a run (e.g. the
/// meeting-summary reconciler) can release it in-session instead of leaving it
/// stranded until the next startup sweep.
class PipelineRunCancelled implements DomainEvent {
  /// Creates a [PipelineRunCancelled].
  const PipelineRunCancelled({
    required this.workspaceId,
    required this.pipelineRunId,
    required this.templateId,
    required this.occurredAt,
  });

  /// The workspace the run belongs to. Required, never optional: pipeline
  /// runs and step runs live in a per-workspace database file, so a listener
  /// that cannot scope the event cannot route or filter it.
  final String workspaceId;

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
    required this.workspaceId,
    required this.pipelineRunId,
    required this.templateId,
    required this.errorMessage,
    required this.occurredAt,
  });

  /// The workspace the run belongs to. Required, never optional: pipeline
  /// runs and step runs live in a per-workspace database file, so a listener
  /// that cannot scope the event cannot route or filter it.
  final String workspaceId;

  /// Pipeline run identifier.
  final String pipelineRunId;

  /// Template that was instantiated.
  final String templateId;

  /// What went wrong.
  final String errorMessage;

  @override
  final DateTime occurredAt;
}
