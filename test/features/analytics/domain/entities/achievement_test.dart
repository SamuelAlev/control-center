import 'package:control_center/features/analytics/domain/entities/achievement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testUnlockedAt = DateTime(2024, 3, 15);

  Achievement createAchievement({
    String id = 'ach-1',
    String agentId = 'agent-1',
    String badgeKey = 'first_merge',
    DateTime? unlockedAt,
    String? metadata,
  }) {
    return Achievement(
      id: id,
      agentId: agentId,
      badgeKey: badgeKey,
      unlockedAt: unlockedAt ?? testUnlockedAt,
      metadata: metadata,
    );
  }

  group('Achievement', () {
    group('constructor', () {
      test('creates achievement with required fields', timeout: const Timeout.factor(2), () {
        final a = createAchievement();
        expect(a.id, 'ach-1');
        expect(a.agentId, 'agent-1');
        expect(a.badgeKey, 'first_merge');
        expect(a.unlockedAt, testUnlockedAt);
        expect(a.metadata, isNull);
      });

      test('creates achievement with metadata', timeout: const Timeout.factor(2), () {
        final a = createAchievement(metadata: '{"prNumber": 42}');
        expect(a.metadata, '{"prNumber": 42}');
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', timeout: const Timeout.factor(2), () {
        final a1 = createAchievement();
        final a2 = createAchievement();
        expect(a1, equals(a2));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final a = createAchievement();
        expect(a, equals(a));
      });

      test('== returns false for different id', timeout: const Timeout.factor(2), () {
        final a1 = createAchievement(id: 'ach-1');
        final a2 = createAchievement(id: 'ach-2');
        expect(a1, isNot(equals(a2)));
      });

      test('== returns false for different agentId', timeout: const Timeout.factor(2), () {
        final a1 = createAchievement(agentId: 'agent-1');
        final a2 = createAchievement(agentId: 'agent-2');
        expect(a1, isNot(equals(a2)));
      });

      test('== returns false for different badgeKey', timeout: const Timeout.factor(2), () {
        final a1 = createAchievement(badgeKey: 'first_merge');
        final a2 = createAchievement(badgeKey: 'centurion');
        expect(a1, isNot(equals(a2)));
      });

      test('== returns false for different unlockedAt', timeout: const Timeout.factor(2), () {
        final a1 = createAchievement(unlockedAt: DateTime(2024, 1, 1));
        final a2 = createAchievement(unlockedAt: DateTime(2024, 2, 1));
        expect(a1, isNot(equals(a2)));
      });

      test('== returns false for different metadata', timeout: const Timeout.factor(2), () {
        final a1 = createAchievement(metadata: 'a');
        final a2 = createAchievement(metadata: 'b');
        expect(a1, isNot(equals(a2)));
      });

      test('== returns false when one has null metadata and other has value', timeout: const Timeout.factor(2), () {
        final a1 = createAchievement();
        final a2 = createAchievement(metadata: 'some');
        expect(a1, isNot(equals(a2)));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final a = createAchievement();
        expect(a, isNot(equals('not an achievement')));
      });

      test('hashCode matches for equal achievements', timeout: const Timeout.factor(2), () {
        final a1 = createAchievement();
        final a2 = createAchievement();
        expect(a1.hashCode, equals(a2.hashCode));
      });

      test('hashCode differs for different achievements', timeout: const Timeout.factor(2), () {
        final a1 = createAchievement(id: 'ach-1');
        final a2 = createAchievement(id: 'ach-2');
        expect(a1.hashCode, isNot(equals(a2.hashCode)));
      });
    });
  });
}
