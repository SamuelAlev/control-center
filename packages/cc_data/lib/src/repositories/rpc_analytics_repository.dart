import 'package:cc_data/src/repositories/remote_analytics_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/analytics/domain/entities/achievement.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:cc_domain/features/analytics/domain/entities/leaderboard_entry.dart';
import 'package:cc_domain/features/analytics/domain/entities/streak.dart';
import 'package:cc_domain/features/analytics/domain/entities/workspace_health.dart';
import 'package:cc_domain/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [AnalyticsRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `analytics.*` ops + the
/// `analytics.watch*` subscriptions, mapping the DTO wire shapes back to the
/// analytics entities. The host is the single source of truth and owns all
/// persistence; this client never touches a database.
///
/// Every interface method takes a leading `workspaceId` (the workspace-isolation
/// contract), but it is NOT sent over the wire: the host injects the
/// authoritative bound workspace per session (`session/set_workspace`) and
/// scopes every query by it, so the client's `workspaceId` arg is validated
/// server-side via the session binding. The maintenance reconcilers
/// (`rebuildDailyStats` / `backfillHistoricalData`) run host-side and throw
/// [UnsupportedError] (never reached from the UI).
class RpcAnalyticsRepository implements AnalyticsRepository {
  /// Creates an [RpcAnalyticsRepository] over [client].
  RpcAnalyticsRepository(RemoteRpcClient client)
    : _remote = RemoteAnalyticsRepository(client);

  final RemoteAnalyticsRepository _remote;

  static DateTime _parse(String? iso) => iso == null
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.parse(iso);

  static AgentDailyStats _statsFromDto(AgentDailyStatsDto d) => AgentDailyStats(
    id: d.id,
    agentId: d.agentId,
    date: _parse(d.date),
    runsCompleted: d.runsCompleted,
    runsErrored: d.runsErrored,
    totalRunDurationMs: d.totalRunDurationMs,
    prsCreated: d.prsCreated,
    prsMerged: d.prsMerged,
    reviewsCompleted: d.reviewsCompleted,
    blockingComments: d.blockingComments,
    linesAdded: d.linesAdded,
    linesDeleted: d.linesDeleted,
    xpEarned: d.xpEarned,
    createdAt: _parse(d.createdAt),
  );

  static Streak _streakFromDto(StreakDto d) => Streak(
    id: d.id,
    agentId: d.agentId,
    streakType: d.streakType,
    currentCount: d.currentCount,
    bestCount: d.bestCount,
    lastDate: d.lastDate == null ? null : DateTime.parse(d.lastDate!),
    updatedAt: _parse(d.updatedAt),
  );

  static Achievement _achievementFromDto(AchievementDto d) => Achievement(
    id: d.id,
    agentId: d.agentId,
    badgeKey: d.badgeKey,
    unlockedAt: _parse(d.unlockedAt),
    metadata: d.metadata,
  );

  static AgentScorecard _scorecardFromDto(AgentScorecardDto d) => AgentScorecard(
    agentId: d.agentId,
    agentName: d.agentName,
    totalRuns: d.totalRuns,
    totalErrored: d.totalErrored,
    successRate: d.successRate,
    avgRunDurationMs: d.avgRunDurationMs,
    totalPrsCreated: d.totalPrsCreated,
    totalPrsMerged: d.totalPrsMerged,
    totalReviews: d.totalReviews,
    totalBlockingComments: d.totalBlockingComments,
    totalXp: d.totalXp,
    level: d.level,
    levelProgress: d.levelProgress,
    currentStreaks: d.currentStreaks.map(_streakFromDto).toList(),
    achievements: d.achievements.map(_achievementFromDto).toList(),
  );

  static LeaderboardEntry _entryFromDto(LeaderboardEntryDto d) =>
      LeaderboardEntry(
        agentId: d.agentId,
        agentName: d.agentName,
        score: d.score,
        rank: d.rank,
      );

  static WorkspaceHealth _healthFromDto(WorkspaceHealthDto d) => WorkspaceHealth(
    workspaceId: d.workspaceId,
    workspaceName: d.workspaceName,
    score: d.score,
    activityScore: d.activityScore,
    throughputScore: d.throughputScore,
    reviewHealthScore: d.reviewHealthScore,
    successRateScore: d.successRateScore,
    activeAgents: d.activeAgents,
    totalAgents: d.totalAgents,
    prsMergedThisWeek: d.prsMergedThisWeek,
    openPRs: d.openPRs,
    stalePRs: d.stalePRs,
    totalRuns: d.totalRuns,
    erroredRuns: d.erroredRuns,
  );

  @override
  Stream<List<AgentDailyStats>> watchByAgent(
    String workspaceId,
    String agentId,
  ) => _remote
      .watchByAgent(agentId)
      .map((list) => list.map(_statsFromDto).toList());

  @override
  Stream<List<AgentDailyStats>> watchByAgentDateRange(
    String workspaceId,
    String agentId,
    DateTime start,
    DateTime end,
  ) => _remote
      .watchByAgentDateRange(agentId, start, end)
      .map((list) => list.map(_statsFromDto).toList());

  @override
  Stream<List<AgentDailyStats>> watchAllByDateRange(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) => _remote
      .watchAllByDateRange(start, end)
      .map((list) => list.map(_statsFromDto).toList());

  @override
  Future<AgentScorecard?> getAgentScorecard(
    String workspaceId,
    String agentId,
  ) async {
    final dto = await _remote.getAgentScorecard(agentId);
    return dto == null ? null : _scorecardFromDto(dto);
  }

  @override
  Future<List<AgentScorecard>> getAllAgentScorecards(String workspaceId) async {
    final dtos = await _remote.getAllAgentScorecards();
    return dtos.map(_scorecardFromDto).toList();
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) async {
    final dtos = await _remote.getLeaderboard(start, end);
    return dtos.map(_entryFromDto).toList();
  }

  @override
  Future<WorkspaceHealth?> getWorkspaceHealth(String workspaceId) async {
    final dto = await _remote.getWorkspaceHealth();
    return dto == null ? null : _healthFromDto(dto);
  }

  @override
  Future<List<WorkspaceHealth>> getAllWorkspaceHealth() async {
    final dtos = await _remote.getAllWorkspaceHealth();
    return dtos.map(_healthFromDto).toList();
  }

  // ---- Maintenance reconcilers: run host-side, never reached from the UI. ----

  @override
  Future<void> rebuildDailyStats() =>
      throw UnsupportedError('rebuildDailyStats runs server-side');

  @override
  Future<void> backfillHistoricalData() =>
      throw UnsupportedError('backfillHistoricalData runs server-side');
}
