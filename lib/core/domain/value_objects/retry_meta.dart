class RetryMeta {
  const RetryMeta({
    this.parentRunId,
    this.attempt = 0,
  });

  final String? parentRunId;

  final int attempt;

  RetryMeta nextAttempt() => RetryMeta(
        parentRunId: parentRunId,
        attempt: attempt + 1,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetryMeta &&
          parentRunId == other.parentRunId &&
          attempt == other.attempt;

  @override
  int get hashCode => Object.hash(parentRunId, attempt);
}
