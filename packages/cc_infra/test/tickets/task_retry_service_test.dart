import 'package:cc_infra/src/tickets/task_retry_service.dart';
import 'package:test/test.dart';

/// `TaskRetryService.maybeRetry` is pure async logic — pipeline tasks are
/// never retried, attempts past the cap never retry and only a known
/// [RetryableFailureReason] name qualifies. These pin the contract.
void main() {
  group('TaskRetryService.maybeRetry', () {
    final service = TaskRetryService();

    test('returns false for pipeline tasks', () async {
      final result = await service.maybeRetry(
        ticketId: 't1',
        failureReason: 'timeout',
        attempt: 0,
        maxAttempts: 3,
        isPipelineTask: true,
      );

      expect(result, isFalse);
    });

    test('returns false when attempt equals the cap', () async {
      final result = await service.maybeRetry(
        ticketId: 't1',
        failureReason: 'timeout',
        attempt: 3,
        maxAttempts: 3,
      );

      expect(result, isFalse);
    });

    test('returns false when attempt exceeds the cap', () async {
      final result = await service.maybeRetry(
        ticketId: 't1',
        failureReason: 'timeout',
        attempt: 4,
        maxAttempts: 3,
      );

      expect(result, isFalse);
    });

    test('returns false for an unknown failure reason', () async {
      final result = await service.maybeRetry(
        ticketId: 't1',
        failureReason: 'not-a-reason',
        attempt: 0,
        maxAttempts: 3,
      );

      expect(result, isFalse);
    });

    test('retries a runtimeOffline failure below the cap', () async {
      final result = await service.maybeRetry(
        ticketId: 't1',
        failureReason: 'runtimeOffline',
        attempt: 0,
        maxAttempts: 3,
      );

      expect(result, isTrue);
    });

    test('retries a timeout failure below the cap', () async {
      final result = await service.maybeRetry(
        ticketId: 't1',
        failureReason: 'timeout',
        attempt: 1,
        maxAttempts: 3,
      );

      expect(result, isTrue);
    });

    test('retries a sandboxViolation failure below the cap', () async {
      final result = await service.maybeRetry(
        ticketId: 't1',
        failureReason: 'sandboxViolation',
        attempt: 2,
        maxAttempts: 3,
      );

      expect(result, isTrue);
    });
  });
}
