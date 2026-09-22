import 'dart:convert';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

Future<void> _seedAgent(WorkspaceDatabase db, String id, String name) async {
  await db.agentDao.upsert(
    AgentsTableCompanion.insert(
      id: id,
      name: name,
      title: name,
      agentMdPath: '.kilo/agent/$name.md',
      skills: 'generic',
      workspaceId: 'ws-test',
    ),
  );
}

void main() {
  late WorkspaceDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedConv(String id) => db
      .into(db.conversationsTable)
      .insert(ConversationsTableCompanion.insert(id: id, spaceId: id));

  group('MessagingDao — spaces', () {
    test('insert and watch spaces', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-1', name: 'general'),
      );
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-2', name: 'random'),
      );

      final spaces = await db.messagingDao.watchSpaces().first;
      expect(spaces.length, 2);
    });

    test('watchSpaces returns empty when no spaces', () async {
      final spaces = await db.messagingDao.watchSpaces().first;
      expect(spaces, isEmpty);
    });

    test('updateSpaceUpdatedAt sets timestamp', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-ts', name: 'ts'),
      );

      final now = DateTime(2026, 1, 1, 12, 0);
      await db.messagingDao.updateSpaceUpdatedAt('ch-ts', now);

      final spaces = await db.messagingDao.watchSpaces().first;
      expect(spaces.first.id, 'ch-ts');
    });

    test('updateSpaceName changes name', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-ren', name: 'old'),
      );

      await db.messagingDao.updateSpaceName('ch-ren', 'new-name');

      final spaces = await db.messagingDao.watchSpaces().first;
      expect(spaces.first.name, 'new-name');
    });

    test(
      'leaving provisioning clears the granular step in the same write',
      () async {
        await db.messagingDao.insertSpace(
          SpacesTableCompanion.insert(
            id: 'ch-prov',
            name: 'prov',
            provisioningStatus: const Value('provisioning'),
          ),
        );
        await db.messagingDao.updateSpaceProvisioningStep(
          'ch-prov',
          '{"kind":"repo","subject":"api"}',
        );

        var row = (await db.messagingDao.watchSpaces().first).first;
        expect(row.provisioningStep, '{"kind":"repo","subject":"api"}');

        await db.messagingDao.updateSpaceProvisioningStatus('ch-prov', 'ready');

        row = (await db.messagingDao.watchSpaces().first).first;
        expect(row.provisioningStatus, 'ready');
        expect(row.provisioningStep, isNull);
      },
    );

    test('spacesByProvisioningStatus finds stranded spaces', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(
          id: 'ch-stuck',
          name: 'stuck',
          provisioningStatus: const Value('provisioning'),
        ),
      );
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-ok', name: 'ok'),
      );

      final stuck = await db.messagingDao.spacesByProvisioningStatus(
        'provisioning',
      );
      expect(stuck.map((c) => c.id), ['ch-stuck']);
    });

    test('deleteSpaceCascade removes space, messages, participants', () async {
      await _seedAgent(db, 'agent-1', 'Agent 1');
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-cascade', name: 'c'),
      );
      await db.messagingDao.insertParticipant(
        SpaceParticipantsTableCompanion.insert(
          id: 'cp-1',
          spaceId: 'ch-cascade',
          principalId: 'agent-1',
        ),
      );
      await seedConv('ch-cascade');
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'msg-1',
          spaceId: 'ch-cascade',
          conversationId: 'ch-cascade',
          senderId: 'agent-1',
          senderType: 'user',
          content: 'hello',
        ),
      );

      await db.messagingDao.deleteSpaceCascade('ch-cascade');

      final spaces = await db.messagingDao.watchSpaces().first;
      expect(spaces, isEmpty);

      final msgs = await db.messagingDao.watchMessages('ch-cascade').first;
      expect(msgs, isEmpty);

      final pts = await db.messagingDao.getParticipants('ch-cascade');
      expect(pts, isEmpty);
    });
  });

  group('MessagingDao — participants', () {
    test('insert and watch participants', () async {
      await _seedAgent(db, 'agent-a', 'Agent A');
      await _seedAgent(db, 'agent-b', 'Agent B');
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-p', name: 'p'),
      );
      await db.messagingDao.insertParticipant(
        SpaceParticipantsTableCompanion.insert(
          id: 'cp-a',
          spaceId: 'ch-p',
          principalId: 'agent-a',
        ),
      );
      await db.messagingDao.insertParticipant(
        SpaceParticipantsTableCompanion.insert(
          id: 'cp-b',
          spaceId: 'ch-p',
          principalId: 'agent-b',
        ),
      );

      final pts = await db.messagingDao.watchParticipants('ch-p').first;
      expect(pts.length, 2);
    });

    test('insertParticipant ignores duplicates', () async {
      await _seedAgent(db, 'agent-d', 'Agent D');
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-dup', name: 'dup'),
      );
      await db.messagingDao.insertParticipant(
        SpaceParticipantsTableCompanion.insert(
          id: 'cp-d',
          spaceId: 'ch-dup',
          principalId: 'agent-d',
        ),
      );
      await db.messagingDao.insertParticipant(
        SpaceParticipantsTableCompanion.insert(
          id: 'cp-d',
          spaceId: 'ch-dup',
          principalId: 'agent-d',
        ),
      );

      final pts = await db.messagingDao.watchParticipants('ch-dup').first;
      expect(pts.length, 1);
    });

    test('getParticipants returns all participants for space', () async {
      await _seedAgent(db, 'a1', 'Agent A1');
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-gp', name: 'gp'),
      );
      await db.messagingDao.insertParticipant(
        SpaceParticipantsTableCompanion.insert(
          id: 'cp-1',
          spaceId: 'ch-gp',
          principalId: 'a1',
        ),
      );

      final pts = await db.messagingDao.getParticipants('ch-gp');
      expect(pts.length, 1);
      expect(pts.first.principalId, 'a1');
    });

    test('removeParticipant deletes participant', () async {
      await _seedAgent(db, 'agent-x', 'Agent X');
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-rm', name: 'rm'),
      );
      await db.messagingDao.insertParticipant(
        SpaceParticipantsTableCompanion.insert(
          id: 'cp-x',
          spaceId: 'ch-rm',
          principalId: 'agent-x',
        ),
      );

      await db.messagingDao.removeParticipant('ch-rm', 'agent-x');

      final pts = await db.messagingDao.getParticipants('ch-rm');
      expect(pts, isEmpty);
    });
  });

  group('MessagingDao — messages', () {
    test('insert and watch messages', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-msg', name: 'msg'),
      );
      await seedConv('ch-msg');
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'msg-1',
          spaceId: 'ch-msg',
          conversationId: 'ch-msg',
          senderId: 'user',
          senderType: 'user',
          content: 'Hello',
        ),
      );
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'msg-2',
          spaceId: 'ch-msg',
          conversationId: 'ch-msg',
          senderId: 'agent',
          senderType: 'assistant',
          content: 'Hi!',
        ),
      );

      final msgs = await db.messagingDao.watchMessages('ch-msg').first;
      expect(msgs.length, 2);
      expect(msgs[0].content, 'Hello');
      expect(msgs[1].content, 'Hi!');
    });

    test('getMessages returns future list', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-get', name: 'get'),
      );
      await seedConv('ch-get');
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'msg-a',
          spaceId: 'ch-get',
          conversationId: 'ch-get',
          senderId: 'user',
          senderType: 'user',
          content: 'A',
        ),
      );

      final msgs = await db.messagingDao.getMessages('ch-get');
      expect(msgs.length, 1);
    });

    test('markCompacted sets compacted flag', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-comp', name: 'comp'),
      );
      await seedConv('ch-comp');
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'msg-c1',
          spaceId: 'ch-comp',
          conversationId: 'ch-comp',
          senderId: 'user',
          senderType: 'user',
          content: 'old',
        ),
      );
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'msg-c2',
          spaceId: 'ch-comp',
          conversationId: 'ch-comp',
          senderId: 'assistant',
          senderType: 'assistant',
          content: 'old reply',
        ),
      );

      await db.messagingDao.markCompacted(['msg-c1']);

      final msgs = await db.messagingDao.getMessages('ch-comp');
      final compacted = msgs.where((m) => m.compacted).toList();
      expect(compacted.length, 1);
      expect(compacted.first.id, 'msg-c1');
    });

    test('clearSpaceMessages removes all messages', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-clear', name: 'clear'),
      );
      await seedConv('ch-clear');
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'msg-x',
          spaceId: 'ch-clear',
          conversationId: 'ch-clear',
          senderId: 'user',
          senderType: 'user',
          content: 'x',
        ),
      );
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'msg-y',
          spaceId: 'ch-clear',
          conversationId: 'ch-clear',
          senderId: 'user',
          senderType: 'user',
          content: 'y',
        ),
      );

      await db.messagingDao.clearSpaceMessages('ch-clear');

      final msgs = await db.messagingDao.getMessages('ch-clear');
      expect(msgs, isEmpty);
    });

    test('updateMessage updates content', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-upd', name: 'upd'),
      );
      await seedConv('ch-upd');
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'msg-u',
          spaceId: 'ch-upd',
          conversationId: 'ch-upd',
          senderId: 'user',
          senderType: 'user',
          content: 'original',
        ),
      );

      await db.messagingDao.updateMessage('msg-u', content: 'updated');

      final msgs = await db.messagingDao.getMessages('ch-upd');
      expect(msgs.first.content, 'updated');
    });

    test('updateMessage updates metadata', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-meta', name: 'meta'),
      );
      await seedConv('ch-meta');
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'msg-m',
          spaceId: 'ch-meta',
          conversationId: 'ch-meta',
          senderId: 'user',
          senderType: 'user',
          content: 'msg',
        ),
      );

      await db.messagingDao.updateMessage('msg-m', metadata: {'key': 'value'});

      final msgs = await db.messagingDao.getMessages('ch-meta');
      expect(msgs.first.metadata, '{"key":"value"}');
    });

    test('updateMessage partially updates content only', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-part', name: 'part'),
      );
      await seedConv('ch-part');
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'msg-p',
          spaceId: 'ch-part',
          conversationId: 'ch-part',
          senderId: 'user',
          senderType: 'user',
          content: 'original',
          metadata: const Value('{"a":1}'),
        ),
      );

      await db.messagingDao.updateMessage('msg-p', content: 'new content');

      final msgs = await db.messagingDao.getMessages('ch-part');
      expect(msgs.first.content, 'new content');
      expect(msgs.first.metadata, '{"a":1}');
    });
    test('messages inserted in the same second keep insertion order '
        '(rowid tie-break)', () async {
      // Regression: created_at is stored at SECOND resolution (Drift
      // currentDateAndTime truncates to whole seconds), so a user message and
      // its immediately-dispatched agent reply share an identical timestamp.
      // Ordering by created_at alone — or with the random-uuid `id` as a
      // tie-break — returned them in an unspecified order, which surfaced as
      // agent replies rendering ABOVE the user message that triggered them.
      // The ids below sort OPPOSITE to insertion order, so a tie-break on `id`
      // would reverse them; only the implicit `rowid` (insertion order) is
      // correct.
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-order', name: 'order'),
      );
      final Value<DateTime> sameSecond = Value(
        DateTime.utc(2024, 1, 1, 12, 0, 0),
      );
      await seedConv('ch-order');
      for (final entry in [
        ('ccc', 'user', 'user', 'first'),
        ('bbb', 'agent', 'agent', 'second'),
        ('aaa', 'agent', 'agent', 'third'),
      ]) {
        await db.messagingDao.insertMessage(
          ConversationMessagesTableCompanion.insert(
            id: entry.$1,
            spaceId: 'ch-order',
            conversationId: 'ch-order',
            senderId: entry.$2,
            senderType: entry.$3,
            content: entry.$4,
            createdAt: sameSecond,
          ),
        );
      }

      final fetched = await db.messagingDao.getMessages('ch-order');
      expect(fetched.map((m) => m.content), ['first', 'second', 'third']);

      final watched = await db.messagingDao.watchMessages('ch-order').first;
      expect(watched.map((m) => m.content), ['first', 'second', 'third']);

      // The window previously tied-break on `id desc`, which (with these ids)
      // would yield [third, second, first]. The rowid tie-break preserves
      // insertion order.
      final window = await db.messagingDao
          .watchMessagesWindow('ch-order', limit: 50)
          .first;
      expect(window.map((m) => m.content), ['first', 'second', 'third']);
    });

    test('list watches drop transcript segments and one-shot reads keep them',
        () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-lite', name: 'lite'),
      );
      await seedConv('ch-lite');
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'm-lite',
          spaceId: 'ch-lite',
          conversationId: 'ch-lite',
          senderId: 'agent',
          senderType: 'agent',
          content: 'answer',
          messageType: const Value('agent_turn'),
          metadata: const Value(
            '{"keep":"yes","segments":[{"t":"text","text":"blob"}]}',
          ),
        ),
      );
      await db.messagingDao.insertMessage(
        ConversationMessagesTableCompanion.insert(
          id: 'm-plain',
          spaceId: 'ch-lite',
          conversationId: 'ch-lite',
          senderId: 'user',
          senderType: 'user',
          content: 'hi',
          metadata: const Value('{"keep":"only"}'),
        ),
      );

      Map<String, dynamic> decoded(String? raw) =>
          jsonDecode(raw!) as Map<String, dynamic>;

      final watched = await db.messagingDao.watchMessages('ch-lite').first;
      final lite = decoded(watched.firstWhere((m) => m.id == 'm-lite').metadata);
      expect(lite.containsKey('segments'), isFalse);
      expect(lite['segments_elided'], isTrue);
      expect(lite['segment_count'], 1);
      expect(lite['keep'], 'yes');
      final plain = decoded(
        watched.firstWhere((m) => m.id == 'm-plain').metadata,
      );
      expect(plain, {'keep': 'only'});

      final window = await db.messagingDao
          .watchMessagesWindow('ch-lite', limit: 10)
          .first;
      final windowLite = decoded(
        window.firstWhere((m) => m.id == 'm-lite').metadata,
      );
      expect(windowLite['segment_count'], 1);
      expect(windowLite.containsKey('segments'), isFalse);

      final spaceWatch = await db.messagingDao
          .watchMessagesForSpace('ch-lite')
          .first;
      expect(
        decoded(spaceWatch.firstWhere((m) => m.id == 'm-lite').metadata)
            .containsKey('segments'),
        isFalse,
      );

      final full = await db.messagingDao.getMessageById('m-lite');
      expect(decoded(full!.metadata)['segments'], isA<List<dynamic>>());
      final oneShot = await db.messagingDao.getMessages('ch-lite');
      expect(
        decoded(oneShot.firstWhere((m) => m.id == 'm-lite').metadata)['segments'],
        isA<List<dynamic>>(),
      );

      final page = await db.messagingDao.getMessagePageRows(
        'ch-lite',
        'ch-lite',
        limit: 10,
      );
      final pageLite = decoded(
        page.firstWhere((r) => r.data.id == 'm-lite').data.metadata,
      );
      expect(pageLite.containsKey('segments'), isFalse);
      expect(pageLite['segment_count'], 1);
      expect(pageLite['keep'], 'yes');

      final hits = await db.messagingDao.searchInSpace('ch-lite', 'answer');
      final hit = hits.firstWhere((m) => m.id == 'm-lite');
      final hitMeta = decoded(hit.metadata);
      expect(hitMeta.containsKey('segments'), isFalse);
      expect(hitMeta['keep'], 'yes');
      expect(hit.embedding, isNull);

      final columns = db.messagingDao.messageListSelectColumns;
      expect(
        columns,
        contains('WHEN list_metadata IS NOT NULL THEN list_metadata'),
      );
      expect(
        columns,
        contains('json_type(metadata, \'\$.segments\')'),
      );

      await db.messagingDao.updateMessage('m-lite', content: 'answer2');
      final kept = await db
          .customSelect(
            'SELECT list_metadata, metadata, content FROM conversation_messages WHERE id = \'m-lite\'',
          )
          .getSingle();
      expect(kept.read<String>('content'), 'answer2');
      expect(
        decoded(kept.read<String>('list_metadata')).containsKey('segments'),
        isFalse,
      );
      expect(
        decoded(kept.read<String>('metadata'))['segments'],
        isA<List<dynamic>>(),
      );

      await db.messagingDao.updateMessage(
        'm-lite',
        metadata: <String, dynamic>{
          'keep': 'yes',
          'segments': <Map<String, dynamic>>[
            <String, dynamic>{'t': 'text'},
          ],
        },
      );
      final typed = await db
          .customSelect(
            'SELECT list_metadata, metadata FROM conversation_messages WHERE id = \'m-lite\'',
          )
          .getSingle();
      final typedLite = decoded(typed.read<String>('list_metadata'));
      expect(typedLite.containsKey('segments'), isFalse);
      expect(typedLite['segment_count'], 1);
      expect(typedLite['keep'], 'yes');
      expect(
        decoded(typed.read<String>('metadata'))['segments'],
        isA<List<dynamic>>(),
      );

      await db.customStatement(
        'INSERT INTO conversation_messages (id, space_id, conversation_id, sender_id, sender_type, content, metadata) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'm-raw',
          'ch-lite',
          'ch-lite',
          'agent',
          'agent',
          'raw',
          '{"keep":"raw","segments":[{"t":"text"}]}',
        ],
      );
      final rawStored = await db
          .customSelect(
            'SELECT list_metadata FROM conversation_messages WHERE id = \'m-raw\'',
          )
          .getSingle();
      expect(rawStored.read<String?>('list_metadata'), isNull);
      final rawWatch = await db.messagingDao.watchMessages('ch-lite').first;
      final rawLite = decoded(
        rawWatch.firstWhere((m) => m.id == 'm-raw').metadata,
      );
      expect(rawLite.containsKey('segments'), isFalse);
      expect(rawLite['segments_elided'], isTrue);
      expect(rawLite['keep'], 'raw');
    });
  });
}
