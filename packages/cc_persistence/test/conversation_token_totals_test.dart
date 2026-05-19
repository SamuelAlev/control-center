import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The SQL aggregate behind `messaging.watchConversationTokens` has to produce
/// exactly what folding the messages produces — the meter it feeds is supposed
/// to agree with the compaction trigger, and the whole point of the aggregate
/// is that nobody ever compares the two at runtime.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoMessagingRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    repo = DaoMessagingRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  /// Both readings of the same conversation: the aggregate the meters use and
  /// the reference fold over the messages themselves.
  Future<({ConversationTokenTotals aggregate, ConversationTokenTotals folded})>
  bothReadings(String spaceId) async {
    final conversationId = await repo.ensureStandingConversation(
      'ws-1',
      spaceId,
    );
    final aggregate = await repo
        .watchConversationTokens('ws-1', spaceId, conversationId)
        .first;
    final messages = await repo.getMessages('ws-1', spaceId);
    return (aggregate: aggregate, folded: conversationTokenTotals(messages));
  }

  test('agrees with the reference fold over plain messages', () async {
    final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
    for (var i = 0; i < 12; i++) {
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        // Deliberately ragged lengths: the estimate rounds UP per message, so
        // equal-length rows would hide a sum-of-ceils / ceil-of-sum mismatch.
        content: 'x' * (i * 7 + 1),
        senderId: 'user',
        senderType: 'user',
      );
    }

    final r = await bothReadings(space.id);
    expect(r.aggregate.tokens, r.folded.tokens);
    expect(r.aggregate.chars, r.folded.chars);
    expect(r.aggregate.tokens, greaterThan(0));
  });

  test('measures an agent turn by its transcript, not its answer', () async {
    final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
    await repo.sendMessage(
      workspaceId: 'ws-1',
      spaceId: space.id,
      content: 'done',
      senderId: 'agent-1',
      senderType: 'agent',
      messageType: 'agent_turn',
      // What the turn actually carried: a four-character answer on top of a
      // transcript three orders of magnitude bigger. A meter that counted the
      // answer would read a full window as nearly empty.
      metadata: const {'transcriptChars': 40000},
    );

    final r = await bothReadings(space.id);
    expect(r.aggregate.tokens, r.folded.tokens);
    expect(r.aggregate.tokens, greaterThan(10000));
  });

  test('falls back to content for a turn with no counted transcript', () async {
    final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
    await repo.sendMessage(
      workspaceId: 'ws-1',
      spaceId: space.id,
      content: 'y' * 380,
      senderId: 'agent-1',
      senderType: 'agent',
      messageType: 'agent_turn',
    );

    final r = await bothReadings(space.id);
    expect(r.aggregate.tokens, r.folded.tokens);
    expect(r.aggregate.tokens, 100);
  });

  test('excludes compacted messages — they are folded context, not live', () async {
    final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
    final live = await repo.sendMessage(
      workspaceId: 'ws-1',
      spaceId: space.id,
      content: 'z' * 190,
      senderId: 'user',
      senderType: 'user',
    );
    final folded = await repo.sendMessage(
      workspaceId: 'ws-1',
      spaceId: space.id,
      content: 'z' * 3800,
      senderId: 'user',
      senderType: 'user',
    );
    await repo.markCompacted('ws-1', [folded]);

    final r = await bothReadings(space.id);
    expect(r.aggregate.tokens, r.folded.tokens);
    // Only the live row: 190 chars at 3.8 chars/token.
    expect(r.aggregate.tokens, 50);
    expect(live, isNotEmpty);
  });

  test('excludes reverted messages', () async {
    final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
    final keep = await repo.sendMessage(
      workspaceId: 'ws-1',
      spaceId: space.id,
      content: 'a' * 190,
      senderId: 'user',
      senderType: 'user',
    );
    await repo.sendMessage(
      workspaceId: 'ws-1',
      spaceId: space.id,
      content: 'b' * 3800,
      senderId: 'user',
      senderType: 'user',
    );
    await repo.revertConversationTo('ws-1', space.id, keep);

    final r = await bothReadings(space.id);
    expect(r.aggregate.tokens, r.folded.tokens);
    expect(r.aggregate.tokens, 50);
  });

  test('an empty conversation reads zero rather than failing', () async {
    final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
    final r = await bothReadings(space.id);
    expect(r.aggregate, ConversationTokenTotals.empty);
    expect(r.folded, ConversationTokenTotals.empty);
  });

  test('does not count a sibling conversation in the same space', () async {
    final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
    final standing = await repo.ensureStandingConversation('ws-1', space.id);
    await repo.sendMessage(
      workspaceId: 'ws-1',
      spaceId: space.id,
      conversationId: standing,
      content: 'c' * 190,
      senderId: 'user',
      senderType: 'user',
    );
    // A thread is a co-equal conversation in the same space; the meter reads
    // one window, not the room.
    final fork = await repo.forkConversation(
      workspaceId: 'ws-1',
      spaceId: space.id,
      conversationId: standing,
    );
    await repo.sendMessage(
      workspaceId: 'ws-1',
      spaceId: space.id,
      conversationId: fork,
      content: 'd' * 38000,
      senderId: 'user',
      senderType: 'user',
    );

    final totals = await repo
        .watchConversationTokens('ws-1', space.id, standing)
        .first;
    expect(totals.tokens, 50);
  });
}
