import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// `conversation.ensure` semantics after the main/parenthesis removal:
/// conversations are flat equals, ids are always fresh uuids (no aliasing to
/// the space id) and the standing conversation of a space with none is minted
/// once, UNTITLED — the title model names it from its first human message.
void main() {
  late WorkspaceDatabaseManager dbs;
  late GlobalDatabase global;
  late DaoMessagingRepository messaging;
  late DaoConversationRepository conversations;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    messaging = DaoMessagingRepository(dbs);
    conversations = DaoConversationRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  test('ensure mints one UNTITLED conversation, and is idempotent', () async {
    final space = await messaging.createSpace('ws-1', 'Build', const []);
    // Fresh space: no conversations at all (no aliased seed row).
    expect(
      await conversations.listForSpace(workspaceId: 'ws-1', spaceId: space.id),
      isEmpty,
    );

    final first = await conversations.ensure(
      workspaceId: 'ws-1',
      spaceId: space.id,
    );
    // The minted row carries no title: the UI renders the untitled
    // placeholder and the title model names it from its first human
    // message. It must NOT be titled after the space.
    expect(first.title, '');
    expect(first.id, isNot(space.id));

    // Repeat calls return the same standing conversation — no duplicates.
    final second = await conversations.ensure(
      workspaceId: 'ws-1',
      spaceId: space.id,
    );
    expect(second.id, first.id);
    expect(
      (await conversations.listForSpace(
        workspaceId: 'ws-1',
        spaceId: space.id,
      )).length,
      1,
    );
  });

  test('concurrent ensures mint exactly ONE standing conversation', () async {
    // Opening a space fires several resolvers at once — a message watch, an
    // artifact watch, a dispatch that named no stream — and each one lands
    // here. Read-then-insert without a transaction let all of them see no
    // standing row and each insert one, so opening a PR review space grew
    // three identical conversations named after it, beside the named ones its
    // reviewers had created.
    final space = await messaging.createSpace('ws-1', 'Build', const []);

    final ids = await Future.wait([
      for (var i = 0; i < 5; i++)
        conversations.ensure(workspaceId: 'ws-1', spaceId: space.id),
    ]);

    expect(ids.toSet(), hasLength(1), reason: 'all callers agree on one id');
    expect(
      await conversations.listForSpace(workspaceId: 'ws-1', spaceId: space.id),
      hasLength(1),
      reason: 'and only one row was written',
    );
  });

  test('ensure returns the oldest conversation when several exist', () async {
    final space = await messaging.createSpace('ws-1', 'Ops', const []);
    final standing = await conversations.ensure(
      workspaceId: 'ws-1',
      spaceId: space.id,
    );
    await conversations.create(
      workspaceId: 'ws-1',
      spaceId: space.id,
      title: 'Side quest',
    );

    final again = await conversations.ensure(
      workspaceId: 'ws-1',
      spaceId: space.id,
    );
    expect(again.id, standing.id);
  });

  test('create stores a thread anchor and reads it back', () async {
    final space = await messaging.createSpace('ws-1', 'Build', const []);
    final anchorId = await messaging.sendMessage(
      workspaceId: 'ws-1',
      spaceId: space.id,
      content: 'anchor',
      senderId: 'user',
      senderType: 'user',
    );

    final thread = await conversations.create(
      workspaceId: 'ws-1',
      spaceId: space.id,
      title: 'Follow-up',
      anchorMessageId: anchorId,
    );
    expect(thread.isThread, isTrue);

    final reread = await conversations.getById(
      workspaceId: 'ws-1',
      conversationId: thread.id,
    );
    expect(reread?.anchorMessageId, anchorId);

    final listed = await conversations.listForSpace(
      workspaceId: 'ws-1',
      spaceId: space.id,
    );
    expect(
      listed.firstWhere((c) => c.id == thread.id).anchorMessageId,
      anchorId,
    );
  });

  test(
    'ensure skips archived conversations and threads, minting a fresh one',
    () async {
      final space = await messaging.createSpace('ws-1', 'Ops', const []);
      final standing = await conversations.ensure(
        workspaceId: 'ws-1',
        spaceId: space.id,
      );
      final anchorId = await messaging.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        conversationId: standing.id,
        content: 'anchor',
        senderId: 'user',
        senderType: 'user',
      );
      // A thread is a conversation too, but it can never BE the stream a
      // space opens on — it hangs off a message inside another one.
      await conversations.create(
        workspaceId: 'ws-1',
        spaceId: space.id,
        title: 'Follow-up',
        anchorMessageId: anchorId,
      );
      // Close the only unanchored conversation.
      await conversations.setStatus(
        workspaceId: 'ws-1',
        conversationId: standing.id,
        status: ConversationStatus.archived,
      );

      final next = await conversations.ensure(
        workspaceId: 'ws-1',
        spaceId: space.id,
      );

      // Not the archived one (invisible in the switcher, so a send would land
      // where the reader cannot see it) and not the thread. Minted untitled,
      // like every standing conversation.
      expect(next.id, isNot(standing.id));
      expect(next.isThread, isFalse);
      expect(next.title, '');
    },
  );

  test('thread summaries roll up replies, last reply and senders', () async {
    final space = await messaging.createSpace('ws-1', 'Build', const []);
    final standing = await conversations.ensure(
      workspaceId: 'ws-1',
      spaceId: space.id,
    );
    final anchorId = await messaging.sendMessage(
      workspaceId: 'ws-1',
      spaceId: space.id,
      conversationId: standing.id,
      content: 'anchor',
      senderId: 'user-1',
      senderType: 'user',
    );
    final thread = await conversations.create(
      workspaceId: 'ws-1',
      spaceId: space.id,
      title: 'Follow-up',
      anchorMessageId: anchorId,
    );
    for (final sender in ['user-1', 'agent-1', 'user-1']) {
      await messaging.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        conversationId: thread.id,
        content: 'reply',
        senderId: sender,
        senderType: sender.startsWith('agent') ? 'agent' : 'user',
      );
    }

    final summaries = await conversations
        .watchThreadSummaries(workspaceId: 'ws-1', spaceId: space.id)
        .first;

    expect(summaries.length, 1);
    final summary = summaries.single;
    expect(summary.threadId, thread.id);
    // Keyed by the ANCHOR, because that is the message the feed draws it
    // under — not by the thread's own id.
    expect(summary.anchorMessageId, anchorId);
    expect(summary.title, 'Follow-up');
    expect(summary.replyCount, 3);
    expect(summary.lastReplyAt, isNotNull);
    // Distinct senders only: three replies from two people is two faces.
    expect(summary.participantIds.toSet(), {'user-1', 'agent-1'});
    // The parent stream is not a thread, so it contributes no row.
    expect(summaries.any((t) => t.threadId == standing.id), isFalse);
  });
}
