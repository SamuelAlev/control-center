import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/dispatch/domain/services/run_failure_classifier.dart';
import 'package:cc_domain/features/dispatch/domain/services/run_retry_policy.dart';
import 'package:test/test.dart';

void main() {
  group('RetryDecision', () {
    test('retry singleton has shouldRetry=true', timeout: const Timeout.factor(2), () {
      expect(RetryDecision.retry.shouldRetry, isTrue);
      expect(RetryDecision.retry.reason, isNull);
    });

    test('suppress includes reason', timeout: const Timeout.factor(2), () {
      final d = RetryDecision.suppress('non_retryable');
      expect(d.shouldRetry, isFalse);
      expect(d.reason, 'non_retryable');
    });
  });

  group('RunRetryPolicy', () {
    late RunRetryPolicy policy;
    late RunFailureClassifier classifier;

    setUp(() {
      classifier = RunFailureClassifier();
      policy = RunRetryPolicy(maxAttempts: 3, classifier: classifier);
    });

    test('retries when classification is retryable and under max attempts', timeout: const Timeout.factor(2), () {
      const classification = RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.execution,
        detail: 'Rate limited',
        retryable: true,
      );
      final decision = policy.decide(classification: classification, attempt: 0);
      expect(decision.shouldRetry, isTrue);
    });

    test('retries on second attempt when maxAttempts=3', timeout: const Timeout.factor(2), () {
      const classification = RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.execution,
        detail: 'Timeout',
        retryable: true,
      );
      final decision = policy.decide(classification: classification, attempt: 1);
      expect(decision.shouldRetry, isTrue);
    });

    test('suppresses when attempt limit reached', timeout: const Timeout.factor(2), () {
      const classification = RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.execution,
        detail: 'Timeout',
        retryable: true,
      );
      // attempt 2 == maxAttempts-1 (maxAttempts=3), so no more retries
      final decision = policy.decide(classification: classification, attempt: 2);
      expect(decision.shouldRetry, isFalse);
      expect(decision.reason, 'attempt_limit_reached');
    });

    test('suppresses non-retryable classification', timeout: const Timeout.factor(2), () {
      const classification = RunFailureClassification(
        family: RunErrorFamily.sandboxInfrastructure,
        stage: FailureStage.launch,
        detail: 'Auth failed',
        retryable: false,
      );
      final decision = policy.decide(classification: classification, attempt: 0);
      expect(decision.shouldRetry, isFalse);
      expect(decision.reason, 'non_retryable');
    });

    test('non-retryable checked before attempt limit', timeout: const Timeout.factor(2), () {
      const classification = RunFailureClassification(
        family: RunErrorFamily.budgetExceeded,
        stage: FailureStage.execution,
        detail: 'Budget',
        retryable: false,
      );
      // Even on first attempt, non-retryable is suppressed
      final decision = policy.decide(classification: classification, attempt: 0);
      expect(decision.shouldRetry, isFalse);
      expect(decision.reason, 'non_retryable');
    });

    test('default maxAttempts is 2', timeout: const Timeout.factor(2), () {
      final p = RunRetryPolicy(classifier: classifier);
      expect(p.maxAttempts, 2);
    });

    test('with maxAttempts=1, never retries', timeout: const Timeout.factor(2), () {
      final p = RunRetryPolicy(maxAttempts: 1, classifier: classifier);
      const classification = RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.execution,
        detail: 'Rate limited',
        retryable: true,
      );
      final decision = p.decide(classification: classification, attempt: 0);
      expect(decision.shouldRetry, isFalse);
      expect(decision.reason, 'attempt_limit_reached');
    });

    test('attempt limit check uses >= (not >)', timeout: const Timeout.factor(2), () {
      // maxAttempts=2 → attempt 1 is the last allowed attempt index
      final p = RunRetryPolicy(maxAttempts: 2, classifier: classifier);
      const classification = RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.execution,
        detail: 'Timeout',
        retryable: true,
      );
      // attempt 0 → should retry
      expect(p.decide(classification: classification, attempt: 0).shouldRetry, isTrue);
      // attempt 1 == maxAttempts-1 → no more
      expect(p.decide(classification: classification, attempt: 1).shouldRetry, isFalse);
    });

    test('with maxAttempts=0, never retries', timeout: const Timeout.factor(2), () {
      final p = RunRetryPolicy(maxAttempts: 0, classifier: classifier);
      const classification = RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.execution,
        detail: 'Rate limited',
        retryable: true,
      );
      // attempt 0 >= maxAttempts-1 (-1) → suppress
      final decision = p.decide(classification: classification, attempt: 0);
      expect(decision.shouldRetry, isFalse);
      expect(decision.reason, 'attempt_limit_reached');
    });

    test('classification without userAction', timeout: const Timeout.factor(2), () {
      const classification = RunFailureClassification(
        family: RunErrorFamily.transientUpstream,
        stage: FailureStage.execution,
        detail: 'Timeout',
        retryable: true,
      );
      expect(classification.userAction, isNull);
      // The policy only inspects retryable; userAction should not affect decision.
      final decision = policy.decide(classification: classification, attempt: 0);
      expect(decision.shouldRetry, isTrue);
    });

    test('all FailureStage values produce a decision without error', timeout: const Timeout.factor(2), () {
      for (final _ in FailureStage.values) {
        const classification = RunFailureClassification(
          family: RunErrorFamily.transientUpstream,
          stage: FailureStage.execution,
          detail: 'test',
          retryable: false,
        );
        final decision = policy.decide(classification: classification, attempt: 0);
        expect(decision.shouldRetry, isFalse);
        expect(decision.reason, 'non_retryable');
      }
    });

    test('all RunErrorFamily values handled', timeout: const Timeout.factor(2), () {
      for (final family in RunErrorFamily.values) {
        final classification = RunFailureClassification(
          family: family,
          stage: FailureStage.execution,
          detail: '$family error',
          retryable: false,
        );
        final decision = policy.decide(classification: classification, attempt: 0);
        expect(decision.shouldRetry, isFalse);
      }
    });
  });
}
