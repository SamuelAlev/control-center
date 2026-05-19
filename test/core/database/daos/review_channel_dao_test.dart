import 'package:control_center/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // review_channels has enforced FKs to workspaces + channels, so seed those.
  Future<void> seedWorkspace(String id) => db
      .into(db.workspacesTable)
      .insert(WorkspacesTableCompanion.insert(id: id, name: 'WS $id'));

  Future<void> seedChannel(String id) => db
      .into(db.channelsTable)
      .insert(ChannelsTableCompanion.insert(id: id, name: 'Ch $id'));

  Future<void> insertAssoc(
    String id,
    String workspaceId,
    String prNodeId,
    String channelId,
  ) async {
    await seedChannel(channelId);
    await db.reviewChannelDao.insertAssociation(
      ReviewChannelsTableCompanion.insert(
        id: id,
        channelId: channelId,
        workspaceId: workspaceId,
        prNodeId: prNodeId,
        prNumber: 1,
        repoFullName: 'octo/repo',
      ),
    );
  }

  group('ReviewChannelDao workspace isolation', () {
    test('watchByPr returns only the active workspace\'s association', () async {
      // The same PR node id linked into two different workspaces.
      await seedWorkspace('ws-a');
      await seedWorkspace('ws-b');
      await insertAssoc('assoc-a', 'ws-a', 'PR_NODE_1', 'channel-a');
      await insertAssoc('assoc-b', 'ws-b', 'PR_NODE_1', 'channel-b');

      final inA = await db.reviewChannelDao.watchByPr('ws-a', 'PR_NODE_1').first;
      final inB = await db.reviewChannelDao.watchByPr('ws-b', 'PR_NODE_1').first;

      expect(inA, isNotNull);
      expect(inA!.workspaceId, 'ws-a');
      expect(inA.channelId, 'channel-a');

      expect(inB, isNotNull);
      expect(inB!.workspaceId, 'ws-b');
      expect(inB.channelId, 'channel-b');
    });

    test('watchByPr returns null for a workspace with no association', () async {
      await seedWorkspace('ws-a');
      await insertAssoc('assoc-a', 'ws-a', 'PR_NODE_1', 'channel-a');

      final other =
          await db.reviewChannelDao.watchByPr('ws-other', 'PR_NODE_1').first;

      expect(other, isNull);
    });
  });
}
