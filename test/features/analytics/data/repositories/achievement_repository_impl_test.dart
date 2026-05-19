import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/events/analytics_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/achievement_dao.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/repositories/achievement_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late AchievementRepositoryImpl repo;
  late AchievementDao dao;
  late AgentDao agentDao;

  Future<void> seedWorkspace(String id) async {
    await db.workspaceDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(id: id, name: id),
    );
  }

  Future<void> seedAgent(String id, String workspaceId) async {
    await db.into(db.agentsTable).insert(
          AgentsTableCompanion.insert(
            id: id,
            name: id,
            title: id,
            agentMdPath: '',
            workspaceId: workspaceId,
            skills: '',
          ),
        );
  }

  setUp(() async {
    db = createTestDatabase();
    await seedWorkspace('ws-1');
    // Insert agent rows so FK constraints on achievements are satisfied.
    await seedAgent('agent-1', 'ws-1');
    await seedAgent('agent-2', 'ws-1');
    dao = AchievementDao(db);
    agentDao = AgentDao(db);
    repo = AchievementRepositoryImpl(dao, agentDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('unlock', () {
    test('creates a new achievement when none exists', () async {
      await repo.unlock('ws-1', 'agent-1', 'first_merge');

      final achievements = await repo.getByAgent('ws-1', 'agent-1');
      expect(achievements.length, 1);
      expect(achievements.first.agentId, 'agent-1');
      expect(achievements.first.badgeKey, 'first_merge');
      expect(achievements.first.id, isNotEmpty);
    });

    test('does not duplicate an existing achievement', () async {
      await repo.unlock('ws-1', 'agent-1', 'first_merge');
      await repo.unlock('ws-1', 'agent-1', 'first_merge');

      final achievements = await repo.getByAgent('ws-1', 'agent-1');
      expect(achievements.length, 1);
    });

    test('different badges for same agent are independent', () async {
      await repo.unlock('ws-1', 'agent-1', 'first_merge');
      await repo.unlock('ws-1', 'agent-1', 'first_review');

      final achievements = await repo.getByAgent('ws-1', 'agent-1');
      expect(achievements.length, 2);
      final keys = achievements.map((a) => a.badgeKey).toSet();
      expect(keys, containsAll(['first_merge', 'first_review']));
    });

    test('same badge for different agents are independent', () async {
      await repo.unlock('ws-1', 'agent-1', 'first_merge');
      await repo.unlock('ws-1', 'agent-2', 'first_merge');

      final a1 = await repo.getByAgent('ws-1', 'agent-1');
      final a2 = await repo.getByAgent('ws-1', 'agent-2');
      expect(a1.length, 1);
      expect(a2.length, 1);
    });

    test('stores optional metadata', () async {
      await repo.unlock('ws-1', 'agent-1', 'milestone', metadata: '{"count": 100}');

      final achievements = await repo.getByAgent('ws-1', 'agent-1');
      expect(achievements.first.metadata, '{"count": 100}');
    });
  });

  group('isUnlocked', () {
    test('returns false when not unlocked', () async {
      final result = await repo.isUnlocked('ws-1', 'agent-1', 'first_merge');
      expect(result, isFalse);
    });

    test('returns true after unlock', () async {
      await repo.unlock('ws-1', 'agent-1', 'first_merge');
      final result = await repo.isUnlocked('ws-1', 'agent-1', 'first_merge');
      expect(result, isTrue);
    });

    test('returns false for different badge', () async {
      await repo.unlock('ws-1', 'agent-1', 'first_merge');
      final result = await repo.isUnlocked('ws-1', 'agent-1', 'other_badge');
      expect(result, isFalse);
    });
  });

  group('getByAgent', () {
    test('returns empty for unknown agent', () async {
      final achievements = await repo.getByAgent('ws-1', 'nobody');
      expect(achievements, isEmpty);
    });

    test('returns all achievements ordered by unlock time desc', () async {
      await repo.unlock('ws-1', 'agent-1', 'first');
      await Future.delayed(const Duration(milliseconds: 100));
      await repo.unlock('ws-1', 'agent-1', 'second');

      final achievements = await repo.getByAgent('ws-1', 'agent-1');
      expect(achievements.length, 2);
      // Most recently unlocked first
      expect(achievements.first.badgeKey, 'second');
      expect(achievements.last.badgeKey, 'first');
    });
  });

  group('watchByAgent', () {
    test('emits current achievements when watching', () async {
      await repo.unlock('ws-1', 'agent-1', 'badge_1');

      final stream = repo.watchByAgent('ws-1', 'agent-1');
      final results = await stream.first;

      expect(results.length, 1);
      expect(results.first.badgeKey, 'badge_1');
    });

    test('emits updates when new achievement unlocked', () async {
      await repo.unlock('ws-1', 'agent-1', 'badge_1');

      final stream = repo.watchByAgent('ws-1', 'agent-1');
      // Read first emission to latch the watch
      final subscription = stream.listen(null);
      await Future.delayed(const Duration(milliseconds: 50));

      await repo.unlock('ws-1', 'agent-1', 'badge_2');

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

      final repo2 = AchievementRepositoryImpl(dao, agentDao, eventBus: eventBus);
      await repo2.unlock('ws-1', 'agent-1', 'published_badge');

      // Allow async event delivery
      await Future.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(events.length, 1);
      expect(events.first.agentId, 'agent-1');
      expect(events.first.badgeKey, 'published_badge');
    });

    test('does not publish event when achievement already exists', () async {
      await repo.unlock('ws-1', 'agent-1', 'dup_badge');

      final events = <AchievementUnlocked>[];
      final eventBus = DomainEventBus();
      final sub = eventBus.on<AchievementUnlocked>().listen(events.add);

      final repo2 = AchievementRepositoryImpl(dao, agentDao, eventBus: eventBus);
      await repo2.unlock('ws-1', 'agent-1', 'dup_badge');

      await Future.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(events, isEmpty);
    });

    test('does not throw when eventBus is null', () async {
      final repoNoBus = AchievementRepositoryImpl(dao, agentDao);
      // Should not throw
      await repoNoBus.unlock('ws-1', 'agent-1', 'no_bus');
    });
  });

  // ─── Workspace isolation ─────────────────────────────────────────────
  //
  // agent-2 lives in ws-2. A caller in ws-1 must not be able to read or write
  // its achievements — reads return nothing, writes are rejected loudly.
  group('workspace isolation', () {
    setUp(() async {
      await seedWorkspace('ws-2');
      await seedAgent('agent-foreign', 'ws-2');
    });

    test('unlock rejects an agent that belongs to another workspace', () async {
      expect(
        () => repo.unlock('ws-1', 'agent-foreign', 'first_merge'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      // Nothing was written for the foreign agent.
      final inOwn = await repo.getByAgent('ws-2', 'agent-foreign');
      expect(inOwn, isEmpty);
    });

    test('isUnlocked rejects a foreign-workspace agent', () async {
      expect(
        () => repo.isUnlocked('ws-1', 'agent-foreign', 'first_merge'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });

    test('getByAgent returns nothing for a foreign-workspace agent', () async {
      // agent-foreign has a real achievement in ws-2.
      await repo.unlock('ws-2', 'agent-foreign', 'first_merge');

      // Reading it via ws-1 must surface nothing.
      final viaWrongWorkspace = await repo.getByAgent('ws-1', 'agent-foreign');
      expect(viaWrongWorkspace, isEmpty);

      // Reading it via its own workspace works.
      final viaOwnWorkspace = await repo.getByAgent('ws-2', 'agent-foreign');
      expect(viaOwnWorkspace, hasLength(1));
    });

    test('watchByAgent returns nothing for a foreign-workspace agent',
        () async {
      await repo.unlock('ws-2', 'agent-foreign', 'first_merge');

      final viaWrongWorkspace =
          await repo.watchByAgent('ws-1', 'agent-foreign').first;
      expect(viaWrongWorkspace, isEmpty);
    });
  });
}
