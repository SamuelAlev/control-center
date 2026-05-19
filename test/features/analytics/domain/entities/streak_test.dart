import 'package:cc_domain/features/analytics/domain/entities/streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testLastDate = DateTime(2024, 6, 1);
  final testUpdatedAt = DateTime(2024, 6, 2);

  Streak createStreak({
    String id = 'streak-1',
    String agentId = 'agent-1',
    String streakType = 'pr_merged',
    int currentCount = 5,
    int bestCount = 10,
    DateTime? lastDate,
    DateTime? updatedAt,
  }) {
    return Streak(
      id: id,
      agentId: agentId,
      streakType: streakType,
      currentCount: currentCount,
      bestCount: bestCount,
      lastDate: lastDate ?? testLastDate,
      updatedAt: updatedAt ?? testUpdatedAt,
    );
  }

  group('Streak', () {
    group('constructor', () {
      test('creates streak with all fields', timeout: const Timeout.factor(2), () {
        final s = createStreak();
        expect(s.id, 'streak-1');
        expect(s.agentId, 'agent-1');
        expect(s.streakType, 'pr_merged');
        expect(s.currentCount, 5);
        expect(s.bestCount, 10);
        expect(s.lastDate, testLastDate);
        expect(s.updatedAt, testUpdatedAt);
      });

      test('creates streak with null lastDate', timeout: const Timeout.factor(2), () {
        final s = Streak(
          id: 'streak-2',
          agentId: 'agent-1',
          streakType: 'daily_active',
          currentCount: 0,
          bestCount: 0,
          lastDate: null,
          updatedAt: testUpdatedAt,
        );
        expect(s.lastDate, isNull);
      });

      test('creates streak with zero counts', timeout: const Timeout.factor(2), () {
        final s = createStreak(currentCount: 0, bestCount: 0);
        expect(s.currentCount, 0);
        expect(s.bestCount, 0);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', timeout: const Timeout.factor(2), () {
        final s1 = createStreak();
        final s2 = createStreak();
        expect(s1, equals(s2));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final s = createStreak();
        expect(s, equals(s));
      });

      test('== returns false for different id', timeout: const Timeout.factor(2), () {
        final s1 = createStreak(id: 'streak-1');
        final s2 = createStreak(id: 'streak-2');
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different agentId', timeout: const Timeout.factor(2), () {
        final s1 = createStreak(agentId: 'agent-1');
        final s2 = createStreak(agentId: 'agent-2');
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different streakType', timeout: const Timeout.factor(2), () {
        final s1 = createStreak(streakType: 'pr_merged');
        final s2 = createStreak(streakType: 'daily_active');
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different currentCount', timeout: const Timeout.factor(2), () {
        final s1 = createStreak(currentCount: 5);
        final s2 = createStreak(currentCount: 6);
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different bestCount', timeout: const Timeout.factor(2), () {
        final s1 = createStreak(bestCount: 10);
        final s2 = createStreak(bestCount: 20);
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different lastDate', timeout: const Timeout.factor(2), () {
        final s1 = createStreak(lastDate: DateTime(2024, 1, 1));
        final s2 = createStreak(lastDate: DateTime(2024, 2, 1));
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false when one lastDate is null', timeout: const Timeout.factor(2), () {
        final s1 = createStreak();
        final s2 = Streak(
          id: 'streak-1',
          agentId: 'agent-1',
          streakType: 'pr_merged',
          currentCount: 5,
          bestCount: 10,
          lastDate: null,
          updatedAt: testUpdatedAt,
        );
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different updatedAt', timeout: const Timeout.factor(2), () {
        final s1 = createStreak(updatedAt: DateTime(2024, 1, 1));
        final s2 = createStreak(updatedAt: DateTime(2024, 2, 1));
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final s = createStreak();
        expect(s, isNot(equals('not a streak')));
      });

      test('hashCode matches for equal streaks', timeout: const Timeout.factor(2), () {
        final s1 = createStreak();
        final s2 = createStreak();
        expect(s1.hashCode, equals(s2.hashCode));
      });

      test('hashCode differs for different streaks', timeout: const Timeout.factor(2), () {
        final s1 = createStreak(id: 'streak-1');
        final s2 = createStreak(id: 'streak-2');
        expect(s1.hashCode, isNot(equals(s2.hashCode)));
      });
    });
  });
}
