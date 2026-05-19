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
      SpacesTableCompanion.insert(id: 'sp', name: 'general'),
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

  Future<String> conversationId() =>
      db.conversationDao.ensureStandingConversation(
        workspaceId: 'ws',
        spaceId: 'sp',
      );

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

  test('a revert moves the tip so the next message lands in the right place',
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
  });

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
        reason: 'sharing rows would make the fork show the original\'s later '
            'messages, which is the one thing a fork must not do',
      );
      expect(forked.nodes.first.parentMessageId, isNull);
      expect(forked.nodes.last.parentMessageId, forked.nodes.first.messageId);
    });

    test('a later message in the fork does not appear in the original',
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
    });

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

  test('a conversation written before the tree still chains', () async {
    // Existing rows have no parent recorded. The leaf falls back to the newest
    // message so the next send joins the history rather than starting a second
    // root beside it.
    final conv = await conversationId();
    await db.messagingDao.insertMessage(
      ConversationMessagesTableCompanion.insert(
        id: 'legacy-1',
        spaceId: 'sp',
        conversationId: conv,
        senderId: 'u1',
        senderType: 'user',
        content: 'from before',
      ),
    );

    final next = await send('after the upgrade');
    final tree = await repo.conversationTree(
      workspaceId: 'ws',
      conversationId: conv,
    );
    expect(
      tree.nodes.firstWhere((n) => n.messageId == next).parentMessageId,
      'legacy-1',
    );
    expect(tree.branchCount, 1);
  });
}

/// A manager that hands out the one test database for any workspace id.
class _SingleWorkspace implements WorkspaceDatabaseManager {
  _SingleWorkspace(this._db);

  final WorkspaceDatabase _db;

  @override
  WorkspaceDatabase of(String workspaceId) => _db;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
