import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';

/// Token usage broken down across the five tracked token axes, plus the
/// estimated cost in US cents those tokens accrued.
///
/// The five axes mirror the per-run [RunCost] categories:
/// * [input] — prompt / input tokens (`RunCost.inputTokens`).
/// * [output] — completion / output tokens (`RunCost.outputTokens`).
/// * [reasoning] — thinking / reasoning tokens (`RunCost.thoughtTokens`).
/// * [cacheRead] — cache-hit read tokens (`RunCost.cachedReadTokens`).
/// * [cacheWrite] — cache-hit write tokens (`RunCost.cachedWriteTokens`).
///
/// [costCents] is summed independently of the token axes (a run reports its
/// own estimated cost in cents) so callers never have to re-derive price.
class TokenAxisTotals {
  /// Creates a [TokenAxisTotals] with explicit per-axis token counts and cost.
  const TokenAxisTotals({
    this.input = 0,
    this.output = 0,
    this.reasoning = 0,
    this.cacheRead = 0,
    this.cacheWrite = 0,
    this.costCents = 0,
  });

  /// Builds a [TokenAxisTotals] from a single run's [RunCost], mapping
  /// `thoughtTokens` to [reasoning] and the `cached*` fields to the cache axes.
  factory TokenAxisTotals.fromRunCost(RunCost cost) => TokenAxisTotals(
    input: cost.inputTokens,
    output: cost.outputTokens,
    reasoning: cost.thoughtTokens,
    cacheRead: cost.cachedReadTokens,
    cacheWrite: cost.cachedWriteTokens,
    costCents: cost.estimatedCostCents,
  );

  /// Prompt / input tokens.
  final int input;

  /// Completion / output tokens.
  final int output;

  /// Thinking / reasoning tokens.
  final int reasoning;

  /// Cache-hit read tokens.
  final int cacheRead;

  /// Cache-hit write tokens.
  final int cacheWrite;

  /// Estimated cost in US cents accrued by these tokens.
  final int costCents;

  /// Sum of all five token axes (cost is excluded — it is not a token count).
  int get total => input + output + reasoning + cacheRead + cacheWrite;

  /// Merges two [TokenAxisTotals], summing every axis and the cost.
  TokenAxisTotals operator +(TokenAxisTotals other) => TokenAxisTotals(
    input: input + other.input,
    output: output + other.output,
    reasoning: reasoning + other.reasoning,
    cacheRead: cacheRead + other.cacheRead,
    cacheWrite: cacheWrite + other.cacheWrite,
    costCents: costCents + other.costCents,
  );

  /// Empty totals with every axis and cost at zero.
  static const TokenAxisTotals zero = TokenAxisTotals();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenAxisTotals &&
          runtimeType == other.runtimeType &&
          input == other.input &&
          output == other.output &&
          reasoning == other.reasoning &&
          cacheRead == other.cacheRead &&
          cacheWrite == other.cacheWrite &&
          costCents == other.costCents;

  @override
  int get hashCode =>
      Object.hash(input, output, reasoning, cacheRead, cacheWrite, costCents);
}

/// Cost and token usage attributed to each agent role (main / sub / advisor).
///
/// Each axis-total carries its own [TokenAxisTotals.costCents], so the
/// per-role cost getters read straight off the corresponding bucket.
class RoleCostBreakdown {
  /// Creates a [RoleCostBreakdown] from the three per-role totals.
  const RoleCostBreakdown({
    this.main = TokenAxisTotals.zero,
    this.sub = TokenAxisTotals.zero,
    this.advisor = TokenAxisTotals.zero,
  });

  /// Usage attributed to top-level driving ([AgentRunRole.main]) runs.
  final TokenAxisTotals main;

  /// Usage attributed to subagent ([AgentRunRole.sub]) runs.
  final TokenAxisTotals sub;

  /// Usage attributed to advisor / shadow-reviewer ([AgentRunRole.advisor])
  /// runs.
  final TokenAxisTotals advisor;

  /// Cost in US cents attributed to main runs.
  int get mainCostCents => main.costCents;

  /// Cost in US cents attributed to subagent runs.
  int get subCostCents => sub.costCents;

  /// Cost in US cents attributed to advisor runs.
  int get advisorCostCents => advisor.costCents;

  /// Combined cost in US cents across all three roles.
  int get totalCostCents => mainCostCents + subCostCents + advisorCostCents;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleCostBreakdown &&
          runtimeType == other.runtimeType &&
          main == other.main &&
          sub == other.sub &&
          advisor == other.advisor;

  @override
  int get hashCode => Object.hash(main, sub, advisor);
}

/// Aggregated token usage for a single model (grouped by `modelId` when
/// present, falling back to the adapter name).
class ModelUsage {
  /// Creates a [ModelUsage].
  const ModelUsage({
    required this.model,
    required this.runs,
    required this.tokens,
  });

  /// Model id (preferred), or adapter name when the run recorded no model id,
  /// or `'unknown'` when neither was recorded.
  final String model;

  /// Number of runs attributed to this model.
  final int runs;

  /// Token and cost totals for this model.
  final TokenAxisTotals tokens;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelUsage &&
          runtimeType == other.runtimeType &&
          model == other.model &&
          runs == other.runs &&
          tokens == other.tokens;

  @override
  int get hashCode => Object.hash(model, runs, tokens);
}

/// Aggregated token usage for a single calendar day.
class DayUsage {
  /// Creates a [DayUsage].
  const DayUsage({required this.day, required this.runs, required this.tokens});

  /// The day these totals cover, normalized to local midnight (date-only:
  /// `DateTime(year, month, day)`).
  final DateTime day;

  /// Number of runs that started on this day.
  final int runs;

  /// Token and cost totals for this day.
  final TokenAxisTotals tokens;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayUsage &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          runs == other.runs &&
          tokens == other.tokens;

  @override
  int get hashCode => Object.hash(day, runs, tokens);
}

/// The full result of aggregating a collection of [AgentRunLog]s across the
/// five token axes, per role, per model, and per day.
class TokenAggregation {
  /// Creates a [TokenAggregation].
  const TokenAggregation({
    required this.totals,
    required this.byRole,
    required this.byModel,
    required this.byDay,
    required this.medianRunTokens,
    required this.runCount,
  });

  /// Empty aggregation, the result of aggregating an empty run set.
  static const TokenAggregation empty = TokenAggregation(
    totals: TokenAxisTotals.zero,
    byRole: RoleCostBreakdown(),
    byModel: <ModelUsage>[],
    byDay: <DayUsage>[],
    medianRunTokens: 0,
    runCount: 0,
  );

  /// Grand total token usage and cost across every run.
  final TokenAxisTotals totals;

  /// Per-role (main / sub / advisor) cost and token attribution.
  final RoleCostBreakdown byRole;

  /// Per-model usage, sorted by [TokenAxisTotals.costCents] descending.
  final List<ModelUsage> byModel;

  /// Per-day usage, sorted by [DayUsage.day] ascending.
  final List<DayUsage> byDay;

  /// Median of each run's total token count across all runs. Zero when there
  /// are no runs; the average of the two middle values when the run count is
  /// even.
  final double medianRunTokens;

  /// Number of runs that were aggregated.
  final int runCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenAggregation &&
          runtimeType == other.runtimeType &&
          totals == other.totals &&
          byRole == other.byRole &&
          _listEquals(byModel, other.byModel) &&
          _listEquals(byDay, other.byDay) &&
          medianRunTokens == other.medianRunTokens &&
          runCount == other.runCount;

  @override
  int get hashCode => Object.hash(
    totals,
    byRole,
    Object.hashAll(byModel),
    Object.hashAll(byDay),
    medianRunTokens,
    runCount,
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Aggregates agent run logs into a [TokenAggregation]: a five-axis token
/// rollup with per-role cost attribution, per-model and per-day breakdowns, and
/// the median per-run token count.
///
/// Pure domain logic — it reads only the [AgentRunLog.cost], [AgentRunLog.role],
/// [AgentRunLog.modelId] (with [AgentRunLog.adapter] fallback) and
/// [AgentRunLog.startedAt] fields and performs no I/O.
class TokenAxisAggregator {
  /// Creates a [TokenAxisAggregator].
  const TokenAxisAggregator();

  /// Sentinel model key used when a run did not record an adapter name.
  static const String unknownModel = 'unknown';

  /// Aggregates [runs] into a [TokenAggregation].
  ///
  /// Returns [TokenAggregation.empty] for an empty input.
  TokenAggregation aggregate(Iterable<AgentRunLog> runs) {
    var totals = TokenAxisTotals.zero;
    var mainTotals = TokenAxisTotals.zero;
    var subTotals = TokenAxisTotals.zero;
    var advisorTotals = TokenAxisTotals.zero;

    // Insertion-ordered so models/days first seen keep a stable relative order
    // before the final sort, making the output deterministic.
    final modelRuns = <String, int>{};
    final modelTokens = <String, TokenAxisTotals>{};
    final dayRuns = <DateTime, int>{};
    final dayTokens = <DateTime, TokenAxisTotals>{};

    final perRunTotalTokens = <int>[];

    var runCount = 0;
    for (final run in runs) {
      runCount++;
      final axis = TokenAxisTotals.fromRunCost(run.cost);

      totals += axis;
      perRunTotalTokens.add(run.cost.totalTokens);

      switch (run.role) {
        case AgentRunRole.main:
          mainTotals += axis;
        case AgentRunRole.sub:
          subTotals += axis;
        case AgentRunRole.advisor:
          advisorTotals += axis;
      }

      final model = run.modelId ?? run.adapter ?? unknownModel;
      modelRuns[model] = (modelRuns[model] ?? 0) + 1;
      modelTokens[model] = (modelTokens[model] ?? TokenAxisTotals.zero) + axis;

      final day = _dateOnly(run.startedAt);
      dayRuns[day] = (dayRuns[day] ?? 0) + 1;
      dayTokens[day] = (dayTokens[day] ?? TokenAxisTotals.zero) + axis;
    }

    if (runCount == 0) {
      return TokenAggregation.empty;
    }

    final byModel = <ModelUsage>[
      for (final entry in modelTokens.entries)
        ModelUsage(
          model: entry.key,
          runs: modelRuns[entry.key] ?? 0,
          tokens: entry.value,
        ),
    ]..sort((a, b) => b.tokens.costCents.compareTo(a.tokens.costCents));

    final byDay = <DayUsage>[
      for (final entry in dayTokens.entries)
        DayUsage(
          day: entry.key,
          runs: dayRuns[entry.key] ?? 0,
          tokens: entry.value,
        ),
    ]..sort((a, b) => a.day.compareTo(b.day));

    return TokenAggregation(
      totals: totals,
      byRole: RoleCostBreakdown(
        main: mainTotals,
        sub: subTotals,
        advisor: advisorTotals,
      ),
      byModel: byModel,
      byDay: byDay,
      medianRunTokens: _median(perRunTotalTokens),
      runCount: runCount,
    );
  }

  /// Strips the time component off [moment], returning local midnight of the
  /// same calendar day.
  static DateTime _dateOnly(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  /// Computes the median of [values]. Returns `0` for an empty list, the middle
  /// element for an odd count, and the average of the two middle elements
  /// (as a [double], so half-values are not truncated) for an even count.
  ///
  /// Mutates a sorted copy, never the input.
  static double _median(List<int> values) {
    if (values.isEmpty) {
      return 0;
    }
    final sorted = List<int>.of(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[mid].toDouble();
    }
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }
}
