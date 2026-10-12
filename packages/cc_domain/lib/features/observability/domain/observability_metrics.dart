import 'package:cc_domain/core/domain/entities/agent_run_log.dart';

/// Aggregate observability metrics computed over a set of [AgentRunLog]s.
///
/// Run counts, an error rate, token totals across all five usage axes, cache
/// effectiveness, latency averages and an output-token throughput figure.
/// All derived ratios are guarded against division by zero — an empty input
/// yields a fully zeroed instance with null [firstRun] / [lastRun].
///
/// Two distinctions this class exists to keep honest:
/// * COMPLETED is not VERIFIED: [successfulRuns] counts runs that ended
///   cleanly, [verifiedSuccessfulRuns] counts the subset an independent
///   verifier passed. A cost-per-success figure built on the former improves by
///   lowering quality.
/// * Own cost is not tree cost: [totalCostMicros] counts each run's own spend
///   exactly once (never double counting a parent and its child), while
///   [inclusiveCostMicros] folds propagated child rollups in for runs whose
///   parent is outside the set.
class ObservabilityMetrics {
  /// Creates an [ObservabilityMetrics] snapshot. All fields are required so
  /// callers cannot accidentally leave a derived figure at a stale default.
  const ObservabilityMetrics({
    required this.totalRuns,
    required this.failedRuns,
    required this.successfulRuns,
    required this.totalCostCents,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCacheReadTokens,
    required this.totalCacheWriteTokens,
    required this.totalReasoningTokens,
    required this.errorRate,
    required this.cacheRate,
    required this.avgDurationMs,
    required this.avgTtftMs,
    required this.tokensPerSecond,
    required this.firstRun,
    required this.lastRun,
    this.verifiedSuccessfulRuns = 0,
    this.successRate = 0,
    this.verifiedSuccessRate = 0,
    this.totalCostMicros = 0,
    this.inclusiveCostMicros = 0,
    this.activeRuns = 0,
  });

  /// A fully zeroed snapshot, used when there are no runs to aggregate.
  static const empty = ObservabilityMetrics(
    totalRuns: 0,
    failedRuns: 0,
    successfulRuns: 0,
    totalCostCents: 0,
    totalInputTokens: 0,
    totalOutputTokens: 0,
    totalCacheReadTokens: 0,
    totalCacheWriteTokens: 0,
    totalReasoningTokens: 0,
    errorRate: 0,
    cacheRate: 0,
    avgDurationMs: 0,
    avgTtftMs: 0,
    tokensPerSecond: 0,
    firstRun: null,
    lastRun: null,
    verifiedSuccessfulRuns: 0,
    successRate: 0,
    verifiedSuccessRate: 0,
    totalCostMicros: 0,
    inclusiveCostMicros: 0,
  );

  /// Total number of runs in the aggregation window.
  final int totalRuns;

  /// Number of runs whose status was [RunStatus.error].
  final int failedRuns;

  /// Number of runs whose status was [RunStatus.completed].
  final int successfulRuns;

  /// Total estimated cost in US cents, summed over every run's `cost`.
  final int totalCostCents;

  /// Total input tokens across all runs.
  final int totalInputTokens;

  /// Total output tokens across all runs.
  final int totalOutputTokens;

  /// Total cache-read (cache-hit) tokens across all runs.
  final int totalCacheReadTokens;

  /// Total cache-write tokens across all runs.
  final int totalCacheWriteTokens;

  /// Total reasoning / thought tokens across all runs.
  final int totalReasoningTokens;

  /// Fraction of runs that failed (`failedRuns / totalRuns`); `0` when there
  /// are no runs.
  final double errorRate;

  /// Cache effectiveness as `cacheRead / (input + cacheRead + cacheWrite)`;
  /// `0` when that denominator is zero.
  ///
  /// Every prompt token the provider processed is in the denominator, so a run
  /// that keeps rebuilding its cached prefix scores low rather than scoring
  /// like one that never needed a cache.
  final double cacheRate;

  /// Mean `cost.durationMs` over runs that recorded a duration; `0` when none
  /// did.
  final double avgDurationMs;

  /// Mean `cost.timeToFirstTokenMs` over runs that recorded one; `0` when none
  /// did.
  ///
  /// MIXED SEMANTICS across history: runs written before stage timing carried a
  /// first-VISIBLE-TEXT-derived value, newer ones carry a provider-observed
  /// TTFB/TTFT or nothing. Use `LatencyBreakdownCalculator` (p50/p95 per stage)
  /// for any latency claim that must be exact.
  final double avgTtftMs;

  /// Output-token throughput: total output tokens of runs with a positive
  /// duration divided by the total of those runs' durations in seconds; `0`
  /// when no run has a positive duration.
  final double tokensPerSecond;

  /// Earliest `startedAt` across all runs, or `null` when there are no runs.
  final DateTime? firstRun;

  /// Latest `startedAt` across all runs, or `null` when there are no runs.
  final DateTime? lastRun;

  /// Number of runs that both completed AND passed an independent verifier.
  ///
  /// The distinction [successfulRuns] alone cannot make: a run can exit
  /// cleanly and still fail its verifier, and a cost-per-success figure built
  /// on [successfulRuns] improves simply by lowering quality.
  final int verifiedSuccessfulRuns;

  /// `successfulRuns / totalRuns` — COMPLETED runs, whether or not anything
  /// checked them.
  final double successRate;

  /// `verifiedSuccessfulRuns / totalRuns` — independently VERIFIED successes.
  /// Always `<=` [successRate].
  final double verifiedSuccessRate;

  /// Total exact cost in micro-USD for the aggregation window, counting each
  /// run's OWN spend exactly once.
  ///
  /// Hierarchy-safe by construction: a parent's delegated spend lives on its
  /// child rows, so summing self costs can never double count a subtree however
  /// the set is composed.
  final int totalCostMicros;

  /// Total cost in micro-USD INCLUDING propagated subagent rollups, for runs
  /// whose parent is not itself in the set.
  ///
  /// A child present in the set is folded into its parent's rollup and never
  /// added again, so this equals [totalCostMicros] for a parent/child-closed set
  /// and exceeds it when the set omits children (the tree view asks "what did
  /// this conversation cost including delegation").
  final int inclusiveCostMicros;

  /// Runs whose status was [RunStatus.pending] or [RunStatus.running].
  ///
  /// While this is non-zero the window is still moving, so
  /// [inclusiveCostMicros] MUST NOT be read as final: a running parent's
  /// delegated spend has not been propagated yet, and "no difference between
  /// inclusive and self cost" then means "the rollup has not landed", not "this
  /// run delegated nothing".
  final int activeRuns;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObservabilityMetrics &&
          totalRuns == other.totalRuns &&
          failedRuns == other.failedRuns &&
          successfulRuns == other.successfulRuns &&
          totalCostCents == other.totalCostCents &&
          totalInputTokens == other.totalInputTokens &&
          totalOutputTokens == other.totalOutputTokens &&
          totalCacheReadTokens == other.totalCacheReadTokens &&
          totalCacheWriteTokens == other.totalCacheWriteTokens &&
          totalReasoningTokens == other.totalReasoningTokens &&
          errorRate == other.errorRate &&
          cacheRate == other.cacheRate &&
          avgDurationMs == other.avgDurationMs &&
          avgTtftMs == other.avgTtftMs &&
          tokensPerSecond == other.tokensPerSecond &&
          firstRun == other.firstRun &&
          lastRun == other.lastRun &&
          verifiedSuccessfulRuns == other.verifiedSuccessfulRuns &&
          successRate == other.successRate &&
          verifiedSuccessRate == other.verifiedSuccessRate &&
          totalCostMicros == other.totalCostMicros &&
          inclusiveCostMicros == other.inclusiveCostMicros &&
          activeRuns == other.activeRuns;

  @override
  int get hashCode => Object.hashAll([
    totalRuns,
    failedRuns,
    successfulRuns,
    totalCostCents,
    totalInputTokens,
    totalOutputTokens,
    totalCacheReadTokens,
    totalCacheWriteTokens,
    totalReasoningTokens,
    errorRate,
    cacheRate,
    avgDurationMs,
    avgTtftMs,
    tokensPerSecond,
    firstRun,
    lastRun,
    verifiedSuccessfulRuns,
    successRate,
    verifiedSuccessRate,
    totalCostMicros,
    inclusiveCostMicros,
    activeRuns,
  ]);
}

/// A single point in a time series of runs, aggregating the runs that started
/// within one bucket window (an hour or a day).
class TimeBucket {
  /// Creates a [TimeBucket].
  const TimeBucket({
    required this.bucketStart,
    required this.runs,
    required this.errors,
    required this.tokens,
    required this.costCents,
  });

  /// The floored start of this bucket window (e.g. `DateTime(y, m, d, h)` for
  /// hourly buckets, `DateTime(y, m, d)` for daily buckets).
  final DateTime bucketStart;

  /// Number of runs that started within this bucket.
  final int runs;

  /// Number of those runs whose status was [RunStatus.error].
  final int errors;

  /// Total tokens across all five usage axes for the runs in this bucket.
  final int tokens;

  /// Total estimated cost in US cents for the runs in this bucket.
  final int costCents;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeBucket &&
          bucketStart == other.bucketStart &&
          runs == other.runs &&
          errors == other.errors &&
          tokens == other.tokens &&
          costCents == other.costCents;

  @override
  int get hashCode => Object.hash(bucketStart, runs, errors, tokens, costCents);
}

/// Computes [ObservabilityMetrics] and time-series breakdowns over a collection
/// of [AgentRunLog]s, with no infrastructure dependencies.
///
/// A run is treated as **failed** when its [AgentRunLog.status] is [RunStatus.error] and as **successful** when it is [RunStatus.completed]; pending/running runs count toward [ObservabilityMetrics.totalRuns] but neither bucket.
class ObservabilityMetricsCalculator {
  /// Creates an [ObservabilityMetricsCalculator].
  const ObservabilityMetricsCalculator();

  /// Aggregates [runs] into a single [ObservabilityMetrics] snapshot.
  ///
  /// Returns [ObservabilityMetrics.empty] for an empty input. All ratio fields
  /// are guarded against division by zero.
  ObservabilityMetrics compute(Iterable<AgentRunLog> runs) {
    // Materialize once: the hierarchy pass needs every id BEFORE any cost is
    // summed, and an [Iterable] may be a single-use stream.
    final all = runs.toList(growable: false);
    if (all.isEmpty) {
      return ObservabilityMetrics.empty;
    }
    final ids = {for (final run in all) run.id};

    var totalRuns = 0;
    var failedRuns = 0;
    var successfulRuns = 0;
    var verifiedSuccessfulRuns = 0;
    var activeRuns = 0;
    var totalCostMicros = 0;
    var inclusiveCostMicros = 0;
    var totalInputTokens = 0;
    var totalOutputTokens = 0;
    var totalCacheReadTokens = 0;
    var totalCacheWriteTokens = 0;
    var totalReasoningTokens = 0;

    // Latency averages only include runs that actually recorded a measurement,
    // so a missing value never drags an average toward zero.
    var durationSum = 0;
    var durationCount = 0;
    var ttftSum = 0;
    var ttftCount = 0;

    // Throughput pairs output tokens with the seconds spent producing them,
    // restricted to runs with a strictly positive duration.
    var throughputOutputTokens = 0;
    var throughputDurationMs = 0;

    DateTime? firstRun;
    DateTime? lastRun;

    for (final run in all) {
      totalRuns++;
      if (run.status == RunStatus.error) {
        failedRuns++;
      } else if (run.status == RunStatus.completed) {
        successfulRuns++;
        if (run.verification.isVerifiedSuccess) {
          verifiedSuccessfulRuns++;
        }
      } else {
        activeRuns++;
      }

      final cost = run.cost;
      // Each run's OWN spend counts exactly once. A parent's delegated cost is
      // only ever its children's own rows, so this is hierarchy-safe for ANY
      // composition of the input set — and it is why the total cannot be
      // inflated by summing both a parent's rollup and its child rows.
      totalCostMicros += cost.preciseCostMicros;
      // The inclusive tree total adds a run's propagated child rollup only when
      // its parent is absent from the set; a child that IS present is already
      // included on its parent's row and must not be added twice.
      final parentRunId = run.parentRunId;
      if (parentRunId == null || !ids.contains(parentRunId)) {
        inclusiveCostMicros += run.totalCostMicrosWithChildren;
      }
      totalInputTokens += cost.inputTokens;
      totalOutputTokens += cost.outputTokens;
      totalCacheReadTokens += cost.cachedReadTokens;
      totalCacheWriteTokens += cost.cachedWriteTokens;
      totalReasoningTokens += cost.thoughtTokens;

      final durationMs = cost.durationMs;
      if (durationMs != null) {
        durationSum += durationMs;
        durationCount++;
        if (durationMs > 0) {
          throughputOutputTokens += cost.outputTokens;
          throughputDurationMs += durationMs;
        }
      }

      final ttftMs = cost.timeToFirstTokenMs;
      if (ttftMs != null) {
        ttftSum += ttftMs;
        ttftCount++;
      }

      final startedAt = run.startedAt;
      if (firstRun == null || startedAt.isBefore(firstRun)) {
        firstRun = startedAt;
      }
      if (lastRun == null || startedAt.isAfter(lastRun)) {
        lastRun = startedAt;
      }
    }

    // Cache-write tokens belong in the denominator: they are prompt tokens the
    // provider charged at a PREMIUM because nothing matched. Leaving them out
    // scored a run that rebuilt its whole prefix every turn — the exact
    // pathology this number exists to catch — the same as one that never
    // needed to, because a cache write reports zero `input_tokens`.
    final cacheDenominator =
        totalInputTokens + totalCacheReadTokens + totalCacheWriteTokens;

    return ObservabilityMetrics(
      totalRuns: totalRuns,
      failedRuns: failedRuns,
      successfulRuns: successfulRuns,
      verifiedSuccessfulRuns: verifiedSuccessfulRuns,
      totalCostCents: (totalCostMicros / 10000).round(),
      totalCostMicros: totalCostMicros,
      inclusiveCostMicros: inclusiveCostMicros,
      activeRuns: activeRuns,
      totalInputTokens: totalInputTokens,
      totalOutputTokens: totalOutputTokens,
      totalCacheReadTokens: totalCacheReadTokens,
      totalCacheWriteTokens: totalCacheWriteTokens,
      totalReasoningTokens: totalReasoningTokens,
      errorRate: failedRuns / totalRuns,
      successRate: successfulRuns / totalRuns,
      verifiedSuccessRate: verifiedSuccessfulRuns / totalRuns,
      cacheRate: cacheDenominator == 0
          ? 0
          : totalCacheReadTokens / cacheDenominator,
      avgDurationMs: durationCount == 0 ? 0 : durationSum / durationCount,
      avgTtftMs: ttftCount == 0 ? 0 : ttftSum / ttftCount,
      tokensPerSecond: throughputDurationMs == 0
          ? 0
          : throughputOutputTokens / (throughputDurationMs / 1000),
      firstRun: firstRun,
      lastRun: lastRun,
    );
  }

  /// Buckets [runs] by the hour their `startedAt` falls in
  /// (`DateTime(y, m, d, h)`), returning the buckets sorted ascending by
  /// [TimeBucket.bucketStart]. Empty input yields an empty list.
  List<TimeBucket> hourlySeries(Iterable<AgentRunLog> runs) =>
      _series(runs, _floorToHour);

  /// Buckets [runs] by the day their `startedAt` falls in
  /// (`DateTime(y, m, d)`), returning the buckets sorted ascending by
  /// [TimeBucket.bucketStart]. Empty input yields an empty list.
  List<TimeBucket> dailySeries(Iterable<AgentRunLog> runs) =>
      _series(runs, _floorToDay);

  /// Shared bucketing core: folds each run into the bucket produced by [floor],
  /// then returns the buckets sorted ascending by their start.
  List<TimeBucket> _series(
    Iterable<AgentRunLog> runs,
    DateTime Function(DateTime) floor,
  ) {
    final accumulators = <DateTime, _BucketAccumulator>{};
    for (final run in runs) {
      final key = floor(run.startedAt);
      final acc = accumulators.putIfAbsent(key, () => _BucketAccumulator(key));
      acc.runs++;
      if (run.status == RunStatus.error) {
        acc.errors++;
      }
      acc.tokens += run.cost.totalTokens;
      acc.costCents += run.cost.estimatedCostCents;
    }

    final buckets = accumulators.values.map((a) => a.toBucket()).toList()
      ..sort((a, b) => a.bucketStart.compareTo(b.bucketStart));
    return buckets;
  }

  /// Floors [t] to the start of its hour, dropping minutes/seconds/sub-second.
  static DateTime _floorToHour(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour);

  /// Floors [t] to the start of its day, dropping the time-of-day.
  static DateTime _floorToDay(DateTime t) => DateTime(t.year, t.month, t.day);
}

/// Mutable running total for one time bucket, folded to an immutable
/// [TimeBucket] once all runs are accounted for.
class _BucketAccumulator {
  /// Creates an accumulator anchored at [bucketStart].
  _BucketAccumulator(this.bucketStart);

  /// The floored bucket window start.
  final DateTime bucketStart;

  /// Running count of runs in this bucket.
  int runs = 0;

  /// Running count of failed runs in this bucket.
  int errors = 0;

  /// Running sum of all-axis tokens in this bucket.
  int tokens = 0;

  /// Running sum of cost in US cents in this bucket.
  int costCents = 0;

  /// Snapshots the running totals into an immutable [TimeBucket].
  TimeBucket toBucket() => TimeBucket(
    bucketStart: bucketStart,
    runs: runs,
    errors: errors,
    tokens: tokens,
    costCents: costCents,
  );
}
