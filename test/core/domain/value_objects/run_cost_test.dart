import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunCost', () {
    test('default constructor creates zero instance equal to RunCost.zero', () {
      const default_ = RunCost();
      expect(default_, equals(RunCost.zero));
    });

    test('RunCost.zero has all zeros and null durations', () {
      expect(RunCost.zero.inputTokens, 0);
      expect(RunCost.zero.outputTokens, 0);
      expect(RunCost.zero.thoughtTokens, 0);
      expect(RunCost.zero.cachedReadTokens, 0);
      expect(RunCost.zero.cachedWriteTokens, 0);
      expect(RunCost.zero.estimatedCostCents, 0);
      expect(RunCost.zero.durationMs, isNull);
      expect(RunCost.zero.timeToFirstTokenMs, isNull);
    });

    group('totalTokens', () {
      test('sums all 5 token fields', () {
        const cost = RunCost(
          inputTokens: 100,
          outputTokens: 200,
          thoughtTokens: 50,
          cachedReadTokens: 30,
          cachedWriteTokens: 20,
        );
        expect(cost.totalTokens, 400);
      });

      test('is zero when all fields are zero', () {
        expect(RunCost.zero.totalTokens, 0);
      });
    });

    group('operator +', () {
      test('adds all numeric fields', () {
        const a = RunCost(
          inputTokens: 10,
          outputTokens: 20,
          thoughtTokens: 5,
          cachedReadTokens: 3,
          cachedWriteTokens: 2,
          estimatedCostCents: 7,
        );
        const b = RunCost(
          inputTokens: 1,
          outputTokens: 2,
          thoughtTokens: 5,
          cachedReadTokens: 7,
          cachedWriteTokens: 8,
          estimatedCostCents: 3,
        );
        final result = a + b;
        expect(result.inputTokens, 11);
        expect(result.outputTokens, 22);
        expect(result.thoughtTokens, 10);
        expect(result.cachedReadTokens, 10);
        expect(result.cachedWriteTokens, 10);
        expect(result.estimatedCostCents, 10);
      });

      group('coalesces nullable durationMs', () {
        test('null + null = null', () {
          const a = RunCost();
          const b = RunCost();
          expect((a + b).durationMs, isNull);
        });

        test('10 + null = 10', () {
          const a = RunCost(durationMs: 10);
          const b = RunCost();
          expect((a + b).durationMs, 10);
        });

        test('null + 20 = 20', () {
          const a = RunCost();
          const b = RunCost(durationMs: 20);
          expect((a + b).durationMs, 20);
        });

        test('10 + 20 = 30', () {
          const a = RunCost(durationMs: 10);
          const b = RunCost(durationMs: 20);
          expect((a + b).durationMs, 30);
        });
      });

      group('coalesces nullable timeToFirstTokenMs', () {
        test('prefers left when both non-null', () {
          const a = RunCost(timeToFirstTokenMs: 5);
          const b = RunCost(timeToFirstTokenMs: 10);
          expect((a + b).timeToFirstTokenMs, 5);
        });

        test('left null falls to right', () {
          const a = RunCost();
          const b = RunCost(timeToFirstTokenMs: 15);
          expect((a + b).timeToFirstTokenMs, 15);
        });

        test('right null uses left', () {
          const a = RunCost(timeToFirstTokenMs: 25);
          const b = RunCost();
          expect((a + b).timeToFirstTokenMs, 25);
        });

        test('null + null = null', () {
          const a = RunCost();
          const b = RunCost();
          expect((a + b).timeToFirstTokenMs, isNull);
        });
      });
    });

    group('== and hashCode', () {
      test('equal when all fields match', () {
        const a = RunCost(
          inputTokens: 1,
          outputTokens: 2,
          thoughtTokens: 3,
          cachedReadTokens: 4,
          cachedWriteTokens: 5,
          estimatedCostCents: 6,
          durationMs: 100,
          timeToFirstTokenMs: 50,
        );
        const b = RunCost(
          inputTokens: 1,
          outputTokens: 2,
          thoughtTokens: 3,
          cachedReadTokens: 4,
          cachedWriteTokens: 5,
          estimatedCostCents: 6,
          durationMs: 100,
          timeToFirstTokenMs: 50,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal when any field differs', () {
        const base = RunCost(
          inputTokens: 1,
          outputTokens: 2,
          estimatedCostCents: 3,
        );
        expect(base, isNot(equals(const RunCost(inputTokens: 99, outputTokens: 2, estimatedCostCents: 3))));
        expect(base, isNot(equals(const RunCost(inputTokens: 1, outputTokens: 99, estimatedCostCents: 3))));
        expect(base, isNot(equals(const RunCost(inputTokens: 1, outputTokens: 2, estimatedCostCents: 99))));
      });

      test('not equal when nullable fields differ', () {
        const a = RunCost(durationMs: 10);
        const b = RunCost(durationMs: null);
        expect(a, isNot(equals(b)));
      });
    });
  });

  group('RunUsage', () {
    test('default constructor creates zero instance equal to RunUsage.zero', () {
      const default_ = RunUsage();
      expect(default_, equals(RunUsage.zero));
    });

    group('totalTokens', () {
      test('sums 5 token fields', () {
        const usage = RunUsage(
          inputTokens: 100,
          outputTokens: 200,
          thoughtTokens: 50,
          cachedReadTokens: 30,
          cachedWriteTokens: 20,
        );
        expect(usage.totalTokens, 400);
      });

      test('is zero when all fields are zero', () {
        expect(RunUsage.zero.totalTokens, 0);
      });
    });

    group('toCost', () {
      test('copies token fields and passes durationMs/timeToFirstTokenMs through', () {
        const usage = RunUsage(
          inputTokens: 10,
          outputTokens: 20,
          thoughtTokens: 5,
          cachedReadTokens: 3,
          cachedWriteTokens: 2,
          estimatedCostCents: 7,
        );
        final cost = usage.toCost(durationMs: 100, timeToFirstTokenMs: 50);
        expect(cost.inputTokens, 10);
        expect(cost.outputTokens, 20);
        expect(cost.thoughtTokens, 5);
        expect(cost.cachedReadTokens, 3);
        expect(cost.cachedWriteTokens, 2);
        expect(cost.estimatedCostCents, 7);
        expect(cost.durationMs, 100);
        expect(cost.timeToFirstTokenMs, 50);
      });

      test('with no args gives null durationMs/timeToFirstTokenMs', () {
        const usage = RunUsage(inputTokens: 5);
        final cost = usage.toCost();
        expect(cost.inputTokens, 5);
        expect(cost.durationMs, isNull);
        expect(cost.timeToFirstTokenMs, isNull);
      });
    });

    group('== and hashCode', () {
      test('equal when all fields match', () {
        const a = RunUsage(
          inputTokens: 1,
          outputTokens: 2,
          thoughtTokens: 3,
          cachedReadTokens: 4,
          cachedWriteTokens: 5,
          estimatedCostCents: 6,
        );
        const b = RunUsage(
          inputTokens: 1,
          outputTokens: 2,
          thoughtTokens: 3,
          cachedReadTokens: 4,
          cachedWriteTokens: 5,
          estimatedCostCents: 6,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal when any field differs', () {
        const base = RunUsage(
          inputTokens: 1,
          outputTokens: 2,
          estimatedCostCents: 3,
        );
        expect(base, isNot(equals(const RunUsage(inputTokens: 99, outputTokens: 2, estimatedCostCents: 3))));
        expect(base, isNot(equals(const RunUsage(inputTokens: 1, outputTokens: 99, estimatedCostCents: 3))));
        expect(base, isNot(equals(const RunUsage(inputTokens: 1, outputTokens: 2, estimatedCostCents: 99))));
      });
    });
  });
}
