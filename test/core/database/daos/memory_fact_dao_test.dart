import 'package:control_center/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  MemoryFactsTableCompanion fact({
    required String id,
    required String workspaceId,
    String topic = 'deploy',
    String content = 'deployment runbook details',
  }) =>
      MemoryFactsTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        domain: 'ops',
        topic: topic,
        content: content,
      );

  setUp(() async {
    db = createTestDatabase();
    // memory_facts_table FKs to workspaces, so seed two workspaces first.
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'ws-1', name: 'WS 1'),
        );
    await db.into(db.workspacesTable).insert(
          WorkspacesTableCompanion.insert(id: 'ws-2', name: 'WS 2'),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('MemoryFactDao workspace isolation', () {
    test(
      'searchFts returns only the caller workspace, even when content collides',
      () async {
        // Identical topic + content in two workspaces. The FTS MATCH is scoped
        // to the caller at the index level, and the post-join workspace filter
        // is the authoritative boundary — neither may leak the other workspace.
        await db.memoryFactDao.upsert(fact(id: 'f-1', workspaceId: 'ws-1'));
        await db.memoryFactDao.upsert(fact(id: 'f-2', workspaceId: 'ws-2'));

        final ws1 = await db.memoryFactDao.searchFts('ws-1', 'deployment');
        expect(ws1.map((f) => f.id), ['f-1']);

        final ws2 = await db.memoryFactDao.searchFts('ws-2', 'deployment');
        expect(ws2.map((f) => f.id), ['f-2']);
      },
    );

    test('searchFts excludes superseded facts', () async {
      await db.memoryFactDao.upsert(
        fact(id: 'f-1', workspaceId: 'ws-1')
            .copyWith(supersededBy: const Value('f-x')),
      );
      expect(await db.memoryFactDao.searchFts('ws-1', 'deployment'), isEmpty);
    });

    test('getById is scoped to the workspace', () async {
      await db.memoryFactDao.upsert(fact(id: 'f-1', workspaceId: 'ws-1'));
      expect(await db.memoryFactDao.getById('ws-1', 'f-1'), isNotNull);
      // The id is a global UUID, but a foreign workspace must not resolve it.
      expect(await db.memoryFactDao.getById('ws-2', 'f-1'), isNull);
    });

    test('deleteById cannot delete another workspace fact', () async {
      await db.memoryFactDao.upsert(fact(id: 'f-1', workspaceId: 'ws-1'));

      await db.memoryFactDao.deleteById('ws-2', 'f-1'); // wrong workspace
      expect(await db.memoryFactDao.getById('ws-1', 'f-1'), isNotNull);

      await db.memoryFactDao.deleteById('ws-1', 'f-1'); // owning workspace
      expect(await db.memoryFactDao.getById('ws-1', 'f-1'), isNull);
    });
  });
}
