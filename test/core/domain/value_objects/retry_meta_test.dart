import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RetryMeta', () {
    group('constructor', () {
      test('defaults to parentRunId=null and attempt=0', () {
        const meta = RetryMeta();
        expect(meta.parentRunId, isNull);
        expect(meta.attempt, 0);
      });

      test('accepts custom parentRunId and attempt', () {
        const meta = RetryMeta(parentRunId: 'run-42', attempt: 3);
        expect(meta.parentRunId, 'run-42');
        expect(meta.attempt, 3);
      });
    });

    group('nextAttempt', () {
      test('increments attempt and preserves parentRunId', () {
        const meta = RetryMeta(parentRunId: 'abc', attempt: 1);
        final next = meta.nextAttempt();
        expect(next.parentRunId, 'abc');
        expect(next.attempt, 2);
      });

      test('increments across multiple calls', () {
        var meta = const RetryMeta(parentRunId: 'x', attempt: 0);
        meta = meta.nextAttempt();
        meta = meta.nextAttempt();
        meta = meta.nextAttempt();
        expect(meta.attempt, 3);
        expect(meta.parentRunId, 'x');
      });

      test('preserves null parentRunId', () {
        const meta = RetryMeta();
        final next = meta.nextAttempt();
        expect(next.parentRunId, isNull);
        expect(next.attempt, 1);
      });
    });

    group('== and hashCode', () {
      test('equal when both fields match', () {
        const a = RetryMeta(parentRunId: 'p', attempt: 2);
        const b = RetryMeta(parentRunId: 'p', attempt: 2);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal when parentRunId differs', () {
        const a = RetryMeta(parentRunId: 'a', attempt: 0);
        const b = RetryMeta(parentRunId: 'b', attempt: 0);
        expect(a, isNot(equals(b)));
      });

      test('not equal when attempt differs', () {
        const a = RetryMeta(parentRunId: 'p', attempt: 1);
        const b = RetryMeta(parentRunId: 'p', attempt: 2);
        expect(a, isNot(equals(b)));
      });

      test('equal with null parentRunId', () {
        const a = RetryMeta(attempt: 5);
        const b = RetryMeta(attempt: 5);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('null vs non-null parentRunId not equal', () {
        const a = RetryMeta(parentRunId: null, attempt: 0);
        const b = RetryMeta(parentRunId: 'x', attempt: 0);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
