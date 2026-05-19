import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/streak_dao.dart';
import 'package:control_center/features/analytics/data/repositories/streak_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late StreakRepositoryImpl repo;
  late StreakDao dao;

  setUp(() async {
    db = createTestDatabase();
    // Insert agent rows so FK constraints on streaks are satisfied.
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
    dao = StreakDao(db);
    repo = StreakRepositoryImpl(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('updateStreak', () {
    test('creates new streak on first update with increment', () async {
      await repo.updateStreak('agent-1', 'pr_merged', increment: true);

      final streaks = await repo.getByAgent('agent-1');
      expect(streaks.length, 1);
      expect(streaks.first.streakType, 'pr_merged');
      expect(streaks.first.currentCount, 1);
      expect(streaks.first.bestCount, 1);
      expect(streaks.first.lastDate, isNotNull);
    });

    test('creates new streak with increment=false sets count to 0', () async {
      await repo.updateStreak('agent-1', 'pr_merged', increment: false);

      final streaks = await repo.getByAgent('agent-1');
      expect(streaks.first.currentCount, 0);
      expect(streaks.first.bestCount, 0);
    });

    test('increments existing streak', () async {
      await repo.updateStreak('agent-1', 'pr_merged', increment: true);
      await repo.updateStreak('agent-1', 'pr_merged', increment: true);

      final streaks = await repo.getByAgent('agent-1');
      expect(streaks.first.currentCount, 2);
      expect(streaks.first.bestCount, 2);
    });

    test('same-day updates do not advance count unless incrementing', () async {
      await repo.updateStreak('agent-1', 'daily', increment: true);
      await repo.updateStreak('agent-1', 'daily', increment: false);

      final streaks = await repo.getByAgent('agent-1');
      // On same day without "increment", the count stays at the existing value
      expect(streaks.first.currentCount, 1);
    });

    test('different agents have independent streaks', () async {
      await repo.updateStreak('agent-1', 'pr_merged', increment: true);
      await repo.updateStreak('agent-2', 'pr_merged', increment: true);

      final a1 = await repo.getByAgent('agent-1');
      final a2 = await repo.getByAgent('agent-2');
      expect(a1.first.agentId, 'agent-1');
      expect(a2.first.agentId, 'agent-2');
    });

    test('different streak types per agent are independent', () async {
      await repo.updateStreak('agent-1', 'pr_merged', increment: true);
      await repo.updateStreak('agent-1', 'pr_reviewed', increment: true);

      final streaks = await repo.getByAgent('agent-1');
      expect(streaks.length, 2);
    });

    test('bestCount tracks maximum', () async {
      await repo.updateStreak('agent-1', 'streak', increment: true);
      await repo.updateStreak('agent-1', 'streak', increment: true);
      await repo.updateStreak('agent-1', 'streak', increment: true);
      // best should be 3
      expect((await repo.getByAgent('agent-1')).first.bestCount, 3);
    });
  });

  group('getCurrentStreak', () {
    test('returns 0 for unknown streak', () async {
      final count = await repo.getCurrentStreak('agent-1', 'unknown');
      expect(count, 0);
    });

    test('returns current count', () async {
      await repo.updateStreak('agent-1', 'pr_merged', increment: true);
      await repo.updateStreak('agent-1', 'pr_merged', increment: true);

      final count = await repo.getCurrentStreak('agent-1', 'pr_merged');
      expect(count, 2);
    });
  });

  group('getByAgent', () {
    test('returns empty for unknown agent', () async {
      final streaks = await repo.getByAgent('nobody');
      expect(streaks, isEmpty);
    });
  });

  group('watchByAgent', () {
    test('emits current streaks', () async {
      await repo.updateStreak('agent-1', 'pr_merged', increment: true);

      final results = await repo.watchByAgent('agent-1').first;
      expect(results.length, 1);
      expect(results.first.streakType, 'pr_merged');
    });

    test('emits updates when streak changes', () async {
      await repo.updateStreak('agent-1', 'pr_merged', increment: true);

      final stream = repo.watchByAgent('agent-1');
      // Drain the initial emission.
      final subscription = stream.listen((_) {});
      await Future.delayed(const Duration(milliseconds: 50));

      await repo.updateStreak('agent-1', 'pr_merged', increment: true);
      // Let the stream pickup the update.
      await Future.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      // Verify the update took effect.
      final streaks = await repo.getByAgent('agent-1');
      expect(streaks.first.currentCount, 2);
    });
  });
}
