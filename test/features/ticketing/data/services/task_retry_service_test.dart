import 'package:control_center/features/ticketing/data/services/task_retry_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TaskRetryService service;

  setUp(() {
    service = TaskRetryService();
  });

  group('TaskRetryService.maybeRetry', () {
    // ── Happy path: retryable reasons ──

    for (final reason in RetryableFailureReason.values) {
      group('RetryableFailureReason.${reason.name}', () {
        test('returns true when attempt=0 < maxAttempts=3',
            () async {
          final result = await service.maybeRetry(
            ticketId: 'ticket-1',
            failureReason: reason.name,
            attempt: 0,
            maxAttempts: 3,
          );
          expect(result, isTrue);
        }, timeout: const Timeout.factor(2));

        test('returns true when attempt=2 < maxAttempts=3',
            () async {
          final result = await service.maybeRetry(
            ticketId: 'ticket-2',
            failureReason: reason.name,
            attempt: 2,
            maxAttempts: 3,
          );
          expect(result, isTrue);
        }, timeout: const Timeout.factor(2));

        test('returns true with maxAttempts=1 and attempt=0',
            () async {
          final result = await service.maybeRetry(
            ticketId: 'ticket-3',
            failureReason: reason.name,
            attempt: 0,
            maxAttempts: 1,
          );
          expect(result, isTrue);
        }, timeout: const Timeout.factor(2));
      });
    }

    // ── Pipeline tasks are never retried ──

    group('pipeline tasks', () {
      test('returns false when isPipelineTask is true (valid reason)',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'pipeline-1',
          failureReason: RetryableFailureReason.timeout.name,
          attempt: 0,
          maxAttempts: 5,
          isPipelineTask: true,
        );
        expect(result, isFalse);
      }, timeout: const Timeout.factor(2));

      test('returns false when isPipelineTask is true (unrecognized reason)',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'pipeline-2',
          failureReason: 'unknown-error',
          attempt: 0,
          maxAttempts: 5,
          isPipelineTask: true,
        );
        expect(result, isFalse);
      }, timeout: const Timeout.factor(2));

      test('returns false when isPipelineTask is true and attempt is already at max',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'pipeline-3',
          failureReason: RetryableFailureReason.runtimeOffline.name,
          attempt: 5,
          maxAttempts: 5,
          isPipelineTask: true,
        );
        expect(result, isFalse);
      }, timeout: const Timeout.factor(2));
    });

    // ── Attempt >= maxAttempts ──

    group('attempt at or beyond maxAttempts', () {
      test('returns false when attempt == maxAttempts',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'ticket-eq',
          failureReason: RetryableFailureReason.timeout.name,
          attempt: 3,
          maxAttempts: 3,
        );
        expect(result, isFalse);
      }, timeout: const Timeout.factor(2));

      test('returns false when attempt > maxAttempts',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'ticket-gt',
          failureReason: RetryableFailureReason.runtimeOffline.name,
          attempt: 5,
          maxAttempts: 3,
        );
        expect(result, isFalse);
      }, timeout: const Timeout.factor(2));

      test('returns false when maxAttempts=0 and attempt=0',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'ticket-zero',
          failureReason: RetryableFailureReason.sandboxViolation.name,
          attempt: 0,
          maxAttempts: 0,
        );
        expect(result, isFalse);
      }, timeout: const Timeout.factor(2));

      test('returns false when maxAttempts=0 and attempt=1',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'ticket-zero-gt',
          failureReason: RetryableFailureReason.timeout.name,
          attempt: 1,
          maxAttempts: 0,
        );
        expect(result, isFalse);
      }, timeout: const Timeout.factor(2));
    });

    // ── Unrecognized failure reasons ──

    group('unrecognized failure reasons', () {
      test('returns false for an empty string',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'ticket-empty',
          failureReason: '',
          attempt: 0,
          maxAttempts: 3,
        );
        expect(result, isFalse);
      }, timeout: const Timeout.factor(2));

      test('returns false for an arbitrary unrecognized string',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'ticket-unknown',
          failureReason: 'out-of-memory',
          attempt: 0,
          maxAttempts: 3,
        );
        expect(result, isFalse);
      }, timeout: const Timeout.factor(2));

      test('returns false for a near-miss reason with different casing',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'ticket-case',
          failureReason: 'Timeout',
          attempt: 0,
          maxAttempts: 3,
        );
        expect(result, isFalse);
      }, timeout: const Timeout.factor(2));

      test('returns false for a null-like string',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'ticket-null',
          failureReason: 'null',
          attempt: 0,
          maxAttempts: 3,
        );
        expect(result, isFalse);
      }, timeout: const Timeout.factor(2));
    });

    // ── Edge cases ──

    group('edge cases', () {
      test('attempt=0 with generous maxAttempts returns true',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'edge-0',
          failureReason: RetryableFailureReason.runtimeOffline.name,
          attempt: 0,
          maxAttempts: 100,
        );
        expect(result, isTrue);
      }, timeout: const Timeout.factor(2));

      test('maxAttempts=1 with attempt=1 returns false (non-retryable boundary)',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'edge-1',
          failureReason: RetryableFailureReason.sandboxViolation.name,
          attempt: 1,
          maxAttempts: 1,
        );
        expect(result, isFalse);
      }, timeout: const Timeout.factor(2));

      test('maxAttempts=1 with attempt=0 is retryable (last chance)',
          () async {
        final result = await service.maybeRetry(
          ticketId: 'edge-last',
          failureReason: RetryableFailureReason.timeout.name,
          attempt: 0,
          maxAttempts: 1,
        );
        expect(result, isTrue);
      }, timeout: const Timeout.factor(2));
    });

    // ── Verification that all three reasons are covered ──

    test('RetryableFailureReason.values contains exactly three reasons',
        () {
      final names = RetryableFailureReason.values.map((r) => r.name).toSet();
      expect(names, containsAll(['runtimeOffline', 'timeout', 'sandboxViolation']));
      expect(names.length, 3);
    }, timeout: const Timeout.factor(2));
  });
}
