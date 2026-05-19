import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/achievement_dao.dart';
import 'package:control_center/core/domain/events/analytics_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/features/analytics/data/repositories/achievement_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late AchievementRepositoryImpl repo;
  late AchievementDao dao;

  setUp(() async {
    db = createTestDatabase();
    // Insert agent row so FK constraints on achievements are satisfied.
    await db.into(db.agentsTable).insert(
          AgentsTableCompanion.insert(
            id: 'agent-1',
            name: 'agent-1',
            title: 'Agent 1',
            agentMdPath: '',
            workspaceId: '',
            skills: '',
          ),
        );
    await db.into(db.agentsTable).insert(
          AgentsTableCompanion.insert(
            id: 'agent-2',
            name: 'agent-2',
            title: 'Agent 2',
            agentMdPath: '',
            workspaceId: '',
            skills: '',
          ),
        );
    dao = AchievementDao(db);
    repo = AchievementRepositoryImpl(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('unlock', () {
    test('creates a new achievement when none exists', () async {
      await repo.unlock('agent-1', 'first_merge');

      final achievements = await repo.getByAgent('agent-1');
      expect(achievements.length, 1);
      expect(achievements.first.agentId, 'agent-1');
      expect(achievements.first.badgeKey, 'first_merge');
      expect(achievements.first.id, isNotEmpty);
    });

    test('does not duplicate an existing achievement', () async {
      await repo.unlock('agent-1', 'first_merge');
      await repo.unlock('agent-1', 'first_merge');

      final achievements = await repo.getByAgent('agent-1');
      expect(achievements.length, 1);
    });

    test('different badges for same agent are independent', () async {
      await repo.unlock('agent-1', 'first_merge');
      await repo.unlock('agent-1', 'first_review');

      final achievements = await repo.getByAgent('agent-1');
      expect(achievements.length, 2);
      final keys = achievements.map((a) => a.badgeKey).toSet();
      expect(keys, containsAll(['first_merge', 'first_review']));
    });

    test('same badge for different agents are independent', () async {
      await repo.unlock('agent-1', 'first_merge');
      await repo.unlock('agent-2', 'first_merge');

      final a1 = await repo.getByAgent('agent-1');
      final a2 = await repo.getByAgent('agent-2');
      expect(a1.length, 1);
      expect(a2.length, 1);
    });

    test('stores optional metadata', () async {
      await repo.unlock('agent-1', 'milestone', metadata: '{"count": 100}');

      final achievements = await repo.getByAgent('agent-1');
      expect(achievements.first.metadata, '{"count": 100}');
    });
  });

  group('isUnlocked', () {
    test('returns false when not unlocked', () async {
      final result = await repo.isUnlocked('agent-1', 'first_merge');
      expect(result, isFalse);
    });

    test('returns true after unlock', () async {
      await repo.unlock('agent-1', 'first_merge');
      final result = await repo.isUnlocked('agent-1', 'first_merge');
      expect(result, isTrue);
    });

    test('returns false for different badge', () async {
      await repo.unlock('agent-1', 'first_merge');
      final result = await repo.isUnlocked('agent-1', 'other_badge');
      expect(result, isFalse);
    });
  });

  group('getByAgent', () {
    test('returns empty for unknown agent', () async {
      final achievements = await repo.getByAgent('nobody');
      expect(achievements, isEmpty);
    });

    test('returns all achievements ordered by unlock time desc', () async {
      await repo.unlock('agent-1', 'first');
      await Future.delayed(const Duration(milliseconds: 100));
      await repo.unlock('agent-1', 'second');

      final achievements = await repo.getByAgent('agent-1');
      expect(achievements.length, 2);
      // Most recently unlocked first
      expect(achievements.first.badgeKey, 'second');
      expect(achievements.last.badgeKey, 'first');
    });
  });

  group('watchByAgent', () {
    test('emits current achievements when watching', () async {
      await repo.unlock('agent-1', 'badge_1');

      final stream = repo.watchByAgent('agent-1');
      final results = await stream.first;

      expect(results.length, 1);
      expect(results.first.badgeKey, 'badge_1');
    });

    test('emits updates when new achievement unlocked', () async {
      await repo.unlock('agent-1', 'badge_1');

      final stream = repo.watchByAgent('agent-1');
      // Read first emission to latch the watch
      final subscription = stream.listen(null);
      await Future.delayed(const Duration(milliseconds: 50));

      await repo.unlock('agent-1', 'badge_2');

      // Collect the next emission
      final next = await stream.first;
      await subscription.cancel();

      expect(next.length, 2);
    });
  });

  group('DomainEventBus integration', () {
    test('publishes AchievementUnlocked event on unlock', () async {
      final events = <AchievementUnlocked>[];
      final eventBus = DomainEventBus();
      final sub = eventBus.on<AchievementUnlocked>().listen(events.add);

      final repo2 = AchievementRepositoryImpl(dao, eventBus: eventBus);
      await repo2.unlock('agent-1', 'published_badge');

      // Allow async event delivery
      await Future.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(events.length, 1);
      expect(events.first.agentId, 'agent-1');
      expect(events.first.badgeKey, 'published_badge');
    });

    test('does not publish event when achievement already exists', () async {
      await repo.unlock('agent-1', 'dup_badge');

      final events = <AchievementUnlocked>[];
      final eventBus = DomainEventBus();
      final sub = eventBus.on<AchievementUnlocked>().listen(events.add);

      final repo2 = AchievementRepositoryImpl(dao, eventBus: eventBus);
      await repo2.unlock('agent-1', 'dup_badge');

      await Future.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(events, isEmpty);
    });

    test('does not throw when eventBus is null', () async {
      final repoNoBus = AchievementRepositoryImpl(dao);
      // Should not throw
      await repoNoBus.unlock('agent-1', 'no_bus');
    });
  });
}
