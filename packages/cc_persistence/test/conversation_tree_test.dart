import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The session tree: parent links on every message plus a leaf pointer.
///
/// The property under test throughout is that going back COSTS NOTHING — no
/// message is deleted, hidden or copied to branch — because that is what makes
/// editing a prompt and re-running safe to do.
void main() {
  late WorkspaceDatabase db;
  late DaoMessagingRepository repo;

  setUp(() async {
    db = createTestDatabase();
    repo = DaoMessagingRepository(_SingleWorkspace(db));
    await db.messagingDao.insertSpace(
      SpacesTableCompanion.insert(
        workspaceId: 'test-workspace',
        id: 'sp',
        name: 'general',
      ),
    );
  });
  tearDown(() async => db.close());

  Future<String> send(String content, {String? conversationId}) =>
      repo.sendMessage(
        workspaceId: 'ws',
        spaceId: 'sp',
        content: content,
        senderId: 'u1',
        senderType: 'user',
        conversationId: conversationId,
      );

  Future<String> conversationId() => db.conversationDao
      .ensureStandingConversation(workspaceId: 'ws', spaceId: 'sp');

  test('each message records the one before it as its parent', () async {
    final a = await send('one');
    final b = await send('two');
    final c = await send('three');

    final tree = await repo.conversationTree(
      workspaceId: 'ws',
      conversationId: await conversationId(),
    );
    final byId = {for (final n in tree.nodes) n.messageId: n};
    expect(byId[a]!.parentMessageId, isNull, reason: 'the first is a root');
    expect(byId[b]!.parentMessageId, a);
    expect(byId[c]!.parentMessageId, b);
    expect(tree.leafMessageId, c);
    expect(tree.branchCount, 1);
  });

  test('branching writes NOTHING but the pointer', () async {
    final a = await send('one');
    final b = await send('two');
    final conv = await conversationId();

    await repo.branchConversationAt(
      workspaceId: 'ws',
      conversationId: conv,
      messageId: a,
    );

    final tree = await repo.conversationTree(
      workspaceId: 'ws',
      conversationId: conv,
    );
    expect(tree.leafMessageId, a);
    expect(
      tree.nodes.map((n) => n.messageId),
      containsAll([a, b]),
      reason: 'the path we left is still there — that is the whole design',
    );
    expect(tree.currentBranch.map((n) => n.messageId), [a]);
  });

  test('a message after a branch forks the tree', () async {
    final a = await send('one');
    await send('two');
    final conv = await conversationId();
    await repo.branchConversationAt(
      workspaceId: 'ws',
      conversationId: conv,
      messageId: a,
    );
    final c = await send('two, differently');

    final tree = await repo.conversationTree(
      workspaceId: 'ws',
      conversationId: conv,
    );
    final root = tree.nodes.firstWhere((n) => n.messageId == a);
    expect(root.childCount, 2);
    expect(root.isBranchPoint, isTrue);
    expect(tree.branchCount, 2, reason: 'two paths now exist');
    expect(tree.currentBranch.map((n) => n.messageId), [a, c]);
  });

  test('switching back is another pointer move, not a restore', () async {
    final a = await send('one');
    final b = await send('two');
    final conv = await conversationId();
    await repo.branchConversationAt(
      workspaceId: 'ws',
      conversationId: conv,
      messageId: a,
    );
    await send('two, differently');

    await repo.branchConversationAt(
      workspaceId: 'ws',
      conversationId: conv,
      messageId: b,
    );
    final tree = await repo.conversationTree(
      workspaceId: 'ws',
      conversationId: conv,
    );
    expect(tree.currentBranch.map((n) => n.messageId), [a, b]);
  });

  test(
    'a revert moves the tip so the next message lands in the right place',
    () async {
      // Without this the tree would record a lineage the conversation no longer
      // shows, and `/tree` would draw a branch nobody made.
      final a = await send('one');
      await send('two');
      await repo.revertConversationTo('ws', 'sp', a);

      final conv = await conversationId();
      final tree = await repo.conversationTree(
        workspaceId: 'ws',
        conversationId: conv,
      );
      expect(tree.leafMessageId, a);

      final c = await send('two, again');
      final after = await repo.conversationTree(
        workspaceId: 'ws',
        conversationId: conv,
      );
      expect(
        after.nodes.firstWhere((n) => n.messageId == c).parentMessageId,
        a,
      );
    },
  );

  group('fork', () {
    test('copies the branch into a new conversation with fresh ids', () async {
      final a = await send('one');
      await send('two');
      final conv = await conversationId();

      final forkId = await repo.forkConversation(
        workspaceId: 'ws',
        spaceId: 'sp',
        conversationId: conv,
        title: 'a different direction',
      );
      expect(forkId, isNot(conv));

      final forked = await repo.conversationTree(
        workspaceId: 'ws',
        conversationId: forkId,
      );
      expect(forked.nodes.map((n) => n.preview), ['one', 'two']);
      expect(
        forked.nodes.map((n) => n.messageId),
        isNot(contains(a)),
        reason:
            'sharing rows would make the fork show the original\'s later '
            'messages, which is the one thing a fork must not do',
      );
      expect(forked.nodes.first.parentMessageId, isNull);
      expect(forked.nodes.last.parentMessageId, forked.nodes.first.messageId);
    });

    test(
      'a later message in the fork does not appear in the original',
      () async {
        await send('one');
        final conv = await conversationId();
        final forkId = await repo.forkConversation(
          workspaceId: 'ws',
          spaceId: 'sp',
          conversationId: conv,
        );
        await send('only in the fork', conversationId: forkId);

        final original = await repo.conversationTree(
          workspaceId: 'ws',
          conversationId: conv,
        );
        expect(original.nodes.map((n) => n.preview), ['one']);
      },
    );

    test('forks from a named message rather than the tip', () async {
      final a = await send('one');
      await send('two');
      final conv = await conversationId();

      final forkId = await repo.forkConversation(
        workspaceId: 'ws',
        spaceId: 'sp',
        conversationId: conv,
        messageId: a,
      );
      final forked = await repo.conversationTree(
        workspaceId: 'ws',
        conversationId: forkId,
      );
      expect(forked.nodes.map((n) => n.preview), ['one']);
    });
  });

  group('branch walk', () {
    Future<void> raw(
      String id, {
      String? parent,
      String? conversation,
      String content = 'x',
      String type = 'text',
      String? metadata,
      int second = 0,
    }) async => db.messagingDao.insertMessage(
      ConversationMessagesTableCompanion.insert(
        id: id,
        spaceId: 'sp',
        conversationId: conversation ?? await conversationId(),
        senderId: 'u1',
        senderType: 'user',
        content: content,
        messageType: Value(type),
        metadata: Value(metadata),
        parentMessageId: Value(parent),
        createdAt: Value(DateTime.utc(2026, 1, 1, 0, 0, second)),
      ),
    );

    test('walks parent links oldest-first and stops at a loop', () async {
      final conv = await conversationId();
      await raw('m1');
      await raw('m2', parent: 'm1');
      await raw('m3', parent: 'm2');
      await raw('m4', parent: 'm3');
      // Close the loop once its target exists: the parent link is a key.
      await db.customStatement(
        "UPDATE conversation_messages SET parent_message_id = 'm3' "
        "WHERE id = 'm1'",
      );

      expect(await db.messagingDao.branchIds(conv, 'm4'), [
        'm1',
        'm2',
        'm3',
        'm4',
      ]);
      expect(await db.messagingDao.branchIds(conv, 'm4', maxDepth: 2), [
        'm3',
        'm4',
      ]);
    });

    test('a parent in another conversation ends the branch', () async {
      final conv = await conversationId();
      await db.conversationDao.insertConversation(
        ConversationsTableCompanion.insert(
          workspaceId: 'test-workspace',
          id: 'other',
          spaceId: 'sp',
        ),
      );
      await raw('elsewhere', conversation: 'other');
      await raw('m1', parent: 'elsewhere');
      await raw('m2', parent: 'm1');

      expect(await db.messagingDao.branchIds(conv, 'm2'), ['m1', 'm2']);
      final rows = await db.messagingDao.branchFrom(conv, 'm2');
      expect(rows.map((r) => r.id), ['m1', 'm2']);
    });

    test('tree nodes carry a bounded content head', () async {
      final conv = await conversationId();
      await raw('long', content: 'y' * 5000, second: 1);
      await raw('short', parent: 'long', content: 'hi', second: 1);

      final nodes = await db.messagingDao.treeNodes(conv);
      expect(nodes.map((n) => n.id), ['long', 'short']);
      expect(
        nodes.first.contentHead.length,
        MessagingDao.treePreviewSourceChars,
      );
      expect(nodes.last.contentHead, 'hi');
      expect(nodes.last.parentMessageId, 'long');
    });

    test('a fork keeps question and plan state', () async {
      final conv = await conversationId();
      await raw(
        'q',
        type: 'user_question',
        metadata: '{"question":"Which?","answered":true}',
      );
      await raw(
        'plan',
        parent: 'q',
        type: 'plan',
        metadata: '{"planStatus":"approved"}',
        second: 1,
      );

      final forkId = await repo.forkConversation(
        workspaceId: 'ws',
        spaceId: 'sp',
        conversationId: conv,
        messageId: 'plan',
      );
      final copied = await db.messagingDao.getMessages(forkId);
      expect(copied.map((m) => m.messageType), ['user_question', 'plan']);
      expect(copied.first.answered, isTrue);
      expect(copied.first.metadata, '{"question":"Which?"}');
      expect(copied.last.planStatus, 'approved');
    });
  });

  test('a conversation with no recorded tip starts a new root', () async {
    // A message inserted without moving the tip is not adopted as a parent.
    final conv = await conversationId();
    await db.messagingDao.insertMessage(
      ConversationMessagesTableCompanion.insert(
        id: 'untracked-1',
        spaceId: 'sp',
        conversationId: conv,
        senderId: 'u1',
        senderType: 'user',
        content: 'from before',
      ),
    );

    final next = await send('next');
    final tree = await repo.conversationTree(
      workspaceId: 'ws',
      conversationId: conv,
    );
    expect(
      tree.nodes.firstWhere((n) => n.messageId == next).parentMessageId,
      isNull,
    );
  });
}

/// A manager that hands out the one test database for any workspace id.
class _SingleWorkspace implements WorkspaceDatabaseManager {
  _SingleWorkspace(this._db);

  final WorkspaceDatabase _db;

  @override
  WorkspaceDatabase of(String workspaceId) => _db;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
