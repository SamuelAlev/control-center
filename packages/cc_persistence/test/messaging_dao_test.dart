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
      .insert(
        ConversationsTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: id,
          spaceId: id,
        ),
      );

  group('MessagingDao — spaces', () {
    test('insert and watch spaces', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-1',
          name: 'general',
        ),
      );
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-2',
          name: 'random',
        ),
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
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-ts',
          name: 'ts',
        ),
      );

      final now = DateTime(2026, 1, 1, 12, 0);
      await db.messagingDao.updateSpaceUpdatedAt('ch-ts', now);

      final spaces = await db.messagingDao.watchSpaces().first;
      expect(spaces.first.id, 'ch-ts');
    });

    test('updateSpaceName changes name', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-ren',
          name: 'old',
        ),
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
            workspaceId: 'test-workspace',
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
          workspaceId: 'test-workspace',
          id: 'ch-stuck',
          name: 'stuck',
          provisioningStatus: const Value('provisioning'),
        ),
      );
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-ok',
          name: 'ok',
        ),
      );

      final stuck = await db.messagingDao.spacesByProvisioningStatus(
        'provisioning',
      );
      expect(stuck.map((c) => c.id), ['ch-stuck']);
    });

    test('deleteSpaceCascade removes space, messages, participants', () async {
      await _seedAgent(db, 'agent-1', 'Agent 1');
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-cascade',
          name: 'c',
        ),
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
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-p',
          name: 'p',
        ),
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
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-dup',
          name: 'dup',
        ),
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
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-gp',
          name: 'gp',
        ),
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
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-rm',
          name: 'rm',
        ),
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
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-msg',
          name: 'msg',
        ),
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
          senderType: 'agent',
          content: 'Hi!',
        ),
      );

      final msgs = await db.messagingDao.watchMessages('ch-msg').first;
      expect(msgs.length, 2);
      expect(msgs[0].data.content, 'Hello');
      expect(msgs[1].data.content, 'Hi!');
    });

    test('getMessages returns future list', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-get',
          name: 'get',
        ),
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
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-comp',
          name: 'comp',
        ),
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
          senderType: 'agent',
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
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-clear',
          name: 'clear',
        ),
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
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-upd',
          name: 'upd',
        ),
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
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-meta',
          name: 'meta',
        ),
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
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-part',
          name: 'part',
        ),
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
        SpacesTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'ch-order',
          name: 'order',
        ),
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
      expect(watched.map((m) => m.data.content), ['first', 'second', 'third']);

      // The window previously tied-break on `id desc`, which (with these ids)
      // would yield [third, second, first]. The rowid tie-break preserves
      // insertion order.
      final window = await db.messagingDao
          .watchMessagesWindow('ch-order', limit: 50)
          .first;
      expect(window.map((m) => m.data.content), ['first', 'second', 'third']);
    });

    test(
      'a turn\'s segments are rows, and list reads only say they exist',
      () async {
        await db.messagingDao.insertSpace(
          SpacesTableCompanion.insert(
            workspaceId: 'test-workspace',
            id: 'ch-lite',
            name: 'lite',
          ),
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

        // The stored JSON never holds the transcript.
        final stored = await db.messagingDao.getMessageById('m-lite');
        expect(decoded(stored!.metadata), {'keep': 'yes'});
        final bodies = await db.runTranscriptDao.segmentBodiesForMessages([
          'm-lite',
          'm-plain',
        ]);
        expect(bodies.keys, ['m-lite']);
        expect(bodies['m-lite']!.map(jsonDecode), [
          {'t': 'text', 'text': 'blob'},
        ]);

        final watched = await db.messagingDao.watchMessages('ch-lite').first;
        final lite = watched.firstWhere((r) => r.data.id == 'm-lite');
        expect(lite.hasTranscript, isTrue);
        expect(lite.segmentCount, 1);
        expect(decoded(lite.data.metadata), {'keep': 'yes'});
        final plain = watched.firstWhere((r) => r.data.id == 'm-plain');
        expect(plain.hasTranscript, isFalse);
        expect(plain.segmentCount, isNull);

        final window = await db.messagingDao
            .watchMessagesWindow('ch-lite', limit: 10)
            .first;
        expect(window.firstWhere((r) => r.data.id == 'm-lite').segmentCount, 1);
        final spaceWatch = await db.messagingDao
            .watchMessagesForSpace('ch-lite')
            .first;
        expect(
          spaceWatch.firstWhere((r) => r.data.id == 'm-lite').hasTranscript,
          isTrue,
        );
        final page = await db.messagingDao.getMessagePageRows(
          'ch-lite',
          'ch-lite',
          limit: 10,
        );
        expect(
          page
              .firstWhere((r) => r.listed.data.id == 'm-lite')
              .listed
              .segmentCount,
          1,
        );
        final hits = await db.messagingDao.searchInSpace('ch-lite', 'answer');
        expect(hits.single.hasTranscript, isTrue);

        // Rewriting the content leaves the transcript alone.
        await db.messagingDao.updateMessage('m-lite', content: 'answer2');
        expect(
          (await db.runTranscriptDao.segmentBodiesForMessages([
            'm-lite',
          ]))['m-lite'],
          hasLength(1),
        );

        // A shorter whole transcript drops the rows past its end.
        await db.messagingDao.updateMessage(
          'm-lite',
          metadata: <String, dynamic>{
            'keep': 'yes',
            'segments': <Map<String, dynamic>>[],
          },
        );
        expect(
          (await db.runTranscriptDao.segmentBodiesForMessages([
            'm-lite',
          ]))['m-lite'],
          isEmpty,
        );
      },
    );
    test(
      'pending questions include old and archived conversations; first answer wins',
      () async {
        await db.messagingDao.insertSpace(
          SpacesTableCompanion.insert(
            id: 'questions-space',
            name: 'Questions',
            workspaceId: 'test-workspace',
          ),
        );
        await db
            .into(db.conversationsTable)
            .insert(
              ConversationsTableCompanion.insert(
                workspaceId: 'test-workspace',
                id: 'archived-thread',
                spaceId: 'questions-space',
                status: const Value('archived'),
              ),
            );
        await db.messagingDao.insertMessage(
          ConversationMessagesTableCompanion.insert(
            id: 'early-question',
            spaceId: 'questions-space',
            conversationId: 'archived-thread',
            senderId: 'agent',
            senderType: 'agent',
            content: 'Choose a deployment target?',
            messageType: const Value('user_question'),
            metadata: Value(
              jsonEncode({
                'question': 'Choose a deployment target?',
                'options': [
                  {'label': 'staging'},
                ],
                'answered': false,
              }),
            ),
          ),
        );
        for (var i = 0; i < 70; i++) {
          await db.messagingDao.insertMessage(
            ConversationMessagesTableCompanion.insert(
              id: 'recent-$i',
              spaceId: 'questions-space',
              conversationId: 'archived-thread',
              senderId: 'agent',
              senderType: 'agent',
              content: '$i',
            ),
          );
        }
        final pending = await db.messagingDao
            .watchPendingQuestions('test-workspace')
            .first;
        expect(pending.map((row) => row.id), ['early-question']);
        expect(
          await db.messagingDao.watchPendingQuestions('other').first,
          isEmpty,
        );
        expect(
          await db.messagingDao.answerQuestion('early-question', {
            'selected': ['staging'],
          }),
          isTrue,
        );
        expect(
          await db.messagingDao.answerQuestion('early-question', {
            'selected': ['production'],
          }),
          isFalse,
        );
        await db.messagingDao.updateMessage(
          'early-question',
          metadata: {'answered': true, 'expired': true},
        );
        final answered = await db.messagingDao.getMessageById('early-question');
        final metadata =
            jsonDecode(answered!.metadata!) as Map<String, dynamic>;
        expect(metadata['answer'], {
          'selected': ['staging'],
        });
        expect(metadata['expired'], isNull);
        expect(
          await db.messagingDao.watchPendingQuestions('test-workspace').first,
          isEmpty,
        );
      },
    );

    test(
      'expiry is conditional and the boot sweep closes only older questions',
      () async {
        await db.messagingDao.insertSpace(
          SpacesTableCompanion.insert(
            id: 'expiry-space',
            name: 'Expiry',
            workspaceId: 'test-workspace',
          ),
        );
        await db
            .into(db.conversationsTable)
            .insert(
              ConversationsTableCompanion.insert(
                workspaceId: 'test-workspace',
                id: 'expiry-thread',
                spaceId: 'expiry-space',
              ),
            );
        Future<void> question(String id, DateTime createdAt) =>
            db.messagingDao.insertMessage(
              ConversationMessagesTableCompanion.insert(
                id: id,
                spaceId: 'expiry-space',
                conversationId: 'expiry-thread',
                senderId: 'agent',
                senderType: 'agent',
                content: 'Which?',
                messageType: const Value('user_question'),
                metadata: Value(
                  jsonEncode({'question': 'Which?', 'answered': false}),
                ),
                createdAt: Value(createdAt),
              ),
            );
        Future<Map<String, dynamic>> meta(String id) async =>
            jsonDecode((await db.messagingDao.getMessageById(id))!.metadata!)
                as Map<String, dynamic>;

        await question('answered-first', DateTime.utc(2026, 1, 1));
        expect(
          await db.messagingDao.answerQuestion('answered-first', {
            'selected': ['a'],
          }),
          isTrue,
        );
        // The waiter's expiry lost the race: the answer must survive it.
        expect(await db.messagingDao.expireQuestion('answered-first'), isFalse);
        expect((await meta('answered-first'))['expired'], isNull);
        expect((await meta('answered-first'))['answer'], {
          'selected': ['a'],
        });

        await question('open', DateTime.utc(2026, 1, 1));
        expect(await db.messagingDao.expireQuestion('open'), isTrue);
        expect((await meta('open'))['expired'], isTrue);
        expect(
          (await db.messagingDao.getMessageById('open'))!.answered,
          isTrue,
        );

        await question('orphan', DateTime.utc(2026, 1, 1));
        await question('after-boot', DateTime.utc(2026, 1, 3));
        expect(
          await db.messagingDao.expireQuestionsCreatedBefore(
            DateTime.utc(2026, 1, 2),
          ),
          1,
        );
        expect((await meta('orphan'))['expired'], isTrue);
        expect(
          (await db.messagingDao.getMessageById('after-boot'))!.answered,
          isFalse,
        );
        expect((await meta('answered-first'))['expired'], isNull);
      },
    );

    test(
      'patchSteering merges onto the current row only in the expected state',
      () async {
        await db.messagingDao.insertSpace(
          SpacesTableCompanion.insert(
            id: 'steer-space',
            name: 'Steer',
            workspaceId: 'test-workspace',
          ),
        );
        await db
            .into(db.conversationsTable)
            .insert(
              ConversationsTableCompanion.insert(
                workspaceId: 'test-workspace',
                id: 'steer-thread',
                spaceId: 'steer-space',
              ),
            );
        await db.messagingDao.insertMessage(
          ConversationMessagesTableCompanion.insert(
            id: 'card',
            spaceId: 'steer-space',
            conversationId: 'steer-thread',
            senderId: 'u1',
            senderType: 'user',
            content: 'nudge',
            messageType: const Value('steering'),
            metadata: Value(
              jsonEncode({'steerState': 'queued', 'steerOrder': 0}),
            ),
          ),
        );
        // The stored JSON plus the queue state, which lives in its column.
        Future<Map<String, dynamic>> meta() async {
          final row = (await db.messagingDao.getMessageById('card'))!;
          final json = jsonDecode(row.metadata!) as Map<String, dynamic>;
          expect(json.containsKey('steerState'), isFalse);
          return {...json, 'steerState': ?row.steerState};
        }

        // A live run drains the card...
        expect(
          await db.messagingDao.patchSteering(
            'card',
            fromState: 'queued',
            patch: {'steerState': 'injected'},
          ),
          isTrue,
        );
        // ...and a reorder that read it as queued must not revert that.
        expect(
          await db.messagingDao.patchSteering(
            'card',
            fromState: 'queued',
            patch: {'steerOrder': 3, 'steerState': 'queued'},
          ),
          isFalse,
        );
        expect(await meta(), {'steerState': 'injected', 'steerOrder': 0});

        expect(
          await db.messagingDao.patchSteering(
            'card',
            fromState: 'injected',
            patch: {'steerRunId': 'r1'},
            content: 'edited',
            messageType: 'text',
          ),
          isTrue,
        );
        final row = (await db.messagingDao.getMessageById('card'))!;
        expect(row.content, 'edited');
        expect(row.messageType, 'text');
        expect((await meta())['steerRunId'], 'r1');
        expect(
          await db.messagingDao.patchSteering(
            'missing',
            fromState: 'queued',
            patch: const {},
          ),
          isFalse,
        );
      },
    );

    test(
      "heldSteeringMessages lists every conversation's held cards, and a "
      "pause's card re-held as a Stop's loses its reset",
      () async {
        await db.messagingDao.insertSpace(
          SpacesTableCompanion.insert(
            id: 'held-space',
            name: 'Held',
            workspaceId: 'test-workspace',
          ),
        );
        for (final thread in ['t-1', 't-2']) {
          await db
              .into(db.conversationsTable)
              .insert(
                ConversationsTableCompanion.insert(
                  workspaceId: 'test-workspace',
                  id: thread,
                  spaceId: 'held-space',
                ),
              );
        }
        Future<void> card(String id, String thread, Map<String, Object> meta) =>
            db.messagingDao.insertMessage(
              ConversationMessagesTableCompanion.insert(
                id: id,
                spaceId: 'held-space',
                conversationId: thread,
                senderId: 'u1',
                senderType: 'user',
                content: id,
                messageType: const Value('steering'),
                metadata: Value(jsonEncode(meta)),
              ),
            );
        await card('paused', 't-1', {
          'steerState': 'held',
          'steerHeldBy': 'limit:run-a',
          'steerLimitResetsAt': '2026-11-20T12:00:00.000Z',
        });
        await card('stopped', 't-2', {
          'steerState': 'held',
          'steerHeldBy': 'stop',
        });
        await card('waiting', 't-2', {'steerState': 'queued'});

        final held = await db.messagingDao.heldSteeringMessages();
        expect(held.map((r) => r.id).toSet(), {'paused', 'stopped'});

        expect(
          await db.messagingDao.patchSteering(
            'paused',
            fromState: 'held',
            patch: {'steerHeldBy': 'stop', 'steerLimitResetsAt': null},
          ),
          isTrue,
        );
        final row = (await db.messagingDao.getMessageById('paused'))!;
        final json = jsonDecode(row.metadata!) as Map<String, dynamic>;
        expect(row.steerState, 'held');
        expect(json['steerHeldBy'], 'stop');
        expect(json['steerLimitResetsAt'], isNull);
      },
    );

    test('openLimitParkRows lists only park rows with no outcome yet', () async {
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(
          id: 'park-space',
          name: 'Park',
          workspaceId: 'test-workspace',
        ),
      );
      await db
          .into(db.conversationsTable)
          .insert(
            ConversationsTableCompanion.insert(
              workspaceId: 'test-workspace',
              id: 'park-thread',
              spaceId: 'park-space',
            ),
          );
      Future<void> row(String id, Map<String, Object> meta) =>
          db.messagingDao.insertMessage(
            ConversationMessagesTableCompanion.insert(
              id: id,
              spaceId: 'park-space',
              conversationId: 'park-thread',
              senderId: 'system',
              senderType: 'system',
              content: id,
              messageType: const Value('system'),
              metadata: Value(jsonEncode(meta)),
            ),
          );
      await row('open', {'kind': 'limit_park', 'wakeId': 'w-1'});
      await row('done', {
        'kind': 'limit_park',
        'wakeId': 'w-2',
        'outcome': 'cancelled',
      });
      await row('other', {'kind': 'wake_skipped'});

      final rows = await db.messagingDao.openLimitParkRows();
      expect(rows.map((r) => r.id), ['open']);
    });
  });
}
