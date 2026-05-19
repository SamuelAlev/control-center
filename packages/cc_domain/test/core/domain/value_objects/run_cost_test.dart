import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:test/test.dart';

/// Covers [RunCost] and [RunUsage] value objects: construction, round-trips,
/// `totalTokens` aggregation, the `+` merge operator (incl. nullable-duration
/// branches), equality/hashCode, and the `zero` constant / `toCost` factory.
void main() {
  group('RunCost construction', () {
    test('defaults to a zero cost with null durations', () {
      const cost = RunCost();
      expect(cost.inputTokens, 0);
      expect(cost.outputTokens, 0);
      expect(cost.thoughtTokens, 0);
      expect(cost.cachedReadTokens, 0);
      expect(cost.cachedWriteTokens, 0);
      expect(cost.estimatedCostCents, 0);
      expect(cost.durationMs, isNull);
      expect(cost.timeToFirstTokenMs, isNull);
    });

    test('round-trips every field through the constructor', () {
      const cost = RunCost(
        inputTokens: 10,
        outputTokens: 5,
        thoughtTokens: 2,
        cachedReadTokens: 3,
        cachedWriteTokens: 1,
        estimatedCostCents: 7,
        durationMs: 1234,
        timeToFirstTokenMs: 56,
      );
      expect(cost.inputTokens, 10);
      expect(cost.outputTokens, 5);
      expect(cost.thoughtTokens, 2);
      expect(cost.cachedReadTokens, 3);
      expect(cost.cachedWriteTokens, 1);
      expect(cost.estimatedCostCents, 7);
      expect(cost.durationMs, 1234);
      expect(cost.timeToFirstTokenMs, 56);
    });
  });

  group('RunCost.totalTokens', () {
    test('sums every token category', () {
      const cost = RunCost(
        inputTokens: 100,
        outputTokens: 50,
        thoughtTokens: 25,
        cachedReadTokens: 10,
        cachedWriteTokens: 5,
      );
      expect(cost.totalTokens, 190);
    });

    test('is zero when nothing was consumed', () {
      expect(RunCost.zero.totalTokens, 0);
    });
  });

  group('RunCost.zero', () {
    test('is equal to a default-constructed RunCost', () {
      expect(RunCost.zero, const RunCost());
      expect(RunCost.zero.totalTokens, 0);
    });
  });

  group('RunCost equality and hashCode', () {
    test('equal by value across all fields', () {
      const a = RunCost(
        inputTokens: 1,
        outputTokens: 2,
        thoughtTokens: 3,
        cachedReadTokens: 4,
        cachedWriteTokens: 5,
        estimatedCostCents: 6,
        durationMs: 7,
        timeToFirstTokenMs: 8,
      );
      const b = RunCost(
        inputTokens: 1,
        outputTokens: 2,
        thoughtTokens: 3,
        cachedReadTokens: 4,
        cachedWriteTokens: 5,
        estimatedCostCents: 6,
        durationMs: 7,
        timeToFirstTokenMs: 8,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differ on any field are not equal', () {
      const base = RunCost(
        inputTokens: 1,
        outputTokens: 2,
        thoughtTokens: 3,
        cachedReadTokens: 4,
        cachedWriteTokens: 5,
        estimatedCostCents: 6,
        durationMs: 7,
        timeToFirstTokenMs: 8,
      );
      expect(base == const RunCost(inputTokens: 99), isFalse);
      expect(base == const RunCost(outputTokens: 99), isFalse);
      expect(base == const RunCost(thoughtTokens: 99), isFalse);
      expect(base == const RunCost(cachedReadTokens: 99), isFalse);
      expect(base == const RunCost(cachedWriteTokens: 99), isFalse);
      expect(base == const RunCost(estimatedCostCents: 99), isFalse);
      expect(base == const RunCost(durationMs: 99), isFalse);
      expect(base == const RunCost(timeToFirstTokenMs: 99), isFalse);
    });

    test('refuses non-RunCost operands', () {
      const cost = RunCost();
      expect(cost == Object(), isFalse);
    });
  });

  group('RunCost merge operator (+)', () {
    test('sums all numeric fields', () {
      const a = RunCost(
        inputTokens: 10,
        outputTokens: 5,
        thoughtTokens: 2,
        cachedReadTokens: 3,
        cachedWriteTokens: 1,
        estimatedCostCents: 7,
      );
      const b = RunCost(
        inputTokens: 1,
        outputTokens: 2,
        thoughtTokens: 3,
        cachedReadTokens: 4,
        cachedWriteTokens: 5,
        estimatedCostCents: 6,
      );
      final sum = a + b;
      expect(sum.inputTokens, 11);
      expect(sum.outputTokens, 7);
      expect(sum.thoughtTokens, 5);
      expect(sum.cachedReadTokens, 7);
      expect(sum.cachedWriteTokens, 6);
      expect(sum.estimatedCostCents, 13);
    });

    test('adds durations when both sides have one', () {
      const a = RunCost(durationMs: 100, timeToFirstTokenMs: 10);
      const b = RunCost(durationMs: 50, timeToFirstTokenMs: 20);
      final sum = a + b;
      expect(sum.durationMs, 150);
      // timeToFirstTokenMs takes the left-hand (first) value when both present.
      expect(sum.timeToFirstTokenMs, 10);
    });

    test('preserves the only defined duration when one side is null', () {
      const a = RunCost(durationMs: 100, timeToFirstTokenMs: 10);
      const b = RunCost();
      final sum = a + b;
      expect(sum.durationMs, 100);
      expect(sum.timeToFirstTokenMs, 10);
    });

    test('takes the right-hand duration when left is null', () {
      const a = RunCost();
      const b = RunCost(durationMs: 200, timeToFirstTokenMs: 30);
      final sum = a + b;
      expect(sum.durationMs, 200);
      expect(sum.timeToFirstTokenMs, 30);
    });

    test('keeps duration null when neither side defines it', () {
      const a = RunCost();
      const b = RunCost();
      final sum = a + b;
      expect(sum.durationMs, isNull);
      expect(sum.timeToFirstTokenMs, isNull);
    });

    test('merging zero is identity for token counts', () {
      const cost = RunCost(
        inputTokens: 4,
        outputTokens: 5,
        thoughtTokens: 6,
        cachedReadTokens: 7,
        cachedWriteTokens: 8,
        estimatedCostCents: 9,
      );
      expect(cost + RunCost.zero, cost);
    });
  });

  group('RunUsage', () {
    test('defaults to a zero usage', () {
      const usage = RunUsage();
      expect(usage.inputTokens, 0);
      expect(usage.outputTokens, 0);
      expect(usage.thoughtTokens, 0);
      expect(usage.cachedReadTokens, 0);
      expect(usage.cachedWriteTokens, 0);
      expect(usage.estimatedCostCents, 0);
      expect(usage.totalTokens, 0);
    });

    test('sums token categories in totalTokens', () {
      const usage = RunUsage(
        inputTokens: 1,
        outputTokens: 2,
        thoughtTokens: 3,
        cachedReadTokens: 4,
        cachedWriteTokens: 5,
      );
      expect(usage.totalTokens, 15);
    });

    test('toCost carries token counts and supplied timings', () {
      const usage = RunUsage(
        inputTokens: 1,
        outputTokens: 2,
        thoughtTokens: 3,
        cachedReadTokens: 4,
        cachedWriteTokens: 5,
        estimatedCostCents: 6,
      );
      final cost = usage.toCost(durationMs: 999, timeToFirstTokenMs: 11);
      expect(cost.inputTokens, 1);
      expect(cost.outputTokens, 2);
      expect(cost.thoughtTokens, 3);
      expect(cost.cachedReadTokens, 4);
      expect(cost.cachedWriteTokens, 5);
      expect(cost.estimatedCostCents, 6);
      expect(cost.durationMs, 999);
      expect(cost.timeToFirstTokenMs, 11);
    });

    test('toCost leaves timings null when not provided', () {
      const usage = RunUsage(inputTokens: 1);
      final cost = usage.toCost();
      expect(cost.durationMs, isNull);
      expect(cost.timeToFirstTokenMs, isNull);
    });

    test('zero is equal to a default-constructed usage', () {
      expect(RunUsage.zero, const RunUsage());
    });

    test('equal by value across all token fields', () {
      // A runtime value (here, a captured int) forces non-const construction
      // so canonicalisation does not make `identical` short-circuit the
      // per-field comparison chain. Intentionally non-const — ignore lint.
      // ignore: prefer_const_declarations
      final seed = 1;
      final a = RunUsage(
        inputTokens: seed,
        outputTokens: 2,
        thoughtTokens: 3,
        cachedReadTokens: 4,
        cachedWriteTokens: 5,
        estimatedCostCents: 6,
      );
      final b = RunUsage(
        inputTokens: seed,
        outputTokens: 2,
        thoughtTokens: 3,
        cachedReadTokens: 4,
        cachedWriteTokens: 5,
        estimatedCostCents: 6,
      );
      expect(identical(a, b), isFalse, reason: 'distinct heap instances');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when any token field changes', () {
      const base = RunUsage(
        inputTokens: 1,
        outputTokens: 2,
        thoughtTokens: 3,
        cachedReadTokens: 4,
        cachedWriteTokens: 5,
        estimatedCostCents: 6,
      );
      expect(base == const RunUsage(inputTokens: 99), isFalse);
      expect(base == const RunUsage(outputTokens: 99), isFalse);
      expect(base == const RunUsage(thoughtTokens: 99), isFalse);
      expect(base == const RunUsage(cachedReadTokens: 99), isFalse);
      expect(base == const RunUsage(cachedWriteTokens: 99), isFalse);
      expect(base == const RunUsage(estimatedCostCents: 99), isFalse);
    });

    test('refuses non-RunUsage operands', () {
      const usage = RunUsage();
      expect(usage == Object(), isFalse);
    });
  });
}
