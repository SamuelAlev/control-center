import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
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
    // Space row + its conversation on its OWN id (conversation_messages
    // references both; a conversation id is never the space id).
    await db
        .into(db.spacesTable)
        .insert(const SpacesTableCompanion(id: Value('c'), name: Value('t')));
    await db
        .into(db.conversationsTable)
        .insert(
          const ConversationsTableCompanion(
            id: Value('conv-c'),
            spaceId: Value('c'),
          ),
        );
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Future<void> seed(int count) async {
    // Interleave user + agent messages, one second apart so ordering is stable.
    for (var i = 0; i < count; i++) {
      await db
          .into(db.conversationMessagesTable)
          .insert(
            ConversationMessagesTableCompanion(
              id: Value('m$i'),
              spaceId: const Value('c'),
              conversationId: const Value('conv-c'),
              senderId: Value(i.isEven ? 'user' : 'agent'),
              senderType: Value(i.isEven ? 'user' : 'agent'),
              content: Value('msg $i'),
              messageType: Value(i.isEven ? 'text' : 'agent_turn'),
              createdAt: Value(DateTime.utc(2026, 1, 1, 0, 0, i)),
            ),
          );
    }
  }

  test('paginates newest-first windows with a working cursor', () async {
    await seed(200);

    final page1 = await repo.getMessagePage('w-1', 'c', 'conv-c', limit: 80);
    expect(page1.messages.length, 80);
    expect(page1.hasMore, isTrue);
    expect(page1.nextCursor, isNotNull);
    // Newest 80 are the page (display ascending → last is the very newest).
    expect(page1.messages.last.id, 'm199');

    final page2 = await repo.getMessagePage(
      'w-1',
      'c',
      'conv-c',
      limit: 80,
      cursor: page1.nextCursor,
    );
    expect(page2.messages.length, 80);
    expect(page2.hasMore, isTrue);
    // Page 2 is strictly older than page 1's oldest.
    expect(
      page2.messages.last.createdAt.isBefore(page1.messages.first.createdAt),
      isTrue,
    );
    // No overlap between pages.
    final ids1 = page1.messages.map((m) => m.id).toSet();
    final ids2 = page2.messages.map((m) => m.id).toSet();
    expect(ids1.intersection(ids2), isEmpty);

    final page3 = await repo.getMessagePage(
      'w-1',
      'c',
      'conv-c',
      limit: 80,
      cursor: page2.nextCursor,
    );
    // 200 total → 80 + 80 + 40.
    expect(page3.messages.length, greaterThanOrEqualTo(40));
    expect(page3.hasMore, isFalse);
    expect(page3.nextCursor, isNull);
  });

  test('short history returns a single complete page', () async {
    await seed(10);
    final page = await repo.getMessagePage('w-1', 'c', 'conv-c', limit: 80);
    expect(page.messages.length, 10);
    expect(page.hasMore, isFalse);
    expect(page.messages.first.id, 'm0');
    expect(page.messages.last.id, 'm9');
  });

  test('empty space yields an empty page', () async {
    final page = await repo.getMessagePage('w-1', 'c', 'conv-c', limit: 80);
    expect(page, isA<MessagePage>());
    expect(page.messages, isEmpty);
    expect(page.hasMore, isFalse);
  });

  test('a page is bound to its space, not just its conversation id', () async {
    // The page query used to filter on the caller-supplied conversation id
    // ALONE. Callers prove they own a CHANNEL, so without this binding owning
    // any one space read every conversation in the workspace file. The
    // predicate is authorization, not a filter — for a legitimate caller
    // (a conversation belongs to exactly one space) it changes nothing.
    await db
        .into(db.spacesTable)
        .insert(
          const SpacesTableCompanion(id: Value('other'), name: Value('o')),
        );
    await db
        .into(db.conversationsTable)
        .insert(
          const ConversationsTableCompanion(
            id: Value('secret'),
            spaceId: Value('other'),
          ),
        );
    await db
        .into(db.conversationMessagesTable)
        .insert(
          ConversationMessagesTableCompanion(
            id: const Value('s0'),
            spaceId: const Value('other'),
            conversationId: const Value('secret'),
            senderId: const Value('user'),
            senderType: const Value('user'),
            content: const Value('private'),
            messageType: const Value('text'),
            createdAt: Value(DateTime.utc(2026, 1, 1)),
          ),
        );

    // Proving ownership of 'c' must not read 'other'\'s conversation.
    final stolen = await repo.getMessagePage('w-1', 'c', 'secret', limit: 80);
    expect(stolen.messages, isEmpty);
    expect(stolen.hasMore, isFalse);

    // The rightful space still reads it.
    final own = await repo.getMessagePage('w-1', 'other', 'secret', limit: 80);
    expect(own.messages.map((m) => m.id), ['s0']);
  });
}
