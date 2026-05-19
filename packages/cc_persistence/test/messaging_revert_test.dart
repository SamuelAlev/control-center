import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late WorkspaceDatabase db;
  late DaoMessagingRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    db = dbs.of('w-1');
    repo = DaoMessagingRepository(dbs);
    await db
        .into(db.channelsTable)
        .insert(const ChannelsTableCompanion(id: Value('c'), name: Value('t')));
    await db
        .into(db.conversationsTable)
        .insert(
          const ConversationsTableCompanion(
            id: Value('c'),
            channelId: Value('c'),
          ),
        );
    for (var i = 0; i < 6; i++) {
      await db
          .into(db.channelMessagesTable)
          .insert(
            ChannelMessagesTableCompanion(
              id: Value('m$i'),
              channelId: const Value('c'),
              conversationId: const Value('c'),
              senderId: const Value('user'),
              senderType: const Value('user'),
              content: Value('msg $i'),
              createdAt: Value(DateTime.utc(2026, 1, 1, 0, 0, i)),
            ),
          );
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  test('revertConversationTo hides newer messages, keeps the target', () async {
    final reverted = await repo.revertConversationTo('w-1', 'c', 'm2');
    expect(reverted, ['m3', 'm4', 'm5']);

    final live = await repo.getMessages('w-1', 'c');
    expect(live.map((m) => m.id), ['m0', 'm1', 'm2']);
  });

  test('inclusive revert hides the target too', () async {
    final reverted = await repo.revertConversationTo(
      'w-1',
      'c',
      'm2',
      inclusive: true,
    );
    expect(reverted, ['m2', 'm3', 'm4', 'm5']);
    final live = await repo.getMessages('w-1', 'c');
    expect(live.map((m) => m.id), ['m0', 'm1']);
  });

  test('unrevert restores the most-recent batch', () async {
    await repo.revertConversationTo('w-1', 'c', 'm4'); // reverts m5
    await repo.revertConversationTo(
      'w-1',
      'c',
      'm2',
    ); // reverts m3, m4 (m5 older batch)

    final restored = await repo.unrevertConversation('w-1', 'c');
    expect(restored.toSet(), {'m3', 'm4'});

    final live = await repo.getMessages('w-1', 'c');
    // m5 stays reverted (older batch); m3/m4 came back.
    expect(live.map((m) => m.id), ['m0', 'm1', 'm2', 'm3', 'm4']);
  });

  test('unrevert is a no-op when nothing is reverted', () async {
    final restored = await repo.unrevertConversation('w-1', 'c');
    expect(restored, isEmpty);
  });

  test('reverting an unknown message changes nothing', () async {
    final reverted = await repo.revertConversationTo('w-1', 'c', 'nope');
    expect(reverted, isEmpty);
    final live = await repo.getMessages('w-1', 'c');
    expect(live.length, 6);
  });
}
