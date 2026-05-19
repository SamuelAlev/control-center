import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/observability/domain/usage_stats.dart';
import 'package:control_center/features/observability/providers/observability_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Usage state + derivation (the observability "Usage" tab) ─────────────────
//
// Like the Insights surfaces, everything here derives CLIENT-SIDE from the
// existing [workspaceRunLogsProvider] feed — no new persisted surface and no
// new RPC op. The headline strip and the activity grid read the UNFILTERED
// feed (they are lifetime figures); the trend chart and the model split read
// the trailing window picked by [usageTrendRangeProvider].

/// The trailing window the trend chart and the model split cover.
enum UsageTrendRange {
  /// The trailing 7 days.
  last7d,

  /// The trailing 30 days.
  last30d;

  /// How many days back the window reaches, inclusive of today.
  int get days => switch (this) {
    UsageTrendRange.last7d => 7,
    UsageTrendRange.last30d => 30,
  };
}

/// The shared pure calculator behind every Usage surface.
final usageStatsCalculatorProvider = Provider<UsageStatsCalculator>(
  (ref) => const UsageStatsCalculator(),
);

/// How the token-activity grid values each day. NOT auto-dispose: the tab view
/// tears the unselected tab's subtree down (it holds no `IndexedStack`), so an
/// auto-disposing selection would silently snap back to daily on every tab
/// switch.
final usageActivityModeProvider =
    NotifierProvider<UsageActivityModeNotifier, UsageActivityMode>(
      UsageActivityModeNotifier.new,
    );

/// Holds the [UsageActivityMode] selection.
class UsageActivityModeNotifier extends Notifier<UsageActivityMode> {
  @override
  UsageActivityMode build() => UsageActivityMode.daily;

  /// Selects [mode].
  void setMode(UsageActivityMode mode) => state = mode;
}

/// The trend/model window. NOT auto-dispose, for the same reason as
/// [usageActivityModeProvider].
final usageTrendRangeProvider =
    NotifierProvider<UsageTrendRangeNotifier, UsageTrendRange>(
      UsageTrendRangeNotifier.new,
    );

/// Holds the [UsageTrendRange] selection.
class UsageTrendRangeNotifier extends Notifier<UsageTrendRange> {
  @override
  UsageTrendRange build() => UsageTrendRange.last30d;

  /// Selects [range].
  void setRange(UsageTrendRange range) => state = range;
}

// ── Pure helpers (unit-tested directly) ──────────────────────────────────────

/// The inclusive first day of [range] relative to [now], floored to local
/// midnight. A 7-day window covers today plus the six days before it, so the
/// rendered axis holds exactly [UsageTrendRange.days] points.
DateTime usageTrendStart(UsageTrendRange range, DateTime now) {
  final today = UsageStatsCalculator.floorToDay(now);
  return today.subtract(Duration(days: range.days - 1));
}

/// Narrows [runs] to those that started on or after [start].
List<AgentRunLog> runsSince(List<AgentRunLog> runs, DateTime start) => [
  for (final run in runs)
    if (!run.startedAt.isBefore(start)) run,
];

// ── Derived providers ────────────────────────────────────────────────────────

/// Runs inside the active trend window, over the whole workspace feed.
final usageTrendRunsProvider = Provider.autoDispose<List<AgentRunLog>>((ref) {
  final runs = ref.watch(workspaceRunLogsProvider);
  final range = ref.watch(usageTrendRangeProvider);
  return runsSince(runs, usageTrendStart(range, DateTime.now()));
});

/// The lifetime headline figures: totals, peak day, longest session, streaks.
final usageSummaryProvider = Provider.autoDispose<UsageSummary>((ref) {
  final runs = ref.watch(workspaceRunLogsProvider);
  return ref
      .watch(usageStatsCalculatorProvider)
      .summarize(runs, today: DateTime.now());
});

/// The trailing-year token-activity grid under the active mode.
final usageActivityGridProvider = Provider.autoDispose<UsageActivityGrid>((
  ref,
) {
  final runs = ref.watch(workspaceRunLogsProvider);
  final mode = ref.watch(usageActivityModeProvider);
  return ref
      .watch(usageStatsCalculatorProvider)
      .activityGrid(runs, today: DateTime.now(), mode: mode);
});

/// One dense daily series per model across the active trend window.
final usageTrendSeriesProvider = Provider.autoDispose<List<UsageTrendSeries>>((
  ref,
) {
  final runs = ref.watch(usageTrendRunsProvider);
  final range = ref.watch(usageTrendRangeProvider);
  final now = DateTime.now();
  return ref
      .watch(usageStatsCalculatorProvider)
      .trend(
        runs,
        start: usageTrendStart(range, now),
        end: UsageStatsCalculator.floorToDay(now),
      );
});

/// The per-model token split across the active trend window.
final usageModelSlicesProvider = Provider.autoDispose<List<UsageModelSlice>>((
  ref,
) {
  final runs = ref.watch(usageTrendRunsProvider);
  return ref.watch(usageStatsCalculatorProvider).byModel(runs);
});
