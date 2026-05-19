import 'package:cc_domain/features/analytics/domain/entities/achievement.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:cc_domain/features/analytics/domain/entities/leaderboard_entry.dart';
import 'package:cc_domain/features/analytics/domain/entities/streak.dart';
import 'package:cc_domain/features/analytics/domain/entities/workspace_health.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/analytics/domain/entities/user_badge.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Data providers ──
//
// Every analytics read is workspace-scoped: the agent-keyed `.family(agentId)`
// providers read `activeWorkspaceIdProvider` internally and pass
// `(workspaceId, agentId)`; the screen-level "all agents / leaderboard"
// providers are scoped to the active workspace too. When there is no active
// workspace they return an empty state rather than leaking another workspace's
// data.

/// Provider for an agent's scorecard by agent ID (scoped to the active workspace).
final agentScorecardProvider = FutureProvider.family<AgentScorecard?, String>((
  ref,
  agentId,
) async {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getAgentScorecard(workspaceId, agentId);
});

/// Provider for scorecards of all agents in the active workspace.
final allAgentScorecardsProvider = FutureProvider<List<AgentScorecard>>((ref) async {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return const [];
  }
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getAllAgentScorecards(workspaceId);
});

/// Leaderboard window.
class LeaderboardWindow {
  /// Creates a new [LeaderboardWindow].
  const LeaderboardWindow(this.start, this.end, this.label);
  /// Start of the window.
  final DateTime start;
  /// End of the window.
  final DateTime end;
  /// Human-readable label (e.g., 'Today').
  final String label;
}

/// Leaderboard window notifier.
class LeaderboardWindowNotifier extends Notifier<LeaderboardWindow> {
  @override
  LeaderboardWindow build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return LeaderboardWindow(today, now, 'Today');
  }

  /// Updates the current leaderboard window.
  void setWindow(LeaderboardWindow window) {
    state = window;
  }
}

/// Provider for the selected leaderboard time window.
final leaderboardWindowProvider = NotifierProvider<LeaderboardWindowNotifier, LeaderboardWindow>(
  LeaderboardWindowNotifier.new,
);

/// Provider for the leaderboard entries within the selected window, scoped to
/// the active workspace.
final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return const [];
  }
  final window = ref.watch(leaderboardWindowProvider);
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getLeaderboard(workspaceId, window.start, window.end);
});

/// Provider for a single workspace's health by workspace ID.
final workspaceHealthProvider = FutureProvider.family<WorkspaceHealth?, String>((
  ref,
  workspaceId,
) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getWorkspaceHealth(workspaceId);
});

/// Provider for health metrics of all workspaces (cross-org dashboard pulse).
final allWorkspaceHealthProvider = FutureProvider<List<WorkspaceHealth>>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getAllWorkspaceHealth();
});

/// Stream provider for an agent's achievements by agent ID (scoped to the
/// active workspace).
final agentAchievementsProvider = StreamProvider.family<List<Achievement>, String>((
  ref,
  agentId,
) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.watchByAgent(workspaceId, agentId);
});

/// Stream provider for an agent's streaks by agent ID (scoped to the active
/// workspace).
final agentStreaksProvider = StreamProvider.family<List<Streak>, String>((
  ref,
  agentId,
) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(streakRepositoryProvider);
  return repo.watchByAgent(workspaceId, agentId);
});

/// Stream provider for an agent's daily stats by agent ID (scoped to the active
/// workspace).
final agentDailyStatsProvider = StreamProvider.family<List<AgentDailyStats>, String>((
  ref,
  agentId,
) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.watchByAgent(workspaceId, agentId);
});

/// Stream provider for an agent's daily stats within a date range (scoped to
/// the active workspace).
final dailyStatsByDateRangeProvider = StreamProvider.family<List<AgentDailyStats>, ({String agentId, DateTime start, DateTime end})>((
  ref,
  params,
) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.watchByAgentDateRange(workspaceId, params.agentId, params.start, params.end);
});

/// Stream provider for daily stats of all agents within a date range, scoped to
/// the active workspace.
final allDailyStatsByDateRangeProvider = StreamProvider.family<List<AgentDailyStats>, ({DateTime start, DateTime end})>((
  ref,
  params,
) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.watchAllByDateRange(workspaceId, params.start, params.end);
});

// ── User badges ──

/// User-facing badge progress across every [userBadgeCategories] category.
///
/// Derived from existing aggregates so it doesn't require a new DB table:
///   * prompter — total agent runs (every run is a user prompt)
///   * reviewer — total reviews completed
///   * shipper — total PRs merged
///   * mentor  — total blocking review comments
///   * explorer — number of workspaces
final userBadgesProvider = FutureProvider<List<UserBadge>>((ref) async {
  final scorecards = await ref.watch(allAgentScorecardsProvider.future);
  final workspaces = ref.watch(workspacesProvider).value ?? const [];

  var prompts = 0;
  var reviews = 0;
  var merged = 0;
  var blocking = 0;
  for (final c in scorecards) {
    prompts += c.totalRuns;
    reviews += c.totalReviews;
    merged += c.totalPrsMerged;
    blocking += c.totalBlockingComments;
  }

  final counts = <String, int>{
    'prompter': prompts,
    'reviewer': reviews,
    'shipper': merged,
    'mentor': blocking,
    'explorer': workspaces.length,
  };

  return [
    for (final cat in userBadgeCategories)
      UserBadge(category: cat, count: counts[cat.key] ?? 0),
  ];
});
