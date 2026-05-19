import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/features/observability/domain/observability_metrics.dart';
import 'package:cc_domain/features/observability/domain/token_axis_aggregator.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/observability/providers/observability_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Insights state + derivation (the observability "Insights" tab) ───────────
//
// Everything here derives from the EXISTING [workspaceRunLogsProvider]; its
// semantics are unchanged — the Live tab's roster depends on the unfiltered
// list, so filtering happens in NEW providers layered on top.

/// The global time-range preset applied to every Insights surface.
enum ObsTimeRange {
  /// The trailing 24 hours (hourly buckets).
  last24h,

  /// The trailing 7 days (daily buckets).
  last7d,

  /// The trailing 30 days (daily buckets).
  last30d,

  /// Everything the run window holds (daily buckets, folded weekly when long).
  all;

  /// The trailing window this preset covers, or `null` for [all].
  Duration? get window => switch (this) {
    ObsTimeRange.last24h => const Duration(hours: 24),
    ObsTimeRange.last7d => const Duration(days: 7),
    ObsTimeRange.last30d => const Duration(days: 30),
    ObsTimeRange.all => null,
  };
}

/// The bucket granularity of a rendered time series.
enum ObsBucketKind {
  /// One bucket per hour.
  hour,

  /// One bucket per day.
  day,

  /// One bucket per ISO week (Monday-floored).
  week,
}

/// The faceted filter selection narrowing the Insights surfaces.
///
/// An empty set for a category means "pass all"; selections compose AND across
/// categories, OR within a category.
@immutable
class ObsRunFilters {
  /// Creates an [ObsRunFilters].
  const ObsRunFilters({
    this.agentIds = const {},
    this.modelKeys = const {},
    this.statuses = const {},
    this.roles = const {},
  });

  /// Selected agent ids ([AgentRunLog.agentId]).
  final Set<String> agentIds;

  /// Selected model keys (`run.modelId ?? run.adapter ?? ''`).
  final Set<String> modelKeys;

  /// Selected run statuses.
  final Set<RunStatus> statuses;

  /// Selected run roles.
  final Set<AgentRunRole> roles;

  /// Whether no facet is selected (everything passes).
  bool get isEmpty =>
      agentIds.isEmpty &&
      modelKeys.isEmpty &&
      statuses.isEmpty &&
      roles.isEmpty;

  /// Returns a copy with the given sets replaced.
  ObsRunFilters copyWith({
    Set<String>? agentIds,
    Set<String>? modelKeys,
    Set<RunStatus>? statuses,
    Set<AgentRunRole>? roles,
  }) {
    return ObsRunFilters(
      agentIds: agentIds ?? this.agentIds,
      modelKeys: modelKeys ?? this.modelKeys,
      statuses: statuses ?? this.statuses,
      roles: roles ?? this.roles,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObsRunFilters &&
          setEquals(agentIds, other.agentIds) &&
          setEquals(modelKeys, other.modelKeys) &&
          setEquals(statuses, other.statuses) &&
          setEquals(roles, other.roles);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(agentIds),
    Object.hashAllUnordered(modelKeys),
    Object.hashAllUnordered(statuses),
    Object.hashAllUnordered(roles),
  );
}

/// The active time-range preset. NOT auto-dispose: the selection survives tab
/// switches within the observability page.
final obsTimeRangeProvider =
    NotifierProvider<ObsTimeRangeNotifier, ObsTimeRange>(
      ObsTimeRangeNotifier.new,
    );

/// Holds the [ObsTimeRange] selection.
class ObsTimeRangeNotifier extends Notifier<ObsTimeRange> {
  @override
  ObsTimeRange build() => ObsTimeRange.last7d;

  /// Selects [range].
  void setRange(ObsTimeRange range) => state = range;
}

/// The active facet selection. NOT auto-dispose, for the same reason as
/// [obsTimeRangeProvider].
final obsRunFiltersProvider =
    NotifierProvider<ObsRunFiltersNotifier, ObsRunFilters>(
      ObsRunFiltersNotifier.new,
    );

/// Holds the [ObsRunFilters] selection with toggle/clear mutators.
class ObsRunFiltersNotifier extends Notifier<ObsRunFilters> {
  @override
  ObsRunFilters build() => const ObsRunFilters();

  /// Toggles [agentId] in the agent facet.
  void toggleAgent(String agentId) =>
      state = state.copyWith(agentIds: _toggle(state.agentIds, agentId));

  /// Toggles [modelKey] in the model facet.
  void toggleModel(String modelKey) =>
      state = state.copyWith(modelKeys: _toggle(state.modelKeys, modelKey));

  /// Toggles [status] in the status facet.
  void toggleStatus(RunStatus status) =>
      state = state.copyWith(statuses: _toggle(state.statuses, status));

  /// Toggles [role] in the role facet.
  void toggleRole(AgentRunRole role) =>
      state = state.copyWith(roles: _toggle(state.roles, role));

  /// Clears the agent facet.
  void clearAgents() => state = state.copyWith(agentIds: const {});

  /// Clears the model facet.
  void clearModels() => state = state.copyWith(modelKeys: const {});

  /// Clears the status facet.
  void clearStatuses() => state = state.copyWith(statuses: const {});

  /// Clears the role facet.
  void clearRoles() => state = state.copyWith(roles: const {});

  /// Clears every facet.
  void clearAll() => state = const ObsRunFilters();

  static Set<T> _toggle<T>(Set<T> set, T value) {
    final next = {...set};
    if (!next.remove(value)) {
      next.add(value);
    }
    return next;
  }
}

// ── Pure helpers (unit-tested directly) ──────────────────────────────────────

/// The inclusive start instant of [range] relative to [now], or `null` when
/// the range is unbounded ([ObsTimeRange.all]).
DateTime? obsRangeStart(ObsTimeRange range, DateTime now) {
  final window = range.window;
  return window == null ? null : now.subtract(window);
}

/// Narrows [runs] to those at-or-after [start] (inclusive; `null` = no bound)
/// and matching [filters]. AND across categories, OR within a category; an
/// empty filter set passes every run for that category.
List<AgentRunLog> filterRunLogs(
  List<AgentRunLog> runs, {
  DateTime? start,
  required ObsRunFilters filters,
}) {
  return [
    for (final run in runs)
      if ((start == null || !run.startedAt.isBefore(start)) &&
          (filters.agentIds.isEmpty ||
              filters.agentIds.contains(run.agentId)) &&
          (filters.modelKeys.isEmpty ||
              filters.modelKeys.contains(run.modelId ?? run.adapter ?? '')) &&
          (filters.statuses.isEmpty || filters.statuses.contains(run.status)) &&
          (filters.roles.isEmpty || filters.roles.contains(run.role)))
        run,
  ];
}

/// Folds [daily] buckets into Monday-floored weekly buckets, summing runs /
/// errors / tokens / cost, sorted ascending.
List<TimeBucket> foldToWeekly(List<TimeBucket> daily) {
  final weekly = <DateTime, TimeBucket>{};
  for (final bucket in daily) {
    final monday = bucket.bucketStart.subtract(
      Duration(days: bucket.bucketStart.weekday - 1),
    );
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final prev = weekly[weekStart];
    weekly[weekStart] = TimeBucket(
      bucketStart: weekStart,
      runs: (prev?.runs ?? 0) + bucket.runs,
      errors: (prev?.errors ?? 0) + bucket.errors,
      tokens: (prev?.tokens ?? 0) + bucket.tokens,
      costCents: (prev?.costCents ?? 0) + bucket.costCents,
    );
  }
  return weekly.values.toList()
    ..sort((a, b) => a.bucketStart.compareTo(b.bucketStart));
}

/// The most slots [padSeries] will materialize. Beyond it the span is not a
/// chart anyone reads, so the series is left as-is rather than expanded.
const int _maxPaddedBuckets = 4000;

/// Floors [t] to the start of its [kind] slot (week = Monday-floored, matching
/// [foldToWeekly]).
DateTime _floorToBucket(DateTime t, ObsBucketKind kind) => switch (kind) {
  ObsBucketKind.hour => DateTime(t.year, t.month, t.day, t.hour),
  ObsBucketKind.day => DateTime(t.year, t.month, t.day),
  ObsBucketKind.week => DateTime(
    t.year,
    t.month,
    t.day,
  ).subtract(Duration(days: t.weekday - 1)),
};

/// The start of the slot following [start]. Calendar arithmetic, not a
/// [Duration] add, so a day step stays a day across a DST shift.
DateTime _nextBucket(DateTime start, ObsBucketKind kind) => switch (kind) {
  ObsBucketKind.hour => DateTime(
    start.year,
    start.month,
    start.day,
    start.hour + 1,
  ),
  ObsBucketKind.day => DateTime(start.year, start.month, start.day + 1),
  ObsBucketKind.week => DateTime(start.year, start.month, start.day + 7),
};

/// Returns [buckets] expanded so every [kind] slot from [from] to [to] is
/// present, zero-filling the slots no run landed in.
///
/// A chart reads its bucket list as "the window", so an unpadded series is
/// read as a shorter range than the one that was picked: seven days holding
/// runs on two of them drew a two-point chart, and the cost line interpolated
/// straight across the five days that were not flat but simply absent. The
/// span is the UNION of `from`..`to` and the buckets already present, so
/// padding can never drop a run sitting just outside the nominal window.
List<TimeBucket> padSeries(
  List<TimeBucket> buckets,
  ObsBucketKind kind, {
  required DateTime from,
  required DateTime to,
}) {
  final byStart = {for (final bucket in buckets) bucket.bucketStart: bucket};
  var first = _floorToBucket(from, kind);
  var last = _floorToBucket(to, kind);
  for (final start in byStart.keys) {
    if (start.isBefore(first)) {
      first = start;
    }
    if (start.isAfter(last)) {
      last = start;
    }
  }
  if (last.isBefore(first)) {
    return buckets;
  }

  final padded = <TimeBucket>[];
  for (var cursor = first; !cursor.isAfter(last); ) {
    padded.add(
      byStart[cursor] ??
          TimeBucket(
            bucketStart: cursor,
            runs: 0,
            errors: 0,
            tokens: 0,
            costCents: 0,
          ),
    );
    if (padded.length >= _maxPaddedBuckets) {
      return buckets;
    }
    cursor = _nextBucket(cursor, kind);
  }
  return padded;
}

/// Selects the series granularity for [range] and buckets [runs] accordingly:
/// 24h → hourly; 7d/30d → daily; all → daily, folded weekly when the window
/// spans more than 62 days (keeps the chart readable).
///
/// The result always spans the WHOLE picked window (relative to [now]), gaps
/// zero-filled by [padSeries] — a range is a claim about time, not about the
/// days that happened to have runs in them.
({List<TimeBucket> buckets, ObsBucketKind kind}) bucketizeSeries(
  List<AgentRunLog> runs,
  ObsTimeRange range,
  ObservabilityMetricsCalculator calc, {
  required DateTime now,
}) {
  switch (range) {
    case ObsTimeRange.last24h:
      return (
        buckets: padSeries(
          calc.hourlySeries(runs),
          ObsBucketKind.hour,
          // 23 back + the current, partial slot = 24 hourly slots.
          from: now.subtract(const Duration(hours: 23)),
          to: now,
        ),
        kind: ObsBucketKind.hour,
      );
    case ObsTimeRange.last7d:
    case ObsTimeRange.last30d:
      final days = range == ObsTimeRange.last7d ? 7 : 30;
      return (
        buckets: padSeries(
          calc.dailySeries(runs),
          ObsBucketKind.day,
          from: now.subtract(Duration(days: days - 1)),
          to: now,
        ),
        kind: ObsBucketKind.day,
      );
    case ObsTimeRange.all:
      // Unbounded: the union in padSeries carries the span back to the oldest
      // run on its own, so only the trailing edge needs naming.
      final daily = padSeries(
        calc.dailySeries(runs),
        ObsBucketKind.day,
        from: now,
        to: now,
      );
      if (daily.length > 62) {
        return (buckets: foldToWeekly(daily), kind: ObsBucketKind.week);
      }
      return (buckets: daily, kind: ObsBucketKind.day);
  }
}

// ── Derived providers ────────────────────────────────────────────────────────

/// Runs inside the active time range, ignoring facet selections. Feeds the
/// filter-option counts so they stay stable while toggles change.
final rangeRunLogsProvider = Provider.autoDispose<List<AgentRunLog>>((ref) {
  final runs = ref.watch(workspaceRunLogsProvider);
  final start = obsRangeStart(ref.watch(obsTimeRangeProvider), DateTime.now());
  return filterRunLogs(runs, start: start, filters: const ObsRunFilters());
});

/// Runs inside the active time range AND matching the facet selection. The
/// single input every Insights surface reads.
final filteredRunLogsProvider = Provider.autoDispose<List<AgentRunLog>>((ref) {
  final runs = ref.watch(workspaceRunLogsProvider);
  final range = ref.watch(obsTimeRangeProvider);
  final filters = ref.watch(obsRunFiltersProvider);
  final start = obsRangeStart(range, DateTime.now());
  return filterRunLogs(runs, start: start, filters: filters);
});

/// Runs in the window immediately PRECEDING the active range
/// (from `start - window` up to `start`), for vs-previous-period deltas. Empty when the
/// [ObsTimeRange.all] (no previous period exists).
final previousWindowRunLogsProvider = Provider.autoDispose<List<AgentRunLog>>((
  ref,
) {
  final range = ref.watch(obsTimeRangeProvider);
  final window = range.window;
  if (window == null) {
    return const [];
  }
  final start = DateTime.now().subtract(window);
  final previousStart = start.subtract(window);
  final runs = ref.watch(workspaceRunLogsProvider);
  return [
    for (final run in runs)
      if (!run.startedAt.isBefore(previousStart) &&
          run.startedAt.isBefore(start))
        run,
  ];
});

/// Headline metrics over the filtered runs.
final insightsMetricsProvider = Provider.autoDispose<ObservabilityMetrics>((
  ref,
) {
  final runs = ref.watch(filteredRunLogsProvider);
  return ref.watch(observabilityMetricsCalculatorProvider).compute(runs);
});

/// Headline metrics over the previous window (delta denominators).
final insightsPreviousMetricsProvider =
    Provider.autoDispose<ObservabilityMetrics>((ref) {
      final runs = ref.watch(previousWindowRunLogsProvider);
      return ref.watch(observabilityMetricsCalculatorProvider).compute(runs);
    });

/// The 5-axis aggregation over the filtered runs.
final insightsTokenAggregationProvider = Provider.autoDispose<TokenAggregation>(
  (ref) {
    final runs = ref.watch(filteredRunLogsProvider);
    return ref.watch(tokenAxisAggregatorProvider).aggregate(runs);
  },
);

/// The bucketed activity/cost series over the filtered runs.
final insightsSeriesProvider =
    Provider.autoDispose<({List<TimeBucket> buckets, ObsBucketKind kind})>((
      ref,
    ) {
      final runs = ref.watch(filteredRunLogsProvider);
      final range = ref.watch(obsTimeRangeProvider);
      return bucketizeSeries(
        runs,
        range,
        ref.watch(observabilityMetricsCalculatorProvider),
        now: DateTime.now(),
      );
    });

/// One row of the per-agent Insights table.
@immutable
class AgentInsightRow {
  /// Creates an [AgentInsightRow].
  const AgentInsightRow({
    required this.agentId,
    required this.displayName,
    required this.runs,
    required this.errors,
    required this.costCents,
    required this.avgDurationMs,
    required this.lastActive,
  });

  /// The agent's id.
  final String agentId;

  /// Display name (agent name, falling back to the raw id).
  final String displayName;

  /// Runs attributed to this agent in the filtered set.
  final int runs;

  /// Of those, how many ended in [RunStatus.error].
  final int errors;

  /// Total estimated cost in US cents.
  final int costCents;

  /// Mean `cost.durationMs` over runs that recorded one; null when none did.
  final double? avgDurationMs;

  /// The agent's most recent `startedAt`.
  final DateTime lastActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentInsightRow &&
          agentId == other.agentId &&
          displayName == other.displayName &&
          runs == other.runs &&
          errors == other.errors &&
          costCents == other.costCents &&
          avgDurationMs == other.avgDurationMs &&
          lastActive == other.lastActive;

  @override
  int get hashCode => Object.hash(
    agentId,
    displayName,
    runs,
    errors,
    costCents,
    avgDurationMs,
    lastActive,
  );
}

/// The per-agent breakdown over the filtered runs, sorted by cost descending.
final insightsPerAgentProvider = Provider.autoDispose<List<AgentInsightRow>>((
  ref,
) {
  final runs = ref.watch(filteredRunLogsProvider);
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  final agents = workspaceId == null
      ? const <Agent>[]
      : ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
            const <Agent>[];
  final names = <String, String>{
    for (final agent in agents) agent.id: agent.name,
  };

  final grouped = <String, List<AgentRunLog>>{};
  for (final run in runs) {
    grouped.putIfAbsent(run.agentId, () => []).add(run);
  }

  final rows = <AgentInsightRow>[];
  for (final entry in grouped.entries) {
    var errors = 0;
    var costCents = 0;
    var durationSum = 0;
    var durationCount = 0;
    var lastActive = entry.value.first.startedAt;
    for (final run in entry.value) {
      if (run.status == RunStatus.error) {
        errors++;
      }
      costCents += run.cost.estimatedCostCents;
      final durationMs = run.cost.durationMs;
      if (durationMs != null) {
        durationSum += durationMs;
        durationCount++;
      }
      if (run.startedAt.isAfter(lastActive)) {
        lastActive = run.startedAt;
      }
    }
    rows.add(
      AgentInsightRow(
        agentId: entry.key,
        displayName: names[entry.key] ?? entry.key,
        runs: entry.value.length,
        errors: errors,
        costCents: costCents,
        avgDurationMs: durationCount == 0 ? null : durationSum / durationCount,
        lastActive: lastActive,
      ),
    );
  }
  rows.sort((a, b) => b.costCents.compareTo(a.costCents));
  return rows;
});

/// One selectable value in a filter category, with its population count.
@immutable
class ObsFilterOptionValue {
  /// Creates an [ObsFilterOptionValue].
  const ObsFilterOptionValue({
    required this.value,
    required this.label,
    required this.count,
  });

  /// The value toggled into the selection set (agent id, model key, enum name).
  final String value;

  /// The display label (enum-name values are translated by the UI).
  final String label;

  /// Runs matching this value inside the current time range.
  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObsFilterOptionValue &&
          value == other.value &&
          label == other.label &&
          count == other.count;

  @override
  int get hashCode => Object.hash(value, label, count);
}

/// The distinct values present in [rangeRunLogsProvider] per filter category.
///
/// Counts intentionally derive from the range-only set so they don't collapse
/// while the user toggles other facets.
final insightsFilterOptionsProvider =
    Provider.autoDispose<
      ({
        List<ObsFilterOptionValue> agents,
        List<ObsFilterOptionValue> models,
        List<ObsFilterOptionValue> statuses,
        List<ObsFilterOptionValue> roles,
      })
    >((ref) {
      final runs = ref.watch(rangeRunLogsProvider);
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      final agents = workspaceId == null
          ? const <Agent>[]
          : ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
                const <Agent>[];
      final names = <String, String>{
        for (final agent in agents) agent.id: agent.name,
      };

      final agentCounts = <String, int>{};
      final modelCounts = <String, int>{};
      final statusCounts = <RunStatus, int>{};
      final roleCounts = <AgentRunRole, int>{};
      for (final run in runs) {
        agentCounts.update(run.agentId, (c) => c + 1, ifAbsent: () => 1);
        final modelKey = run.modelId ?? run.adapter ?? '';
        modelCounts.update(modelKey, (c) => c + 1, ifAbsent: () => 1);
        statusCounts.update(run.status, (c) => c + 1, ifAbsent: () => 1);
        roleCounts.update(run.role, (c) => c + 1, ifAbsent: () => 1);
      }

      final agentOptions =
          [
            for (final entry in agentCounts.entries)
              ObsFilterOptionValue(
                value: entry.key,
                label: names[entry.key] ?? entry.key,
                count: entry.value,
              ),
          ]..sort((a, b) {
            final byCount = b.count.compareTo(a.count);
            return byCount != 0 ? byCount : a.label.compareTo(b.label);
          });
      final modelOptions =
          [
            for (final entry in modelCounts.entries)
              ObsFilterOptionValue(
                value: entry.key,
                label: entry.key.isEmpty ? '—' : entry.key,
                count: entry.value,
              ),
          ]..sort((a, b) {
            final byCount = b.count.compareTo(a.count);
            return byCount != 0 ? byCount : a.label.compareTo(b.label);
          });
      final statusOptions = [
        for (final status in RunStatus.values)
          if (statusCounts.containsKey(status))
            ObsFilterOptionValue(
              value: status.name,
              label: status.name,
              count: statusCounts[status]!,
            ),
      ];
      final roleOptions = [
        for (final role in AgentRunRole.values)
          if (roleCounts.containsKey(role))
            ObsFilterOptionValue(
              value: role.name,
              label: role.name,
              count: roleCounts[role]!,
            ),
      ];

      return (
        agents: agentOptions,
        models: modelOptions,
        statuses: statusOptions,
        roles: roleOptions,
      );
    });
