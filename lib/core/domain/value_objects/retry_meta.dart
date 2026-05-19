/// Metadata tracking retry attempts for an agent run.
class RetryMeta {
  /// Creates a [RetryMeta] with an optional parent run and attempt counter.
  const RetryMeta({
    this.parentRunId,
    this.attempt = 0,
  });

  /// Run ID of the parent attempt, if this is a retry.
  final String? parentRunId;

  /// Zero-based attempt number for this run.
  final int attempt;
  /// Returns a new [RetryMeta] incremented to the next attempt.
  RetryMeta nextAttempt() => RetryMeta(
        parentRunId: parentRunId,
        attempt: attempt + 1,
      );


  @override
  /// Equality based on [parentRunId] and [attempt].
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetryMeta &&
          parentRunId == other.parentRunId &&
          attempt == other.attempt;

  @override
  /// Hash based on [parentRunId] and [attempt].
  int get hashCode => Object.hash(parentRunId, attempt);
}
