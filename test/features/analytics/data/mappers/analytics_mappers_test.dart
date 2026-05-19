import 'package:cc_domain/features/analytics/domain/entities/achievement.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:cc_domain/features/analytics/domain/entities/streak.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/mappers/analytics_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testDate = DateTime(2024, 6, 1);
  final testCreatedAt = DateTime(2024, 6, 2);
  final testUnlockedAt = DateTime(2024, 3, 15);
  final testUpdatedAt = DateTime(2024, 6, 3);

  group('AnalyticsMappers', () {
    test('creates instance', timeout: const Timeout.factor(2), () {
      final mapper = AnalyticsMappers();
      expect(mapper, isNotNull);
    });

    // ── toDomain ────────────────────────────────────────────────────────

    group('toDomain', () {
      test('maps AgentDailyStatsTableData to AgentDailyStats',
          timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final row = AgentDailyStatsTableData(
          id: 'stats-1',
          agentId: 'agent-1',
          date: testDate,
          runsCompleted: 10,
          runsErrored: 2,
          totalRunDurationMs: 5000,
          prsCreated: 3,
          prsMerged: 2,
          reviewsCompleted: 4,
          blockingComments: 1,
          linesAdded: 150,
          linesDeleted: 30,
          xpEarned: 200,
          createdAt: testCreatedAt,
        );

        final result = mapper.toDomain(row);
        expect(result, isA<AgentDailyStats>());
        expect(result.id, 'stats-1');
        expect(result.agentId, 'agent-1');
        expect(result.date, testDate);
        expect(result.runsCompleted, 10);
        expect(result.runsErrored, 2);
        expect(result.totalRunDurationMs, 5000);
        expect(result.prsCreated, 3);
        expect(result.prsMerged, 2);
        expect(result.reviewsCompleted, 4);
        expect(result.blockingComments, 1);
        expect(result.linesAdded, 150);
        expect(result.linesDeleted, 30);
        expect(result.xpEarned, 200);
        expect(result.createdAt, testCreatedAt);
      });

      test('maps row with zeroes correctly',
          timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final row = AgentDailyStatsTableData(
          id: 'stats-zero',
          agentId: 'agent-2',
          date: testDate,
          runsCompleted: 0,
          runsErrored: 0,
          totalRunDurationMs: 0,
          prsCreated: 0,
          prsMerged: 0,
          reviewsCompleted: 0,
          blockingComments: 0,
          linesAdded: 0,
          linesDeleted: 0,
          xpEarned: 0,
          createdAt: testCreatedAt,
        );

        final result = mapper.toDomain(row);
        expect(result.id, 'stats-zero');
        expect(result.agentId, 'agent-2');
        expect(result.runsCompleted, 0);
        expect(result.runsErrored, 0);
        expect(result.xpEarned, 0);
      });
    });

    // ── toDomainList ────────────────────────────────────────────────────

    group('toDomainList', () {
      test('converts empty list', timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final result = mapper.toDomainList([]);
        expect(result, isEmpty);
      });

      test('converts single-element list', timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final row = AgentDailyStatsTableData(
          id: 'stats-1',
          agentId: 'agent-1',
          date: testDate,
          runsCompleted: 5,
          runsErrored: 1,
          totalRunDurationMs: 1000,
          prsCreated: 1,
          prsMerged: 0,
          reviewsCompleted: 0,
          blockingComments: 0,
          linesAdded: 50,
          linesDeleted: 10,
          xpEarned: 50,
          createdAt: testCreatedAt,
        );

        final result = mapper.toDomainList([row]);
        expect(result, hasLength(1));
        expect(result.first.id, 'stats-1');
        expect(result.first.agentId, 'agent-1');
      });

      test('converts multi-element list preserving order',
          timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final rows = List.generate(
          3,
          (i) => AgentDailyStatsTableData(
            id: 'stats-$i',
            agentId: 'agent-$i',
            date: testDate,
            runsCompleted: i,
            runsErrored: 0,
            totalRunDurationMs: 100,
            prsCreated: 0,
            prsMerged: 0,
            reviewsCompleted: 0,
            blockingComments: 0,
            linesAdded: 0,
            linesDeleted: 0,
            xpEarned: i * 10,
            createdAt: testCreatedAt,
          ),
        );

        final result = mapper.toDomainList(rows);
        expect(result, hasLength(3));
        expect(result[0].id, 'stats-0');
        expect(result[1].id, 'stats-1');
        expect(result[2].id, 'stats-2');
      });
    });

    // ── achievementToDomain ─────────────────────────────────────────────

    group('achievementToDomain', () {
      test('maps AchievementsTableData to Achievement',
          timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final row = AchievementsTableData(
          id: 'ach-1',
          agentId: 'agent-1',
          badgeKey: 'first_merge',
          unlockedAt: testUnlockedAt,
          metadata: 'extra-info',
        );

        final result = mapper.achievementToDomain(row);
        expect(result, isA<Achievement>());
        expect(result.id, 'ach-1');
        expect(result.agentId, 'agent-1');
        expect(result.badgeKey, 'first_merge');
        expect(result.unlockedAt, testUnlockedAt);
        expect(result.metadata, 'extra-info');
      });

      test('maps row with null metadata', timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final row = AchievementsTableData(
          id: 'ach-2',
          agentId: 'agent-2',
          badgeKey: 'centurion',
          unlockedAt: testUnlockedAt,
        );

        final result = mapper.achievementToDomain(row);
        expect(result.id, 'ach-2');
        expect(result.agentId, 'agent-2');
        expect(result.badgeKey, 'centurion');
        expect(result.metadata, isNull);
      });
    });

    // ── achievementsToDomain ────────────────────────────────────────────

    group('achievementsToDomain', () {
      test('converts empty list', timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final result = mapper.achievementsToDomain([]);
        expect(result, isEmpty);
      });

      test('converts single-element list', timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final row = AchievementsTableData(
          id: 'ach-1',
          agentId: 'agent-1',
          badgeKey: 'first_merge',
          unlockedAt: testUnlockedAt,
        );

        final result = mapper.achievementsToDomain([row]);
        expect(result, hasLength(1));
        expect(result.first.badgeKey, 'first_merge');
      });

      test('converts multiple achievements', timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final rows = [
          AchievementsTableData(
            id: 'ach-1',
            agentId: 'agent-1',
            badgeKey: 'first_merge',
            unlockedAt: testUnlockedAt,
          ),
          AchievementsTableData(
            id: 'ach-2',
            agentId: 'agent-1',
            badgeKey: 'centurion',
            unlockedAt: testUnlockedAt,
          ),
        ];

        final result = mapper.achievementsToDomain(rows);
        expect(result, hasLength(2));
        expect(result[0].badgeKey, 'first_merge');
        expect(result[1].badgeKey, 'centurion');
      });
    });

    // ── streakToDomain ──────────────────────────────────────────────────

    group('streakToDomain', () {
      test('maps StreaksTableData to Streak',
          timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final row = StreaksTableData(
          id: 'streak-1',
          agentId: 'agent-1',
          streakType: 'pr_merged',
          currentCount: 5,
          bestCount: 10,
          lastDate: testDate,
          updatedAt: testUpdatedAt,
        );

        final result = mapper.streakToDomain(row);
        expect(result, isA<Streak>());
        expect(result.id, 'streak-1');
        expect(result.agentId, 'agent-1');
        expect(result.streakType, 'pr_merged');
        expect(result.currentCount, 5);
        expect(result.bestCount, 10);
        expect(result.lastDate, testDate);
        expect(result.updatedAt, testUpdatedAt);
      });

      test('maps row with null lastDate', timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final row = StreaksTableData(
          id: 'streak-2',
          agentId: 'agent-2',
          streakType: 'daily_active',
          currentCount: 0,
          bestCount: 3,
          updatedAt: testUpdatedAt,
        );

        final result = mapper.streakToDomain(row);
        expect(result.id, 'streak-2');
        expect(result.lastDate, isNull);
        expect(result.currentCount, 0);
      });
    });

    // ── streaksToDomain ─────────────────────────────────────────────────

    group('streaksToDomain', () {
      test('converts empty list', timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final result = mapper.streaksToDomain([]);
        expect(result, isEmpty);
      });

      test('converts single-element list', timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final row = StreaksTableData(
          id: 'streak-1',
          agentId: 'agent-1',
          streakType: 'pr_merged',
          currentCount: 3,
          bestCount: 7,
          updatedAt: testUpdatedAt,
        );

        final result = mapper.streaksToDomain([row]);
        expect(result, hasLength(1));
        expect(result.first.streakType, 'pr_merged');
      });

      test('converts multiple streaks', timeout: const Timeout.factor(2), () {
        final mapper = AnalyticsMappers();
        final rows = [
          StreaksTableData(
            id: 'streak-1',
            agentId: 'agent-1',
            streakType: 'pr_merged',
            currentCount: 5,
            bestCount: 10,
            updatedAt: testUpdatedAt,
          ),
          StreaksTableData(
            id: 'streak-2',
            agentId: 'agent-1',
            streakType: 'daily_active',
            currentCount: 7,
            bestCount: 7,
            updatedAt: testUpdatedAt,
          ),
        ];

        final result = mapper.streaksToDomain(rows);
        expect(result, hasLength(2));
        expect(result[0].streakType, 'pr_merged');
        expect(result[1].streakType, 'daily_active');
      });
    });
  });
}
