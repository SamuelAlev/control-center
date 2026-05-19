import 'package:control_center/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:control_center/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:control_center/features/analytics/domain/entities/leaderboard_entry.dart';
import 'package:control_center/features/analytics/domain/entities/workspace_health.dart';

/// Analytics repository.
abstract class AnalyticsRepository {
  /// Watches daily stats for a specific agent as a stream.
  Stream<List<AgentDailyStats>> watchByAgent(String agentId);
  /// Watches daily stats for a specific agent within a date range.
  Stream<List<AgentDailyStats>> watchByAgentDateRange(String agentId, DateTime start, DateTime end);
  /// Watches daily stats for all agents within a date range.
  Stream<List<AgentDailyStats>> watchAllByDateRange(DateTime start, DateTime end);
  /// Get agent scorecard.
  Future<AgentScorecard?> getAgentScorecard(String agentId);
  /// Retrieves scorecards for all agents.
  Future<List<AgentScorecard>> getAllAgentScorecards();
  /// Retrieves the leaderboard for a date range.
  Future<List<LeaderboardEntry>> getLeaderboard(DateTime start, DateTime end);
  /// Get workspace health.
  Future<WorkspaceHealth?> getWorkspaceHealth(String workspaceId);
  /// Retrieves health metrics for all workspaces.
  Future<List<WorkspaceHealth>> getAllWorkspaceHealth();
  /// Rebuild daily stats.
  Future<void> rebuildDailyStats();
  /// Backfill historical data.
  Future<void> backfillHistoricalData();
}
