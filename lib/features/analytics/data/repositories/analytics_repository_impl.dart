import 'dart:math';

import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/agent_dao.dart';
import 'package:control_center/core/database/daos/analytics_dao.dart';
import 'package:control_center/core/database/daos/pull_request_dao.dart';
import 'package:control_center/core/database/daos/workspace_dao.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/analytics/data/mappers/analytics_mappers.dart';
import 'package:control_center/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:control_center/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:control_center/features/analytics/domain/entities/leaderboard_entry.dart';
import 'package:control_center/features/analytics/domain/entities/workspace_health.dart';
import 'package:control_center/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Analytics repository impl.
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  /// Creates a new [Analytics repository impl].
  AnalyticsRepositoryImpl(
    this._analyticsDao,
    this._agentDao,
    this._pullRequestDao,
    this._workspaceDao,
  );

  final AnalyticsDao _analyticsDao;
  final AgentDao _agentDao;
  final PullRequestDao _pullRequestDao;
  final WorkspaceDao _workspaceDao;
  final _mappers = AnalyticsMappers();

  @override
  Stream<List<AgentDailyStats>> watchByAgent(String agentId) =>
      _analyticsDao.watchByAgent(agentId).map(_mappers.toDomainList);

  @override
  Stream<List<AgentDailyStats>> watchByAgentDateRange(
    String agentId,
    DateTime start,
    DateTime end,
  ) =>
      _analyticsDao
          .watchByAgentAndDateRange(agentId, start, end)
          .map(_mappers.toDomainList);

  @override
  Stream<List<AgentDailyStats>> watchAllByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      _analyticsDao
          .watchAllByDateRange(start, end)
          .map(_mappers.toDomainList);

  @override
  Future<AgentScorecard?> getAgentScorecard(String agentId) async {
    final agent = await _agentDao.getById(agentId);
    if (agent == null) {
      return null;
    }
    final allStats = await _analyticsDao.getByAgent(agentId);
    if (allStats.isEmpty) {
      return AgentScorecard(
        agentId: agentId,
        agentName: agent.name,
        totalRuns: 0,
        totalErrored: 0,
        successRate: 0,
        avgRunDurationMs: 0,
        totalPrsCreated: 0,
        totalPrsMerged: 0,
        totalReviews: 0,
        totalBlockingComments: 0,
        totalXp: 0,
        level: 0,
        levelProgress: 0,
        currentStreaks: const [],
        achievements: const [],
      );
    }

    final totalRuns = allStats.fold<int>(0, (s, e) => s + e.runsCompleted);
    final totalErrored = allStats.fold<int>(0, (s, e) => s + e.runsErrored);
    final totalAttempts = totalRuns + totalErrored;
    final totalDuration = allStats.fold<int>(0, (s, e) => s + e.totalRunDurationMs);
    final prsCreated = allStats.fold<int>(0, (s, e) => s + e.prsCreated);
    final prsMerged = allStats.fold<int>(0, (s, e) => s + e.prsMerged);
    final reviewsDone = allStats.fold<int>(0, (s, e) => s + e.reviewsCompleted);
    final blockingComments = allStats.fold<int>(0, (s, e) => s + e.blockingComments);
    final totalXp = allStats.fold<int>(0, (s, e) => s + e.xpEarned);

    final successRate = totalAttempts > 0 ? totalRuns / totalAttempts : 0.0;
    final avgDuration = totalAttempts > 0 ? totalDuration ~/ totalAttempts : 0;

    final level = _calculateLevel(totalXp);
    final levelProgress = _calculateLevelProgress(totalXp, level);

    return AgentScorecard(
      agentId: agentId,
      agentName: agent.name,
      totalRuns: totalRuns,
      totalErrored: totalErrored,
      successRate: successRate,
      avgRunDurationMs: avgDuration,
      totalPrsCreated: prsCreated,
      totalPrsMerged: prsMerged,
      totalReviews: reviewsDone,
      totalBlockingComments: blockingComments,
      totalXp: totalXp,
      level: level,
      levelProgress: levelProgress,
      currentStreaks: const [],
      achievements: const [],
    );
  }

  @override
  Future<List<AgentScorecard>> getAllAgentScorecards() async {
    final agents = await _agentDao.getAll();
    final results = <AgentScorecard>[];
    for (final agent in agents) {
      final card = await getAgentScorecard(agent.id);
      if (card != null) {
        results.add(card);
      }
    }
    return results;
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard(
    DateTime start,
    DateTime end,
  ) async {
    final stats = await _analyticsDao.getAllByDateRange(start, end);
    final agents = await _agentDao.getAll();
    final agentMap = {for (final a in agents) a.id: a.name};

    final scored = <_AgentScore>[];
    for (final s in stats) {
      final name = agentMap[s.agentId] ?? 'Unknown';
      final score = s.runsCompleted * 1 +
          s.prsCreated * 5 +
          s.prsMerged * 10 +
          s.reviewsCompleted * 6 +
          s.blockingComments * 3 -
          s.runsErrored * 2;
      scored.add(_AgentScore(s.agentId, name, score));
    }

    final grouped = <String, _AgentScore>{};
    for (final s in scored) {
      final existing = grouped[s.agentId];
      if (existing != null) {
        grouped[s.agentId] = _AgentScore(s.agentId, s.agentName, existing.score + s.score);
      } else {
        grouped[s.agentId] = s;
      }
    }

    final sorted = grouped.values.toList()..sort((a, b) => b.score.compareTo(a.score));

    return [
      for (var i = 0; i < sorted.length; i++)
        LeaderboardEntry(
          agentId: sorted[i].agentId,
          agentName: sorted[i].agentName,
          score: sorted[i].score,
          rank: i + 1,
        ),
    ];
  }

  @override
  Future<WorkspaceHealth?> getWorkspaceHealth(String workspaceId) async {
    final ws = await _workspaceDao.getById(workspaceId);
    if (ws == null) {
      return null;
    }

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final agentIds = <String>{};
    int totalRuns = 0;
    int erroredRuns = 0;
    try {
      // TODO: Use a SQL WHERE clause (watchLogsByWorkspace) instead of in-memory filtering
      final logs = await _agentDao.watchAllLogs().first;
      for (final l in logs) {
        if (l.workspaceId == workspaceId) {
          agentIds.add(l.agentId);
          if (l.startedAt.isAfter(thirtyDaysAgo)) {
            if (l.status == 'completed') {
              totalRuns++;
            } else if (l.status == 'errored' || l.status == 'error') {
              erroredRuns++;
            }
          }
        }
      }
    } catch (_) {
      AppLog.w('AnalyticsRepositoryImpl', 'Failed to watch all logs for workspace health');
    }

    final activeAgents = agentIds.length;
    final totalAgents = (await _agentDao.getAll()).length;

    // Compute PRs merged this week from daily stats (global, not workspace-scoped)
    int prsMergedThisWeek = 0;
    try {
      final allStats = await _analyticsDao.getAllByDateRange(weekAgo, now);
      prsMergedThisWeek = allStats.fold<int>(0, (s, e) => s + e.prsMerged);
    } catch (_) {
      AppLog.w('AnalyticsRepositoryImpl', 'Failed to get PR merge stats for date range');
    }

    int totalOpenPRs = 0;
    int stalePRs = 0;
    try {
      final prs = await _pullRequestDao.watchByWorkspace(workspaceId).first;
      totalOpenPRs = prs.length;
      stalePRs = prs.where((p) {
        if (p.createdAt.isBefore(now.subtract(const Duration(days: 14)))) {
          return p.mergedAt == null && p.closedAt == null;
        }
        return false;
      }).length;
    } catch (_) {
      AppLog.w('AnalyticsRepositoryImpl', 'Failed to watch PRs for workspace health');
    }

    final activity = (activeAgents / max(totalAgents, 1) * 30).clamp(0.0, 30.0);
    final throughput = (prsMergedThisWeek / 5.0 * 25.0).clamp(0.0, 25.0);
    final reviewHealth = ((1 - stalePRs / max(totalOpenPRs, 1)) * 25.0).clamp(0.0, 25.0);
    final successRate = ((1 - erroredRuns / max(totalRuns + erroredRuns, 1)) * 20.0).clamp(0.0, 20.0);
    final health = activity + throughput + reviewHealth + successRate;

    return WorkspaceHealth(
      workspaceId: workspaceId,
      workspaceName: ws.name,
      score: health,
      activityScore: activity,
      throughputScore: throughput,
      reviewHealthScore: reviewHealth,
      successRateScore: successRate,
      activeAgents: activeAgents,
      totalAgents: totalAgents,
      prsMergedThisWeek: prsMergedThisWeek,
      openPRs: totalOpenPRs,
      stalePRs: stalePRs,
      totalRuns: totalRuns,
      erroredRuns: erroredRuns,
    );
  }

  @override
  Future<List<WorkspaceHealth>> getAllWorkspaceHealth() async {
    final workspaces = await _workspaceDao.getAll();
    final results = <WorkspaceHealth>[];
    for (final ws in workspaces) {
      final h = await getWorkspaceHealth(ws.id);
      if (h != null) {
        results.add(h);
      }
    }
    return results;
  }

  @override
  Future<void> rebuildDailyStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final agents = await _agentDao.getAll();

    for (final agent in agents) {
      final runs = await _agentDao.watchLogsByAgent(agent.id).first;
      final todayRuns = runs.where((r) {
        return r.startedAt.isAfter(today);
      });

      final completedRuns = todayRuns.where((r) => r.status == 'completed').length;
      final erroredRuns = todayRuns.where((r) => r.status == 'errored' || r.status == 'error').length;
      final totalDuration = todayRuns
          .where((r) => r.completedAt != null)
          .fold<int>(0, (s, r) => s + r.completedAt!.difference(r.startedAt).inMilliseconds);

      final existing = await _analyticsDao.getByAgentAndDate(agent.id, today);
      const uuid = Uuid();

      await _analyticsDao.upsertDailyStats(
        AgentDailyStatsTableCompanion.insert(
          id: existing?.id ?? uuid.v4(),
          agentId: agent.id,
          date: today,
          runsCompleted: drift.Value(completedRuns),
          runsErrored: drift.Value(erroredRuns),
          totalRunDurationMs: drift.Value(totalDuration),
          xpEarned: drift.Value(existing?.xpEarned ?? 0),
        ),
      );
    }
  }

  @override
  Future<void> backfillHistoricalData() async {
    final agents = await _agentDao.getAll();
    const uuid = Uuid();

    for (final agent in agents) {
      final runs = await _agentDao.watchLogsByAgent(agent.id).first;
      final grouped = <DateTime, List<AgentRunLogsTableData>>{};
      for (final r in runs) {
        final day = DateTime(r.startedAt.year, r.startedAt.month, r.startedAt.day);
        grouped.putIfAbsent(day, () => []).add(r);
      }

      for (final entry in grouped.entries) {
        final dayRuns = entry.value;
        final completed = dayRuns.where((r) => r.status == 'completed').length;
        final errored = dayRuns.where((r) => r.status == 'errored' || r.status == 'error').length;
        final duration = dayRuns
            .where((r) => r.completedAt != null)
            .fold<int>(0, (s, r) => s + r.completedAt!.difference(r.startedAt).inMilliseconds);

        final existing = await _analyticsDao.getByAgentAndDate(agent.id, entry.key);

        await _analyticsDao.upsertDailyStats(
          AgentDailyStatsTableCompanion.insert(
            id: existing?.id ?? uuid.v4(),
            agentId: agent.id,
            date: entry.key,
            runsCompleted: drift.Value(completed),
            runsErrored: drift.Value(errored),
            totalRunDurationMs: drift.Value(duration),
          ),
        );
      }
    }
  }

  int _calculateLevel(int totalXp) {
    return sqrt(totalXp / 100).floor();
  }

  double _calculateLevelProgress(int totalXp, int level) {
    final currentLevelXp = level * level * 100;
    final nextLevelXp = (level + 1) * (level + 1) * 100;
    final xpNeeded = nextLevelXp - currentLevelXp;
    if (xpNeeded == 0) {
      return 1.0;
    }
    return (totalXp - currentLevelXp) / xpNeeded;
  }
}

class _AgentScore {
  _AgentScore(this.agentId, this.agentName, this.score);
  final String agentId;
  final String agentName;
  final int score;
}
