import 'package:control_center/features/analytics/domain/entities/achievement.dart';
import 'package:control_center/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:control_center/features/analytics/domain/entities/streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testStreak = Streak(
    id: 'streak-1',
    agentId: 'agent-1',
    streakType: 'pr_merged',
    currentCount: 5,
    bestCount: 10,
    lastDate: DateTime(2024, 6, 1),
    updatedAt: DateTime(2024, 6, 2),
  );

  final testAchievement = Achievement(
    id: 'ach-1',
    agentId: 'agent-1',
    badgeKey: 'first_merge',
    unlockedAt: DateTime(2024, 3, 15),
  );

  AgentScorecard createScorecard({
    String agentId = 'agent-1',
    String agentName = 'Test Agent',
    int totalRuns = 50,
    int totalErrored = 3,
    double successRate = 0.94,
    int avgRunDurationMs = 1200,
    int totalPrsCreated = 8,
    int totalPrsMerged = 6,
    int totalReviews = 12,
    int totalBlockingComments = 2,
    int totalXp = 1500,
    int level = 5,
    double levelProgress = 0.75,
    List<Streak>? currentStreaks,
    List<Achievement>? achievements,
  }) {
    return AgentScorecard(
      agentId: agentId,
      agentName: agentName,
      totalRuns: totalRuns,
      totalErrored: totalErrored,
      successRate: successRate,
      avgRunDurationMs: avgRunDurationMs,
      totalPrsCreated: totalPrsCreated,
      totalPrsMerged: totalPrsMerged,
      totalReviews: totalReviews,
      totalBlockingComments: totalBlockingComments,
      totalXp: totalXp,
      level: level,
      levelProgress: levelProgress,
      currentStreaks: currentStreaks ?? [testStreak],
      achievements: achievements ?? [testAchievement],
    );
  }

  group('AgentScorecard', () {
    group('constructor', () {
      test('creates scorecard with all fields', timeout: const Timeout.factor(2), () {
        final sc = createScorecard();
        expect(sc.agentId, 'agent-1');
        expect(sc.agentName, 'Test Agent');
        expect(sc.totalRuns, 50);
        expect(sc.totalErrored, 3);
        expect(sc.successRate, 0.94);
        expect(sc.avgRunDurationMs, 1200);
        expect(sc.totalPrsCreated, 8);
        expect(sc.totalPrsMerged, 6);
        expect(sc.totalReviews, 12);
        expect(sc.totalBlockingComments, 2);
        expect(sc.totalXp, 1500);
        expect(sc.level, 5);
        expect(sc.levelProgress, 0.75);
        expect(sc.currentStreaks, hasLength(1));
        expect(sc.achievements, hasLength(1));
      });

      test('creates scorecard with empty streaks and achievements', timeout: const Timeout.factor(2), () {
        final sc = createScorecard(
          currentStreaks: [],
          achievements: [],
        );
        expect(sc.currentStreaks, isEmpty);
        expect(sc.achievements, isEmpty);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', timeout: const Timeout.factor(2), () {
        final sc1 = createScorecard();
        final sc2 = createScorecard();
        expect(sc1, equals(sc2));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final sc = createScorecard();
        expect(sc, equals(sc));
      });

      test('== returns false for different agentId', timeout: const Timeout.factor(2), () {
        final sc1 = createScorecard(agentId: 'agent-1');
        final sc2 = createScorecard(agentId: 'agent-2');
        expect(sc1, isNot(equals(sc2)));
      });

      test('== returns false for different agentName', timeout: const Timeout.factor(2), () {
        final sc1 = createScorecard(agentName: 'Agent A');
        final sc2 = createScorecard(agentName: 'Agent B');
        expect(sc1, isNot(equals(sc2)));
      });

      test('== returns false for different totalRuns', timeout: const Timeout.factor(2), () {
        final sc1 = createScorecard(totalRuns: 10);
        final sc2 = createScorecard(totalRuns: 20);
        expect(sc1, isNot(equals(sc2)));
      });

      test('== returns false for different successRate', timeout: const Timeout.factor(2), () {
        final sc1 = createScorecard(successRate: 0.9);
        final sc2 = createScorecard(successRate: 0.8);
        expect(sc1, isNot(equals(sc2)));
      });

      test('== returns false for different totalXp', timeout: const Timeout.factor(2), () {
        final sc1 = createScorecard(totalXp: 1000);
        final sc2 = createScorecard(totalXp: 2000);
        expect(sc1, isNot(equals(sc2)));
      });

      test('== returns false for different level', timeout: const Timeout.factor(2), () {
        final sc1 = createScorecard(level: 3);
        final sc2 = createScorecard(level: 4);
        expect(sc1, isNot(equals(sc2)));
      });

      test('== returns false for different levelProgress', timeout: const Timeout.factor(2), () {
        final sc1 = createScorecard(levelProgress: 0.5);
        final sc2 = createScorecard(levelProgress: 0.6);
        expect(sc1, isNot(equals(sc2)));
      });

      test('== returns false for different currentStreaks', timeout: const Timeout.factor(2), () {
        final otherStreak = Streak(
          id: 'streak-2',
          agentId: 'agent-1',
          streakType: 'daily_active',
          currentCount: 3,
          bestCount: 7,
          updatedAt: DateTime(2024, 6, 2),
        );
        final sc1 = createScorecard(currentStreaks: [testStreak]);
        final sc2 = createScorecard(currentStreaks: [otherStreak]);
        expect(sc1, isNot(equals(sc2)));
      });

      test('== returns false for different achievements', timeout: const Timeout.factor(2), () {
        final otherAch = Achievement(
          id: 'ach-2',
          agentId: 'agent-1',
          badgeKey: 'centurion',
          unlockedAt: DateTime(2024, 4, 1),
        );
        final sc1 = createScorecard(achievements: [testAchievement]);
        final sc2 = createScorecard(achievements: [otherAch]);
        expect(sc1, isNot(equals(sc2)));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final sc = createScorecard();
        expect(sc, isNot(equals('not a scorecard')));
      });

      test('hashCode matches for equal scorecards', timeout: const Timeout.factor(2), () {
        final sc1 = createScorecard();
        final sc2 = createScorecard();
        expect(sc1.hashCode, equals(sc2.hashCode));
      });

      test('hashCode differs for different scorecards', timeout: const Timeout.factor(2), () {
        final sc1 = createScorecard(agentId: 'agent-1');
        final sc2 = createScorecard(agentId: 'agent-2');
        expect(sc1.hashCode, isNot(equals(sc2.hashCode)));
      });
    });
  });
}
