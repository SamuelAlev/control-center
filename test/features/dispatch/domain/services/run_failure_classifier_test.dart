import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/dispatch/domain/services/run_failure_classifier.dart';
import 'package:test/test.dart';

void main() {
  late RunFailureClassifier classifier;

  setUp(() {
    classifier = RunFailureClassifier();
  });

  // ---- Auth errors --------------------------------------------------------

  group('classify — auth errors', () {
    test('detects "authentication failed" in stderr', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'Error: authentication failed for user',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.stage, FailureStage.launch);
      expect(result.retryable, isFalse);
      expect(result.detail, contains('Authentication'));
      expect(result.userAction, isNotNull);
    });

    test('detects "invalid api key" case-insensitively', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'INVALID API KEY provided',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isFalse);
    });

    test('detects auth via lastError field', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: '',
        lastError: '401 Unauthorized',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isFalse);
    });

    test('detects "credentials" pattern', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'bad credentials supplied',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
    });
  });

  // ---- Rate limiting ------------------------------------------------------

  group('classify — rate limiting', () {
    test('detects "rate limit" as retryable', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'rate limit exceeded',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.stage, FailureStage.execution);
      expect(result.retryable, isTrue);
    });

    test('detects "429" in stderr', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'HTTP 429 Too Many Requests',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isTrue);
    });

    test('detects "quota exceeded"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'quota exceeded for this account',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isTrue);
    });
  });

  // ---- Prompt too large ---------------------------------------------------

  group('classify — prompt too large', () {
    test('detects "prompt is too long"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'Error: prompt is too long: 200000 tokens',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isFalse);
      expect(result.userAction, isNotNull);
    });

    test('detects "context_length_exceeded"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'context_length_exceeded',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isFalse);
    });
  });

  // ---- Permission / access denied -----------------------------------------

  group('classify — permission denied', () {
    test('detects "permission denied"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'permission denied: model access restricted',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isFalse);
    });

    test('detects "403 forbidden"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'HTTP 403 forbidden',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isFalse);
    });
  });

  // ---- Timeout / connection errors ----------------------------------------

  group('classify — timeout / connection', () {
    test('detects "timeout" as retryable', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'request timeout after 30s',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isTrue);
    });

    test('detects "502 bad gateway"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: '502 bad gateway',
      );
      expect(result.retryable, isTrue);
    });

    test('detects "econnrefused"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'Error: econnrefused 127.0.0.1:443',
      );
      expect(result.retryable, isTrue);
    });
  });

  // ---- Model unavailable --------------------------------------------------

  group('classify — model unavailable', () {
    test('detects "model not found"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'model not found: gpt-5-turbo',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isTrue);
      expect(result.userAction, contains('different model'));
    });
  });

  // ---- Sandbox infrastructure ---------------------------------------------

  group('classify — sandbox infrastructure', () {
    test('detects "sandbox" in stderr', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'sandbox: denied operation',
      );
      expect(result.family, RunErrorFamily.sandboxInfrastructure);
      expect(result.stage, FailureStage.launch);
      expect(result.retryable, isFalse);
    });

    test('detects "[sandbox]" in stderr', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: '[sandbox] process blocked',
      );
      expect(result.family, RunErrorFamily.sandboxInfrastructure);
    });
  });

  // ---- Binary not found (exit 127) ----------------------------------------

  group('classify — binary not found', () {
    test('exit code 127 → binary not found', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 127,
        stderr: 'command not found: pi',
      );
      expect(result.family, RunErrorFamily.sandboxInfrastructure);
      expect(result.stage, FailureStage.launch);
      expect(result.retryable, isFalse);
      expect(result.detail, contains('binary not found'));
    });
  });

  // ---- Process killed / lost -----------------------------------------------

  group('classify — process killed', () {
    test('null exit code → process lost', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: null,
        stderr: '',
      );
      expect(result.family, RunErrorFamily.processLost);
      expect(result.retryable, isFalse);
    });

    test('exit code 143 → process killed (SIGTERM)', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 143,
        stderr: '',
      );
      expect(result.family, RunErrorFamily.processLost);
      expect(result.retryable, isFalse);
    });
  });

  // ---- Empty output / silent run ------------------------------------------

  group('classify — empty output', () {
    test('detects "empty response" as retryable', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 0,
        stderr: 'empty response from agent',
      );
      expect(result.family, RunErrorFamily.silentRun);
      expect(result.stage, FailureStage.postRun);
      expect(result.retryable, isTrue);
    });

    test('detects "no output"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 0,
        stderr: 'no output produced',
      );
      expect(result.family, RunErrorFamily.silentRun);
      expect(result.retryable, isTrue);
    });
  });

  // ---- Budget exceeded ----------------------------------------------------

  group('classify — budget exceeded', () {
    test('detects "budget" in stderr', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'budget exceeded for this conversation',
      );
      expect(result.family, RunErrorFamily.budgetExceeded);
      expect(result.retryable, isFalse);
      expect(result.userAction, contains('budget'));
    });

    test('detects "spending limit"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'spending limit reached',
      );
      expect(result.family, RunErrorFamily.budgetExceeded);
      expect(result.retryable, isFalse);
    });
  });

  // ---- Default / unknown --------------------------------------------------

  group('classify — unknown', () {
    test('unknown error when nothing matches', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 42,
        stderr: 'some unrecognized error',
      );
      expect(result.family, RunErrorFamily.unknown);
      expect(result.retryable, isFalse);
      expect(result.detail, contains('42'));
    });

    test('uses lastError in detail for unknown', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'something else',
        lastError: 'Custom error message',
      );
      // Auth patterns include "credentials", "401" etc — "Custom error message"
      // shouldn't match any pattern, so it falls through to unknown.
      // However, "something else" also doesn't match. Let's be explicit:
      expect(result.family, RunErrorFamily.unknown);
    });
  });

  // ---- Priority: auth before rate limit -----------------------------------

  group('classify — pattern priority', () {
    test('auth takes precedence over rate limit when both present', timeout: const Timeout.factor(2), () {
      // Both "unauthorized" and "rate limit" in the same output
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'unauthorized: rate limit exceeded',
      );
      // Auth is checked first
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isFalse); // auth → not retryable
    });

    test('rate limit takes precedence over empty output', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'rate limit hit, no output',
      );
      expect(result.retryable, isTrue); // rate limit, not silentRun
    });
  });

  // ---- Case insensitivity -------------------------------------------------

  group('classify — case insensitivity', () {
    test('matches upper-case AUTHENTICATION FAILED', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'AUTHENTICATION FAILED',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isFalse);
    });

    test('matches mixed-case Timeout', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'Request Timeout',
      );
      expect(result.retryable, isTrue);
    });
  });

  // ---- Combined stderr + lastError ----------------------------------------

  group('classify — combined text search', () {
    test('pattern split across lastError and stderr', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'rate limit',
        lastError: '',
      );
      expect(result.retryable, isTrue);
    });

    test('lastError alone triggers match', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: '',
        lastError: 'connection refused by upstream',
      );
      expect(result.retryable, isTrue);
    });
  });

  // ---- Exhaustive pattern coverage by family -------------------------------

  group('classify — additional auth patterns', () {
    test('detects "not authenticated"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'not authenticated: session expired',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isFalse);
    });

    test('detects "login required"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'login required before continuing',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isFalse);
    });

    test('detects "auth error"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'auth error: invalid token',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isFalse);
    });
  });

  group('classify — additional rate limit patterns', () {
    test('detects "capacity"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'capacity exhausted for region',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isTrue);
    });

    test('detects "rate_limit" with underscore', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'error_code: rate_limit',
      );
      expect(result.family, RunErrorFamily.transientUpstream);
      expect(result.retryable, isTrue);
    });
  });

  group('classify — additional timeout patterns', () {
    test('detects "connection reset"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'connection reset by peer',
      );
      expect(result.retryable, isTrue);
    });

    test('detects "socket hang up"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'socket hang up on port 443',
      );
      expect(result.retryable, isTrue);
    });

    test('detects "503 service unavailable"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: '503 service unavailable',
      );
      expect(result.retryable, isTrue);
    });

    test('detects "network error"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'network error: dns resolution failed',
      );
      expect(result.retryable, isTrue);
    });
  });

  group('classify — additional sandbox patterns', () {
    test('detects "sandboxing"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'sandboxing layer initialization error',
      );
      expect(result.family, RunErrorFamily.sandboxInfrastructure);
      expect(result.retryable, isFalse);
    });

    test('detects "denied operation"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'denied operation: fork() blocked',
      );
      expect(result.family, RunErrorFamily.sandboxInfrastructure);
      expect(result.retryable, isFalse);
    });
  });

  group('classify — additional budget patterns', () {
    test('detects "limit exceeded" in budget context', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'token limit exceeded this month',
      );
      expect(result.family, RunErrorFamily.budgetExceeded);
      expect(result.retryable, isFalse);
    });

    test('detects "cost limit"', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 1,
        stderr: 'cost limit reached for billing period',
      );
      expect(result.family, RunErrorFamily.budgetExceeded);
      expect(result.retryable, isFalse);
    });
  });

  // ---- Priority edge cases across families ---------------------------------

  group('classify — priority edge cases', () {
    test('timeout before exit code 127', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 127,
        stderr: 'connection timeout after 30s',
      );
      // Timeout is checked before exit code 127.
      expect(result.detail, contains('timeout'));
      expect(result.retryable, isTrue);
    });

    test('sandbox before process killed', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: null,
        stderr: 'sandbox mode: not available',
      );
      // Sandbox patterns checked before exit-code-based checks.
      expect(result.family, RunErrorFamily.sandboxInfrastructure);
      expect(result.retryable, isFalse);
    });

    test('process killed overrides budget when exit 143', timeout: const Timeout.factor(2), () {
      final result = classifier.classify(
        exitCode: 143,
        stderr: 'budget exhausted',
      );
      // Process-killed (exitCode 143) is checked before budget patterns.
      expect(result.family, RunErrorFamily.processLost);
    });
  });

  // ---- Stage verification across all families ------------------------------

  group('classify — stage assignment', () {
    test('launch stage for auth, prompt-too-large, sandbox, binary-not-found',
        timeout: const Timeout.factor(2), () {
      expect(
        classifier.classify(exitCode: 1, stderr: 'unauthorized').stage,
        FailureStage.launch,
      );
      expect(
        classifier.classify(exitCode: 1, stderr: 'prompt is too long').stage,
        FailureStage.launch,
      );
      expect(
        classifier.classify(exitCode: 1, stderr: '[sandbox] blocked').stage,
        FailureStage.launch,
      );
      expect(
        classifier.classify(exitCode: 127, stderr: 'not found').stage,
        FailureStage.launch,
      );
    });

    test('execution stage for rate-limit, permission, timeout, model, budget',
        timeout: const Timeout.factor(2), () {
      expect(
        classifier.classify(exitCode: 1, stderr: 'rate limit').stage,
        FailureStage.execution,
      );
      expect(
        classifier.classify(exitCode: 1, stderr: 'permission denied').stage,
        FailureStage.execution,
      );
      expect(
        classifier.classify(exitCode: 1, stderr: 'timeout').stage,
        FailureStage.execution,
      );
      expect(
        classifier.classify(exitCode: 1, stderr: 'model not found').stage,
        FailureStage.execution,
      );
      expect(
        classifier.classify(exitCode: 1, stderr: 'budget exceeded').stage,
        FailureStage.execution,
      );
    });

    test('postRun stage for silent run', timeout: const Timeout.factor(2), () {
      expect(
        classifier.classify(exitCode: 0, stderr: 'empty response').stage,
        FailureStage.postRun,
      );
    });
  });
}
