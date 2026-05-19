import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/analytics/domain/entities/achievement.dart';
import 'package:control_center/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:control_center/features/analytics/domain/entities/streak.dart';

/// Analytics mappers.
class AnalyticsMappers {
  /// To domain.
  AgentDailyStats toDomain(AgentDailyStatsTableData row) => AgentDailyStats(
    id: row.id,
    agentId: row.agentId,
    date: row.date,
    runsCompleted: row.runsCompleted,
    runsErrored: row.runsErrored,
    totalRunDurationMs: row.totalRunDurationMs,
    prsCreated: row.prsCreated,
    prsMerged: row.prsMerged,
    reviewsCompleted: row.reviewsCompleted,
    blockingComments: row.blockingComments,
    linesAdded: row.linesAdded,
    linesDeleted: row.linesDeleted,
    xpEarned: row.xpEarned,
    createdAt: row.createdAt,
  );

  /// To domain list.
  List<AgentDailyStats> toDomainList(List<AgentDailyStatsTableData> rows) =>
      rows.map(toDomain).toList();

  /// Achievement to domain.
  Achievement achievementToDomain(AchievementsTableData row) => Achievement(
    id: row.id,
    agentId: row.agentId,
    badgeKey: row.badgeKey,
    unlockedAt: row.unlockedAt,
    metadata: row.metadata,
  );

  /// Achievements to domain.
  List<Achievement> achievementsToDomain(List<AchievementsTableData> rows) =>
      rows.map(achievementToDomain).toList();

  /// Streak to domain.
  Streak streakToDomain(StreaksTableData row) => Streak(
    id: row.id,
    agentId: row.agentId,
    streakType: row.streakType,
    currentCount: row.currentCount,
    bestCount: row.bestCount,
    lastDate: row.lastDate,
    updatedAt: row.updatedAt,
  );

  /// Streaks to domain.
  List<Streak> streaksToDomain(List<StreaksTableData> rows) =>
      rows.map(streakToDomain).toList();
}

