import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_infra/src/dispatch/peer_ask_service.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/peer_ask_ops.dart';
import 'package:test/test.dart';

import '../../cc_infra/test/dispatch/peer_test_kit.dart';
import 'helpers/test_database.dart';

/// [PeerAskService] on the stored repository: what drift reads back (local
/// times, whole seconds) is what the service and the wire see, the expiry
/// sweep settles a stored ask, and the limits hold for asks made at once.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoPeerAskRepository store;
  late PeerKit kit;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    store = DaoPeerAskRepository(dbs);
    await seedTestWorkspace(global, dbs, PeerKit.ws);
    final db = dbs.of(PeerKit.ws);
    for (final agent in ['agent-a', 'agent-b']) {
      await db.customStatement(
        'INSERT INTO agents (id, name, title, agent_md_path, workspace_id, '
        "skills) VALUES (?, ?, 'Agent', '', ?, '')",
        [agent, agent, PeerKit.ws],
      );
    }
    for (final (conversation, space) in [('c-a', 'sp-a'), ('c-b', 'sp-b')]) {
      await db.customStatement(
        'INSERT INTO spaces (id, name, workspace_id) VALUES (?, ?, ?)',
        [space, space, PeerKit.ws],
      );
      await db.customStatement(
        'INSERT INTO conversations (id, space_id, workspace_id) '
        'VALUES (?, ?, ?)',
        [conversation, space, PeerKit.ws],
      );
    }
    // A clock with a sub-second part, as a real one has.
    kit =
        PeerKit(
            now: DateTime.utc(2026, 11, 19, 14, 0, 0, 250, 500),
            store: store,
          )
          ..agent('agent-a', 'Ada')
          ..agent('agent-b', 'Bo')
          ..conversation('c-a', spaceId: 'sp-a')
          ..conversation('c-b', spaceId: 'sp-b');
    await kit.start();
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  PeerAskRequest request(String question) => PeerAskRequest(
    workspaceId: PeerKit.ws,
    kind: PeerAskKind.ask,
    mode: PeerAskMode.background,
    askerAgentId: 'agent-a',
    askerName: 'Ada',
    askerConversationId: 'c-a',
    recipientAgentId: 'agent-b',
    recipientSpaceId: 'sp-b',
    recipientConversationId: 'c-b',
    questionMessageId: 'q-1',
    question: question,
    chain: const ['agent-a'],
  );

  test('an ask read back is UTC, on the wire too, and the expiry sweep '
      'settles it', () async {
    final made = await kit.service.ask(request('Is the cast safe?'));
    final id = (made as PeerAskPending).ask.id;
    final read = (await store.getById(PeerKit.ws, id))!;
    expect(read.createdAt.isUtc, isTrue);
    expect(read.expiresAt.isUtc, isTrue);
    expect(read.createdAt, DateTime.utc(2026, 11, 19, 14));
    final wire = peerAskToWire(read);
    expect(wire['created_at'], '2026-11-19T14:00:00.000Z');
    expect(wire['expires_at'], '2026-11-20T14:00:00.000Z');

    kit.now = kit.now.add(PeerAskLimits.expiry);
    await kit.service.sweep();
    final expired = (await store.getById(PeerKit.ws, id))!;
    expect(expired.status, PeerAskStatus.expired);
    expect(expired.settledAt!.isUtc, isTrue);
    expect(peerAskToWire(expired)['settled_at'], endsWith('Z'));
    final notice = kit.wakes
        .all(PeerKit.ws)
        .where((w) => w.reason == WakeReason.peerReply)
        .single;
    expect(notice.detail.status, PeerAskStatus.expired.wire);
    expect(notice.agentId, 'agent-a');
    // Once: a second sweep finds nothing to settle.
    await kit.service.sweep();
    expect(
      kit.wakes.all(PeerKit.ws).where((w) => w.reason == WakeReason.peerReply),
      hasLength(1),
    );
  });

  test('asks made at once: the asker cap and the repeat refusal hold on the '
      'stored repository', () async {
    Future<String> attempt(String question) async {
      final refusal = await kit.service.refusalFor(
        workspaceId: PeerKit.ws,
        askerAgentId: 'agent-a',
        askerConversationId: 'c-a',
        recipientAgentId: 'agent-b',
        question: question,
        chain: PeerChain.none,
      );
      if (refusal != null) {
        return refusal.kind;
      }
      return switch (await kit.service.ask(request(question))) {
        PeerAskRefused(:final refusal) => refusal.kind,
        _ => 'asked',
      };
    }

    final outcomes = await Future.wait([
      for (var i = 0; i < 12; i++) attempt('Question $i?'),
    ]);
    expect(outcomes.where((o) => o == 'asked'), hasLength(10));
    expect(
      outcomes.where((o) => o == PeerAskRefusals.limitReached),
      hasLength(2),
    );
    expect(await store.countPending(PeerKit.ws, askerAgentId: 'agent-a'), 10);
    // The same question again, twice at once: the pending one is repeated.
    final repeats = await Future.wait([
      attempt('Question 0?'),
      attempt('Question 0?'),
    ]);
    expect(repeats, everyElement(PeerAskRefusals.duplicate));
  });
}
