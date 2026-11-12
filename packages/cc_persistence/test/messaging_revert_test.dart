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
        .into(db.spacesTable)
        .insert(
          const SpacesTableCompanion(
            id: Value('c'),
            name: Value('t'),
            workspaceId: Value('w-1'),
          ),
        );
    await db
        .into(db.conversationsTable)
        .insert(
          const ConversationsTableCompanion(
            id: Value('c'),
            spaceId: Value('c'),
            workspaceId: Value('w-1'),
          ),
        );
    for (var i = 0; i < 6; i++) {
      await db
          .into(db.conversationMessagesTable)
          .insert(
            ConversationMessagesTableCompanion(
              id: Value('m$i'),
              spaceId: const Value('c'),
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

  test('a revert whose tip move fails hides nothing', () async {
    // Fail the last step, moving the branch tip. The read, the hide and the
    // tip move are one unit: none of it may stay behind.
    await db.customStatement(
      'CREATE TRIGGER fail_leaf BEFORE UPDATE OF leaf_message_id '
      "ON conversations BEGIN SELECT RAISE(ABORT, 'leaf write refused'); END",
    );

    await expectLater(
      repo.revertConversationTo('w-1', 'c', 'm2'),
      throwsA(anything),
    );

    final live = await repo.getMessages('w-1', 'c');
    expect(live, hasLength(6));
  });

  test('the activity row follows a revert and its undo', () async {
    await (db.update(db.spacesTable)..where((t) => t.id.equals('c'))).write(
      const SpacesTableCompanion(workspaceId: Value('w-1')),
    );
    final before = await db.messagingDao.watchSpaceActivity('w-1').first;
    await repo.revertConversationTo('w-1', 'c', 'm2');
    final reverted = await db.messagingDao.watchSpaceActivity('w-1').first;
    expect(
      reverted.single.lastMessageAt.toUtc(),
      DateTime.utc(2026, 1, 1, 0, 0, 2),
    );

    await repo.unrevertConversation('w-1', 'c');
    expect(await db.messagingDao.watchSpaceActivity('w-1').first, before);
  });
}
