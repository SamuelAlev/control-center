import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';

/// A single execution of a pipeline template.
///
/// Persisted across app restarts so the engine can resume in-flight runs.
class PipelineRun {
  /// Creates a [PipelineRun].
  PipelineRun({
    required this.id,
    required this.templateId,
    required this.workspaceId,
    required this.status,
    Map<String, dynamic>? state,
    this.triggerEventType,
    this.triggerPayload,
    this.dedupKey,
    required this.startedAt,
    this.finishedAt,
    this.errorMessage,
    this.errorStackTrace,
    this.parentPipelineRunId,
    this.parentStepId,
    this.templateVersion = 1,
    this.totalCostCents = 0,
    this.totalTokens = 0,
    this.dryRun = false,
  }) : _state = state ?? {};

  /// Unique run identifier (UUID v4).
  final String id;

  /// Which template this run is an instance of.
  final String templateId;

  /// Workspace this run belongs to.
  final String workspaceId;

  /// Current lifecycle status.
  final PipelineRunStatus status;

  /// Mutable state bag shared across steps.
  Map<String, dynamic> get state => Map.unmodifiable(_state);
  final Map<String, dynamic> _state;

  /// Fully-qualified type name of the domain event that triggered this run.
  final String? triggerEventType;

  /// Payload from the trigger event.
  final Map<String, dynamic>? triggerPayload;

  /// Idempotency key for event-triggered runs.
  final String? dedupKey;

  /// When this run was created.
  final DateTime startedAt;

  /// When this run reached a terminal state.
  final DateTime? finishedAt;

  /// Error message if [status] is [PipelineRunStatus.failed].
  final String? errorMessage;

  /// Stack trace captured at failure time.
  final String? errorStackTrace;

  /// Parent run id when started by a `flow.callPipeline` node (else null).
  final String? parentPipelineRunId;

  /// Parent run's calling step id (paired with [parentPipelineRunId]).
  final String? parentStepId;

  /// Template version this run was pinned to at start.
  final int templateVersion;

  /// Aggregated agent cost for this run, in cents.
  final int totalCostCents;

  /// Aggregated token usage for this run.
  final int totalTokens;

  /// Whether this run is a dry run (side effects skipped).
  final bool dryRun;

  /// Whether this run is in a terminal state.
  bool get isTerminal => status.isTerminal;

  /// Creates a copy with updated fields.
  PipelineRun copyWith({
    PipelineRunStatus? status,
    Map<String, dynamic>? state,
    DateTime? finishedAt,
    String? errorMessage,
    String? errorStackTrace,
    int? totalCostCents,
    int? totalTokens,
  }) {
    return PipelineRun(
      id: id,
      templateId: templateId,
      workspaceId: workspaceId,
      status: status ?? this.status,
      state: state ?? Map<String, dynamic>.from(_state),
      triggerEventType: triggerEventType,
      triggerPayload: triggerPayload,
      dedupKey: dedupKey,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      errorStackTrace: errorStackTrace ?? this.errorStackTrace,
      parentPipelineRunId: parentPipelineRunId,
      parentStepId: parentStepId,
      templateVersion: templateVersion,
      totalCostCents: totalCostCents ?? this.totalCostCents,
      totalTokens: totalTokens ?? this.totalTokens,
      dryRun: dryRun,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineRun &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          templateId == other.templateId &&
          workspaceId == other.workspaceId &&
          status == other.status &&
          finishedAt == other.finishedAt &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        id,
        templateId,
        workspaceId,
        status,
        finishedAt,
        errorMessage,
      );
}
