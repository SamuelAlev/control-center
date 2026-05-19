import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/observability/domain/observability_metrics.dart';
import 'package:test/test.dart';

/// Builds an [AgentRunLog] with just the fields the calculator reads.
AgentRunLog _run({
  String id = 'r',
  required DateTime startedAt,
  RunStatus status = RunStatus.completed,
  int inputTokens = 0,
  int outputTokens = 0,
  int thoughtTokens = 0,
  int cachedReadTokens = 0,
  int cachedWriteTokens = 0,
  int estimatedCostCents = 0,
  int? durationMs,
  int? timeToFirstTokenMs,
}) => AgentRunLog(
  id: id,
  agentId: 'a',
  startedAt: startedAt,
  status: status,
  cost: RunCost(
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    thoughtTokens: thoughtTokens,
    cachedReadTokens: cachedReadTokens,
    cachedWriteTokens: cachedWriteTokens,
    estimatedCostCents: estimatedCostCents,
    durationMs: durationMs,
    timeToFirstTokenMs: timeToFirstTokenMs,
  ),
);

void main() {
  const calc = ObservabilityMetricsCalculator();

  group('compute', () {
    test('empty input yields the zeroed snapshot with null bounds', () {
      final m = calc.compute(const <AgentRunLog>[]);
      expect(m, ObservabilityMetrics.empty);
      expect(m.totalRuns, 0);
      expect(m.failedRuns, 0);
      expect(m.successfulRuns, 0);
      expect(m.totalCostCents, 0);
      expect(m.errorRate, 0);
      expect(m.cacheRate, 0);
      expect(m.avgDurationMs, 0);
      expect(m.avgTtftMs, 0);
      expect(m.tokensPerSecond, 0);
      expect(m.firstRun, isNull);
      expect(m.lastRun, isNull);
    });

    test('counts runs, failures and successes by status', () {
      final base = DateTime(2026, 1, 1);
      final m = calc.compute([
        _run(startedAt: base, status: RunStatus.completed),
        _run(startedAt: base, status: RunStatus.error),
        _run(startedAt: base, status: RunStatus.error),
        _run(startedAt: base, status: RunStatus.running),
        _run(startedAt: base, status: RunStatus.pending),
      ]);
      expect(m.totalRuns, 5);
      expect(m.failedRuns, 2);
      expect(m.successfulRuns, 1);
      // pending/running count toward total but neither success nor failure.
      expect(m.errorRate, closeTo(2 / 5, 1e-12));
    });

    test('sums all five token axes and cost independently', () {
      final base = DateTime(2026, 1, 1);
      final m = calc.compute([
        _run(
          startedAt: base,
          inputTokens: 10,
          outputTokens: 20,
          thoughtTokens: 30,
          cachedReadTokens: 40,
          cachedWriteTokens: 50,
          estimatedCostCents: 7,
        ),
        _run(
          startedAt: base,
          inputTokens: 1,
          outputTokens: 2,
          thoughtTokens: 3,
          cachedReadTokens: 4,
          cachedWriteTokens: 5,
          estimatedCostCents: 8,
        ),
      ]);
      expect(m.totalInputTokens, 11);
      expect(m.totalOutputTokens, 22);
      expect(m.totalReasoningTokens, 33);
      expect(m.totalCacheReadTokens, 44);
      expect(m.totalCacheWriteTokens, 55);
      expect(m.totalCostCents, 15);
    });

    test('cacheRate = cacheRead / (input + cacheRead)', () {
      final base = DateTime(2026, 1, 1);
      final m = calc.compute([
        _run(startedAt: base, inputTokens: 30, cachedReadTokens: 10),
      ]);
      // 10 / (30 + 10) = 0.25
      expect(m.cacheRate, closeTo(0.25, 1e-12));
    });

    test('cacheRate is 0 when input and cacheRead are both zero', () {
      final base = DateTime(2026, 1, 1);
      // Only output/write tokens present — cache denominator is zero.
      final m = calc.compute([
        _run(startedAt: base, outputTokens: 100, cachedWriteTokens: 100),
      ]);
      expect(m.cacheRate, 0);
    });

    test('errorRate is 0 when no runs failed', () {
      final base = DateTime(2026, 1, 1);
      final m = calc.compute([
        _run(startedAt: base, status: RunStatus.completed),
        _run(startedAt: base, status: RunStatus.completed),
      ]);
      expect(m.errorRate, 0);
    });

    test('avgDurationMs averages only runs that recorded a duration', () {
      final base = DateTime(2026, 1, 1);
      final m = calc.compute([
        _run(startedAt: base, durationMs: 100),
        _run(startedAt: base, durationMs: 300),
        _run(startedAt: base), // no duration — excluded from the average
      ]);
      // (100 + 300) / 2 = 200, NOT /3.
      expect(m.avgDurationMs, closeTo(200, 1e-12));
    });

    test('avgDurationMs is 0 when no run recorded a duration', () {
      final base = DateTime(2026, 1, 1);
      final m = calc.compute([_run(startedAt: base), _run(startedAt: base)]);
      expect(m.avgDurationMs, 0);
    });

    test('avgTtftMs averages only runs that recorded a ttft', () {
      final base = DateTime(2026, 1, 1);
      final m = calc.compute([
        _run(startedAt: base, timeToFirstTokenMs: 50),
        _run(startedAt: base, timeToFirstTokenMs: 150),
        _run(startedAt: base), // no ttft — excluded
      ]);
      expect(m.avgTtftMs, closeTo(100, 1e-12));
    });

    test('avgTtftMs is 0 when no run recorded a ttft', () {
      final base = DateTime(2026, 1, 1);
      final m = calc.compute([_run(startedAt: base, durationMs: 1000)]);
      expect(m.avgTtftMs, 0);
    });

    test('tokensPerSecond uses only positive-duration runs', () {
      final base = DateTime(2026, 1, 1);
      final m = calc.compute([
        // 1000 output tokens over 2000 ms = 2 s.
        _run(startedAt: base, outputTokens: 1000, durationMs: 2000),
        // 500 output tokens over 1000 ms = 1 s.
        _run(startedAt: base, outputTokens: 500, durationMs: 1000),
        // No duration: its output tokens must NOT count toward throughput.
        _run(startedAt: base, outputTokens: 9999),
      ]);
      // (1000 + 500) output / (3000 ms = 3 s) = 500 tokens/s.
      expect(m.tokensPerSecond, closeTo(500, 1e-9));
    });

    test('tokensPerSecond excludes zero-duration runs (no div by zero)', () {
      final base = DateTime(2026, 1, 1);
      final m = calc.compute([
        _run(startedAt: base, outputTokens: 1000, durationMs: 0),
      ]);
      expect(m.tokensPerSecond, 0);
      // A zero duration is still recorded for the average (it is non-null).
      expect(m.avgDurationMs, 0);
    });

    test('tokensPerSecond is 0 when no run has a positive duration', () {
      final base = DateTime(2026, 1, 1);
      final m = calc.compute([_run(startedAt: base, outputTokens: 500)]);
      expect(m.tokensPerSecond, 0);
    });

    test(
      'firstRun and lastRun track the min/max startedAt regardless of order',
      () {
        final early = DateTime(2026, 1, 1, 8);
        final mid = DateTime(2026, 1, 1, 12);
        final late = DateTime(2026, 1, 1, 18);
        // Deliberately out of chronological order.
        final m = calc.compute([
          _run(startedAt: mid),
          _run(startedAt: late),
          _run(startedAt: early),
        ]);
        expect(m.firstRun, early);
        expect(m.lastRun, late);
      },
    );

    test('single run: firstRun equals lastRun', () {
      final t = DateTime(2026, 3, 4, 5, 6, 7);
      final m = calc.compute([_run(startedAt: t)]);
      expect(m.firstRun, t);
      expect(m.lastRun, t);
    });
  });

  group('hourlySeries', () {
    test('empty input yields an empty series', () {
      expect(calc.hourlySeries(const <AgentRunLog>[]), isEmpty);
    });

    test('buckets by floored hour and sorts ascending', () {
      // Two runs in the 09:00 hour, one in 10:00, one in 08:00.
      final runs = [
        _run(startedAt: DateTime(2026, 1, 1, 10, 5)),
        _run(startedAt: DateTime(2026, 1, 1, 9, 59, 59)),
        _run(startedAt: DateTime(2026, 1, 1, 9, 0, 1)),
        _run(startedAt: DateTime(2026, 1, 1, 8, 30)),
      ];
      final series = calc.hourlySeries(runs);
      expect(series.map((b) => b.bucketStart).toList(), [
        DateTime(2026, 1, 1, 8),
        DateTime(2026, 1, 1, 9),
        DateTime(2026, 1, 1, 10),
      ]);
      expect(series[0].runs, 1);
      expect(series[1].runs, 2);
      expect(series[2].runs, 1);
    });

    test('sums all five token axes, cost and counts errors per bucket', () {
      final hour = DateTime(2026, 1, 1, 9);
      final runs = [
        _run(
          startedAt: DateTime(2026, 1, 1, 9, 10),
          status: RunStatus.error,
          inputTokens: 1,
          outputTokens: 2,
          thoughtTokens: 3,
          cachedReadTokens: 4,
          cachedWriteTokens: 5,
          estimatedCostCents: 10,
        ),
        _run(
          startedAt: DateTime(2026, 1, 1, 9, 50),
          status: RunStatus.completed,
          inputTokens: 10,
          outputTokens: 20,
          thoughtTokens: 30,
          cachedReadTokens: 40,
          cachedWriteTokens: 50,
          estimatedCostCents: 90,
        ),
      ];
      final series = calc.hourlySeries(runs);
      expect(series, hasLength(1));
      final b = series.single;
      expect(b.bucketStart, hour);
      expect(b.runs, 2);
      expect(b.errors, 1);
      // (1+2+3+4+5) + (10+20+30+40+50) = 15 + 150 = 165
      expect(b.tokens, 165);
      expect(b.costCents, 100);
    });

    test('runs straddling a day boundary land in distinct hour buckets', () {
      final runs = [
        _run(startedAt: DateTime(2026, 1, 1, 23, 59)),
        _run(startedAt: DateTime(2026, 1, 2, 0, 0, 1)),
      ];
      final series = calc.hourlySeries(runs);
      expect(series.map((b) => b.bucketStart).toList(), [
        DateTime(2026, 1, 1, 23),
        DateTime(2026, 1, 2, 0),
      ]);
    });
  });

  group('dailySeries', () {
    test('empty input yields an empty series', () {
      expect(calc.dailySeries(const <AgentRunLog>[]), isEmpty);
    });

    test('buckets by floored day and sorts ascending', () {
      final runs = [
        _run(startedAt: DateTime(2026, 1, 3, 23)),
        _run(startedAt: DateTime(2026, 1, 1, 1)),
        _run(startedAt: DateTime(2026, 1, 1, 22)),
        _run(startedAt: DateTime(2026, 1, 2, 12)),
      ];
      final series = calc.dailySeries(runs);
      expect(series.map((b) => b.bucketStart).toList(), [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
      ]);
      // Two runs collapse into the Jan-1 bucket.
      expect(series.first.runs, 2);
    });

    test('aggregates tokens, cost and errors within a day', () {
      final runs = [
        _run(
          startedAt: DateTime(2026, 1, 1, 1),
          status: RunStatus.error,
          inputTokens: 100,
          estimatedCostCents: 5,
        ),
        _run(
          startedAt: DateTime(2026, 1, 1, 23),
          status: RunStatus.completed,
          outputTokens: 200,
          estimatedCostCents: 15,
        ),
      ];
      final series = calc.dailySeries(runs);
      expect(series, hasLength(1));
      final b = series.single;
      expect(b.runs, 2);
      expect(b.errors, 1);
      expect(b.tokens, 300);
      expect(b.costCents, 20);
    });
  });

  group('value object equality', () {
    test('ObservabilityMetrics == and hashCode are structural', () {
      final base = DateTime(2026, 1, 1);
      final runs = [
        _run(
          startedAt: base,
          inputTokens: 10,
          outputTokens: 20,
          estimatedCostCents: 5,
          durationMs: 1000,
          timeToFirstTokenMs: 100,
        ),
      ];
      final a = calc.compute(runs);
      final b = calc.compute(runs);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(ObservabilityMetrics.empty));
    });

    test('TimeBucket == and hashCode are structural', () {
      final t = DateTime(2026, 1, 1, 9);
      final b1 = TimeBucket(
        bucketStart: t,
        runs: 1,
        errors: 0,
        tokens: 5,
        costCents: 2,
      );
      final b2 = TimeBucket(
        bucketStart: t,
        runs: 1,
        errors: 0,
        tokens: 5,
        costCents: 2,
      );
      final b3 = TimeBucket(
        bucketStart: t,
        runs: 1,
        errors: 1,
        tokens: 5,
        costCents: 2,
      );
      expect(b1, b2);
      expect(b1.hashCode, b2.hashCode);
      expect(b1, isNot(b3));
    });
  });
}
