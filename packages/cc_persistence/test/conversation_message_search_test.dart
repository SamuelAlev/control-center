import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// In-space full-text search (§8.4): the `conversation_messages_fts` index +
/// triggers must find messages by content, scoped to one space, excluding
/// reverted rows.
void main() {
  late WorkspaceDatabase db;

  Future<void> insertMsg(
    String id,
    String space,
    String content, {
    bool reverted = false,
  }) => db
      .into(db.conversationMessagesTable)
      .insert(
        ConversationMessagesTableCompanion(
          id: Value(id),
          spaceId: Value(space),
          conversationId: Value('conv-$space'),
          senderId: const Value('u1'),
          senderType: const Value('user'),
          content: Value(content),
          reverted: Value(reverted),
        ),
      );

  Future<void> insertSpace(String id) => db
      .into(db.spacesTable)
      .insert(
        SpacesTableCompanion(
          id: Value(id),
          name: Value(id.toUpperCase()),
          workspaceId: const Value('ws-1'),
        ),
      );

  /// The space's conversation, keyed on its OWN uuid — a conversation id is
  /// never the space id. Required because
  /// `conversation_messages.conversation_id` REFERENCES `conversations(id)`.
  Future<void> insertConversation(String spaceId) => db
      .into(db.conversationsTable)
      .insert(
        ConversationsTableCompanion(
          id: Value('conv-$spaceId'),
          spaceId: Value(spaceId),
          workspaceId: const Value('ws-1'),
        ),
      );

  setUp(() async {
    db = createTestDatabase(workspaceId: 'ws-1');
    await insertSpace('c1');
    await insertSpace('c2');
    await insertConversation('c1');
    await insertConversation('c2');
  });
  tearDown(() => db.close());

  test('finds a message by a content word, scoped to its space', () async {
    await insertMsg('m1', 'c1', 'the deployment pipeline is broken');
    await insertMsg('m2', 'c1', 'lunch plans for friday');
    await insertMsg('m3', 'c2', 'another deployment note'); // other space

    final hits = await db.messagingDao.searchInSpace('c1', 'deployment');
    expect(hits.map((m) => m.id), ['m1']);
  });

  test('does not leak results from another space', () async {
    await insertMsg('m1', 'c1', 'shared keyword apples');
    await insertMsg('m2', 'c2', 'shared keyword apples');

    final c1 = await db.messagingDao.searchInSpace('c1', 'apples');
    expect(c1.map((m) => m.id), ['m1']);
    final c2 = await db.messagingDao.searchInSpace('c2', 'apples');
    expect(c2.map((m) => m.id), ['m2']);
  });

  test('excludes reverted messages', () async {
    await insertMsg('m1', 'c1', 'reverted secret token', reverted: true);
    await insertMsg('m2', 'c1', 'live secret note');

    final hits = await db.messagingDao.searchInSpace('c1', 'secret');
    expect(hits.map((m) => m.id), ['m2']);
  });

  test('tracks edits via the update trigger', () async {
    await insertMsg('m1', 'c1', 'original wording');
    // No hit for the new term before the edit.
    expect(await db.messagingDao.searchInSpace('c1', 'rewritten'), isEmpty);
    await db.messagingDao.updateMessage('m1', content: 'rewritten wording');
    final hits = await db.messagingDao.searchInSpace('c1', 'rewritten');
    expect(hits.map((m) => m.id), ['m1']);
    // The old term no longer matches.
    expect(await db.messagingDao.searchInSpace('c1', 'original'), isEmpty);
  });

  test(
    'empty / stopword-only query returns nothing (no malformed MATCH)',
    () async {
      await insertMsg('m1', 'c1', 'hello world');
      expect(await db.messagingDao.searchInSpace('c1', '   '), isEmpty);
      expect(await db.messagingDao.searchInSpace('c1', 'the a of'), isEmpty);
    },
  );

  test('rebuild reindexes messages written before the index existed', () async {
    // Simulate the v31 migration path: drop the FTS index, insert while it is
    // absent (so the triggers can't fire), then recreate + rebuild.
    await db.customStatement('DROP TRIGGER IF EXISTS conversation_messages_ai');
    await db.customStatement('DROP TRIGGER IF EXISTS conversation_messages_ad');
    await db.customStatement('DROP TRIGGER IF EXISTS conversation_messages_au');
    await db.customStatement('DROP TABLE IF EXISTS conversation_messages_fts');
    await insertMsg('m1', 'c1', 'pre-existing indexable content');
    // Nothing yet — the index is gone.
    // Recreate via the same DDL the migration uses, then rebuild.
    await db.customStatement(
      'CREATE VIRTUAL TABLE IF NOT EXISTS conversation_messages_fts '
      'USING fts5(content, space_id, content=conversation_messages, content_rowid=rowid)',
    );
    await db.customStatement(
      "INSERT INTO conversation_messages_fts(conversation_messages_fts) VALUES('rebuild')",
    );
    final hits = await db.messagingDao.searchInSpace('c1', 'indexable');
    expect(hits.map((m) => m.id), ['m1']);
  });
}
