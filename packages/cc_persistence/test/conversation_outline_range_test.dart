import 'package:cc_domain/cc_domain.dart' show NotFoundException;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_lifecycle_states.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The conversation feed's server reads beside the newest-N window: the
/// per-row revision, the whole-conversation outline and the anchored range.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late WorkspaceDatabase db;
  late DaoMessagingRepository repo;
  late String spaceId;
  late String conversationId;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    db = dbs.of('ws-1');
    repo = DaoMessagingRepository(dbs);
    spaceId = (await repo.createSpace('ws-1', 'Chat', const [])).id;
    conversationId = await repo.ensureStandingConversation('ws-1', spaceId);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Future<void> conversation(String id, String space) =>
      db.conversationDao.insertConversation(
        ConversationsTableCompanion(
          id: Value(id),
          workspaceId: const Value('ws-1'),
          spaceId: Value(space),
          title: const Value(''),
          status: const Value('active'),
        ),
      );

  /// A message at [second] past a fixed minute; rows of one second keep
  /// their insertion order through `rowid`.
  Future<void> msg(
    String id, {
    required int second,
    String? conversation,
    String? space,
    String content = 'x',
    String type = 'text',
    String? metadata,
  }) => db.messagingDao.insertMessage(
    ConversationMessagesTableCompanion(
      id: Value(id),
      spaceId: Value(space ?? spaceId),
      conversationId: Value(conversation ?? conversationId),
      senderId: const Value('user-1'),
      senderType: const Value('user'),
      content: Value(content),
      messageType: Value(type),
      metadata: Value(metadata),
      createdAt: Value(DateTime(2026, 11, 16, 9, 0, second)),
    ),
  );

  Future<int> revisionOf(String id) async =>
      (await db
              .customSelect(
                'SELECT revision FROM conversation_messages WHERE id = ?',
                variables: [Variable.withString(id)],
              )
              .getSingle())
          .read<int>('revision');

  Future<void> revert(String id) => db.customStatement(
    'UPDATE conversation_messages SET reverted = 1 WHERE id = ?',
    [id],
  );

  group('revision', () {
    test('0 on insert, exactly one more per update of the row', () async {
      await msg('m1', second: 0);
      expect(await revisionOf('m1'), 0);

      await repo.updateMessage('ws-1', 'm1', content: 'edit');
      expect(await revisionOf('m1'), 1);

      // A write that changes nothing is still an update of the row.
      await db.customStatement(
        "UPDATE conversation_messages SET content = content WHERE id = 'm1'",
      );
      expect(await revisionOf('m1'), 2);

      // A stale revision written back is bumped past the stored one.
      await db.customStatement(
        "UPDATE conversation_messages SET revision = 0 WHERE id = 'm1'",
      );
      expect(await revisionOf('m1'), 3);
    });

    test('the domain message carries it', () async {
      await msg('m1', second: 0);
      await revert('m1');
      await db.customStatement(
        'UPDATE conversation_messages SET reverted = 0 WHERE id = ?',
        ['m1'],
      );
      final message = await repo.getMessageById('ws-1', 'm1');
      expect(message!.revision, 2);
    });
  });

  group('getConversationOutline', () {
    test('every live message, in order, from stored values', () async {
      await msg('m1', second: 0, content: 'héllo');
      await msg('m2', second: 0);
      await msg(
        't1',
        second: 1,
        type: 'agent_turn',
        metadata:
            '{"segments":[{"type":"text","text":"a"},'
            '{"type":"text","text":"b"}]}',
      );
      await msg('gone', second: 2);
      await revert('gone');
      await msg(
        'q1',
        second: 3,
        type: 'steering',
        metadata: '{"steerState":"queued"}',
      );
      await repo.updateMessage('ws-1', 'm1', content: 'héllo!');

      final outline = await repo.getConversationOutline(
        'ws-1',
        spaceId,
        conversationId,
      );
      expect(outline.map((e) => e.id), ['m1', 'm2', 't1', 'q1']);
      final m1 = outline[0];
      expect(m1.contentChars, 'héllo!'.runes.length);
      expect(m1.revision, 1);
      expect(m1.senderType, SenderType.user);
      expect(m1.segmentCount, isNull);
      expect(outline[2].messageType, MessageType.agentTurn);
      expect(outline[2].segmentCount, 2);
      expect(outline[3].steerState, SteeringState.queued);
    });

    test('scoped by the space as well as the conversation', () async {
      await msg('m1', second: 0);
      final other = (await repo.createSpace('ws-1', 'Other', const [])).id;
      expect(
        await repo.getConversationOutline('ws-1', other, conversationId),
        isEmpty,
      );
    });

    test('reads a covering index, never a message row', () async {
      final plan =
          (await db
                  .customSelect(
                    'EXPLAIN QUERY PLAN ${MessagingDaoHistory.conversationOutlineSql}',
                    variables: [
                      Variable.withString(conversationId),
                      Variable.withString(spaceId),
                    ],
                  )
                  .get())
              .map((r) => r.data.values.join(' '))
              .join('\n');
      expect(
        plan,
        contains('USING COVERING INDEX idx_conversation_messages_outline'),
      );
      expect(plan, contains('idx_transcripts_message_id'));
      expect(plan, isNot(contains('SCAN m')));
      for (final blob in ['content,', 'list_metadata', 'm.*']) {
        expect(MessagingDaoHistory.conversationOutlineSql, isNot(contains(blob)));
      }
    });
  });

  group('watchMessagesRange', () {
    Future<({String ids, bool hasOlder, bool hasNewer})> range(
      String anchor, {
      int before = 2,
      int after = 2,
      String? conversation,
      String? space,
    }) async {
      final r = await repo
          .watchMessagesRange(
            'ws-1',
            space ?? spaceId,
            conversation ?? conversationId,
            anchorId: anchor,
            before: before,
            after: after,
          )
          .first;
      return (
        ids: [for (final m in r.messages) m.id].join(','),
        hasOlder: r.hasOlder,
        hasNewer: r.hasNewer,
      );
    }

    setUp(() async {
      // Seconds: a=0 b=1 c=1 d=1 e=2 f=3 (b, c, d share a second).
      await msg('a', second: 0);
      await msg('b', second: 1);
      await msg('c', second: 1);
      await msg('d', second: 1);
      await msg('e', second: 2);
      await msg('f', second: 3);
    });

    test('equal-second neighbours land on the right side once', () async {
      expect(await range('c', before: 1, after: 1), (
        ids: 'b,c,d',
        hasOlder: true,
        hasNewer: true,
      ));
      expect(await range('c', before: 10, after: 10), (
        ids: 'a,b,c,d,e,f',
        hasOlder: false,
        hasNewer: false,
      ));
      expect(await range('a', before: 3, after: 2), (
        ids: 'a,b,c',
        hasOlder: false,
        hasNewer: true,
      ));
      expect(await range('f', before: 2, after: 0), (
        ids: 'd,e,f',
        hasOlder: true,
        hasNewer: false,
      ));
      expect(await range('d', before: 0, after: 0), (
        ids: 'd',
        hasOlder: true,
        hasNewer: true,
      ));
    });

    test('reverted messages are hidden', () async {
      await revert('d');
      expect(await range('c', before: 1, after: 1), (
        ids: 'b,c,e',
        hasOlder: true,
        hasNewer: true,
      ));
    });

    test('follows writes on both sides of the anchor', () async {
      final emissions = repo
          .watchMessagesRange(
            'ws-1',
            spaceId,
            conversationId,
            anchorId: 'e',
            before: 1,
            after: 5,
          )
          .map((r) => [for (final m in r.messages) m.id]);
      final seen = <List<String>>[];
      final sub = emissions.listen(seen.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await msg('g', second: 4);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(seen.first, ['d', 'e', 'f']);
      expect(seen.last, ['d', 'e', 'f', 'g']);
    });

    test(
      'an anchor that is missing, reverted or elsewhere is not found',
      () async {
        await conversation('conv-2', spaceId);
        await msg('elsewhere', second: 5, conversation: 'conv-2');
        final otherSpace = (await repo.createSpace(
          'ws-1',
          'Other',
          const [],
        )).id;
        await revert('b');
        for (final (anchor, conversationArg, spaceArg) in [
          ('nope', null, null),
          ('b', null, null),
          // A message of another conversation of the same space.
          ('elsewhere', null, null),
          // This conversation's message, asked for under another space.
          ('c', null, otherSpace),
        ]) {
          await expectLater(
            range(anchor, conversation: conversationArg, space: spaceArg),
            throwsA(isA<NotFoundException>()),
            reason: anchor,
          );
        }
        // The same message under its own conversation is found.
        expect(
          (await range('elsewhere', conversation: 'conv-2')).ids,
          'elsewhere',
        );
      },
    );
  });
}
