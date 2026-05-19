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

  Future<void> seedSpace(String id) => db
      .into(db.spacesTable)
      .insert(SpacesTableCompanion.insert(id: id, name: 'Ch $id'));

  Future<void> insertAssoc(
    String id,
    String workspaceId,
    String prExternalId,
    String spaceId,
  ) async {
    await seedSpace(spaceId);
    await db.reviewSpaceDao.insertAssociation(
      ReviewSpacesTableCompanion.insert(
        id: id,
        spaceId: spaceId,
        workspaceId: workspaceId,
        prExternalId: prExternalId,
        prNumber: 1,
        repoFullName: 'octo/repo',
      ),
    );
  }

  group('ReviewSpaceDao workspace isolation', () {
    test('watchByPr returns only the active workspace\'s association', () async {
      // The same PR node id linked into two different workspaces. Both rows sit
      // in one database file here; what is under test is the DAO's
      // `WHERE workspace_id = ?`, not the per-file split.
      await insertAssoc('assoc-a', 'ws-a', 'PR_NODE_1', 'channel-a');
      await insertAssoc('assoc-b', 'ws-b', 'PR_NODE_1', 'channel-b');

      final inA = await db.reviewSpaceDao.watchByPr('ws-a', 'PR_NODE_1').first;
      final inB = await db.reviewSpaceDao.watchByPr('ws-b', 'PR_NODE_1').first;

      expect(inA, isNotNull);
      expect(inA!.workspaceId, 'ws-a');
      expect(inA.spaceId, 'channel-a');

      expect(inB, isNotNull);
      expect(inB!.workspaceId, 'ws-b');
      expect(inB.spaceId, 'channel-b');
    });

    test(
      'watchByPr returns null for a workspace with no association',
      () async {
        await insertAssoc('assoc-a', 'ws-a', 'PR_NODE_1', 'channel-a');

        final other = await db.reviewSpaceDao
            .watchByPr('ws-other', 'PR_NODE_1')
            .first;

        expect(other, isNull);
      },
    );
  });
}
