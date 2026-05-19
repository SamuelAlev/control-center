import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart' show PipelineStepRun;

/// Lifecycle status for a [PipelineStepRun].
enum PipelineStepStatus {
  /// Waiting for predecessor steps to complete.
  pending,

  /// Currently executing.
  running,

  /// Paused, waiting for external event or tasks to complete.
  suspended,

  /// Finished successfully.
  completed,

  /// Finished with error.
  failed,

  /// Skipped (e.g. by a router that took a different branch).
  skipped,

  /// Cancelled by user or because the parent run was cancelled.
  cancelled;

  /// Whether this status represents a terminal state.
  bool get isTerminal =>
      this == PipelineStepStatus.completed ||
      this == PipelineStepStatus.failed ||
      this == PipelineStepStatus.skipped ||
      this == PipelineStepStatus.cancelled;

  /// Parses a stored status string, defaulting to [pending].
  static PipelineStepStatus fromString(String value) {
    return switch (value) {
      'pending' => PipelineStepStatus.pending,
      'running' => PipelineStepStatus.running,
      'suspended' => PipelineStepStatus.suspended,
      'completed' => PipelineStepStatus.completed,
      'failed' => PipelineStepStatus.failed,
      'skipped' => PipelineStepStatus.skipped,
      'cancelled' => PipelineStepStatus.cancelled,
      _ => PipelineStepStatus.pending,
    };
  }

  /// Serializes to a storage string.
  String toStorageString() => name;
}
