import 'package:control_center/core/utils/app_log.dart';

/// Failure reasons that are eligible for retry handling.
enum RetryableFailureReason {
  /// The task runtime was unavailable when execution was attempted.
  runtimeOffline,

  /// The task exceeded its allowed execution time.
  timeout,

  /// The task failed because of a sandbox policy violation.
  sandboxViolation,
}

/// Determines whether a failed task should be retried.
class TaskRetryService {
  /// Returns whether the failed ticket should be retried for the given context.
  Future<bool> maybeRetry({
    required String ticketId,
    required String failureReason,
    required int attempt,
    required int maxAttempts,
    bool isPipelineTask = false,
  }) async {
    if (isPipelineTask) {
      return false;
    }
    if (attempt >= maxAttempts) {
      return false;
    }
    final reason = RetryableFailureReason.values.where(
      (r) => r.name == failureReason,
    );
    if (reason.isEmpty) {
      return false;
    }
    AppLog.d('TaskRetryService', 'Retrying ticket $ticketId (attempt ${attempt + 1}/$maxAttempts)');
    return true;
  }
}
