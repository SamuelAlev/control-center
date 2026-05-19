import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> item({
    required String id,
    required String ws,
    required String agentId,
    String content = 'c',
    DateTime? expiresAt,
  }) => db.workingMemoryItemDao.upsert(
    WorkingMemoryItemsTableCompanion.insert(
      id: id,
      workspaceId: ws,
      agentId: agentId,
      content: content,
      expiresAt: expiresAt == null ? const Value.absent() : Value(expiresAt),
    ),
  );

  group('WorkingMemoryItemDao workspace isolation', () {
    test('getForAgent + getForWorkspace are workspace-scoped', () async {
      await item(id: 'i-1', ws: 'w-1', agentId: 'a-1');
      await item(id: 'i-2', ws: 'w-2', agentId: 'a-1');
      expect(
        await db.workingMemoryItemDao.getForAgent('w-1', 'a-1'),
        hasLength(1),
      );
      expect(
        await db.workingMemoryItemDao.getForWorkspace('w-1'),
        hasLength(1),
      );
      expect(
        await db.workingMemoryItemDao.getForWorkspace('w-2'),
        hasLength(1),
      );
    });

    test('watchForAgent emits scoped rows', () async {
      await item(id: 'i-1', ws: 'w-1', agentId: 'a-1');
      final rows = await db.workingMemoryItemDao
          .watchForAgent('w-1', 'a-1')
          .first;
      expect(rows, hasLength(1));
    });

    test(
      'deleteByIds is workspace-scoped and a no-op for empty input',
      () async {
        await item(id: 'i-1', ws: 'w-1', agentId: 'a-1');
        await item(id: 'i-2', ws: 'w-1', agentId: 'a-1');
        // empty list short-circuits
        await db.workingMemoryItemDao.deleteByIds('w-1', const []);
        expect(
          await db.workingMemoryItemDao.getForWorkspace('w-1'),
          hasLength(2),
        );

        // foreign workspace cannot delete
        await db.workingMemoryItemDao.deleteByIds('w-2', ['i-1']);
        expect(
          await db.workingMemoryItemDao.getForWorkspace('w-1'),
          hasLength(2),
        );

        await db.workingMemoryItemDao.deleteByIds('w-1', ['i-1']);
        expect(
          await db.workingMemoryItemDao.getForWorkspace('w-1'),
          hasLength(1),
        );
      },
    );

    test('deleteExpired removes only past-due rows in the workspace', () async {
      await item(
        id: 'i-1',
        ws: 'w-1',
        agentId: 'a-1',
        expiresAt: DateTime.utc(2020, 1, 1),
      );
      await item(
        id: 'i-2',
        ws: 'w-1',
        agentId: 'a-1',
        expiresAt: DateTime.utc(2030, 1, 1),
      );
      // a row with no expiry is never reaped
      await item(id: 'i-3', ws: 'w-1', agentId: 'a-1');

      final deleted = await db.workingMemoryItemDao.deleteExpired(
        'w-1',
        DateTime.utc(2025, 1, 1),
      );
      expect(deleted, 1);
      expect(
        await db.workingMemoryItemDao.getForWorkspace('w-1'),
        hasLength(2),
      );
    });
  });
}
