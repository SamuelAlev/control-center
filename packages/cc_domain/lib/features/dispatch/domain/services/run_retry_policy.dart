import 'package:cc_domain/features/dispatch/domain/services/run_failure_classifier.dart';

/// Decision returned by the retry policy.
class RetryDecision {
  const RetryDecision._({
    required this.shouldRetry,
    this.reason,
  });

  /// Retry the run with the same strategy.
  static const retry = RetryDecision._(shouldRetry: true);

  /// Do not retry, with a reason.
  static RetryDecision suppress(String reason) =>
      RetryDecision._(shouldRetry: false, reason: reason);

  /// Whether the run should be retried.
  final bool shouldRetry;

  /// Reason for suppression, when [shouldRetry] is false.
  final String? reason;
}

/// Decides whether a failed run should be automatically retried.
///
/// Retries are allowed only for transient failures (rate limits, upstream
/// timeouts) and only up to [maxAttempts] total attempts. Side-effecting
/// runs (those that may have mutated files) are never retried to avoid
/// duplicate mutations.
class RunRetryPolicy {
  /// Creates a [RunRetryPolicy] with the given max attempts and classifier.
  const RunRetryPolicy({
    this.maxAttempts = 2,
    required this.classifier,
  });

  /// Maximum number of attempts (including the original).
  final int maxAttempts;

  /// Failure classifier used to determine retryability.
  final RunFailureClassifier classifier;

  /// Decides whether to retry a failed run.
  ///
  /// [classification] is the pre-computed failure classification.
  /// [attempt] is the current attempt number (0-based).
  RetryDecision decide({
    required RunFailureClassification classification,
    required int attempt,
  }) {
    // Already at max attempts.
    if (attempt >= maxAttempts - 1) {
      return RetryDecision.suppress('attempt_limit_reached');
    }

    // Only retry if the classifier says it's retryable.
    if (!classification.retryable) {
      return RetryDecision.suppress('non_retryable');
    }

    return RetryDecision.retry;
  }
}
