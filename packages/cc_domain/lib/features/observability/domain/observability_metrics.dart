import 'package:cc_domain/core/domain/entities/agent_run_log.dart';

/// Aggregate observability metrics computed over a set of [AgentRunLog]s.
///
/// Run counts, an error rate, token totals across all five usage axes, cache
/// effectiveness, latency averages and an output-token throughput figure.
/// All derived ratios are guarded against division by zero — an empty input
/// yields a fully zeroed instance with null [firstRun] / [lastRun].
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

  /// Cache effectiveness as `cacheRead / (input + cacheRead)`; `0` when that
  /// denominator is zero.
  final double cacheRate;

  /// Mean `cost.durationMs` over runs that recorded a duration; `0` when none
  /// did.
  final double avgDurationMs;

  /// Mean `cost.timeToFirstTokenMs` over runs that recorded one; `0` when none
  /// did.
  final double avgTtftMs;

  /// Output-token throughput: total output tokens of runs with a positive
  /// duration divided by the total of those runs' durations in seconds; `0`
  /// when no run has a positive duration.
  final double tokensPerSecond;

  /// Earliest `startedAt` across all runs, or `null` when there are no runs.
  final DateTime? firstRun;

  /// Latest `startedAt` across all runs, or `null` when there are no runs.
  final DateTime? lastRun;

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
          lastRun == other.lastRun;

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
    var totalRuns = 0;
    var failedRuns = 0;
    var successfulRuns = 0;
    var totalCostCents = 0;
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

    for (final run in runs) {
      totalRuns++;
      if (run.status == RunStatus.error) {
        failedRuns++;
      } else if (run.status == RunStatus.completed) {
        successfulRuns++;
      }

      final cost = run.cost;
      totalCostCents += cost.estimatedCostCents;
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

    if (totalRuns == 0) {
      return ObservabilityMetrics.empty;
    }

    final cacheDenominator = totalInputTokens + totalCacheReadTokens;

    return ObservabilityMetrics(
      totalRuns: totalRuns,
      failedRuns: failedRuns,
      successfulRuns: successfulRuns,
      totalCostCents: totalCostCents,
      totalInputTokens: totalInputTokens,
      totalOutputTokens: totalOutputTokens,
      totalCacheReadTokens: totalCacheReadTokens,
      totalCacheWriteTokens: totalCacheWriteTokens,
      totalReasoningTokens: totalReasoningTokens,
      errorRate: failedRuns / totalRuns,
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
