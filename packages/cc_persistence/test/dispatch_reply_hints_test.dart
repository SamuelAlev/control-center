import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoMessagingRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    repo = DaoMessagingRepository(dbs);
    final db = dbs.of('ws-1');
    await db.messagingDao.insertSpace(
      SpacesTableCompanion.insert(
        id: 's',
        name: 'S',
        workspaceId: const Value('ws-1'),
      ),
    );
    await db.conversationDao.insertConversation(
      ConversationsTableCompanion.insert(
        id: 'c',
        spaceId: 's',
        workspaceId: const Value('ws-1'),
      ),
    );
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Future<void> message({
    required String id,
    required String senderId,
    required String senderType,
    required String messageType,
    required int second,
    String content = 'body',
    String? metadata,
    bool reverted = false,
    String conversationId = 'c',
  }) {
    return dbs.of('ws-1').messagingDao.insertMessage(
      ConversationMessagesTableCompanion.insert(
        id: id,
        spaceId: 's',
        conversationId: conversationId,
        senderId: senderId,
        senderType: senderType,
        content: content,
        messageType: Value(messageType),
        createdAt: Value(DateTime.utc(2026, 1, 1, 0, 0, second)),
        metadata: Value(metadata),
        reverted: Value(reverted),
      ),
    );
  }

  test('reply hints skip transcript blobs', () async {
    final chunk = 'x' * 4000;
    final blob = '{"segments":[{"t":"$chunk"}]}';
    await message(
      id: 'agent-old',
      senderId: 'agent-old',
      senderType: 'agent',
      messageType: 'agent_turn',
      second: 1,
      metadata: blob,
    );
    await message(
      id: 'agent-new',
      senderId: 'agent-new',
      senderType: 'agent',
      messageType: 'text',
      second: 2,
    );
    await message(
      id: 'steer',
      senderId: 'agent-steer',
      senderType: 'agent',
      messageType: 'steering',
      second: 3,
    );
    await message(
      id: 'reverted-agent',
      senderId: 'agent-reverted',
      senderType: 'agent',
      messageType: 'text',
      second: 4,
      reverted: true,
    );
    await message(
      id: 'plan-old',
      senderId: 'agent-new',
      senderType: 'agent',
      messageType: 'plan',
      second: 5,
      metadata: '{}',
    );
    await message(
      id: 'plan-new',
      senderId: 'agent-other',
      senderType: 'agent',
      messageType: 'plan',
      second: 6,
      metadata: '{"planStatus":"approved"}',
    );
    await message(
      id: 'user',
      senderId: 'user',
      senderType: 'user',
      messageType: 'text',
      second: 7,
      content: 'go',
    );

    final dao = dbs.of('ws-1').messagingDao;
    expect(await dao.latestAgentSenderId('c'), 'agent-new');
    final kinds = await dao.recentLiveMessageKinds('c');
    expect(kinds.map((k) => k.messageType).toList(), ['text', 'plan']);
    expect(kinds[1].planStatus, 'approved');
    expect(await dao.latestPlanMessageId('c', pendingOnly: true), 'plan-old');
    expect(await dao.latestPlanMessageId('c'), 'plan-new');

    final hints = await repo.dispatchReplyHints(
      workspaceId: 'ws-1',
      spaceId: 's',
      conversationId: 'c',
    );
    expect(hints.previousIsPendingPlan, isFalse);
    expect(hints.lastAgentSenderId, 'agent-new');

    final standing = await repo.dispatchReplyHints(
      workspaceId: 'ws-1',
      spaceId: 's',
    );
    expect(standing.previousIsPendingPlan, isFalse);
    expect(standing.lastAgentSenderId, 'agent-new');

    final plan = await repo.latestPlanMessage(
      workspaceId: 'ws-1',
      spaceId: 's',
    );
    expect(plan?.id, 'plan-old');
    expect(plan?.planStatus, 'pending');

    final db = dbs.of('ws-1');
    for (final sql in [
      MessagingDao.latestAgentSenderSql,
      MessagingDao.recentLiveMessageKindsSql,
      MessagingDao.latestPendingPlanIdSql,
      MessagingDao.latestPlanIdSql,
    ]) {
      expect(sql.contains('content'), isFalse);
      final rows = await db
          .customSelect(
            'EXPLAIN QUERY PLAN $sql',
            variables: [Variable.withString('c')],
          )
          .get();
      final planText = rows.map((r) => r.data.values.join(' ')).join('\n');
      expect(
        planText,
        contains('idx_conversation_messages_conversation_created'),
      );
    }
    expect(MessagingDao.latestAgentSenderSql.contains('metadata'), isFalse);
    expect(MessagingDao.recentLiveMessageKindsSql.contains('segments'), isFalse);
  });

  test('a pending plan immediately before the send is the previous message',
      () async {
    await message(
      id: 'agent',
      senderId: 'agent-1',
      senderType: 'agent',
      messageType: 'agent_turn',
      second: 1,
    );
    await message(
      id: 'plan',
      senderId: 'agent-1',
      senderType: 'agent',
      messageType: 'plan',
      second: 2,
      metadata: '{"planStatus":"pending"}',
    );
    await message(
      id: 'user',
      senderId: 'user',
      senderType: 'user',
      messageType: 'text',
      second: 3,
    );
    final hints = await repo.dispatchReplyHints(
      workspaceId: 'ws-1',
      spaceId: 's',
      conversationId: 'c',
    );
    expect(hints.previousIsPendingPlan, isTrue);
    expect(hints.lastAgentSenderId, 'agent-1');
  });

  test('same-second agent rows keep insertion order', () async {
    final at = Value(DateTime.utc(2026, 1, 1, 0, 0, 10));
    final dao = dbs.of('ws-1').messagingDao;
    for (final id in ['first-agent', 'second-agent']) {
      await dao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: id,
          spaceId: 's',
          conversationId: 'c',
          senderId: id,
          senderType: 'agent',
          content: id,
          messageType: const Value('text'),
          createdAt: at,
        ),
      );
    }
    expect(await dao.latestAgentSenderId('c'), 'second-agent');
  });
}
