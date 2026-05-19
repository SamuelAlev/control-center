
/// Lifecycle status for a PipelineRun.
enum PipelineRunStatus {
  /// Created but not yet started.
  pending,

  /// Currently executing one or more steps.
  running,

  /// Paused waiting for external events or tasks to complete.
  suspended,

  /// All steps completed successfully.
  completed,

  /// One or more steps failed.
  failed,

  /// Cancelled by user or system.
  cancelled;

  /// Whether this status represents a terminal state.
  bool get isTerminal =>
      this == PipelineRunStatus.completed ||
      this == PipelineRunStatus.failed ||
      this == PipelineRunStatus.cancelled;

  /// Parses a stored status string, defaulting to [pending].
  static PipelineRunStatus fromString(String value) {
    return switch (value) {
      'pending' => PipelineRunStatus.pending,
      'running' => PipelineRunStatus.running,
      'suspended' => PipelineRunStatus.suspended,
      'completed' => PipelineRunStatus.completed,
      'failed' => PipelineRunStatus.failed,
      'cancelled' => PipelineRunStatus.cancelled,
      _ => PipelineRunStatus.pending,
    };
  }

  /// Serializes to a storage string.
  String toStorageString() => name;
}
