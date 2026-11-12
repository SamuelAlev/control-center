import 'dart:async';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/services/side_channel_render.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

String _render(List<Message> messages, int maxChars) {
  final rendered = <String>[];
  var total = 0;
  for (final message in messages.reversed) {
    final line = sideChannelLine(message);
    if (line == null) {
      continue;
    }
    if (total + line.length > maxChars) {
      rendered.add('[…earlier conversation omitted]');
      break;
    }
    total += line.length;
    rendered.add(line);
  }
  return rendered.reversed.join('\n\n');
}

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
      SpacesTableCompanion.insert(id: 's', name: 'S', workspaceId: 'ws-1'),
    );
    await db.conversationDao.insertConversation(
      ConversationsTableCompanion.insert(
        id: 'c',
        spaceId: 's',
        workspaceId: 'ws-1',
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
    String content = 'body',
    String? metadata,
    String? senderId,
  }) {
    return dbs
        .of('ws-1')
        .messagingDao
        .insertMessage(
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
          ),
        );
  }

  test('queued steering skips transcript rows', () async {
    final chunk = 'x' * 4000;
    final blob = '{"segments":[{"type":"tool","toolName":"Old","t":"$chunk"}]}';
    await message(
      id: 'turn',
      senderType: 'agent',
      messageType: 'agent_turn',
      second: 1,
      content: 'OLD-TURN',
      metadata: blob,
    );
    await message(
      id: 'later',
      senderType: 'user',
      senderId: 'user',
      messageType: 'steering',
      second: 3,
      content: 'second steer',
      metadata: '{"steerState":"queued","steerOrder":2}',
    );
    await message(
      id: 'injected',
      senderType: 'user',
      senderId: 'user',
      messageType: 'steering',
      second: 4,
      content: 'already in',
      metadata: '{"steerState":"injected","steerOrder":3}',
    );
    await message(
      id: 'first',
      senderType: 'user',
      senderId: 'user',
      messageType: 'steering',
      second: 2,
      content: 'first steer',
      metadata: '{"steerState":"queued","steerOrder":0}',
    );

    final queued = await repo.queuedSteeringMessages(
      workspaceId: 'ws-1',
      spaceId: 's',
      conversationId: 'c',
    );
    expect(queued.map((m) => m.id).toList(), ['first', 'later']);
    expect(queued.every((m) => m.metadata?['segments'] == null), isTrue);

    // The queue state lives in its column, not in the stored JSON, and the
    // domain message still carries it.
    expect(queued.map((m) => m.metadata?['steerState']), ['queued', 'queued']);
    final stored = await dbs.of('ws-1').messagingDao.getMessageById('first');
    expect(stored!.steerState, 'queued');
    expect(stored.metadata, isNot(contains('steerState')));

    final db = dbs.of('ws-1');
    final dao = db.messagingDao;
    expect(dao.queuedSteeringSql.contains('transcript_segments'), isFalse);
    final plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN ${dao.queuedSteeringSql}',
          variables: [Variable.withString('c'), Variable.withString('s')],
        )
        .get();
    final text = plan.map((r) => r.data.values.join(' ')).join('\n');
    expect(text, contains('idx_conversation_messages_queued_steering'));
  });

  test('title lookup reads the first human message only', () async {
    final chunk = 'y' * 4000;
    final blob = '{"segments":[{"type":"tool","toolName":"Old","t":"$chunk"}]}';
    await message(
      id: 'turn',
      senderType: 'agent',
      messageType: 'agent_turn',
      second: 1,
      content: 'agent spoke first',
      metadata: blob,
    );
    await message(
      id: 'human',
      senderType: 'user',
      senderId: 'user',
      messageType: 'text',
      second: 2,
      content: '  name me  ',
    );
    await message(
      id: 'later',
      senderType: 'user',
      senderId: 'user',
      messageType: 'text',
      second: 3,
      content: 'not this',
    );

    final text = await repo.firstHumanContent(
      workspaceId: 'ws-1',
      spaceId: 's',
      conversationId: 'c',
    );
    expect(text, 'name me');

    expect(MessagingDao.firstHumanContentSql.contains('metadata'), isFalse);
    expect(MessagingDao.firstHumanContentSql.contains('content'), isTrue);
    final plan = await dbs
        .of('ws-1')
        .customSelect(
          'EXPLAIN QUERY PLAN ${MessagingDao.firstHumanContentSql}',
          variables: [Variable.withString('c')],
        )
        .get();
    final planText = plan.map((r) => r.data.values.join(' ')).join('\n');
    expect(
      planText,
      contains('idx_conversation_messages_conversation_created'),
    );
  });

  test('harvest reads the newest message from that agent', () async {
    final chunk = 'z' * 4000;
    final blob = '{"segments":[{"type":"tool","toolName":"Old","t":"$chunk"}]}';
    await message(
      id: 'old',
      senderType: 'agent',
      senderId: 'agent-1',
      messageType: 'agent_turn',
      second: 1,
      content: 'old answer',
      metadata: blob,
    );
    await message(
      id: 'latest',
      senderType: 'agent',
      senderId: 'agent-1',
      messageType: 'agent_turn',
      second: 2,
      content: 'the answer',
      metadata: blob,
    );
    await message(
      id: 'other',
      senderType: 'agent',
      senderId: 'agent-2',
      messageType: 'text',
      second: 3,
      content: 'someone else',
    );

    final text = await repo.latestAgentContent(
      workspaceId: 'ws-1',
      conversationId: 'c',
      agentId: 'agent-1',
    );
    expect(text, 'the answer');
    expect(MessagingDao.latestAgentContentSql.contains('metadata'), isFalse);
    final plan = await dbs
        .of('ws-1')
        .customSelect(
          'EXPLAIN QUERY PLAN ${MessagingDao.latestAgentContentSql}',
          variables: [Variable.withString('c'), Variable.withString('agent-1')],
        )
        .get();
    final planText = plan.map((r) => r.data.values.join(' ')).join('\n');
    expect(
      planText,
      contains('idx_conversation_messages_conversation_created'),
    );
  });

  test('side channel pages the rendered window', () async {
    final chunk = 'q' * 4000;
    final blob = '{"segments":[{"type":"tool","toolName":"Old","t":"$chunk"}]}';
    await message(
      id: 'older',
      senderType: 'user',
      senderId: 'user',
      messageType: 'text',
      second: 1,
      content: 'SHOULD_NOT_LOAD',
      metadata: blob,
    );
    await message(
      id: 'old',
      senderType: 'agent',
      senderId: 'agent-1',
      messageType: 'agent_turn',
      second: 2,
      content: 'A' * 400,
      metadata: blob,
    );
    await message(
      id: 'keep',
      senderType: 'user',
      senderId: 'user',
      messageType: 'text',
      second: 3,
      content: 'keep',
      metadata: blob,
    );
    await message(
      id: 'tool',
      senderType: 'agent',
      senderId: 'agent-1',
      messageType: 'agent_turn',
      second: 4,
      content: '   ',
      metadata:
          '{"agentName":"Scout","segments":['
          '{"type":"text","text":"looked"},'
          '{"type":"tool","toolName":"edit","inputs":{"path":"lib/auth.dart"}}'
          ']}',
    );
    await message(
      id: 'newest',
      senderType: 'user',
      senderId: 'user',
      messageType: 'text',
      second: 5,
      content: 'newest',
    );

    const budget = 80;
    final fast = await repo.sideChannelMessages(
      workspaceId: 'ws-1',
      spaceId: 's',
      conversationId: 'c',
      maxChars: budget,
      pageSize: 2,
    );
    final full = await repo.getMessages('ws-1', 's', conversationId: 'c');
    expect(_render(fast, budget), _render(full, budget));
    expect(fast.map((m) => m.id).toList(), ['old', 'keep', 'tool', 'newest']);
    expect(_render(fast, budget), contains('User: newest'));
    expect(_render(fast, budget), contains('[edit lib/auth.dart]'));
    expect(_render(fast, budget), contains('earlier conversation omitted'));
    expect(_render(fast, budget).contains('SHOULD_NOT_LOAD'), isFalse);
    expect(_render(fast, budget).contains('A' * 40), isFalse);
    for (final row in fast) {
      expect('${row.metadata}'.contains(chunk), isFalse);
    }
    final tool = fast.firstWhere((m) => m.id == 'tool');
    expect(tool.transcript, isNotEmpty);
    expect(
      fast.firstWhere((m) => m.id == 'keep').metadata?['segments'],
      isNull,
    );

    final dao = dbs.of('ws-1').messagingDao;
    expect(
      dao.sideChannelTailSql(hasCursor: false).contains('transcript_segments'),
      isFalse,
    );
    expect(
      dao.sideChannelTailSql(hasCursor: false).contains('compacted = 0'),
      isFalse,
    );
    final plan = await dbs
        .of('ws-1')
        .customSelect(
          'EXPLAIN QUERY PLAN ${dao.sideChannelTailSql(hasCursor: false)}',
          variables: [Variable.withString('c'), Variable.withInt(2)],
        )
        .get();
    final planText = plan.map((r) => r.data.values.join(' ')).join('\n');
    expect(
      planText,
      contains('idx_conversation_messages_conversation_created'),
    );
  });

  test('tool flush does not republish the feed', () async {
    await message(
      id: 'turn',
      senderType: 'agent',
      senderId: 'agent-1',
      messageType: 'agent_turn',
      second: 1,
      content: 'hello',
      metadata:
          '{"agentName":"Scout","streamComplete":false,"transcriptChars":4,'
          '"segments":[{"type":"text","text":"hello"}]}',
    );
    final seen = <Map<String, dynamic>?>[];
    final contents = <String>[];
    final sub = repo.watchMessagesWindow('ws-1', 's', 'c', limit: 10).listen((
      window,
    ) {
      seen.add(window.messages.single.metadata);
      contents.add(window.messages.single.content);
    });
    final started = DateTime.now();
    while (seen.isEmpty) {
      if (DateTime.now().difference(started) > const Duration(seconds: 2)) {
        fail('feed did not emit');
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    // A streaming turn says it has a transcript but not yet how long it is:
    // the count changes on every tool call, and the feed must not.
    expect(seen.single?['segments_elided'], isTrue);
    expect(seen.single?.containsKey('segment_count'), isFalse);

    final dao = dbs.of('ws-1').messagingDao;
    await dao.flushStreamingTurn(
      'turn',
      metadata: const {'transcriptChars': 80},
      writeMetadata: false,
      changedSegments: {
        1: '{"type":"tool","toolName":"edit","inputs":{"path":"a.dart"}}',
      },
      segmentCount: 2,
    );
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(seen, hasLength(1));

    final stored = await dbs
        .of('ws-1')
        .customSelect(
          'SELECT transcript_chars, list_metadata '
          'FROM conversation_messages WHERE id = ?',
          variables: [Variable.withString('turn')],
        )
        .getSingle();
    expect(stored.read<int>('transcript_chars'), 80);
    expect(stored.read<String>('list_metadata'), isNot(contains('segment')));

    await dao.flushStreamingTurn(
      'turn',
      content: 'hello!',
      metadata: const {
        'agentName': 'Scout',
        'streamComplete': true,
        'transcriptChars': 90,
      },
      writeMetadata: true,
      changedSegments: {0: '{"type":"text","text":"hello!"}'},
      segmentCount: 2,
    );
    final grew = DateTime.now();
    while (seen.length < 2) {
      if (DateTime.now().difference(grew) > const Duration(seconds: 2)) {
        fail('feed did not publish the visible edit');
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(contents.last, 'hello!');
    expect(seen.last?['segment_count'], 2);
    await sub.cancel();
  });
}
