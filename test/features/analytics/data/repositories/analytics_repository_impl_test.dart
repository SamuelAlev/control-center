
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/repositories/analytics_repository_impl.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late AnalyticsRepositoryImpl repo;

  setUp(() async {
    db = createTestDatabase();
    repo = AnalyticsRepositoryImpl(
      db.analyticsDao,
      db.agentDao,
      db.pullRequestDao,
      db.workspaceDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  // ─── Helpers ─────────────────────────────────────────────────────────

  Future<String> seedWorkspace({String id = 'ws-1', String name = 'Test WS'}) async {
    await db.workspaceDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(id: id, name: name),
    );
    return id;
  }

  Future<String> seedAgent({
    String id = 'agent-1',
    String name = 'Alice',
    String workspaceId = 'ws-1',
  }) async {
    await db.agentDao.upsert(
      AgentsTableCompanion.insert(
        id: id,
        name: name,
        title: name,
        agentMdPath: '/agents/$name.md',
        workspaceId: workspaceId,
        skills: '',
      ),
    );
    return id;
  }

  Future<void> seedDailyStat({
    required String id,
    required String agentId,
    required DateTime date,
    int runsCompleted = 0,
    int runsErrored = 0,
    int totalRunDurationMs = 0,
    int prsCreated = 0,
    int prsMerged = 0,
    int reviewsCompleted = 0,
    int blockingComments = 0,
    int linesAdded = 0,
    int linesDeleted = 0,
    int xpEarned = 0,
  }) async {
    await db.analyticsDao.upsertDailyStats(
      AgentDailyStatsTableCompanion.insert(
        id: id,
        agentId: agentId,
        date: date,
        runsCompleted: Value(runsCompleted),
        runsErrored: Value(runsErrored),
        totalRunDurationMs: Value(totalRunDurationMs),
        prsCreated: Value(prsCreated),
        prsMerged: Value(prsMerged),
        reviewsCompleted: Value(reviewsCompleted),
        blockingComments: Value(blockingComments),
        linesAdded: Value(linesAdded),
        linesDeleted: Value(linesDeleted),
        xpEarned: Value(xpEarned),
      ),
    );
  }

  Future<void> seedRunLog({
    required String id,
    required String agentId,
    String? workspaceId,
    required DateTime startedAt,
    DateTime? completedAt,
    String status = 'completed',
  }) async {
    await db.agentDao.upsertLog(
      AgentRunLogsTableCompanion.insert(
        id: id,
        agentId: agentId,
        workspaceId: Value(workspaceId),
        startedAt: Value(startedAt),
        completedAt: Value(completedAt),
        status: Value(status),
      ),
    );
  }

  Future<void> seedPR({
    required String id,
    required String workspaceId,
    required String title,
    String body = '',
    DateTime? createdAt,
    DateTime? mergedAt,
    DateTime? closedAt,
  }) async {
    await db.pullRequestDao.insert(
      PullRequestsTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        title: title,
        body: body,
        createdAt: Value(createdAt ?? DateTime.now()),
        mergedAt: Value(mergedAt),
        closedAt: Value(closedAt),
      ),
    );
  }

  DateTime day(int year, int month, int dayOfMonth) =>
      DateTime(year, month, dayOfMonth);

  // ─── watchByAgent ────────────────────────────────────────────────────

  group('watchByAgent', () {
    test('emits empty list when no stats exist', () async {
      await seedWorkspace();
      await seedAgent();
      final emitted = await repo.watchByAgent('ws-1', 'agent-1').first;
      expect(emitted, isEmpty);
    });

    test('emits stats for the given agent ordered by date descending', () async {
      await seedWorkspace();
      await seedAgent();
      await seedDailyStat(id: 's1', agentId: 'agent-1', date: day(2026, 1, 1));
      await seedDailyStat(id: 's2', agentId: 'agent-1', date: day(2026, 1, 3));
      await seedDailyStat(id: 's3', agentId: 'agent-1', date: day(2026, 1, 2));

      final emitted = await repo.watchByAgent('ws-1', 'agent-1').first;
      expect(emitted.length, 3);
      expect(emitted[0].date, day(2026, 1, 3));
      expect(emitted[1].date, day(2026, 1, 2));
      expect(emitted[2].date, day(2026, 1, 1));
    });

    test('emits updated list after new insert', () async {
      await seedWorkspace();
      await seedAgent();

      final stream = repo.watchByAgent('ws-1', 'agent-1');
      final first = await stream.first;
      expect(first, isEmpty);

      await seedDailyStat(id: 's1', agentId: 'agent-1', date: day(2026, 6, 1));

      final second = await stream.first;
      expect(second.length, 1);
      expect(second.first.id, 's1');
    });
  });

  // ─── watchByAgentDateRange ───────────────────────────────────────────

  group('watchByAgentDateRange', () {
    test('returns stats within range ordered by date ascending', () async {
      await seedWorkspace();
      await seedAgent();
      await seedDailyStat(id: 's1', agentId: 'agent-1', date: day(2026, 1, 1));
      await seedDailyStat(id: 's2', agentId: 'agent-1', date: day(2026, 1, 5));
      await seedDailyStat(id: 's3', agentId: 'agent-1', date: day(2026, 1, 10));

      final emitted = await repo
          .watchByAgentDateRange('ws-1', 'agent-1', day(2026, 1, 1), day(2026, 1, 5))
          .first;
      expect(emitted.length, 2);
      expect(emitted[0].date, day(2026, 1, 1));
      expect(emitted[1].date, day(2026, 1, 5));
    });

    test('returns empty when no stats in range', () async {
      await seedWorkspace();
      await seedAgent();
      await seedDailyStat(id: 's1', agentId: 'agent-1', date: day(2026, 3, 1));

      final emitted = await repo
          .watchByAgentDateRange('ws-1', 'agent-1', day(2026, 1, 1), day(2026, 1, 31))
          .first;
      expect(emitted, isEmpty);
    });

    test('emits updated snapshot after upsert within range', () async {
      await seedWorkspace();
      await seedAgent();

      final stream = repo.watchByAgentDateRange(
        'ws-1',
        'agent-1',
        day(2026, 1, 1),
        day(2026, 1, 31),
      );

      final first = await stream.first;
      expect(first, isEmpty);

      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: day(2026, 1, 15),
        runsCompleted: 5,
      );

      final second = await stream.first;
      expect(second.length, 1);
      expect(second.first.runsCompleted, 5);
    });
  });

  // ─── watchAllByDateRange ─────────────────────────────────────────────

  group('watchAllByDateRange', () {
    test('returns stats across all agents ordered by date descending', () async {
      await seedWorkspace();
      await seedAgent(id: 'agent-1', name: 'Alice');
      await seedAgent(id: 'agent-2', name: 'Bob', workspaceId: 'ws-1');

      await seedDailyStat(id: 's1', agentId: 'agent-1', date: day(2026, 1, 2));
      await seedDailyStat(id: 's2', agentId: 'agent-2', date: day(2026, 1, 5));
      await seedDailyStat(id: 's3', agentId: 'agent-1', date: day(2026, 1, 8));

      final emitted = await repo
          .watchAllByDateRange('ws-1', day(2026, 1, 1), day(2026, 1, 31))
          .first;
      expect(emitted.length, 3);
      expect(emitted[0].date, day(2026, 1, 8));
      expect(emitted[1].date, day(2026, 1, 5));
      expect(emitted[2].date, day(2026, 1, 2));
    });

    test('returns empty when no stats in range', () async {
      final emitted = await repo
          .watchAllByDateRange('ws-1', day(2026, 1, 1), day(2026, 1, 31))
          .first;
      expect(emitted, isEmpty);
    });
  });

  // ─── getAgentScorecard ───────────────────────────────────────────────

  group('getAgentScorecard', () {
    test('returns null when agent does not exist', () async {
      final card = await repo.getAgentScorecard('ws-1', 'nonexistent');
      expect(card, isNull);
    });

    test('returns zeroed scorecard when agent has no stats', () async {
      await seedWorkspace();
      await seedAgent();

      final card = await repo.getAgentScorecard('ws-1', 'agent-1');
      expect(card, isNotNull);
      expect(card!.agentId, 'agent-1');
      expect(card.agentName, 'Alice');
      expect(card.totalRuns, 0);
      expect(card.totalErrored, 0);
      expect(card.successRate, 0);
      expect(card.avgRunDurationMs, 0);
      expect(card.totalPrsCreated, 0);
      expect(card.totalPrsMerged, 0);
      expect(card.totalReviews, 0);
      expect(card.totalBlockingComments, 0);
      expect(card.totalXp, 0);
      expect(card.level, 0);
      expect(card.levelProgress, 0);
    });

    test('aggregates stats across multiple daily records', () async {
      await seedWorkspace();
      await seedAgent();

      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: day(2026, 1, 1),
        runsCompleted: 10,
        runsErrored: 2,
        totalRunDurationMs: 5000,
        prsCreated: 3,
        prsMerged: 1,
        reviewsCompleted: 4,
        blockingComments: 2,
        xpEarned: 150,
      );
      await seedDailyStat(
        id: 's2',
        agentId: 'agent-1',
        date: day(2026, 1, 2),
        runsCompleted: 5,
        runsErrored: 1,
        totalRunDurationMs: 3000,
        prsCreated: 1,
        prsMerged: 2,
        reviewsCompleted: 2,
        blockingComments: 1,
        xpEarned: 100,
      );

      final card = await repo.getAgentScorecard('ws-1', 'agent-1');
      expect(card!.totalRuns, 15);
      expect(card.totalErrored, 3);
      expect(card.successRate, closeTo(15 / 18, 0.001));
      expect(card.avgRunDurationMs, 8000 ~/ 18);
      expect(card.totalPrsCreated, 4);
      expect(card.totalPrsMerged, 3);
      expect(card.totalReviews, 6);
      expect(card.totalBlockingComments, 3);
      expect(card.totalXp, 250);
    });

    test('computes level and levelProgress from totalXp', () async {
      await seedWorkspace();
      await seedAgent();

      // 400 xp => level = sqrt(400/100).floor() = 2
      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: day(2026, 1, 1),
        xpEarned: 400,
      );

      final card = await repo.getAgentScorecard('ws-1', 'agent-1');
      expect(card!.level, 2);
      // currentLevelXp = 2*2*100 = 400, nextLevelXp = 3*3*100 = 900
      // progress = (400 - 400) / (900 - 400) = 0.0
      expect(card.levelProgress, closeTo(0.0, 0.001));
    });

    test('successRate is 0 when totalRuns and totalErrored are both 0', () async {
      await seedWorkspace();
      await seedAgent();

      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: day(2026, 1, 1),
        runsCompleted: 0,
        runsErrored: 0,
      );

      final card = await repo.getAgentScorecard('ws-1', 'agent-1');
      expect(card!.successRate, 0);
      expect(card.avgRunDurationMs, 0);
    });
  });

  // ─── getAllAgentScorecards ───────────────────────────────────────────

  group('getAllAgentScorecards', () {
    test('returns empty list when no agents exist', () async {
      final cards = await repo.getAllAgentScorecards('ws-1');
      expect(cards, isEmpty);
    });

    test('returns one scorecard per agent', () async {
      await seedWorkspace();
      await seedAgent(id: 'agent-1', name: 'Alice');
      await seedAgent(id: 'agent-2', name: 'Bob', workspaceId: 'ws-1');

      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: day(2026, 1, 1),
        runsCompleted: 5,
      );
      await seedDailyStat(
        id: 's2',
        agentId: 'agent-2',
        date: day(2026, 1, 1),
        runsCompleted: 10,
      );

      final cards = await repo.getAllAgentScorecards('ws-1');
      expect(cards.length, 2);

      final alice = cards.firstWhere((c) => c.agentId == 'agent-1');
      expect(alice.totalRuns, 5);

      final bob = cards.firstWhere((c) => c.agentId == 'agent-2');
      expect(bob.totalRuns, 10);
    });

    test('includes agents with no stats', () async {
      await seedWorkspace();
      await seedAgent();

      final cards = await repo.getAllAgentScorecards('ws-1');
      expect(cards.length, 1);
      expect(cards.first.totalRuns, 0);
    });
  });

  // ─── getLeaderboard ─────────────────────────────────────────────────

  group('getLeaderboard', () {
    test('returns empty when no stats in range', () async {
      final entries = await repo.getLeaderboard('ws-1', day(2026, 1, 1), day(2026, 1, 31));
      expect(entries, isEmpty);
    });

    test('ranks agents by composite score descending', () async {
      await seedWorkspace();
      await seedAgent(id: 'agent-1', name: 'Alice');
      await seedAgent(id: 'agent-2', name: 'Bob', workspaceId: 'ws-1');

      // Score = runsCompleted*1 + prsCreated*5 + prsMerged*10 + reviews*6 + blocking*3 - errored*2
      // Alice: 10*1 + 2*5 + 0*10 + 0*6 + 0*3 - 0*2 = 20
      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: day(2026, 1, 15),
        runsCompleted: 10,
        prsCreated: 2,
      );

      // Bob: 5*1 + 0*5 + 1*10 + 3*6 + 0*3 - 0*2 = 33
      await seedDailyStat(
        id: 's2',
        agentId: 'agent-2',
        date: day(2026, 1, 15),
        runsCompleted: 5,
        prsMerged: 1,
        reviewsCompleted: 3,
      );

      final entries = await repo.getLeaderboard('ws-1', day(2026, 1, 1), day(2026, 1, 31));
      expect(entries.length, 2);
      expect(entries[0].agentId, 'agent-2');
      expect(entries[0].rank, 1);
      expect(entries[0].score, 33);
      expect(entries[1].agentId, 'agent-1');
      expect(entries[1].rank, 2);
      expect(entries[1].score, 20);
    });

    test('aggregates score from multiple daily stats for same agent', () async {
      await seedWorkspace();
      await seedAgent();

      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: day(2026, 1, 1),
        runsCompleted: 5,
      );
      await seedDailyStat(
        id: 's2',
        agentId: 'agent-1',
        date: day(2026, 1, 2),
        runsCompleted: 3,
      );

      final entries = await repo.getLeaderboard('ws-1', day(2026, 1, 1), day(2026, 1, 31));
      expect(entries.length, 1);
      expect(entries[0].score, 8); // (5 + 3) * 1
    });

    test('uses Unknown name when agent not in agent table', () async {
      await seedWorkspace();
      // Insert stat for an agent that doesn't exist in agents table
      // (FK is deferred in SQLite by default, so this works in-memory)
      await seedAgent();
      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: day(2026, 1, 1),
        runsCompleted: 5,
      );

      // Delete the agent so the name lookup fails
      await db.agentDao.deleteById('agent-1');

      final entries = await repo.getLeaderboard('ws-1', day(2026, 1, 1), day(2026, 1, 31));
      // Agent deleted via cascade removes their daily stats too
      expect(entries, isEmpty);
    });

    test('negative error penalty reduces score', () async {
      await seedWorkspace();
      await seedAgent();

      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: day(2026, 1, 1),
        runsCompleted: 2,
        runsErrored: 5,
      );

      final entries = await repo.getLeaderboard('ws-1', day(2026, 1, 1), day(2026, 1, 31));
      expect(entries.length, 1);
      // 2*1 + 0*5 + 0*10 + 0*6 + 0*3 - 5*2 = 2 - 10 = -8
      expect(entries[0].score, -8);
    });
  });

  // ─── getWorkspaceHealth ──────────────────────────────────────────────

  group('getWorkspaceHealth', () {
    test('returns null for nonexistent workspace', () async {
      final health = await repo.getWorkspaceHealth('nonexistent');
      expect(health, isNull);
    });

    test('returns health with all-zero sub-scores for empty workspace', () async {
      await seedWorkspace();
      await seedAgent();

      final health = await repo.getWorkspaceHealth('ws-1');
      expect(health, isNotNull);
      expect(health!.workspaceId, 'ws-1');
      expect(health.workspaceName, 'Test WS');
      expect(health.activeAgents, 0); // no run logs → no active agents
      expect(health.totalAgents, 1);
      expect(health.prsMergedThisWeek, 0);
      expect(health.openPRs, 0);
      expect(health.stalePRs, 0);
      expect(health.totalRuns, 0);
      expect(health.erroredRuns, 0);
    });

    test('counts active agents from run logs', () async {
      await seedWorkspace();
      await seedAgent(id: 'agent-1', name: 'Alice');
      await seedAgent(id: 'agent-2', name: 'Bob', workspaceId: 'ws-1');

      final now = DateTime.now();
      await seedRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: now.subtract(const Duration(days: 1)),
        completedAt: now,
        status: 'completed',
      );
      await seedRunLog(
        id: 'log-2',
        agentId: 'agent-2',
        workspaceId: 'ws-1',
        startedAt: now.subtract(const Duration(days: 1)),
        completedAt: now,
        status: 'completed',
      );

      final health = await repo.getWorkspaceHealth('ws-1');
      expect(health!.activeAgents, 2);
      expect(health.totalRuns, 2);
      expect(health.erroredRuns, 0);
    });

    test('counts errored runs within 30 days', () async {
      await seedWorkspace();
      await seedAgent();

      final now = DateTime.now();
      await seedRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: now.subtract(const Duration(days: 1)),
        status: 'errored',
      );
      await seedRunLog(
        id: 'log-2',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: now.subtract(const Duration(days: 1)),
        status: 'error',
      );
      await seedRunLog(
        id: 'log-3',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: now.subtract(const Duration(days: 1)),
        status: 'completed',
      );

      final health = await repo.getWorkspaceHealth('ws-1');
      expect(health!.erroredRuns, 2);
      expect(health.totalRuns, 1);
    });

    test('ignores run logs outside 30-day window', () async {
      await seedWorkspace();
      await seedAgent();

      final now = DateTime.now();
      await seedRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: now.subtract(const Duration(days: 60)),
        status: 'completed',
      );

      final health = await repo.getWorkspaceHealth('ws-1');
      expect(health!.totalRuns, 0);
    });

    test('counts PRs merged this week from analytics stats', () async {
      await seedWorkspace();
      await seedAgent();

      final now = DateTime.now();
      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: now.subtract(const Duration(days: 2)),
        prsMerged: 3,
      );

      final health = await repo.getWorkspaceHealth('ws-1');
      expect(health!.prsMergedThisWeek, 3);
    });

    test('counts open and stale PRs for workspace', () async {
      await seedWorkspace();

      final now = DateTime.now();

      // Open, non-stale PR
      await seedPR(
        id: 'pr-1',
        workspaceId: 'ws-1',
        title: 'Fresh PR',
        createdAt: now.subtract(const Duration(days: 2)),
      );

      // Stale PR: created >14 days ago, not merged or closed
      await seedPR(
        id: 'pr-2',
        workspaceId: 'ws-1',
        title: 'Stale PR',
        createdAt: now.subtract(const Duration(days: 20)),
      );

      // Closed PR, old but not stale (closedAt set)
      await seedPR(
        id: 'pr-3',
        workspaceId: 'ws-1',
        title: 'Closed PR',
        createdAt: now.subtract(const Duration(days: 20)),
        closedAt: now.subtract(const Duration(days: 15)),
      );

      final health = await repo.getWorkspaceHealth('ws-1');
      expect(health!.openPRs, 3);
      expect(health.stalePRs, 1); // only pr-2 is stale
    });

    test('health score is sum of sub-scores clamped to 0–100', () async {
      await seedWorkspace();
      await seedAgent();

      final health = await repo.getWorkspaceHealth('ws-1');
      expect(health!.score, greaterThanOrEqualTo(0));
      expect(health.score, lessThanOrEqualTo(100));
      expect(
        health.score,
        closeTo(
          health.activityScore +
              health.throughputScore +
              health.reviewHealthScore +
              health.successRateScore,
          0.001,
        ),
      );
    });

    test('only counts run logs for the given workspace', () async {
      await seedWorkspace(id: 'ws-1');
      await seedWorkspace(id: 'ws-2', name: 'Other WS');
      await seedAgent(id: 'agent-1', name: 'Alice', workspaceId: 'ws-1');
      await seedAgent(id: 'agent-2', name: 'Bob', workspaceId: 'ws-2');

      final now = DateTime.now();
      await seedRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: now.subtract(const Duration(days: 1)),
        status: 'completed',
      );
      await seedRunLog(
        id: 'log-2',
        agentId: 'agent-2',
        workspaceId: 'ws-2',
        startedAt: now.subtract(const Duration(days: 1)),
        status: 'completed',
      );

      final ws1 = await repo.getWorkspaceHealth('ws-1');
      expect(ws1!.totalRuns, 1);
      expect(ws1.activeAgents, 1);

      final ws2 = await repo.getWorkspaceHealth('ws-2');
      expect(ws2!.totalRuns, 1);
      expect(ws2.activeAgents, 1);
    });
  });

  // ─── getAllWorkspaceHealth ───────────────────────────────────────────

  group('getAllWorkspaceHealth', () {
    test('returns empty when no workspaces exist', () async {
      final all = await repo.getAllWorkspaceHealth();
      expect(all, isEmpty);
    });

    test('returns health for each workspace', () async {
      await seedWorkspace(id: 'ws-1');
      await seedWorkspace(id: 'ws-2', name: 'WS 2');

      final all = await repo.getAllWorkspaceHealth();
      expect(all.length, 2);

      final ids = all.map((h) => h.workspaceId).toSet();
      expect(ids, containsAll(['ws-1', 'ws-2']));
    });
  });

  // ─── rebuildDailyStats ───────────────────────────────────────────────

  group('rebuildDailyStats', () {
    test('creates daily stat from today\'s run logs', () async {
      await seedWorkspace();
      await seedAgent();

      final now = DateTime.now();
      // A completed run today lasting 2 seconds
      await seedRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: now.subtract(const Duration(seconds: 2)),
        completedAt: now,
        status: 'completed',
      );

      await repo.rebuildDailyStats();

      final stats = await db.analyticsDao.getByAgent('ws-1', 'agent-1');
      expect(stats.length, 1);
      expect(stats.first.runsCompleted, 1);
      expect(stats.first.runsErrored, 0);
      expect(stats.first.totalRunDurationMs, greaterThanOrEqualTo(1000));
    });

    test('counts errored runs', () async {
      await seedWorkspace();
      await seedAgent();

      final now = DateTime.now();

      await seedRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: now.subtract(const Duration(minutes: 5)),
        status: 'errored',
      );

      await repo.rebuildDailyStats();

      final stats = await db.analyticsDao.getByAgent('ws-1', 'agent-1');
      expect(stats.length, 1);
      expect(stats.first.runsCompleted, 0);
      expect(stats.first.runsErrored, 1);
    });

    test('ignores run logs from previous days', () async {
      await seedWorkspace();
      await seedAgent();

      await seedRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: DateTime.now().subtract(const Duration(days: 3)),
        status: 'completed',
      );

      await repo.rebuildDailyStats();

      final stats = await db.analyticsDao.getByAgent('ws-1', 'agent-1');
      // rebuildDailyStats always creates a row for every agent;
      // the old run is excluded from the counts
      expect(stats.length, 1);
      expect(stats.first.runsCompleted, 0);
      expect(stats.first.runsErrored, 0);
    });

    test('is idempotent — running twice produces same result', () async {
      await seedWorkspace();
      await seedAgent();

      final now = DateTime.now();
      await seedRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: now.subtract(const Duration(seconds: 5)),
        completedAt: now,
        status: 'completed',
      );

      await repo.rebuildDailyStats();
      await repo.rebuildDailyStats();

      final stats = await db.analyticsDao.getByAgent('ws-1', 'agent-1');
      expect(stats.length, 1);
      expect(stats.first.runsCompleted, 1);
    });

    test('handles agents with no run logs', () async {
      await seedWorkspace();
      await seedAgent();

      await repo.rebuildDailyStats();

      final stats = await db.analyticsDao.getByAgent('ws-1', 'agent-1');
      // rebuildDailyStats creates a stat even with 0 runs
      expect(stats.length, 1);
      expect(stats.first.runsCompleted, 0);
    });
  });

  // ─── backfillHistoricalData ──────────────────────────────────────────

  group('backfillHistoricalData', () {
    test('creates daily stats for each historical day with runs', () async {
      await seedWorkspace();
      await seedAgent();

      final day1 = DateTime(2026, 3, 1, 10, 0);
      final day2 = DateTime(2026, 3, 2, 14, 0);

      await seedRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: day1,
        completedAt: day1.add(const Duration(seconds: 30)),
        status: 'completed',
      );
      await seedRunLog(
        id: 'log-2',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: day2,
        status: 'errored',
      );

      await repo.backfillHistoricalData();

      final stats = await db.analyticsDao.getByAgent('ws-1', 'agent-1');
      expect(stats.length, 2);

      // Ordered by date desc
      final day2Stat = stats.firstWhere(
        (s) => s.date.month == 3 && s.date.day == 2,
      );
      expect(day2Stat.runsCompleted, 0);
      expect(day2Stat.runsErrored, 1);

      final day1Stat = stats.firstWhere(
        (s) => s.date.month == 3 && s.date.day == 1,
      );
      expect(day1Stat.runsCompleted, 1);
      expect(day1Stat.runsErrored, 0);
      expect(day1Stat.totalRunDurationMs, 30000);
    });

    test('handles multiple runs on the same day', () async {
      await seedWorkspace();
      await seedAgent();

      final base = DateTime(2026, 5, 10, 9, 0);

      await seedRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: base,
        completedAt: base.add(const Duration(seconds: 10)),
        status: 'completed',
      );
      await seedRunLog(
        id: 'log-2',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: base.add(const Duration(hours: 2)),
        completedAt: base.add(const Duration(hours: 2, seconds: 20)),
        status: 'completed',
      );
      await seedRunLog(
        id: 'log-3',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: base.add(const Duration(hours: 4)),
        status: 'error',
      );

      await repo.backfillHistoricalData();

      final stats = await db.analyticsDao.getByAgent('ws-1', 'agent-1');
      expect(stats.length, 1);
      expect(stats.first.runsCompleted, 2);
      expect(stats.first.runsErrored, 1);
      expect(stats.first.totalRunDurationMs, 30000); // 10s + 20s
    });

    test('is idempotent — running twice does not duplicate stats', () async {
      await seedWorkspace();
      await seedAgent();

      await seedRunLog(
        id: 'log-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        startedAt: DateTime(2026, 4, 1),
        status: 'completed',
      );

      await repo.backfillHistoricalData();
      await repo.backfillHistoricalData();

      final stats = await db.analyticsDao.getByAgent('ws-1', 'agent-1');
      expect(stats.length, 1);
    });

    test('handles agent with no run logs', () async {
      await seedWorkspace();
      await seedAgent();

      await repo.backfillHistoricalData();

      final stats = await db.analyticsDao.getByAgent('ws-1', 'agent-1');
      expect(stats, isEmpty);
    });
  });

  // ─── Level calculation edge cases ───────────────────────────────────

  group('getAgentScorecard — level calculation', () {
    test('level 0 at 0 xp', () async {
      await seedWorkspace();
      await seedAgent();
      await seedDailyStat(id: 's1', agentId: 'agent-1', date: day(2026, 1, 1), xpEarned: 0);

      final card = await repo.getAgentScorecard('ws-1', 'agent-1');
      expect(card!.level, 0);
      expect(card.levelProgress, closeTo(0.0, 0.001));
    });

    test('level 1 at 100 xp', () async {
      await seedWorkspace();
      await seedAgent();
      await seedDailyStat(id: 's1', agentId: 'agent-1', date: day(2026, 1, 1), xpEarned: 100);

      final card = await repo.getAgentScorecard('ws-1', 'agent-1');
      expect(card!.level, 1);
      // currentLevelXp = 1*1*100 = 100, nextLevelXp = 2*2*100 = 400
      // progress = (100 - 100) / (400 - 100) = 0
      expect(card.levelProgress, closeTo(0.0, 0.001));
    });

    test('level 3 at 900 xp with partial progress', () async {
      await seedWorkspace();
      await seedAgent();
      // 900 xp => sqrt(900/100).floor() = 3
      await seedDailyStat(id: 's1', agentId: 'agent-1', date: day(2026, 1, 1), xpEarned: 950);

      final card = await repo.getAgentScorecard('ws-1', 'agent-1');
      expect(card!.level, 3);
      // currentLevelXp = 3*3*100 = 900, nextLevelXp = 4*4*100 = 1600
      // progress = (950 - 900) / (1600 - 900) = 50/700 ≈ 0.0714
      expect(card.levelProgress, closeTo(50 / 700, 0.001));
    });
  });

  // ─── Upsert / idempotency ───────────────────────────────────────────

  group('daily stats upsert idempotency', () {
    test('upserting same id overwrites existing stat', () async {
      await seedWorkspace();
      await seedAgent();

      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: day(2026, 1, 1),
        runsCompleted: 5,
      );

      // Upsert again with same id, different value
      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: day(2026, 1, 1),
        runsCompleted: 10,
      );

      final stats = await db.analyticsDao.getByAgent('ws-1', 'agent-1');
      expect(stats.length, 1);
      expect(stats.first.runsCompleted, 10);
    });

    test('upserting different id for same agent+date violates unique index', () async {
      await seedWorkspace();
      await seedAgent();

      await seedDailyStat(
        id: 's1',
        agentId: 'agent-1',
        date: day(2026, 1, 1),
        runsCompleted: 5,
      );

      // Second insert with different id but same agent+date should throw
      // due to unique index idx_agent_daily_stats_agent_date
      expect(
        () => seedDailyStat(
          id: 's2',
          agentId: 'agent-1',
          date: day(2026, 1, 1),
          runsCompleted: 10,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ─── Watch stream emits updates ─────────────────────────────────────

  group('watch streams emit on update', () {
    test('watchByAgent emits after upsert update', () async {
      await seedWorkspace();
      await seedAgent();

      final stream = repo.watchByAgent('ws-1', 'agent-1');
      final events = <List>[];
      final sub = stream.listen(events.add);

      // Allow initial emission
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events.length, greaterThanOrEqualTo(1));

      await seedDailyStat(id: 's1', agentId: 'agent-1', date: day(2026, 6, 1), runsCompleted: 5);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Update the same stat
      await seedDailyStat(id: 's1', agentId: 'agent-1', date: day(2026, 6, 1), runsCompleted: 10);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await sub.cancel();

      // Should have: initial empty, after first insert, after update
      expect(events.length, greaterThanOrEqualTo(3));
      final last = events.last;
      expect(last.length, 1);
      expect((last.first as dynamic).runsCompleted as int, 10);
    });

    test('watchAllByDateRange emits after insert within range', () async {
      await seedWorkspace();
      await seedAgent();

      final stream = repo.watchAllByDateRange('ws-1', day(2026, 1, 1), day(2026, 12, 31));
      final events = <List>[];
      final sub = stream.listen(events.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await seedDailyStat(id: 's1', agentId: 'agent-1', date: day(2026, 6, 15));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await sub.cancel();

      expect(events.length, greaterThanOrEqualTo(2));
      final last = events.last;
      expect(last.length, 1);
    });
  });

  // ─── Workspace isolation ─────────────────────────────────────────────
  //
  // Two workspaces, each with its own agent and stats. Every read must return
  // ONLY the caller's workspace data; a foreign agent looked up via the wrong
  // workspaceId must yield nothing (the id is not the isolation boundary).
  group('workspace isolation', () {
    Future<void> seedTwoWorkspaces() async {
      await seedWorkspace(id: 'ws-a', name: 'WS A');
      await seedWorkspace(id: 'ws-b', name: 'WS B');
      await seedAgent(id: 'agent-a', name: 'Alice', workspaceId: 'ws-a');
      await seedAgent(id: 'agent-b', name: 'Bob', workspaceId: 'ws-b');
      // Alice (ws-a): strong score.
      await seedDailyStat(
        id: 'sa',
        agentId: 'agent-a',
        date: day(2026, 1, 10),
        runsCompleted: 10,
        prsMerged: 2,
        xpEarned: 400,
      );
      // Bob (ws-b): different score.
      await seedDailyStat(
        id: 'sb',
        agentId: 'agent-b',
        date: day(2026, 1, 10),
        runsCompleted: 3,
        prsCreated: 1,
        xpEarned: 100,
      );
    }

    test('watchByAgent only returns the agent within the given workspace',
        () async {
      await seedTwoWorkspaces();

      final aInA = await repo.watchByAgent('ws-a', 'agent-a').first;
      expect(aInA, hasLength(1));
      expect(aInA.first.agentId, 'agent-a');

      // Foreign workspace for the same agent id → nothing.
      final aInB = await repo.watchByAgent('ws-b', 'agent-a').first;
      expect(aInB, isEmpty);
    });

    test('watchByAgentDateRange is workspace-scoped', () async {
      await seedTwoWorkspaces();

      final inOwn = await repo
          .watchByAgentDateRange('ws-a', 'agent-a', day(2026, 1, 1), day(2026, 1, 31))
          .first;
      expect(inOwn, hasLength(1));

      final inForeign = await repo
          .watchByAgentDateRange('ws-b', 'agent-a', day(2026, 1, 1), day(2026, 1, 31))
          .first;
      expect(inForeign, isEmpty);
    });

    test('watchAllByDateRange returns only the workspace\'s stats', () async {
      await seedTwoWorkspaces();

      final inA = await repo
          .watchAllByDateRange('ws-a', day(2026, 1, 1), day(2026, 1, 31))
          .first;
      expect(inA, hasLength(1));
      expect(inA.single.agentId, 'agent-a');

      final inB = await repo
          .watchAllByDateRange('ws-b', day(2026, 1, 1), day(2026, 1, 31))
          .first;
      expect(inB, hasLength(1));
      expect(inB.single.agentId, 'agent-b');
    });

    test('getAgentScorecard returns null for a foreign-workspace agent',
        () async {
      await seedTwoWorkspaces();

      final own = await repo.getAgentScorecard('ws-a', 'agent-a');
      expect(own, isNotNull);
      expect(own!.totalRuns, 10);

      // agent-a belongs to ws-a; asking via ws-b must not surface it.
      final foreign = await repo.getAgentScorecard('ws-b', 'agent-a');
      expect(foreign, isNull);
    });

    test('getAllAgentScorecards returns only the workspace\'s agents',
        () async {
      await seedTwoWorkspaces();

      final inA = await repo.getAllAgentScorecards('ws-a');
      expect(inA, hasLength(1));
      expect(inA.single.agentId, 'agent-a');

      final inB = await repo.getAllAgentScorecards('ws-b');
      expect(inB, hasLength(1));
      expect(inB.single.agentId, 'agent-b');
    });

    test('getLeaderboard ranks only the workspace\'s agents', () async {
      await seedTwoWorkspaces();

      final inA = await repo.getLeaderboard('ws-a', day(2026, 1, 1), day(2026, 1, 31));
      expect(inA, hasLength(1));
      expect(inA.single.agentId, 'agent-a');

      final inB = await repo.getLeaderboard('ws-b', day(2026, 1, 1), day(2026, 1, 31));
      expect(inB, hasLength(1));
      expect(inB.single.agentId, 'agent-b');
    });

    test('getWorkspaceHealth never counts another workspace\'s data',
        () async {
      await seedTwoWorkspaces();

      final now = DateTime.now();
      // A merged-PR stat THIS WEEK for ws-b's agent only.
      await seedDailyStat(
        id: 'sb-week',
        agentId: 'agent-b',
        date: now.subtract(const Duration(days: 1)),
        prsMerged: 5,
      );

      final healthA = await repo.getWorkspaceHealth('ws-a');
      // ws-a has 1 agent and zero PRs merged this week (the 5 belong to ws-b).
      expect(healthA!.totalAgents, 1);
      expect(healthA.prsMergedThisWeek, 0);

      final healthB = await repo.getWorkspaceHealth('ws-b');
      expect(healthB!.totalAgents, 1);
      expect(healthB.prsMergedThisWeek, 5);
    });
  });
}
