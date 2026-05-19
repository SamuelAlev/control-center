import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('CronExecutionDao', () {
    test('claimSlot records a fresh slot and returns true', () async {
      final claimed = await db.cronExecutionDao.claimSlot(
        id: 'ce-1',
        workspaceId: 'w-1',
        triggerId: 'trig-1',
        plannedAt: DateTime.utc(2025, 1, 1, 0, 15),
      );
      expect(claimed, isTrue);

      final rows = await db.cronExecutionDao.forTrigger('w-1', 'trig-1');
      expect(rows, hasLength(1));
      // The DAO normalizes plannedAt to UTC; Drift returns the stored instant in
      // the local zone, so compare in UTC.
      expect(rows.first.plannedAt.toUtc(), DateTime.utc(2025, 1, 1, 0, 15));
    });

    test(
      'claimSlot is idempotent for the same (triggerId, plannedAt) slot',
      () async {
        final slot = DateTime.utc(2025, 1, 1, 0, 15);
        final first = await db.cronExecutionDao.claimSlot(
          id: 'ce-1',
          workspaceId: 'w-1',
          triggerId: 'trig-1',
          plannedAt: slot,
        );
        final second = await db.cronExecutionDao.claimSlot(
          id: 'ce-2',
          workspaceId: 'w-1',
          triggerId: 'trig-1',
          plannedAt: slot,
        );
        expect(first, isTrue);
        expect(second, isFalse);

        // Only the first row was recorded.
        expect(
          await db.cronExecutionDao.forTrigger('w-1', 'trig-1'),
          hasLength(1),
        );
      },
    );

    test(
      'claimSlot allows the same triggerId at a different plannedAt',
      () async {
        final a = await db.cronExecutionDao.claimSlot(
          id: 'ce-1',
          workspaceId: 'w-1',
          triggerId: 'trig-1',
          plannedAt: DateTime.utc(2025, 1, 1, 0, 15),
        );
        final b = await db.cronExecutionDao.claimSlot(
          id: 'ce-2',
          workspaceId: 'w-1',
          triggerId: 'trig-1',
          plannedAt: DateTime.utc(2025, 1, 1, 0, 30),
        );
        expect(a, isTrue);
        expect(b, isTrue);
        expect(
          await db.cronExecutionDao.forTrigger('w-1', 'trig-1'),
          hasLength(2),
        );
      },
    );

    test('forTrigger is workspace-scoped', () async {
      await db.cronExecutionDao.claimSlot(
        id: 'ce-1',
        workspaceId: 'w-1',
        triggerId: 'trig-1',
        plannedAt: DateTime.utc(2025, 1, 1, 0, 15),
      );
      await db.cronExecutionDao.claimSlot(
        id: 'ce-2',
        workspaceId: 'w-2',
        triggerId: 'trig-1',
        plannedAt: DateTime.utc(2025, 1, 1, 0, 15),
      );
      expect(
        await db.cronExecutionDao.forTrigger('w-1', 'trig-1'),
        hasLength(1),
      );
    });

    test('forTrigger is newest-planned-first', () async {
      await db.cronExecutionDao.claimSlot(
        id: 'ce-1',
        workspaceId: 'w-1',
        triggerId: 'trig-1',
        plannedAt: DateTime.utc(2025, 1, 1, 0, 15),
      );
      await db.cronExecutionDao.claimSlot(
        id: 'ce-2',
        workspaceId: 'w-1',
        triggerId: 'trig-1',
        plannedAt: DateTime.utc(2025, 1, 1, 0, 30),
      );
      final rows = await db.cronExecutionDao.forTrigger('w-1', 'trig-1');
      expect(rows.first.plannedAt.toUtc(), DateTime.utc(2025, 1, 1, 0, 30));
    });

    test(
      'deleteOlderThan removes rows whose createdAt precedes the cutoff',
      () async {
        await db.cronExecutionDao.claimSlot(
          id: 'ce-1',
          workspaceId: 'w-1',
          triggerId: 'trig-1',
          plannedAt: DateTime.utc(2025, 1, 1, 0, 15),
        );
        // createdAt defaults to now, so deleteOlderThan(now + 1s) clears it.
        final deleted = await db.cronExecutionDao.deleteOlderThan(
          DateTime.now().add(const Duration(seconds: 1)),
        );
        expect(deleted, 1);
        expect(await db.cronExecutionDao.forTrigger('w-1', 'trig-1'), isEmpty);
      },
    );
  });
}
