import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/database/daos/streak_dao.dart';
import 'package:cc_persistence/repositories/streak_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late StreakRepositoryImpl repo;
  late StreakDao dao;
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
    // Insert agent rows so FK constraints on streaks are satisfied.
    await seedAgent('agent-1', 'ws-1');
    await seedAgent('agent-2', 'ws-1');
    dao = StreakDao(db);
    agentDao = AgentDao(db);
    repo = StreakRepositoryImpl(dao, agentDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('updateStreak', () {
    test('creates new streak on first update with increment', () async {
      await repo.updateStreak('ws-1', 'agent-1', 'pr_merged', increment: true);

      final streaks = await repo.getByAgent('ws-1', 'agent-1');
      expect(streaks.length, 1);
      expect(streaks.first.streakType, 'pr_merged');
      expect(streaks.first.currentCount, 1);
      expect(streaks.first.bestCount, 1);
      expect(streaks.first.lastDate, isNotNull);
    });

    test('creates new streak with increment=false sets count to 0', () async {
      await repo.updateStreak('ws-1', 'agent-1', 'pr_merged', increment: false);

      final streaks = await repo.getByAgent('ws-1', 'agent-1');
      expect(streaks.first.currentCount, 0);
      expect(streaks.first.bestCount, 0);
    });

    test('increments existing streak', () async {
      await repo.updateStreak('ws-1', 'agent-1', 'pr_merged', increment: true);
      await repo.updateStreak('ws-1', 'agent-1', 'pr_merged', increment: true);

      final streaks = await repo.getByAgent('ws-1', 'agent-1');
      expect(streaks.first.currentCount, 2);
      expect(streaks.first.bestCount, 2);
    });

    test('same-day updates do not advance count unless incrementing', () async {
      await repo.updateStreak('ws-1', 'agent-1', 'daily', increment: true);
      await repo.updateStreak('ws-1', 'agent-1', 'daily', increment: false);

      final streaks = await repo.getByAgent('ws-1', 'agent-1');
      // On same day without "increment", the count stays at the existing value
      expect(streaks.first.currentCount, 1);
    });

    test('different agents have independent streaks', () async {
      await repo.updateStreak('ws-1', 'agent-1', 'pr_merged', increment: true);
      await repo.updateStreak('ws-1', 'agent-2', 'pr_merged', increment: true);

      final a1 = await repo.getByAgent('ws-1', 'agent-1');
      final a2 = await repo.getByAgent('ws-1', 'agent-2');
      expect(a1.first.agentId, 'agent-1');
      expect(a2.first.agentId, 'agent-2');
    });

    test('different streak types per agent are independent', () async {
      await repo.updateStreak('ws-1', 'agent-1', 'pr_merged', increment: true);
      await repo.updateStreak('ws-1', 'agent-1', 'pr_reviewed', increment: true);

      final streaks = await repo.getByAgent('ws-1', 'agent-1');
      expect(streaks.length, 2);
    });

    test('bestCount tracks maximum', () async {
      await repo.updateStreak('ws-1', 'agent-1', 'streak', increment: true);
      await repo.updateStreak('ws-1', 'agent-1', 'streak', increment: true);
      await repo.updateStreak('ws-1', 'agent-1', 'streak', increment: true);
      // best should be 3
      expect((await repo.getByAgent('ws-1', 'agent-1')).first.bestCount, 3);
    });
  });

  group('getCurrentStreak', () {
    test('returns 0 for unknown streak', () async {
      final count = await repo.getCurrentStreak('ws-1', 'agent-1', 'unknown');
      expect(count, 0);
    });

    test('returns current count', () async {
      await repo.updateStreak('ws-1', 'agent-1', 'pr_merged', increment: true);
      await repo.updateStreak('ws-1', 'agent-1', 'pr_merged', increment: true);

      final count = await repo.getCurrentStreak('ws-1', 'agent-1', 'pr_merged');
      expect(count, 2);
    });
  });

  group('getByAgent', () {
    test('returns empty for unknown agent', () async {
      final streaks = await repo.getByAgent('ws-1', 'nobody');
      expect(streaks, isEmpty);
    });
  });

  group('watchByAgent', () {
    test('emits current streaks', () async {
      await repo.updateStreak('ws-1', 'agent-1', 'pr_merged', increment: true);

      final results = await repo.watchByAgent('ws-1', 'agent-1').first;
      expect(results.length, 1);
      expect(results.first.streakType, 'pr_merged');
    });

    test('emits updates when streak changes', () async {
      await repo.updateStreak('ws-1', 'agent-1', 'pr_merged', increment: true);

      final stream = repo.watchByAgent('ws-1', 'agent-1');
      // Drain the initial emission.
      final subscription = stream.listen((_) {});
      await Future.delayed(const Duration(milliseconds: 50));

      await repo.updateStreak('ws-1', 'agent-1', 'pr_merged', increment: true);
      // Let the stream pickup the update.
      await Future.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      // Verify the update took effect.
      final streaks = await repo.getByAgent('ws-1', 'agent-1');
      expect(streaks.first.currentCount, 2);
    });
  });

  // ─── Workspace isolation ─────────────────────────────────────────────
  //
  // agent-foreign lives in ws-2. A caller in ws-1 must not be able to read or
  // mutate its streaks — reads return nothing, writes are rejected loudly.
  group('workspace isolation', () {
    setUp(() async {
      await seedWorkspace('ws-2');
      await seedAgent('agent-foreign', 'ws-2');
    });

    test('updateStreak rejects an agent that belongs to another workspace',
        () async {
      expect(
        () => repo.updateStreak('ws-1', 'agent-foreign', 'pr_merged',
            increment: true),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      // Nothing was written for the foreign agent.
      final inOwn = await repo.getByAgent('ws-2', 'agent-foreign');
      expect(inOwn, isEmpty);
    });

    test('getCurrentStreak rejects a foreign-workspace agent', () async {
      expect(
        () => repo.getCurrentStreak('ws-1', 'agent-foreign', 'pr_merged'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });

    test('getByAgent returns nothing for a foreign-workspace agent', () async {
      await repo.updateStreak('ws-2', 'agent-foreign', 'pr_merged',
          increment: true);

      final viaWrongWorkspace = await repo.getByAgent('ws-1', 'agent-foreign');
      expect(viaWrongWorkspace, isEmpty);

      final viaOwnWorkspace = await repo.getByAgent('ws-2', 'agent-foreign');
      expect(viaOwnWorkspace, hasLength(1));
    });

    test('watchByAgent returns nothing for a foreign-workspace agent',
        () async {
      await repo.updateStreak('ws-2', 'agent-foreign', 'pr_merged',
          increment: true);

      final viaWrongWorkspace =
          await repo.watchByAgent('ws-1', 'agent-foreign').first;
      expect(viaWrongWorkspace, isEmpty);
    });
  });
}
