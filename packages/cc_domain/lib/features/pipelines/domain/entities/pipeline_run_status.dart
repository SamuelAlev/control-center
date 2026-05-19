/// Lifecycle status for a PipelineRun.
enum PipelineRunStatus {
  /// Created but not yet started.
  pending,

  /// Admitted but held back: the template's `maxParallelRuns` cap was full at
  /// start, so this run waits for a slot instead of being dropped. The engine
  /// promotes the oldest queued run when a sibling run of the same template
  /// reaches a terminal state.
  ///
  /// Distinct from [pending], which is the momentary state of a run that IS
  /// starting (the entry step flips it to [running]); a queued run has no step
  /// rows at all and nothing is executing on its behalf.
  queued,

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
      'queued' => PipelineRunStatus.queued,
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
