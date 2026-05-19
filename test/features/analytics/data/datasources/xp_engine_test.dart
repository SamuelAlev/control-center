import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/features/analytics/domain/entities/achievement.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:cc_domain/features/analytics/domain/entities/leaderboard_entry.dart';
import 'package:cc_domain/features/analytics/domain/entities/streak.dart';
import 'package:cc_domain/features/analytics/domain/entities/workspace_health.dart';
import 'package:cc_domain/features/analytics/domain/repositories/achievement_repository.dart';
import 'package:cc_domain/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:cc_domain/features/analytics/domain/repositories/streak_repository.dart';
import 'package:cc_domain/features/analytics/domain/services/xp_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake for [AnalyticsRepository].
class _FakeAnalyticsRepository implements AnalyticsRepository {
  AgentScorecard? _scorecard;

  /// Records the workspaceId the last scorecard read was scoped to.
  String? lastScorecardWorkspaceId;

  void setScorecard(AgentScorecard? scorecard) => _scorecard = scorecard;

  @override
  Future<AgentScorecard?> getAgentScorecard(
    String workspaceId,
    String agentId,
  ) async {
    lastScorecardWorkspaceId = workspaceId;
    return _scorecard;
  }

  @override
  Stream<List<AgentDailyStats>> watchByAgent(
    String workspaceId,
    String agentId,
  ) =>
      const Stream.empty();

  @override
  Stream<List<AgentDailyStats>> watchByAgentDateRange(
    String workspaceId,
    String agentId,
    DateTime start,
    DateTime end,
  ) =>
      const Stream.empty();

  @override
  Stream<List<AgentDailyStats>> watchAllByDateRange(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) =>
      const Stream.empty();

  @override
  Future<List<AgentScorecard>> getAllAgentScorecards(String workspaceId) async => [];

  @override
  Future<List<LeaderboardEntry>> getLeaderboard(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) async =>
      [];

  @override
  Future<WorkspaceHealth?> getWorkspaceHealth(String workspaceId) async => null;

  @override
  Future<List<WorkspaceHealth>> getAllWorkspaceHealth() async => [];

  @override
  Future<void> rebuildDailyStats() async {}

  @override
  Future<void> backfillHistoricalData() async {}
}

/// Analytics repository whose [getAgentScorecard] always throws.
class _ThrowingAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<AgentScorecard?> getAgentScorecard(
    String workspaceId,
    String agentId,
  ) async =>
      throw Exception('boom');

  @override
  Stream<List<AgentDailyStats>> watchByAgent(
    String workspaceId,
    String agentId,
  ) =>
      const Stream.empty();

  @override
  Stream<List<AgentDailyStats>> watchByAgentDateRange(
    String workspaceId,
    String agentId,
    DateTime start,
    DateTime end,
  ) =>
      const Stream.empty();

  @override
  Stream<List<AgentDailyStats>> watchAllByDateRange(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) =>
      const Stream.empty();

  @override
  Future<List<AgentScorecard>> getAllAgentScorecards(String workspaceId) async => [];

  @override
  Future<List<LeaderboardEntry>> getLeaderboard(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) async =>
      [];

  @override
  Future<WorkspaceHealth?> getWorkspaceHealth(String workspaceId) async => null;

  @override
  Future<List<WorkspaceHealth>> getAllWorkspaceHealth() async => [];

  @override
  Future<void> rebuildDailyStats() async {}

  @override
  Future<void> backfillHistoricalData() async {}
}

/// In-memory fake for [AchievementRepository].
class _FakeAchievementRepository implements AchievementRepository {
  final List<String> unlockedKeys = [];

  /// Records the workspaceId every unlock was scoped to.
  final List<String> unlockWorkspaceIds = [];

  @override
  Future<void> unlock(
    String workspaceId,
    String agentId,
    String badgeKey, {
    String? metadata,
  }) async {
    unlockWorkspaceIds.add(workspaceId);
    unlockedKeys.add(badgeKey);
  }

  @override
  Stream<List<Achievement>> watchByAgent(String workspaceId, String agentId) =>
      const Stream.empty();

  @override
  Future<List<Achievement>> getByAgent(String workspaceId, String agentId) async => [];

  @override
  Future<bool> isUnlocked(String workspaceId, String agentId, String badgeKey) async =>
      unlockedKeys.contains(badgeKey);
}

/// In-memory fake for [StreakRepository].
class _FakeStreakRepository implements StreakRepository {
  final List<(String, String, String, bool)> updates = [];

  @override
  Future<void> updateStreak(
    String workspaceId,
    String agentId,
    String streakType, {
    required bool increment,
  }) async {
    updates.add((workspaceId, agentId, streakType, increment));
  }

  @override
  Stream<List<Streak>> watchByAgent(String workspaceId, String agentId) =>
      const Stream.empty();

  @override
  Future<List<Streak>> getByAgent(String workspaceId, String agentId) async => [];

  @override
  Future<int> getCurrentStreak(String workspaceId, String agentId, String streakType) async => 0;
}

void main() {
  late DomainEventBus eventBus;
  late _FakeAnalyticsRepository analyticsRepo;
  late _FakeAchievementRepository achievementRepo;
  late _FakeStreakRepository streakRepo;

  setUp(() {
    eventBus = DomainEventBus();
    analyticsRepo = _FakeAnalyticsRepository();
    achievementRepo = _FakeAchievementRepository();
    streakRepo = _FakeStreakRepository();
  });

  tearDown(() {
    eventBus.dispose();
  });

  XpEngine createEngine() => XpEngine(
        eventBus,
        analyticsRepo,
        achievementRepo,
        streakRepo,
      );

  /// Helper: publish a PrMerged event and wait for async handlers to settle.
  Future<void> publishAndWait(String agentId) async {
    final engine = createEngine();
    addTearDown(engine.dispose);

    eventBus.publish(PrMerged(
      prId: 'pr-1',
      workspaceId: 'ws-1',
      agentId: agentId,
      occurredAt: DateTime.now(),
    ));

    // Let the event loop process the stream listener and ensuing futures.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  group('XpEngine', () {
    test('subscribes to PrMerged events', timeout: const Timeout.factor(2), () {
      final engine = createEngine();
      eventBus.publish(PrMerged(
        prId: 'pr-1',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        occurredAt: DateTime.now(),
      ));
      engine.dispose();
    });

    test('updates streaks on PrMerged', timeout: const Timeout.factor(2), () async {
      await publishAndWait('agent-1');
      expect(streakRepo.updates, hasLength(2));
      expect(streakRepo.updates[0], ('ws-1', 'agent-1', 'pr_merged', true));
      expect(streakRepo.updates[1], ('ws-1', 'agent-1', 'daily_active', true));
    });

    test('threads the event workspaceId into the analytics scorecard read',
        timeout: const Timeout.factor(2), () async {
      await publishAndWait('agent-1');
      expect(analyticsRepo.lastScorecardWorkspaceId, 'ws-1');
    });

    test('threads the event workspaceId into achievement unlocks',
        timeout: const Timeout.factor(2), () async {
      await publishAndWait('agent-1');
      expect(achievementRepo.unlockWorkspaceIds, isNotEmpty);
      expect(
        achievementRepo.unlockWorkspaceIds.every((w) => w == 'ws-1'),
        isTrue,
      );
    });

    test('unlocks first_merge achievement on PrMerged', timeout: const Timeout.factor(2), () async {
      await publishAndWait('agent-1');
      expect(achievementRepo.unlockedKeys, contains('first_merge'));
    });

    test('unlocks centurion when totalRuns >= 100', timeout: const Timeout.factor(2), () async {
      analyticsRepo.setScorecard(const AgentScorecard(
        agentId: 'agent-1',
        agentName: 'Test',
        totalRuns: 100,
        totalErrored: 0,
        successRate: 1.0,
        avgRunDurationMs: 1000,
        totalPrsCreated: 0,
        totalPrsMerged: 0,
        totalReviews: 0,
        totalBlockingComments: 0,
        totalXp: 0,
        level: 1,
        levelProgress: 0.0,
        currentStreaks: [],
        achievements: [],
      ));

      await publishAndWait('agent-1');
      expect(achievementRepo.unlockedKeys, contains('centurion'));
    });

    test('unlocks pr_machine when totalPrsCreated >= 10', timeout: const Timeout.factor(2), () async {
      analyticsRepo.setScorecard(const AgentScorecard(
        agentId: 'agent-1',
        agentName: 'Test',
        totalRuns: 5,
        totalErrored: 0,
        successRate: 1.0,
        avgRunDurationMs: 1000,
        totalPrsCreated: 10,
        totalPrsMerged: 0,
        totalReviews: 0,
        totalBlockingComments: 0,
        totalXp: 0,
        level: 1,
        levelProgress: 0.0,
        currentStreaks: [],
        achievements: [],
      ));

      await publishAndWait('agent-1');
      expect(achievementRepo.unlockedKeys, contains('pr_machine'));
    });

    test('unlocks merge_master when totalPrsMerged >= 10', timeout: const Timeout.factor(2), () async {
      analyticsRepo.setScorecard(const AgentScorecard(
        agentId: 'agent-1',
        agentName: 'Test',
        totalRuns: 5,
        totalErrored: 0,
        successRate: 1.0,
        avgRunDurationMs: 1000,
        totalPrsCreated: 0,
        totalPrsMerged: 10,
        totalReviews: 0,
        totalBlockingComments: 0,
        totalXp: 0,
        level: 1,
        levelProgress: 0.0,
        currentStreaks: [],
        achievements: [],
      ));

      await publishAndWait('agent-1');
      expect(achievementRepo.unlockedKeys, contains('merge_master'));
    });

    test('unlocks sharpshooter when totalBlockingComments >= 10', timeout: const Timeout.factor(2), () async {
      analyticsRepo.setScorecard(const AgentScorecard(
        agentId: 'agent-1',
        agentName: 'Test',
        totalRuns: 5,
        totalErrored: 0,
        successRate: 1.0,
        avgRunDurationMs: 1000,
        totalPrsCreated: 0,
        totalPrsMerged: 0,
        totalReviews: 0,
        totalBlockingComments: 10,
        totalXp: 0,
        level: 1,
        levelProgress: 0.0,
        currentStreaks: [],
        achievements: [],
      ));

      await publishAndWait('agent-1');
      expect(achievementRepo.unlockedKeys, contains('sharpshooter'));
    });

    test('does not unlock lifetime achievements when scorecard is null', timeout: const Timeout.factor(2), () async {
      analyticsRepo.setScorecard(null);

      await publishAndWait('agent-1');
      // first_merge is always unlocked, but no lifetime achievements
      expect(achievementRepo.unlockedKeys, ['first_merge']);
    });

    test('does not unlock lifetime achievements when thresholds not met',
        timeout: const Timeout.factor(2), () async {
      analyticsRepo.setScorecard(const AgentScorecard(
        agentId: 'agent-1',
        agentName: 'Test',
        totalRuns: 50,
        totalErrored: 2,
        successRate: 0.96,
        avgRunDurationMs: 1000,
        totalPrsCreated: 5,
        totalPrsMerged: 5,
        totalReviews: 0,
        totalBlockingComments: 5,
        totalXp: 0,
        level: 1,
        levelProgress: 0.0,
        currentStreaks: [],
        achievements: [],
      ));

      await publishAndWait('agent-1');
      expect(achievementRepo.unlockedKeys, ['first_merge']);
    });

    test('unlocks multiple lifetime achievements in one event',
        timeout: const Timeout.factor(2), () async {
      analyticsRepo.setScorecard(const AgentScorecard(
        agentId: 'agent-1',
        agentName: 'Test',
        totalRuns: 100,
        totalErrored: 0,
        successRate: 1.0,
        avgRunDurationMs: 1000,
        totalPrsCreated: 10,
        totalPrsMerged: 10,
        totalReviews: 0,
        totalBlockingComments: 10,
        totalXp: 0,
        level: 1,
        levelProgress: 0.0,
        currentStreaks: [],
        achievements: [],
      ));

      await publishAndWait('agent-1');
      expect(achievementRepo.unlockedKeys, contains('first_merge'));
      expect(achievementRepo.unlockedKeys, contains('centurion'));
      expect(achievementRepo.unlockedKeys, contains('pr_machine'));
      expect(achievementRepo.unlockedKeys, contains('merge_master'));
      expect(achievementRepo.unlockedKeys, contains('sharpshooter'));
    });

    test('swallows errors from _checkLifetimeAchievements',
        timeout: const Timeout.factor(2), () async {
      // Override getAgentScorecard to throw so _checkLifetimeAchievements
      // exercises its catch clause.
      analyticsRepo.setScorecard(null);
      // Replace the fake with a throwing variant.
      final throwingRepo = _ThrowingAnalyticsRepository();
      final engine = XpEngine(
        eventBus,
        throwingRepo,
        achievementRepo,
        streakRepo,
      );
      addTearDown(engine.dispose);

      eventBus.publish(PrMerged(
        prId: 'pr-1',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        occurredAt: DateTime.now(),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      // first_merge should still unlock even though _checkLifetimeAchievements threw
      expect(achievementRepo.unlockedKeys, contains('first_merge'));
    });

    test('dispose cancels subscriptions', timeout: const Timeout.factor(2), () {
      final engine = createEngine();
      engine.dispose();
      // Publishing after dispose should not crash or trigger any side effects
      eventBus.publish(PrMerged(
        prId: 'pr-2',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        occurredAt: DateTime.now(),
      ));
    });
  });
}
