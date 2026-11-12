import 'dart:convert';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/seed_spaces.dart';
import 'helpers/test_database.dart';

/// The rules the space, conversation, notification, calendar, meeting and
/// memory tables state in the schema: delete rules that remove only what the
/// caller named, natural keys the writes upsert on, closed value sets, JSON
/// checks, and the indexes the hot reads depend on.
void main() {
  late WorkspaceDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> plan(String sql, [List<Object?> args = const []]) async {
    final rows = await db
        .customSelect(
          'EXPLAIN QUERY PLAN $sql',
          variables: [for (final a in args) Variable(a)],
        )
        .get();
    return rows.map((r) => r.data['detail']).join('\n');
  }

  Future<ConversationsTableData?> conversation(String id) => (db.select(
    db.conversationsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<String>> messageIds(String conversationId) async => [
    for (final row in await (db.select(
      db.conversationMessagesTable,
    )..where((t) => t.conversationId.equals(conversationId))).get())
      row.id,
  ];

  /// Space `s` with conversation `main`, message `anchor` in it, and thread
  /// `thread` hanging off that message with one reply.
  Future<void> seedThread() async {
    await seedMessage(db, 'anchor', conversationId: 'main', spaceId: 's');
    await db.conversationDao.insertConversation(
      ConversationsTableCompanion.insert(
        id: 'thread',
        workspaceId: db.workspaceId,
        spaceId: 's',
        anchorMessageId: const Value('anchor'),
      ),
    );
    await seedMessage(db, 'reply', conversationId: 'thread', spaceId: 's');
  }

  group('thread anchor', () {
    test('deleting the anchor keeps the thread and its replies', () async {
      await seedThread();

      await db.messagingDao.deleteMessageById('anchor');

      final thread = await conversation('thread');
      expect(thread, isNotNull);
      expect(thread!.anchorMessageId, isNull);
      expect(await messageIds('thread'), ['reply']);
      expect(await messageIds('main'), isEmpty);
    });

    test('an unanchored thread drops out of the thread rollup', () async {
      await seedThread();
      final before = await db.conversationDao
          .watchThreadSummaries(db.workspaceId, 's')
          .first;
      expect(before.map((t) => t.threadId), ['thread']);

      await db.messagingDao.deleteMessageById('anchor');

      final after = await db.conversationDao
          .watchThreadSummaries(db.workspaceId, 's')
          .first;
      expect(after, isEmpty);
    });

    test('clearing the space removes its threads with the messages', () async {
      await seedThread();

      await db.messagingDao.clearSpaceMessages('s');

      expect(await conversation('thread'), isNull);
      expect(await conversation('main'), isNotNull);
      expect(await messageIds('thread'), isEmpty);
    });

    test('a parent delete is a lookup on the anchor index', () async {
      final detail = await plan(
        'SELECT 1 FROM conversations WHERE anchor_message_id = ?',
        ['m'],
      );
      expect(detail, contains('idx_conversations_anchorMessageId'));
    });
  });

  group('message tree pointers', () {
    test('deleting the tip leaves the conversation without one', () async {
      await seedMessage(db, 'm1', conversationId: 'c');
      await seedMessage(db, 'm2', conversationId: 'c', parentMessageId: 'm1');
      await db.messagingDao.setLeaf('c', 'm2');

      await db.messagingDao.deleteMessageById('m2');

      expect(await db.messagingDao.currentLeaf('c'), isNull);
    });

    test('deleting a parent makes its child a root, not a casualty', () async {
      await seedMessage(db, 'm1', conversationId: 'c');
      await seedMessage(db, 'm2', conversationId: 'c', parentMessageId: 'm1');

      await db.messagingDao.deleteMessageById('m1');

      final child = await db.messagingDao.getMessageById('m2');
      expect(child, isNotNull);
      expect(child!.parentMessageId, isNull);
    });
  });

  group('hot reads stay on an index', () {
    test('the message window of a conversation in a space', () async {
      final detail = await plan(
        'SELECT id FROM conversation_messages '
        'WHERE space_id = ? AND conversation_id = ? AND reverted = 0 '
        'ORDER BY created_at DESC, rowid DESC LIMIT ?',
        ['s', 'c', 50],
      );
      expect(detail, contains('USING INDEX idx_conversation_messages_'));
      expect(detail, isNot(contains('TEMP B-TREE')));
    });

    test('a thread read', () async {
      final detail = await plan(
        'SELECT id FROM conversation_messages '
        'WHERE conversation_id = ? AND reverted = 0 '
        'ORDER BY created_at ASC, rowid ASC',
        ['thread'],
      );
      expect(detail, contains('USING INDEX idx_conversation_messages_'));
      expect(detail, isNot(contains('TEMP B-TREE')));
    });

    test('the conversations of a space', () async {
      final detail = await plan(
        'SELECT id FROM conversations WHERE workspace_id = ? AND space_id = ?',
        [db.workspaceId, 's'],
      );
      expect(detail, contains('idx_conversations_spaceId'));
    });

    test('the notification feed page', () async {
      final detail = await plan(
        'SELECT *, rowid AS _seq FROM notification_feed '
        'WHERE workspace_id = ? ORDER BY created_at DESC, rowid DESC LIMIT ?',
        [db.workspaceId, 50],
      );
      expect(detail, contains('idx_notification_feed_created'));
      expect(detail, isNot(contains('TEMP B-TREE')));
    });

    test('the queued steering cards', () async {
      final detail = await plan(db.messagingDao.queuedSteeringSql, ['c', 's']);
      expect(detail, contains('idx_conversation_messages_queued_steering'));
    });

    test('the audit page and its retention sweep', () async {
      expect(
        await plan(
          'SELECT id FROM user_activity WHERE workspace_id = ? '
          'ORDER BY created_at DESC, id DESC LIMIT 50',
          [db.workspaceId],
        ),
        contains('idx_user_activity_created'),
      );
      expect(
        await plan('DELETE FROM user_activity WHERE created_at < ?', [0]),
        contains('idx_user_activity_created'),
      );
    });
  });

  group('closed value sets', () {
    Future<void> insert(String type, {String? metadata}) async =>
        db.messagingDao.insertMessage(
          ConversationMessagesTableCompanion.insert(
            id: 'm-$type',
            spaceId: 'c',
            conversationId: 'c',
            senderId: 'agent',
            senderType: 'agent',
            content: 'x',
            messageType: Value(type),
            metadata: Value(metadata),
          ),
        );

    setUp(() => seedConversation(db, 'c'));

    test('a message type no enum case names is refused', () async {
      await expectLater(insert('bogus'), throwsA(isA<SqliteException>()));
      await insert('agent_turn');
    });

    test('metadata that is not a JSON object is refused', () async {
      await expectLater(
        insert('text', metadata: '[1, 2]'),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        insert('system', metadata: '{not json'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('an unknown plan or steering state is refused', () async {
      await expectLater(
        insert('plan', metadata: jsonEncode({'planStatus': 'shipped'})),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        insert('steering', metadata: jsonEncode({'steerState': 'lost'})),
        throwsA(isA<ArgumentError>()),
      );
      await insert('plan', metadata: jsonEncode({'planStatus': 'refining'}));
      final row = await db.messagingDao.getMessageById('m-plan');
      expect(row!.planStatus, 'refining');
    });

    test('an empty metadata string stores no metadata', () async {
      await insert('text', metadata: '');
      final row = await db.messagingDao.getMessageById('m-text');
      expect(row!.metadata, isNull);
    });

    test('a feed frame must be a JSON object', () async {
      await expectLater(
        db.notificationFeedDao.insertAndPrune(
          NotificationFeedTableCompanion.insert(
            id: 'n',
            workspaceId: db.workspaceId,
            method: 'notifications/x',
            paramsJson: 'nope',
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('a memory type no enum case names is refused', () async {
      await expectLater(
        db.customStatement(
          'INSERT INTO memory_facts '
          '(id, workspace_id, domain, topic, content, memory_type) '
          "VALUES ('f', ?, 'd', 't', 'c', 'hunch')",
          [db.workspaceId],
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('natural keys', () {
    test('a principal joins a space once; a read moves its cursor', () async {
      await seedSpace(db, 's');
      for (final id in ['p1', 'p2']) {
        await db.messagingDao.insertParticipant(
          SpaceParticipantsTableCompanion.insert(
            id: id,
            spaceId: 's',
            principalId: 'user-1',
            participantType: const Value('user'),
          ),
        );
      }
      await db.messagingDao.markSpaceRead('s', 'user-1');

      final rows = await db.messagingDao.getParticipants('s');
      expect(rows.map((r) => r.id), ['p1']);
      expect(rows.single.lastReadAt, isNotNull);
    });

    test('the Notes doc bumps its version in place', () async {
      await seedSpace(db, 's');
      Future<SpaceNotesTableData> write(String id, String text) =>
          db.spaceExtrasDao.upsertNote(
            id: id,
            workspaceId: db.workspaceId,
            spaceId: 's',
            contentMarkdown: text,
            updatedByPrincipal: 'user:u',
          );

      await write('n1', 'one');
      final second = await write('n2', 'two');

      expect(second.id, 'n1');
      expect(second.version, 2);
      expect(second.contentMarkdown, 'two');
    });

    test('an autonomy dial is one row per agent and space', () async {
      await seedSpace(db, 's');
      await seedAgent(db, 'a');
      for (final (id, level) in [('d1', 'proposeOnly'), ('d2', 'actFreely')]) {
        await db.spaceExtrasDao.setAutonomy(
          id: id,
          workspaceId: db.workspaceId,
          spaceId: 's',
          agentId: 'a',
          autonomyLevel: level,
        );
      }
      final dials = await db.spaceExtrasDao.autonomyForSpace(
        db.workspaceId,
        's',
      );
      expect(dials.map((d) => (d.id, d.autonomyLevel)), [('d1', 'actFreely')]);
    });

    test('reconnecting a calendar account keeps its row', () async {
      for (final id in ['a1', 'a2']) {
        await db.calendarDao.upsertAccount(
          CalendarAccountsTableCompanion.insert(
            id: id,
            workspaceId: db.workspaceId,
            userId: const Value('u'),
            accountEmail: 'me@example.com',
            displayName: Value('Name $id'),
          ),
        );
      }
      final accounts = await db.calendarDao.getAccounts(db.workspaceId);
      expect(accounts.map((a) => (a.id, a.displayName)), [('a1', 'Name a2')]);
    });

    test('relinking a meeting moves its one link', () async {
      await seedMeeting(db, 'm');
      await seedCalendarEvent(db, 'e1');
      await seedCalendarEvent(db, 'e2');
      for (final (id, event) in [('l1', 'e1'), ('l2', 'e2')]) {
        await db.calendarDao.linkMeetingToEvent(
          MeetingCalendarLinksTableCompanion.insert(
            id: id,
            workspaceId: db.workspaceId,
            meetingId: 'm',
            calendarEventId: event,
          ),
        );
      }
      final links = await db.select(db.meetingCalendarLinksTable).get();
      expect(links.map((l) => (l.id, l.calendarEventId)), [('l1', 'e2')]);
    });

    test('renaming a speaker by label writes one row', () async {
      await seedMeeting(db, 'm');
      for (final (id, name) in [('s1', 'Alex'), ('s2', 'Sam')]) {
        await db.meetingDao.upsertSpeakerDisplayName(
          workspaceId: db.workspaceId,
          meetingId: 'm',
          channel: 'them',
          label: 'Person 1',
          displayName: name,
          newId: id,
          createdAt: DateTime.utc(2026),
        );
      }
      final speakers = await db.meetingDao.getSpeakers(db.workspaceId, 'm');
      expect(speakers.map((s) => (s.id, s.displayName)), [('s1', 'Sam')]);
    });

    test('an edge between two facts is one row per type', () async {
      await seedMemoryFact(db, 'f1');
      await seedMemoryFact(db, 'f2');
      for (final (id, weight) in [('e1', 0.2), ('e2', 0.9)]) {
        await db.episodicEdgeDao.upsert(
          EpisodicEdgesTableCompanion.insert(
            id: id,
            workspaceId: db.workspaceId,
            sourceFactId: 'f1',
            targetFactId: 'f2',
            edgeType: 'related_to',
            weight: Value(weight),
          ),
        );
      }
      final edges = await db.episodicEdgeDao.getByWorkspace(db.workspaceId);
      expect(edges.map((e) => (e.id, e.weight)), [('e1', 0.9)]);
    });

    test("an agent's working memory is one row", () async {
      await seedAgent(db, 'a');
      for (final (id, text) in [('w1', 'first'), ('w2', 'second')]) {
        await db.agentWorkingMemoryDao.upsert(
          AgentWorkingMemoryTableCompanion.insert(
            id: id,
            workspaceId: db.workspaceId,
            agentId: 'a',
            content: Value(text),
          ),
        );
      }
      final row = await db.agentWorkingMemoryDao.getByAgent(
        db.workspaceId,
        'a',
      );
      expect((row!.id, row.content), ('w1', 'second'));
    });
  });

  group('cascades', () {
    test('a per-item state goes when its item is pruned', () async {
      await seedFeedItem(db, 'old');
      await db.notificationFeedDao.setItemRead(
        db.workspaceId,
        'u',
        'old',
        DateTime.utc(2026),
      );

      await db.customStatement(
        "DELETE FROM notification_feed WHERE id = 'old'",
      );

      expect(await db.select(db.notificationItemStatesTable).get(), isEmpty);
    });

    test('deleting a fact removes its edges and conflicts', () async {
      await seedMemoryFact(db, 'f1');
      await seedMemoryFact(db, 'f2');
      await db.episodicEdgeDao.upsert(
        EpisodicEdgesTableCompanion.insert(
          id: 'e',
          workspaceId: db.workspaceId,
          sourceFactId: 'f1',
          targetFactId: 'f2',
          edgeType: 'related_to',
        ),
      );
      await db.memoryConflictDao.upsert(
        MemoryConflictsTableCompanion.insert(
          id: 'c',
          workspaceId: db.workspaceId,
          factAId: 'f1',
          factBId: 'f2',
        ),
      );

      await db.memoryFactDao.deleteById(db.workspaceId, 'f2');

      expect(await db.episodicEdgeDao.getByWorkspace(db.workspaceId), isEmpty);
      expect(
        await db.memoryConflictDao.getByWorkspace(db.workspaceId),
        isEmpty,
      );
    });
  });
}
