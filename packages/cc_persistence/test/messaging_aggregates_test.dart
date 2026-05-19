import 'dart:async';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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
    await seedTestWorkspace(global, dbs, 'ws-2');
    repo = DaoMessagingRepository(dbs);
    // Isolation is now defended twice over, so both layers stay covered:
    //   `mis-stamped` is a ws-2 row sitting in ws-1's OWN file — only the
    //     aggregate's `WHERE c.workspace_id = ?` can exclude it,
    //   `foreign` lives in ws-2's file — only correct routing keeps it out.
    for (final (ch, name, ws, file) in [
      ('a', 'A', 'ws-1', 'ws-1'),
      ('b', 'B', 'ws-1', 'ws-1'),
      ('mis-stamped', 'M', 'ws-2', 'ws-1'),
      ('foreign', 'F', 'ws-2', 'ws-2'),
    ]) {
      final db = dbs.of(file);
      await db
          .into(db.channelsTable)
          .insert(
            ChannelsTableCompanion(
              id: Value(ch),
              name: Value(name),
              workspaceId: Value(ws),
            ),
          );
      // Seed each channel's `main` conversation (id == channel id) so the
      // `conversation_id` FK on channel_messages resolves.
      await db.messagingDao.ensureMainConversation(ch, workspaceId: ws);
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  // [parent] non-null routes the message into a *parenthesis* conversation
  // (a side stream), which watchChannelActivity intentionally excludes — the
  // successor to the old "thread replies don't bump the badge" behavior.
  Future<void> msg(
    String id, {
    String channel = 'a',
    String workspace = 'ws-1',
    String? parent,
    String sender = 'user',
    String senderType = 'user',
    String type = 'text',
    String content = 'hello',
    String? metadata,
    bool reverted = false,
    required int atSecond,
  }) async {
    final db = dbs.of(workspace);
    final conversationId = parent != null ? '$channel-paren' : channel;
    if (parent != null) {
      await db
          .into(db.conversationsTable)
          .insert(
            ConversationsTableCompanion(
              id: Value(conversationId),
              channelId: Value(channel),
              kind: const Value('parenthesis'),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    await db
        .into(db.channelMessagesTable)
        .insert(
          ChannelMessagesTableCompanion(
            id: Value(id),
            channelId: Value(channel),
            conversationId: Value(conversationId),
            senderId: Value(sender),
            senderType: Value(senderType),
            content: Value(content),
            messageType: Value(type),
            metadata: Value(metadata),
            reverted: Value(reverted),
            createdAt: Value(DateTime.utc(2026, 1, 1, 0, 0, atSecond)),
          ),
        );
  }

  group('watchChannelActivity', () {
    test('aggregates per channel and scopes to the workspace', () async {
      // Channel a: user msg, top-level agent msg, newer agent THREAD reply
      // (must not move lastAgentMessageAt), one open + one answered question.
      await msg('u1', atSecond: 0);
      await msg(
        'a1',
        sender: 'agent-1',
        senderType: 'agent',
        type: 'agent_turn',
        atSecond: 1,
      );
      await msg(
        'ar',
        parent: 'u1',
        sender: 'agent-1',
        senderType: 'agent',
        type: 'agent_turn',
        atSecond: 5,
      );
      await msg(
        'q-open',
        sender: 'agent-1',
        senderType: 'agent',
        type: 'user_question',
        metadata: '{"answered": false}',
        atSecond: 2,
      );
      await msg(
        'q-done',
        sender: 'agent-1',
        senderType: 'agent',
        type: 'user_question',
        metadata: '{"answered": true}',
        atSecond: 3,
      );
      // Channel b: a single user message, nothing needing input.
      await msg('bu', channel: 'b', atSecond: 4);
      // Neither foreign-workspace channel may surface in ws-1: one is filtered
      // out by workspace_id inside ws-1's file, the other lives elsewhere.
      await msg('mu', channel: 'mis-stamped', atSecond: 6);
      await msg('fu', channel: 'foreign', workspace: 'ws-2', atSecond: 6);

      final activity = await repo.watchChannelActivity('ws-1').first;
      expect(activity.map((a) => a.channelId), unorderedEquals(['a', 'b']));

      final a = activity.singleWhere((x) => x.channelId == 'a');
      expect(a.openQuestionCount, 1);
      expect(a.needsInput, isTrue);
      // Newest message overall (the agent thread reply at second 5).
      expect(
        a.lastMessageAt!.millisecondsSinceEpoch,
        DateTime.utc(2026, 1, 1, 0, 0, 5).millisecondsSinceEpoch,
      );
      // The unread signal only counts TOP-LEVEL agent messages — the newest
      // top-level agent message is the question at second 3.
      expect(
        a.lastAgentMessageAt!.millisecondsSinceEpoch,
        DateTime.utc(2026, 1, 1, 0, 0, 3).millisecondsSinceEpoch,
      );

      final b = activity.singleWhere((x) => x.channelId == 'b');
      expect(b.openQuestionCount, 0);
      expect(b.needsInput, isFalse);
      expect(b.lastAgentMessageAt, isNull);
    });

    test('ignores reverted messages', () async {
      await msg('u1', atSecond: 0);
      await msg(
        'q',
        sender: 'agent-1',
        senderType: 'agent',
        type: 'user_question',
        reverted: true,
        atSecond: 1,
      );

      final activity = await repo.watchChannelActivity('ws-1').first;
      final a = activity.singleWhere((x) => x.channelId == 'a');
      expect(a.openQuestionCount, 0);
      expect(
        a.lastMessageAt!.millisecondsSinceEpoch,
        DateTime.utc(2026).millisecondsSinceEpoch,
      );
    });
  });

  group('emission dedup (_distinctRows)', () {
    test(
      'a write to another channel does not re-emit an unchanged list',
      () async {
        await msg('b1', channel: 'b', atSecond: 0);

        var emissions = 0;
        final sub = repo
            .watchMessages('ws-1', 'b', 'b')
            .listen((_) => emissions++);
        // First emission.
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(emissions, 1);

        // Drift's table-granular invalidation re-runs the query on ANY
        // channel_messages write — the dedup layer must swallow the identical
        // result instead of re-emitting (and re-encoding) it.
        await msg('a1', channel: 'a', atSecond: 1);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(emissions, 1);

        // A write to the watched channel DOES emit.
        await msg('b2', channel: 'b', atSecond: 2);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(emissions, 2);

        await sub.cancel();
      },
    );
  });
}
