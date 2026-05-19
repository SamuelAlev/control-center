import 'package:control_center/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testDate = DateTime(2024, 6, 1);
  final testCreatedAt = DateTime(2024, 6, 2);

  AgentDailyStats createStats({
    String id = 'stats-1',
    String agentId = 'agent-1',
    DateTime? date,
    int runsCompleted = 10,
    int runsErrored = 1,
    int totalRunDurationMs = 5000,
    int prsCreated = 3,
    int prsMerged = 2,
    int reviewsCompleted = 4,
    int blockingComments = 1,
    int linesAdded = 150,
    int linesDeleted = 30,
    int xpEarned = 200,
    DateTime? createdAt,
  }) {
    return AgentDailyStats(
      id: id,
      agentId: agentId,
      date: date ?? testDate,
      runsCompleted: runsCompleted,
      runsErrored: runsErrored,
      totalRunDurationMs: totalRunDurationMs,
      prsCreated: prsCreated,
      prsMerged: prsMerged,
      reviewsCompleted: reviewsCompleted,
      blockingComments: blockingComments,
      linesAdded: linesAdded,
      linesDeleted: linesDeleted,
      xpEarned: xpEarned,
      createdAt: createdAt ?? testCreatedAt,
    );
  }

  group('AgentDailyStats', () {
    group('constructor', () {
      test('creates stats with all fields', timeout: const Timeout.factor(2), () {
        final s = createStats();
        expect(s.id, 'stats-1');
        expect(s.agentId, 'agent-1');
        expect(s.date, testDate);
        expect(s.runsCompleted, 10);
        expect(s.runsErrored, 1);
        expect(s.totalRunDurationMs, 5000);
        expect(s.prsCreated, 3);
        expect(s.prsMerged, 2);
        expect(s.reviewsCompleted, 4);
        expect(s.blockingComments, 1);
        expect(s.linesAdded, 150);
        expect(s.linesDeleted, 30);
        expect(s.xpEarned, 200);
        expect(s.createdAt, testCreatedAt);
      });

      test('creates stats with zero values', timeout: const Timeout.factor(2), () {
        final s = createStats(
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
        );
        expect(s.runsCompleted, 0);
        expect(s.xpEarned, 0);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', timeout: const Timeout.factor(2), () {
        final s1 = createStats();
        final s2 = createStats();
        expect(s1, equals(s2));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final s = createStats();
        expect(s, equals(s));
      });

      test('== returns false for different id', timeout: const Timeout.factor(2), () {
        final s1 = createStats(id: 'stats-1');
        final s2 = createStats(id: 'stats-2');
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different agentId', timeout: const Timeout.factor(2), () {
        final s1 = createStats(agentId: 'agent-1');
        final s2 = createStats(agentId: 'agent-2');
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different date', timeout: const Timeout.factor(2), () {
        final s1 = createStats(date: DateTime(2024, 1, 1));
        final s2 = createStats(date: DateTime(2024, 2, 1));
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different runsCompleted', timeout: const Timeout.factor(2), () {
        final s1 = createStats(runsCompleted: 10);
        final s2 = createStats(runsCompleted: 20);
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different xpEarned', timeout: const Timeout.factor(2), () {
        final s1 = createStats(xpEarned: 100);
        final s2 = createStats(xpEarned: 200);
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different createdAt', timeout: const Timeout.factor(2), () {
        final s1 = createStats(createdAt: DateTime(2024, 1, 1));
        final s2 = createStats(createdAt: DateTime(2024, 2, 1));
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final s = createStats();
        expect(s, isNot(equals('not stats')));
      });

      test('hashCode matches for equal stats', timeout: const Timeout.factor(2), () {
        final s1 = createStats();
        final s2 = createStats();
        expect(s1.hashCode, equals(s2.hashCode));
      });

      test('hashCode differs for different stats', timeout: const Timeout.factor(2), () {
        final s1 = createStats(id: 'stats-1');
        final s2 = createStats(id: 'stats-2');
        expect(s1.hashCode, isNot(equals(s2.hashCode)));
      });
    });
  });
}
