import 'dart:async';
import 'dart:convert';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/messaging_mapper.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// `conversation_activity`: the per-conversation signals the sidebar reads,
/// kept by the message write path instead of aggregated from every message
/// on each read.
void main() {
  late WorkspaceDatabase db;
  late MessagingDao dao;

  setUp(() async {
    db = createTestDatabase(workspaceId: 'w-1');
    dao = db.messagingDao;
    await dao.insertSpace(
      SpacesTableCompanion.insert(id: 's', name: 'S', workspaceId: 'w-1'),
    );
    for (final id in ['c', 'd']) {
      await db.conversationDao.insertConversation(
        ConversationsTableCompanion.insert(
          id: id,
          spaceId: 's',
          workspaceId: 'w-1',
        ),
      );
    }
  });

  tearDown(() async {
    await db.close();
  });

  DateTime at(int second) => DateTime.utc(2026, 1, 1, 0, 0, second);

  Future<void> message(
    String id, {
    required int second,
    String conversationId = 'c',
    String senderType = 'agent',
    String type = 'text',
    Map<String, Object?>? metadata,
  }) => dao.insertMessage(
    ConversationMessagesTableCompanion.insert(
      id: id,
      spaceId: 's',
      conversationId: conversationId,
      senderId: senderType == 'user' ? 'u' : 'agent-1',
      senderType: senderType,
      content: id,
      messageType: Value(type),
      metadata: Value(metadata == null ? null : jsonEncode(metadata)),
      createdAt: Value(at(second)),
    ),
  );

  Future<ConversationActivityTableData?> activityOf(String conversationId) =>
      (db.select(db.conversationActivityTable)
            ..where((t) => t.conversationId.equals(conversationId)))
          .getSingleOrNull();

  Future<int> seqOf(String messageId) async =>
      (await db
              .customSelect(
                'SELECT rowid AS seq FROM conversation_messages WHERE id = ?',
                variables: [Variable.withString(messageId)],
              )
              .getSingle())
          .read<int>('seq');

  /// The row a full recompute from the messages would write.
  Future<ConversationActivityTableData?> rebuilt(String conversationId) async {
    await dao.rebuildConversationActivity([conversationId]);
    return activityOf(conversationId);
  }

  test('an insert folds into the row as the write commits', () async {
    await message('u1', second: 1, senderType: 'user');
    var row = (await activityOf('c'))!;
    expect(row.lastMessageAt.toUtc(), at(1));
    expect(row.lastAgentMessageAt?.toUtc(), isNull);
    expect(row.lastAgentMessageSeq, isNull);

    await message('a1', second: 2);
    await message('a2', second: 2);
    await message('u2', second: 3, senderType: 'user');
    row = (await activityOf('c'))!;
    expect(row.lastMessageAt.toUtc(), at(3));
    // The newest agent message by (second, insertion): a2, not a1.
    expect(row.lastAgentMessageAt?.toUtc(), at(2));
    expect(row.lastAgentMessageSeq, await seqOf('a2'));
    expect(row.spaceId, 's');

    // An older message written late does not move the row back.
    await message('late', second: 0);
    expect(await activityOf('c'), row);
    expect(await rebuilt('c'), row);
  });

  test('open questions follow answer, expiry and type changes', () async {
    await message('q1', second: 1, type: 'user_question');
    await message('q2', second: 2, type: 'user_question');
    await message(
      'q-closed',
      second: 3,
      type: 'user_question',
      metadata: {'answered': true},
    );
    expect((await activityOf('c'))!.openQuestionCount, 2);

    expect(
      await dao.answerQuestion('q1', {
        'selected': ['a'],
      }),
      isTrue,
    );
    expect((await activityOf('c'))!.openQuestionCount, 1);

    expect(await dao.expireQuestion('q2'), isTrue);
    expect((await activityOf('c'))!.openQuestionCount, 0);

    await message('q3', second: 4, type: 'user_question');
    expect((await activityOf('c'))!.openQuestionCount, 1);
    await dao.updateMessage('q3', messageType: 'text');
    expect((await activityOf('c'))!.openQuestionCount, 0);

    await message('q4', second: 5, type: 'user_question');
    await dao.updateMessage('q4', metadata: {'answered': true});
    expect((await activityOf('c'))!.openQuestionCount, 0);
    expect(await dao.watchPendingQuestions('w-1').first, isEmpty);
  });

  test('a rewrite without the answered key keeps a question closed', () async {
    await message('q', second: 1, type: 'user_question');
    expect(
      await dao.answerQuestion('q', {
        'selected': ['a'],
      }),
      isTrue,
    );
    await dao.updateMessage('q', metadata: {'question': 'Which?'});

    expect((await dao.getMessageById('q'))!.answered, isTrue);
    expect((await activityOf('c'))!.openQuestionCount, 0);
  });

  test('revert and unrevert recompute the row', () async {
    await message('a1', second: 1);
    await message('q', second: 2, type: 'user_question');
    await message('u', second: 3, senderType: 'user');
    final before = await activityOf('c');

    await dao.revertMessages(['q', 'u'], 1000);
    final row = (await activityOf('c'))!;
    expect(row.lastMessageAt.toUtc(), at(1));
    expect(row.lastAgentMessageSeq, await seqOf('a1'));
    expect(row.openQuestionCount, 0);

    await dao.unrevertMessages(['q', 'u']);
    expect(await activityOf('c'), before);

    // Reverting every live message leaves no row: the conversation has no
    // activity to report.
    await dao.revertMessages(['a1', 'q', 'u'], 2000);
    expect(await activityOf('c'), isNull);
    expect(await dao.watchSpaceActivity('w-1').first, isEmpty);
  });

  test('deletes recompute the row', () async {
    await message('a1', second: 1);
    await message('a2', second: 2);

    await dao.deleteMessageById('a2');
    var row = (await activityOf('c'))!;
    expect(row.lastAgentMessageSeq, await seqOf('a1'));

    await dao.deleteMessageInConversation('c', 'a1');
    expect(await activityOf('c'), isNull);

    // Wrong conversation: nothing deleted, nothing recomputed away.
    await message('a3', second: 3);
    await dao.deleteMessageInConversation('d', 'a3');
    row = (await activityOf('c'))!;
    expect(row.lastAgentMessageSeq, await seqOf('a3'));
  });

  test('deleting the conversation or the space drops its rows', () async {
    await message('a1', second: 1);
    await message('d1', second: 1, conversationId: 'd');

    await db.customStatement("DELETE FROM conversations WHERE id = 'c'");
    expect(await activityOf('c'), isNull);
    expect(await activityOf('d'), isNotNull);

    await dao.clearSpaceMessages('s');
    expect(await activityOf('d'), isNull);
  });

  test('the first read fills conversations written before the table', () async {
    // Rows written straight to the table, as in a file converged from
    // before `conversation_activity` existed.
    for (final (id, sender, second) in [
      ('u1', 'user', 1),
      ('a1', 'agent', 2),
    ]) {
      await db
          .into(db.conversationMessagesTable)
          .insert(
            ConversationMessagesTableCompanion.insert(
              id: id,
              spaceId: 's',
              conversationId: 'c',
              senderId: sender,
              senderType: sender,
              content: id,
              createdAt: Value(at(second)),
            ),
          );
    }
    expect(await activityOf('c'), isNull);

    final activity = await dao.watchSpaceActivity('w-1').first;
    expect(activity.single.conversationId, 'c');
    expect(activity.single.lastMessageAt.toUtc(), at(2));
    expect(activity.single.lastAgentMessage!.seq, await seqOf('a1'));
  });

  test('a streaming flush does not re-run the activity watch', () async {
    await message('turn', second: 1, type: 'agent_turn');
    final emissions = <Object>[];
    final sub = dao.watchSpaceActivity('w-1').listen(emissions.add);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, hasLength(1));

    for (var i = 0; i < 3; i++) {
      await dao.updateMessage(
        'turn',
        content: 'partial $i',
        metadata: {
          'segments': [
            {'type': 'text', 't': 'x' * (i + 1)},
          ],
        },
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, hasLength(1));

    await message('next', second: 2);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, hasLength(2));
    await sub.cancel();
  });

  test('the open-question recount reads the partial index', () async {
    final plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN SELECT COUNT(*) FROM conversation_messages '
          "WHERE conversation_id = ? AND message_type = 'user_question' "
          'AND answered = 0 AND reverted = 0',
          variables: [Variable.withString('c')],
        )
        .get();
    expect(
      plan.map((r) => r.data.values.join(' ')).join('\n'),
      contains('idx_conversation_messages_open_questions'),
    );
  });

  group('promoted metadata keys', () {
    test('live in their columns, not the stored JSON', () async {
      await message(
        'q',
        second: 1,
        type: 'user_question',
        metadata: {'question': 'Which?', 'answered': true},
      );
      await message(
        'plan',
        second: 2,
        type: 'plan',
        metadata: {'planStatus': 'approved', 'steps': 2},
      );
      await message(
        'steer',
        second: 3,
        senderType: 'user',
        type: 'steering',
        metadata: {'steerState': 'queued', 'steerOrder': 0},
      );

      final q = (await dao.getMessageById('q'))!;
      expect(q.answered, isTrue);
      expect(jsonDecode(q.metadata!), {'question': 'Which?'});
      final plan = (await dao.getMessageById('plan'))!;
      expect(plan.planStatus, 'approved');
      expect(jsonDecode(plan.metadata!), {'steps': 2});
      final steer = (await dao.getMessageById('steer'))!;
      expect(steer.steerState, 'queued');
      expect(jsonDecode(steer.metadata!), {'steerOrder': 0});

      // The domain message carries them again.
      expect(const MessagingMapper().messageToDomain(q).metadata, {
        'question': 'Which?',
        'answered': true,
      });
      expect(
        const MessagingMapper().messageToDomain(plan).metadata?['planStatus'],
        'approved',
      );
      expect(
        const MessagingMapper().messageToDomain(steer).metadata?['steerState'],
        'queued',
      );
    });

    test('a metadata rewrite moves plan state to its column', () async {
      await message('plan', second: 1, type: 'plan', metadata: {});
      await dao.updateMessage('plan', metadata: {'planStatus': 'refining'});
      var row = (await dao.getMessageById('plan'))!;
      expect(row.planStatus, 'refining');
      expect(row.metadata, '{}');

      await dao.updateMessage('plan', metadata: {'steps': 1});
      row = (await dao.getMessageById('plan'))!;
      expect(row.planStatus, isNull);
    });
  });
}
