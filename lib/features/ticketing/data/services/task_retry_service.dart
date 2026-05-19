import 'package:control_center/core/utils/app_log.dart';

enum RetryableFailureReason {
  runtimeOffline,
  timeout,
  sandboxViolation,
}

class TaskRetryService {
  Future<bool> maybeRetry({
    required String ticketId,
    required String failureReason,
    required int attempt,
    required int maxAttempts,
    bool isPipelineTask = false,
  }) async {
    if (isPipelineTask) return false;
    if (attempt >= maxAttempts) return false;
    final reason = RetryableFailureReason.values.where(
      (r) => r.name == failureReason,
    );
    if (reason.isEmpty) return false;
    AppLog.d('TaskRetryService', 'Retrying ticket $ticketId (attempt ${attempt + 1}/$maxAttempts)');
    return true;
  }
}
