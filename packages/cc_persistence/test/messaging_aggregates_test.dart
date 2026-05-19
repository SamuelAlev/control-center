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
          .into(db.spacesTable)
          .insert(
            SpacesTableCompanion(
              id: Value(ch),
              name: Value(name),
              workspaceId: Value(ws),
            ),
          );
      // Fixture: an aliased conversation row (test-local convention) so the
      // `conversation_id` FK on conversation_messages resolves for msg().
      await db
          .into(db.conversationsTable)
          .insert(
            ConversationsTableCompanion(
              id: Value(ch),
              spaceId: Value(ch),
              workspaceId: Value(ws),
            ),
          );
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  // [parent] non-null routes the message into a SIDE conversation of the same
  // space. Read marks are SPACE-scoped, so watchSpaceActivity counts it like
  // any other — the old "only the main stream bumps the badge" rule is gone
  // along with the main stream itself.
  Future<void> msg(
    String id, {
    String space = 'a',
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
    final conversationId = parent != null ? '$space-paren' : space;
    if (parent != null) {
      await db
          .into(db.conversationsTable)
          .insert(
            ConversationsTableCompanion(
              id: Value(conversationId),
              spaceId: Value(space),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    await db
        .into(db.conversationMessagesTable)
        .insert(
          ConversationMessagesTableCompanion(
            id: Value(id),
            spaceId: Value(space),
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

  group('watchSpaceActivity', () {
    test('aggregates per space and scopes to the workspace', () async {
      // Space a: user msg, agent msg, a newer agent reply in a SIDE
      // conversation, one open + one answered question.
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
      // Space b: a single user message, nothing needing input.
      await msg('bu', space: 'b', atSecond: 4);
      // Neither foreign-workspace space may surface in ws-1: one is filtered
      // out by workspace_id inside ws-1's file, the other lives elsewhere.
      await msg('mu', space: 'mis-stamped', atSecond: 6);
      await msg('fu', space: 'foreign', workspace: 'ws-2', atSecond: 6);

      final activity = await repo.watchSpaceActivity('ws-1').first;
      expect(activity.map((a) => a.spaceId), unorderedEquals(['a', 'b']));

      final a = activity.singleWhere((x) => x.spaceId == 'a');
      expect(a.openQuestionCount, 1);
      expect(a.needsInput, isTrue);
      // Newest message overall (the agent thread reply at second 5).
      expect(
        a.lastMessageAt!.millisecondsSinceEpoch,
        DateTime.utc(2026, 1, 1, 0, 0, 5).millisecondsSinceEpoch,
      );
      // EVERY conversation counts: the newest agent message in the space is
      // the side-conversation reply at second 5, not the top-level question at
      // second 3. This used to be narrowed with `conversation_id = space_id`,
      // a predicate that can no longer be true — so the signal was dead.
      expect(
        a.lastAgentMessageAt!.millisecondsSinceEpoch,
        DateTime.utc(2026, 1, 1, 0, 0, 5).millisecondsSinceEpoch,
      );

      final b = activity.singleWhere((x) => x.spaceId == 'b');
      expect(b.openQuestionCount, 0);
      expect(b.needsInput, isFalse);
      expect(b.lastAgentMessageAt, isNull);
    });

    test('an archived space emits no activity until restored', () async {
      // An archived space's row is gone from the sidebar, so its unread /
      // needs-input signals must go quiet too — a hidden room cannot demand
      // attention. The messages stay, so restoring brings the signals back.
      await msg('u1', atSecond: 0);
      await msg(
        'q-open',
        sender: 'agent-1',
        senderType: 'agent',
        type: 'user_question',
        metadata: '{"answered": false}',
        atSecond: 1,
      );
      await msg('bu', space: 'b', atSecond: 2);

      await repo.archiveSpace('ws-1', 'a');
      var activity = await repo.watchSpaceActivity('ws-1').first;
      expect(activity.map((a) => a.spaceId), ['b']);

      await repo.unarchiveSpace('ws-1', 'a');
      activity = await repo.watchSpaceActivity('ws-1').first;
      final a = activity.singleWhere((x) => x.spaceId == 'a');
      expect(a.openQuestionCount, 1);
      expect(a.needsInput, isTrue);
    });

    test('an open question in a side conversation still needs input', () async {
      await msg('u1', atSecond: 0);
      await msg(
        'q-side',
        parent: 'u1',
        sender: 'agent-1',
        senderType: 'agent',
        type: 'user_question',
        metadata: '{"answered": false}',
        atSecond: 1,
      );

      final activity = await repo.watchSpaceActivity('ws-1').first;
      final a = activity.singleWhere((x) => x.spaceId == 'a');

      // A question asked inside a thread is still a question waiting on the
      // human. Scoping the count to one stream made every thread's question
      // invisible in the sidebar.
      expect(a.openQuestionCount, 1);
      expect(a.needsInput, isTrue);
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

      final activity = await repo.watchSpaceActivity('ws-1').first;
      final a = activity.singleWhere((x) => x.spaceId == 'a');
      expect(a.openQuestionCount, 0);
      expect(
        a.lastMessageAt!.millisecondsSinceEpoch,
        DateTime.utc(2026).millisecondsSinceEpoch,
      );
    });
  });

  group('emission dedup (_distinctRows)', () {
    test(
      'a write to another space does not re-emit an unchanged list',
      () async {
        await msg('b1', space: 'b', atSecond: 0);

        var emissions = 0;
        final sub = repo
            .watchMessages('ws-1', 'b', 'b')
            .listen((_) => emissions++);
        // First emission.
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(emissions, 1);

        // Drift's table-granular invalidation re-runs the query on ANY
        // conversation_messages write — the dedup layer must swallow the
        // identical result instead of re-emitting (and re-encoding) it.
        await msg('a1', space: 'a', atSecond: 1);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(emissions, 1);

        // A write to the watched space DOES emit.
        await msg('b2', space: 'b', atSecond: 2);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(emissions, 2);

        await sub.cancel();
      },
    );
  });
}
