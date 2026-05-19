import 'package:cc_domain/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:cc_domain/features/analytics/domain/entities/leaderboard_entry.dart';
import 'package:cc_domain/features/analytics/domain/entities/workspace_health.dart';

/// Analytics repository.
///
/// Every agent-keyed read takes a required `workspaceId` (first positional)
/// and is scoped to that workspace via a JOIN on Agents — a foreign agent
/// simply yields no rows. The screen-level "all agents / leaderboard" reads are
/// likewise workspace-scoped: the analytics view shows the current workspace,
/// never data from another. See the workspace-isolation invariant in CLAUDE.md.
abstract class AnalyticsRepository {
  /// Watches daily stats for a specific agent within [workspaceId] as a stream.
  Stream<List<AgentDailyStats>> watchByAgent(String workspaceId, String agentId);
  /// Watches daily stats for a specific agent within [workspaceId] and a date range.
  Stream<List<AgentDailyStats>> watchByAgentDateRange(String workspaceId, String agentId, DateTime start, DateTime end);
  /// Watches daily stats for all agents in [workspaceId] within a date range.
  Stream<List<AgentDailyStats>> watchAllByDateRange(String workspaceId, DateTime start, DateTime end);
  /// Get agent scorecard for an agent in [workspaceId].
  Future<AgentScorecard?> getAgentScorecard(String workspaceId, String agentId);
  /// Retrieves scorecards for all agents in [workspaceId].
  Future<List<AgentScorecard>> getAllAgentScorecards(String workspaceId);
  /// Retrieves the leaderboard for [workspaceId] within a date range.
  Future<List<LeaderboardEntry>> getLeaderboard(String workspaceId, DateTime start, DateTime end);
  /// Get workspace health.
  Future<WorkspaceHealth?> getWorkspaceHealth(String workspaceId);
  /// Retrieves health metrics for all workspaces.
  ///
  /// CROSS-WORKSPACE BY DESIGN — the cross-org dashboard "workspace pulse" view
  /// intentionally spans every workspace. For a single workspace's health use
  /// [getWorkspaceHealth] with its `workspaceId`.
  Future<List<WorkspaceHealth>> getAllWorkspaceHealth();
  /// Rebuild daily stats (startup/maintenance reconciler over all agents).
  Future<void> rebuildDailyStats();
  /// Backfill historical data (maintenance reconciler over all agents).
  Future<void> backfillHistoricalData();
}
