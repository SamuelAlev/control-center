import 'package:control_center/features/analytics/domain/entities/leaderboard_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LeaderboardEntry createEntry({
    String agentId = 'agent-1',
    String agentName = 'Test Agent',
    int score = 500,
    int rank = 1,
  }) {
    return LeaderboardEntry(
      agentId: agentId,
      agentName: agentName,
      score: score,
      rank: rank,
    );
  }

  group('LeaderboardEntry', () {
    group('constructor', () {
      test('creates entry with all fields', timeout: const Timeout.factor(2), () {
        final e = createEntry();
        expect(e.agentId, 'agent-1');
        expect(e.agentName, 'Test Agent');
        expect(e.score, 500);
        expect(e.rank, 1);
      });

      test('creates entry with zero score', timeout: const Timeout.factor(2), () {
        final e = createEntry(score: 0);
        expect(e.score, 0);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', timeout: const Timeout.factor(2), () {
        final e1 = createEntry();
        final e2 = createEntry();
        expect(e1, equals(e2));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final e = createEntry();
        expect(e, equals(e));
      });

      test('== returns false for different agentId', timeout: const Timeout.factor(2), () {
        final e1 = createEntry(agentId: 'agent-1');
        final e2 = createEntry(agentId: 'agent-2');
        expect(e1, isNot(equals(e2)));
      });

      test('== returns false for different agentName', timeout: const Timeout.factor(2), () {
        final e1 = createEntry(agentName: 'Agent A');
        final e2 = createEntry(agentName: 'Agent B');
        expect(e1, isNot(equals(e2)));
      });

      test('== returns false for different score', timeout: const Timeout.factor(2), () {
        final e1 = createEntry(score: 100);
        final e2 = createEntry(score: 200);
        expect(e1, isNot(equals(e2)));
      });

      test('== returns false for different rank', timeout: const Timeout.factor(2), () {
        final e1 = createEntry(rank: 1);
        final e2 = createEntry(rank: 2);
        expect(e1, isNot(equals(e2)));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final e = createEntry();
        expect(e, isNot(equals('not an entry')));
      });

      test('hashCode matches for equal entries', timeout: const Timeout.factor(2), () {
        final e1 = createEntry();
        final e2 = createEntry();
        expect(e1.hashCode, equals(e2.hashCode));
      });

      test('hashCode differs for different entries', timeout: const Timeout.factor(2), () {
        final e1 = createEntry(agentId: 'agent-1');
        final e2 = createEntry(agentId: 'agent-2');
        expect(e1.hashCode, isNot(equals(e2.hashCode)));
      });
    });
  });
}
