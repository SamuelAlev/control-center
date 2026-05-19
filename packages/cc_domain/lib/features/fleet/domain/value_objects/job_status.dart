/// Lifecycle status of a fleet job (PRD 20 §2, §8).
enum JobStatus {
  /// Submitted, awaiting placement.
  queued('queued'),

  /// Leased to a worker, not yet reported running.
  leased('leased'),

  /// The worker reported it started executing.
  running('running'),

  /// Completed successfully.
  done('done'),

  /// Terminally failed (retries exhausted or non-retryable).
  failed('failed'),

  /// The lease expired without completion and the job was reclaimed.
  reaped('reaped'),

  /// Cancelled (lease revoked; will not run).
  cancelled('cancelled');

  const JobStatus(this.wire);

  /// Stable wire/storage string.
  final String wire;

  /// Parses a [JobStatus] from its [wire] string.
  static JobStatus fromWire(String value) => JobStatus.values.firstWhere(
    (s) => s.wire == value,
    orElse: () => JobStatus.queued,
  );

  /// Whether this is a terminal (non-executing) state.
  bool get isTerminal =>
      this == JobStatus.done ||
      this == JobStatus.failed ||
      this == JobStatus.cancelled;

  /// Whether the job currently holds (or should hold) a lease.
  bool get isActive => this == JobStatus.leased || this == JobStatus.running;
}
