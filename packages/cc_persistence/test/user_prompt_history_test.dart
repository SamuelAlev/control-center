import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  test('prompt history is the caller, oldest first, and capped', () async {
    final global = createTestGlobalDatabase();
    final manager = createTestWorkspaceDatabases(global: global);
    addTearDown(() async {
      await manager.closeAll();
      await global.close();
    });
    await seedTestWorkspace(global, manager, 'ws-hist');
    final db = manager.of('ws-hist');
    await db.messagingDao.insertSpace(
      SpacesTableCompanion.insert(id: 'sp', name: 'general'),
    );
    await db.into(db.conversationsTable).insert(
      ConversationsTableCompanion.insert(id: 'conv', spaceId: 'sp'),
    );

    Future<void> add(
      String id,
      String sender,
      String content, {
      bool compacted = false,
      String type = 'text',
    }) {
      return db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: id,
          spaceId: 'sp',
          conversationId: 'conv',
          senderId: sender,
          senderType: sender == 'me' ? 'user' : 'agent',
          content: content,
          messageType: Value(type),
          compacted: Value(compacted),
        ),
      );
    }

    await add('1', 'me', 'alpha');
    await add('2', 'me', 'alpha');
    await add('3', 'bot', 'nope', type: 'agent_turn');
    await add('4', 'other', 'beta');
    await add('5', 'me', 'gamma', compacted: true);
    await add('6', 'me', 'alpha');
    await add('7', 'me', '  delta  ');
    await add('8', 'me', '   ');

    final repo = DaoMessagingRepository(manager);
    final history = await repo
        .watchUserPromptHistory('ws-hist', 'sp', 'conv', 'me')
        .first;
    expect(history, ['alpha', 'alpha', 'delta']);

    for (var i = 0; i < 70; i++) {
      await add('x$i', 'me', 'p${i.toString().padLeft(2, '0')}');
    }
    final capped = await repo
        .watchUserPromptHistory('ws-hist', 'sp', 'conv', 'me')
        .first;
    expect(capped, hasLength(DaoMessagingRepository.promptHistoryRowLimit));
    expect(capped.first, 'p06');
    expect(capped.last, 'p69');
  });
}
