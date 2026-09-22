import 'dart:typed_data';

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
    required String senderType,
    required String messageType,
    required int second,
    String? senderId,
    String content = 'body',
    String? metadata,
    bool compacted = false,
    Uint8List? embedding,
  }) {
    return dbs.of('ws-1').messagingDao.insertMessage(
      ConversationMessagesTableCompanion.insert(
        id: id,
        spaceId: 's',
        conversationId: 'c',
        senderId: senderId ?? id,
        senderType: senderType,
        content: content,
        messageType: Value(messageType),
        createdAt: Value(DateTime.utc(2026, 1, 1, 0, 0, second)),
        metadata: Value(metadata),
        compacted: Value(compacted),
        embedding: Value(embedding),
      ),
    );
  }

  test('dispatch history stops before older transcripts', () async {
    final chunk = 'x' * 4000;
    final blob = '{"segments":[{"type":"tool","toolName":"Old","t":"$chunk"}]}';
    await message(
      id: 'sum-old',
      senderType: 'agent',
      messageType: 'compaction',
      second: 1,
      content: 'SUM-OLD',
    );
    await message(
      id: 'old-blob',
      senderType: 'agent',
      messageType: 'agent_turn',
      second: 2,
      content: 'OLD-TURN',
      metadata: blob,
    );
    await message(
      id: 'sum-legacy',
      senderType: 'agent',
      messageType: 'system',
      second: 3,
      content: 'SUM-LEGACY',
      metadata: '{"compacted":true}',
      compacted: true,
    );
    await message(
      id: 'latest-turn',
      senderType: 'agent',
      messageType: 'agent_turn',
      second: 4,
      content: 'LATEST-TURN',
      metadata:
          '{"segments":[{"type":"tool","toolName":"Read","toolCallId":"1","ts":0}],"outcome":"completed"}',
    );
    for (var second = 10; second < 16; second++) {
      final label = 'u$second';
      await message(
        id: label,
        senderId: 'user',
        senderType: 'user',
        messageType: 'text',
        second: second,
        content: label.padRight(100, 'x'),
      );
    }

    final history = await repo.dispatchContextHistory(
      workspaceId: 'ws-1',
      spaceId: 's',
      conversationId: 'c',
      characterBudget: 250,
      pageSize: 2,
    );

    expect(history.messages.map((m) => m.id).toList(), ['u13', 'u14', 'u15']);
    expect(history.messages.every((m) => m.metadata?['segments'] == null), isTrue);
    expect(history.summaries.map((m) => m.content).toList(), [
      'SUM-OLD',
      'SUM-LEGACY',
    ]);
    expect(history.lastAgentTurn?.id, 'latest-turn');
    final segments = history.lastAgentTurn?.metadata?['segments'];
    expect(segments, isA<List<dynamic>>());
    expect((segments as List<dynamic>).first, containsPair('toolName', 'Read'));

    final dao = dbs.of('ws-1').messagingDao;
    final tailPlan = await dbs
        .of('ws-1')
        .customSelect(
          'EXPLAIN QUERY PLAN ${dao.contextTailSql(hasCursor: false)}',
          variables: [Variable.withString('c'), Variable.withInt(2)],
        )
        .get();
    final tailText = tailPlan.map((r) => r.data.values.join(' ')).join('\n');
    expect(tailText, contains('idx_conversation_messages_conversation_created'));
    expect(dao.contextTailSql(hasCursor: false), contains('list_metadata'));
    expect(
      MessagingDao.latestContextAgentTurnIdSql.contains('metadata'),
      isFalse,
    );

    final turnPlan = await dbs
        .of('ws-1')
        .customSelect(
          'EXPLAIN QUERY PLAN ${MessagingDao.latestContextAgentTurnIdSql}',
          variables: [Variable.withString('c')],
        )
        .get();
    final turnText = turnPlan.map((r) => r.data.values.join(' ')).join('\n');
    expect(
      turnText,
      contains('idx_conversation_messages_conversation_created'),
    );
  });

  test('embedded recall does not return transcript segments', () async {
    final chunk = 'x' * 2000;
    final blob = '{"segments":[{"type":"tool","toolName":"Old","t":"$chunk"}]}';
    await message(
      id: 'embedded',
      senderType: 'user',
      messageType: 'text',
      second: 1,
      content: 'remember this',
      metadata: blob,
      embedding: Uint8List.fromList(const [1, 2, 3, 4]),
    );
    final rows = await repo.getMessagesWithEmbedding('ws-1', 's');
    expect(rows, hasLength(1));
    expect(rows.single.message.content, 'remember this');
    expect(rows.single.embedding, isNotEmpty);
    expect(rows.single.message.metadata?['segments'], isNull);
    expect(rows.single.message.metadata?['segments_elided'], isTrue);
  });
}
