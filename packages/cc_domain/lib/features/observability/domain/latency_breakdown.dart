import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/observability/domain/run_stage.dart';

/// Warm/cold cache classification of a run, for latency grouping.
///
/// Derived from the run's own token axes rather than asserted, and kept
/// separate from an unknown because "the cache missed" and "nobody recorded
/// tokens" are different observations.
enum RunCacheState {
  /// The provider served at least part of the prompt from cache.
  warm,

  /// The run processed prompt tokens with NO cache hit.
  cold,

  /// The run reported no prompt tokens at all, so its cache behavior is
  /// unknown.
  unknown;

  /// Stable label used as a grouping key.
  String get wire {
    switch (this) {
      case RunCacheState.warm:
        return 'warm';
      case RunCacheState.cold:
        return 'cold';
      case RunCacheState.unknown:
        return 'unknown';
    }
  }

  /// Classifies [run] from its reported token axes.
  static RunCacheState of(AgentRunLog run) {
    if (run.cost.cachedReadTokens > 0) {
      return RunCacheState.warm;
    }
    if (run.cost.inputTokens > 0 || run.cost.cachedWriteTokens > 0) {
      return RunCacheState.cold;
    }
    return RunCacheState.unknown;
  }
}

/// A dimension a latency breakdown can be grouped by.
///
/// Every one of these is an ACTUAL attribute recorded on the run. Where the
/// attribute is missing the run forms a `null` group — it is never folded into
/// a real value.
enum RunLatencyDimension {
  /// [AgentRunLog.adapter].
  adapter,

  /// [AgentRunLog.modelId].
  model,

  /// [AgentRunLog.effort] — the effort actually executed at.
  effort,

  /// [AgentRunLog.taskFamily].
  taskFamily,

  /// [RunCacheState] derived from the run's tokens.
  cacheState;

  /// Reads this dimension's value off [run]; null means not recorded.
  String? valueOf(AgentRunLog run) {
    switch (this) {
      case RunLatencyDimension.adapter:
        return run.adapter;
      case RunLatencyDimension.model:
        return run.modelId;
      case RunLatencyDimension.effort:
        return run.effort;
      case RunLatencyDimension.taskFamily:
        return run.taskFamily;
      case RunLatencyDimension.cacheState:
        return RunCacheState.of(run).wire;
    }
  }

  /// Stable label for the group key.
  String get wire {
    switch (this) {
      case RunLatencyDimension.adapter:
        return 'adapter';
      case RunLatencyDimension.model:
        return 'model';
      case RunLatencyDimension.effort:
        return 'effort';
      case RunLatencyDimension.taskFamily:
        return 'task_family';
      case RunLatencyDimension.cacheState:
        return 'cache_state';
    }
  }
}

/// Linearly interpolated percentile summary of an integer millisecond sample.
///
/// Percentiles are the point: a mean latency hides exactly the tail an
/// efficiency claim is about (one cold tool-heavy turn), and p50 vs p95 is the
/// smallest pair that shows it. [count] is carried so a p95 over three samples
/// is visibly different from one over three hundred.
class LatencyPercentiles {
  /// Creates a summary from the computed sample statistics.
  LatencyPercentiles._({
    required this.count,
    required this.p50,
    required this.p95,
    required this.min,
    required this.max,
  });

  /// Summarizes [values]; null when the sample is empty (an unknown is not a
  /// zero).
  static LatencyPercentiles? of(List<int> values) {
    if (values.isEmpty) {
      return null;
    }
    final sorted = List<int>.of(values)..sort();
    return LatencyPercentiles._(
      count: sorted.length,
      p50: _percentile(sorted, 0.50),
      p95: _percentile(sorted, 0.95),
      min: sorted.first,
      max: sorted.last,
    );
  }

  /// Number of samples.
  final int count;

  /// Median.
  final double p50;

  /// 95th percentile.
  final double p95;

  /// Smallest sample.
  final int min;

  /// Largest sample.
  final int max;

  /// Linear-interpolation percentile over an ASCENDING list.
  ///
  /// Interpolating (rather than taking the nearest rank) keeps a 50th
  /// percentile meaningful on an even-sized sample instead of snapping to one
  /// side.
  static double _percentile(List<int> ascending, double fraction) {
    if (ascending.length == 1) {
      return ascending.first.toDouble();
    }
    final rank = fraction * (ascending.length - 1);
    final lower = rank.floor();
    final upper = rank.ceil();
    if (lower == upper) {
      return ascending[lower].toDouble();
    }
    final weight = rank - lower;
    return ascending[lower] * (1 - weight) + ascending[upper] * weight;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatencyPercentiles &&
          count == other.count &&
          p50 == other.p50 &&
          p95 == other.p95 &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode => Object.hash(count, p50, p95, min, max);

  @override
  String toString() =>
      'LatencyPercentiles(n=$count, p50=${p50.toStringAsFixed(1)}, '
      'p95=${p95.toStringAsFixed(1)}, min=$min, max=$max)';
}

/// Latency distribution over a set of runs, per stage.
///
/// Each stage's offsets are percentiled SEPARATELY and independently of the
/// others: a run that never reported a stage simply does not appear in that
/// stage's sample, so an unobservable provider TTFB never enters the TTFB
/// percentile as a zero.
class RunLatencyStats {
  /// Creates a distribution.
  const RunLatencyStats({
    required this.runCount,
    required this.stageOffsets,
    required this.stageDurations,
    required this.timeToFirstUsefulWorkMs,
    required this.transportTtfbMs,
    required this.providerTtftMs,
  });

  /// Distribution over an empty set.
  static const empty = RunLatencyStats(
    runCount: 0,
    stageOffsets: <RunStage, LatencyPercentiles>{},
    stageDurations: <RunStage, LatencyPercentiles>{},
    timeToFirstUsefulWorkMs: null,
    transportTtfbMs: null,
    providerTtftMs: null,
  );

  /// Number of runs in the sample.
  final int runCount;

  /// Per-stage offset-from-start distributions (only observed runs appear).
  final Map<RunStage, LatencyPercentiles> stageOffsets;

  /// Per-stage self-duration distributions (only spanned stages appear).
  final Map<RunStage, LatencyPercentiles> stageDurations;

  /// Distribution of `submitted → firstUsefulText`.
  final LatencyPercentiles? timeToFirstUsefulWorkMs;

  /// Distribution of `requestSent → firstResponseByte` (transport TTFB), from
  /// runs whose byte was actually observable.
  final LatencyPercentiles? transportTtfbMs;

  /// Distribution of `requestSent → firstModelDelta` (provider TTFT).
  final LatencyPercentiles? providerTtftMs;

  /// Offset distribution for one stage, or null when nothing reported it.
  LatencyPercentiles? offsetOf(RunStage stage) => stageOffsets[stage];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunLatencyStats &&
          runCount == other.runCount &&
          timeToFirstUsefulWorkMs == other.timeToFirstUsefulWorkMs &&
          transportTtfbMs == other.transportTtfbMs &&
          providerTtftMs == other.providerTtftMs &&
          _mapEquals(stageOffsets, other.stageOffsets) &&
          _mapEquals(stageDurations, other.stageDurations);

  @override
  int get hashCode => Object.hash(
    runCount,
    timeToFirstUsefulWorkMs,
    transportTtfbMs,
    providerTtftMs,
    Object.hashAll(RunStage.values.map((s) => Object.hash(s, stageOffsets[s]))),
    Object.hashAll(
      RunStage.values.map((s) => Object.hash(s, stageDurations[s])),
    ),
  );

  static bool _mapEquals(
    Map<RunStage, LatencyPercentiles> a,
    Map<RunStage, LatencyPercentiles> b,
  ) => a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}

/// One group of a [RunLatencyDimension] and its distribution.
class RunLatencyGroupStats {
  /// Creates a group result.
  const RunLatencyGroupStats({
    required this.dimension,
    required this.value,
    required this.stats,
  });

  /// Dimension this group keys on.
  final RunLatencyDimension dimension;

  /// The group's value, or null when the attribute was not recorded on any run
  /// in the group.
  final String? value;

  /// The group's latency distribution.
  final RunLatencyStats stats;

  /// Stable label for the group key (`<dimension>=<value|unknown>`).
  String get label => '${dimension.wire}=${value ?? 'unknown'}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunLatencyGroupStats &&
          dimension == other.dimension &&
          value == other.value &&
          stats == other.stats;

  @override
  int get hashCode => Object.hash(dimension, value, stats);
}

/// Computes p50/p95 latency distributions over [AgentRunLog]s, overall and
/// grouped by the run attributes that actually exist.
///
/// Pure domain: it reads only [AgentRunLog.latency], [AgentRunLog.adapter],
/// [AgentRunLog.modelId], [AgentRunLog.effort], [AgentRunLog.taskFamily] and the
/// token axes, and performs no I/O.
class LatencyBreakdownCalculator {
  /// Creates a calculator.
  const LatencyBreakdownCalculator();

  /// Overall distribution across [runs].
  RunLatencyStats overall(Iterable<AgentRunLog> runs) {
    final all = runs.toList(growable: false);
    return _stats(all);
  }

  /// Distribution per group of [dimension], ordered by group label so the
  /// output is stable across runs of the same input.
  List<RunLatencyGroupStats> grouped(
    Iterable<AgentRunLog> runs,
    RunLatencyDimension dimension,
  ) {
    final buckets = <String?, List<AgentRunLog>>{};
    for (final run in runs) {
      // A null key is a real bucket: "attribute not recorded" is a distinct
      // finding from "recorded at level X", and merging them would hide that
      // the attribute is missing on most runs.
      (buckets[dimension.valueOf(run)] ??= <AgentRunLog>[]).add(run);
    }
    final groups =
        [
          for (final entry in buckets.entries)
            RunLatencyGroupStats(
              dimension: dimension,
              value: entry.key,
              stats: _stats(entry.value),
            ),
        ]..sort((a, b) {
          // Unknown last, then alphabetical: a stable, readable order.
          if (a.value == null) {
            return b.value == null ? 0 : 1;
          }
          if (b.value == null) {
            return -1;
          }
          return a.value!.compareTo(b.value!);
        });
    return groups;
  }

  /// Breakdown across every dimension at once, keyed by [RunLatencyDimension].
  Map<RunLatencyDimension, List<RunLatencyGroupStats>> breakdown(
    Iterable<AgentRunLog> runs,
  ) {
    final all = runs.toList(growable: false);
    return {
      for (final dimension in RunLatencyDimension.values)
        dimension: grouped(all, dimension),
    };
  }

  RunLatencyStats _stats(List<AgentRunLog> runs) {
    if (runs.isEmpty) {
      return RunLatencyStats.empty;
    }
    final offsets = <RunStage, List<int>>{};
    final durations = <RunStage, List<int>>{};
    final usefulWork = <int>[];
    final ttfb = <int>[];
    final ttft = <int>[];

    for (final run in runs) {
      final profile = run.latency;
      for (final timing in profile.timings.values) {
        (offsets[timing.stage] ??= <int>[]).add(timing.offsetMs);
        final duration = timing.durationMs;
        if (duration != null) {
          (durations[timing.stage] ??= <int>[]).add(duration);
        }
      }
      final useful = profile.timeToFirstUsefulWorkMs;
      if (useful != null) {
        usefulWork.add(useful);
      }
      final ttfbMs = profile.transportTtfbMs;
      if (ttfbMs != null) {
        ttfb.add(ttfbMs);
      }
      final ttftMs = profile.providerTtftMs;
      if (ttftMs != null) {
        ttft.add(ttftMs);
      }
    }

    // A stage with no usable sample is ABSENT from the map, not present with a
    // zero: every consumer reads "no key" as unknown, which is the truth, while
    // a zero would be a fabricated measurement.
    final offsetStats = <RunStage, LatencyPercentiles>{};
    for (final entry in offsets.entries) {
      final stats = LatencyPercentiles.of(entry.value);
      if (stats != null) {
        offsetStats[entry.key] = stats;
      }
    }
    final durationStats = <RunStage, LatencyPercentiles>{};
    for (final entry in durations.entries) {
      final stats = LatencyPercentiles.of(entry.value);
      if (stats != null) {
        durationStats[entry.key] = stats;
      }
    }

    return RunLatencyStats(
      runCount: runs.length,
      stageOffsets: offsetStats,
      stageDurations: durationStats,
      timeToFirstUsefulWorkMs: LatencyPercentiles.of(usefulWork),
      transportTtfbMs: LatencyPercentiles.of(ttfb),
      providerTtftMs: LatencyPercentiles.of(ttft),
    );
  }
}
