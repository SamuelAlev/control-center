import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/observability/domain/latency_breakdown.dart';
import 'package:cc_domain/features/observability/domain/run_stage.dart';
import 'package:test/test.dart';

final _t0 = DateTime.utc(2026, 1, 1, 12);

/// Builds a stage timing with a default harness source.
RunStageTiming _timing(
  RunStage stage,
  int offsetMs, {
  RunTimingSource source = RunTimingSource.harness,
  int? durationMs,
}) => RunStageTiming(
  stage: stage,
  offsetMs: offsetMs,
  source: source,
  durationMs: durationMs,
);

/// Builds a run with the attributes the breakdown groups on.
AgentRunLog _run({
  required String id,
  RunLatencyProfile? latency,
  String? adapter = 'claude-cli',
  String? modelId = 'claude-sonnet',
  String? effort = 'medium',
  String? taskFamily = 'refactor',
  RunCost? cost,
  RunStatus status = RunStatus.completed,
}) => AgentRunLog(
  id: id,
  agentId: 'agent-1',
  startedAt: _t0,
  status: status,
  adapter: adapter,
  modelId: modelId,
  effort: effort,
  taskFamily: taskFamily,
  cost: cost,
  latency: latency,
);

/// Covers [LatencyBreakdownCalculator] and its supporting types: linear
/// interpolation percentiles, per-stage samples that exclude runs which never
/// reported the stage, derived metrics that stay null unless observable, and
/// the null-is-a-real-group grouping rule.
void main() {
  const calculator = LatencyBreakdownCalculator();

  // ---------------------------------------------------------------------------
  // LatencyPercentiles
  // ---------------------------------------------------------------------------
  group('LatencyPercentiles.of', () {
    // Protects: an empty sample is an unknown, not a zero.
    test('is null for an empty sample', () {
      expect(LatencyPercentiles.of(const <int>[]), isNull);
    });

    // Protects: a single sample is its own median and tail, with a count of 1
    // that is visibly different from a larger sample.
    test('summarizes a single sample', () {
      final stats = LatencyPercentiles.of(const <int>[10]);
      expect(stats, isNotNull);
      expect(stats!.count, 1);
      expect(stats.p50, 10.0);
      expect(stats.p95, 10.0);
      expect(stats.min, 10);
      expect(stats.max, 10);
    });

    // Protects: on an even-sized sample the median interpolates instead of
    // snapping to one side.
    test('linearly interpolates the median of two samples', () {
      final stats = LatencyPercentiles.of(const <int>[10, 20])!;
      expect(stats.count, 2);
      expect(stats.p50, 15.0);
      expect(stats.p95, 19.5);
      expect(stats.min, 10);
      expect(stats.max, 20);
    });

    // Protects: p95 on three samples interpolates between the top two rather
    // than jumping to the max.
    test('interpolates p95 on three samples', () {
      final stats = LatencyPercentiles.of(const <int>[10, 20, 30])!;
      expect(stats.count, 3);
      expect(stats.p50, 20.0);
      expect(stats.p95, 29.0);
      expect(stats.min, 10);
      expect(stats.max, 30);
    });

    // Protects: the sample is sorted before percentiling, so input order does
    // not change the answer.
    test('sorts its input before summarizing', () {
      expect(
        LatencyPercentiles.of(const <int>[30, 10, 20]),
        LatencyPercentiles.of(const <int>[10, 20, 30]),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // overall
  // ---------------------------------------------------------------------------
  group('LatencyBreakdownCalculator.overall', () {
    final r1 = _run(
      id: 'r1',
      latency: RunLatencyProfile.empty.mergeAll([
        _timing(RunStage.submitted, 0),
        _timing(RunStage.requestSent, 50, source: RunTimingSource.transport),
        _timing(
          RunStage.firstResponseByte,
          80,
          source: RunTimingSource.transport,
        ),
        _timing(
          RunStage.firstModelDelta,
          200,
          source: RunTimingSource.provider,
        ),
        _timing(RunStage.firstUsefulText, 400),
      ]),
    );
    final r2 = _run(
      id: 'r2',
      latency: RunLatencyProfile.empty.mergeAll([
        _timing(RunStage.submitted, 0),
        _timing(RunStage.requestSent, 40, source: RunTimingSource.transport),
        _timing(
          RunStage.firstResponseByte,
          60,
          source: RunTimingSource.transport,
        ),
        _timing(
          RunStage.firstModelDelta,
          300,
          source: RunTimingSource.provider,
        ),
        _timing(RunStage.firstUsefulText, 500),
      ]),
    );
    final r3 = _run(id: 'r3');

    // Protects: a run with no latency profile still counts toward runCount but
    // contributes to no stage sample — an unobservable stage must not enter a
    // percentile as a zero.
    test('a run with no profile counts but joins no stage sample', () {
      final stats = calculator.overall([r1, r2, r3]);
      expect(stats.runCount, 3);

      final delta = stats.offsetOf(RunStage.firstModelDelta);
      expect(delta, isNotNull);
      expect(delta!.count, 2);
      expect(delta.min, 200);
      expect(delta.max, 300);
      expect(delta.p50, 250.0);

      // No run reported this stage, so it is absent rather than all-zero.
      expect(stats.offsetOf(RunStage.verifiedCompletion), isNull);
    });

    // Protects: each derived metric percentiles only the runs that actually
    // observed its boundaries.
    test('derives ttfb, ttft and useful-work samples independently', () {
      final stats = calculator.overall([r1, r2, r3]);

      // ttfb: 80-50=30 and 60-40=20.
      expect(stats.transportTtfbMs, isNotNull);
      expect(stats.transportTtfbMs!.count, 2);
      expect(stats.transportTtfbMs!.min, 20);
      expect(stats.transportTtfbMs!.max, 30);
      expect(stats.transportTtfbMs!.p50, 25.0);

      // ttft: 200-50=150 and 300-40=260.
      expect(stats.providerTtftMs, isNotNull);
      expect(stats.providerTtftMs!.count, 2);
      expect(stats.providerTtftMs!.p50, 205.0);

      // useful work: 400 and 500.
      expect(stats.timeToFirstUsefulWorkMs, isNotNull);
      expect(stats.timeToFirstUsefulWorkMs!.count, 2);
      expect(stats.timeToFirstUsefulWorkMs!.p50, 450.0);
    });

    // Protects: a harness-observed byte is recorded as an offset but never
    // enters the transport TTFB distribution.
    test('a harness-observed byte is excluded from the ttfb sample', () {
      final run = _run(
        id: 'harness-byte',
        latency: RunLatencyProfile.empty.mergeAll([
          _timing(RunStage.submitted, 0),
          _timing(RunStage.requestSent, 10, source: RunTimingSource.adapter),
          _timing(RunStage.firstResponseByte, 20),
          _timing(RunStage.firstUsefulText, 100),
        ]),
      );

      final stats = calculator.overall([run]);
      expect(stats.offsetOf(RunStage.firstResponseByte)!.count, 1);
      expect(stats.transportTtfbMs, isNull);
    });

    // Protects: a stage reported without its start boundary never enters the
    // derived metric (unknown, not zero).
    test('a missing start boundary keeps the derived metric null', () {
      final run = _run(
        id: 'no-start',
        latency: RunLatencyProfile.empty.merge(
          _timing(RunStage.firstUsefulText, 300),
        ),
      );

      final stats = calculator.overall([run]);
      expect(stats.offsetOf(RunStage.firstUsefulText)!.count, 1);
      expect(stats.timeToFirstUsefulWorkMs, isNull);
    });

    // Protects: no runs is the empty distribution, not a zero-filled one.
    test('an empty input is the empty distribution', () {
      expect(calculator.overall(const []), RunLatencyStats.empty);
    });
  });

  // ---------------------------------------------------------------------------
  // grouping by a recorded dimension
  // ---------------------------------------------------------------------------
  group('LatencyBreakdownCalculator.grouped by effort', () {
    // Protects: a run whose effort was not recorded forms its own null group,
    // distinct from any real level, and sorts last.
    test('makes a null group for runs with no effort and sorts it last', () {
      final runs = [
        _run(id: 'a', effort: 'low'),
        _run(id: 'b', effort: null),
        _run(id: 'c', effort: 'high'),
        _run(id: 'd', effort: 'low'),
      ];

      final groups = calculator.grouped(runs, RunLatencyDimension.effort);
      expect(groups.map((g) => g.value).toList(), ['high', 'low', null]);
      expect(groups.length, 3);

      expect(groups.last.value, isNull);
      expect(groups.last.stats.runCount, 1);
      expect(groups.last.label, 'effort=unknown');

      final low = groups.firstWhere((g) => g.value == 'low');
      expect(low.stats.runCount, 2);
      expect(low.label, 'effort=low');
    });

    // Protects: no runs means no groups.
    test('an empty input yields no groups', () {
      expect(calculator.grouped(const [], RunLatencyDimension.effort), isEmpty);
    });

    // Protects: an unrecorded attribute reads as null so it can form its own
    // group rather than being folded into a real value.
    test('valueOf reports null for unrecorded attributes', () {
      final bare = _run(
        id: 'bare',
        adapter: null,
        modelId: null,
        effort: null,
        taskFamily: null,
      );

      expect(RunLatencyDimension.adapter.valueOf(bare), isNull);
      expect(RunLatencyDimension.model.valueOf(bare), isNull);
      expect(RunLatencyDimension.effort.valueOf(bare), isNull);
      expect(RunLatencyDimension.taskFamily.valueOf(bare), isNull);
      expect(RunLatencyDimension.cacheState.valueOf(bare), 'unknown');
    });
  });

  // ---------------------------------------------------------------------------
  // cache state
  // ---------------------------------------------------------------------------
  group('RunCacheState.of', () {
    // Protects: any cache read makes the run warm, even alongside fresh input.
    test('warm when the provider served part of the prompt from cache', () {
      expect(
        RunCacheState.of(
          _run(
            id: 'warm',
            cost: const RunCost(inputTokens: 100, cachedReadTokens: 5),
          ),
        ),
        RunCacheState.warm,
      );
    });

    // Protects: processing prompt tokens with no cache hit is a genuine cold
    // observation, distinct from unknown.
    test('cold when prompt tokens were processed with no cache hit', () {
      expect(
        RunCacheState.of(
          _run(id: 'cold', cost: const RunCost(inputTokens: 10)),
        ),
        RunCacheState.cold,
      );
    });

    // Protects: a cache write alone is still a cold observation.
    test('cold on a cache write alone', () {
      expect(
        RunCacheState.of(
          _run(id: 'write', cost: const RunCost(cachedWriteTokens: 10)),
        ),
        RunCacheState.cold,
      );
    });

    // Protects: no prompt tokens at all means the cache behaviour is unknown,
    // not a cold claim.
    test('unknown when no prompt tokens were reported', () {
      expect(RunCacheState.of(_run(id: 'none')), RunCacheState.unknown);
      expect(
        RunCacheState.of(_run(id: 'zero', cost: RunCost.zero)),
        RunCacheState.unknown,
      );
    });

    // Protects: grouping by cacheState yields only real derived states (it is
    // always derivable, so no null group) in a stable order.
    test('groups runs by derived cache state, alphabetically', () {
      final runs = [
        _run(
          id: 'warm',
          cost: const RunCost(inputTokens: 1, cachedReadTokens: 5),
        ),
        _run(id: 'cold', cost: const RunCost(inputTokens: 9)),
        _run(id: 'none'),
      ];

      final groups = calculator.grouped(runs, RunLatencyDimension.cacheState);
      expect(groups.map((g) => g.value).toList(), ['cold', 'unknown', 'warm']);
      expect(groups.every((g) => g.value != null), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // breakdown
  // ---------------------------------------------------------------------------
  group('LatencyBreakdownCalculator.breakdown', () {
    // Protects: the combined breakdown covers every dimension and agrees with a
    // single-dimension grouping.
    test('covers every dimension and matches grouped()', () {
      final runs = [
        _run(id: 'a'),
        _run(id: 'b', effort: null, taskFamily: null, adapter: null),
      ];

      final map = calculator.breakdown(runs);
      expect(map.keys.toSet(), RunLatencyDimension.values.toSet());
      for (final dimension in RunLatencyDimension.values) {
        expect(map[dimension], calculator.grouped(runs, dimension));
      }
    });
  });
}
