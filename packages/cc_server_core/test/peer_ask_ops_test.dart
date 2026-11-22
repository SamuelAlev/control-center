import 'package:cc_domain/cc_domain.dart'
    show RepoOpKind, ValidationException, WorkspaceMismatchException;
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/peer_ask_ops.dart';
import 'package:test/test.dart';

import '../../cc_infra/test/dispatch/peer_test_kit.dart';

/// The `peerAsks.*` ops: workspace isolation at each op (a foreign ask or
/// conversation id is a `WorkspaceMismatchException`), the space gate, a
/// cancel that wakes nobody, and the wire shape.
void main() {
  late PeerKit kit;
  late List<RepoOp> ops;
  late List<WatchQuery> watches;
  late Set<String> unreadableSpaces;

  PeerAsk ask(String id, String ws, {String conversation = 'c-a'}) => PeerAsk(
    id: id,
    workspaceId: ws,
    askerAgentId: 'agent-a',
    askerConversationId: conversation,
    askerSpaceId: 'sp-a',
    recipientAgentId: 'agent-b',
    recipientConversationId: 'c-b',
    dispatchedRunId: 'run-b',
    questionHash: 'h-$id',
    chain: const ['agent-z'],
    requestedByUserId: 'user-1',
    createdAt: kit.now,
    expiresAt: kit.now.add(const Duration(hours: 24)),
  );

  setUp(() async {
    kit = PeerKit()
      ..conversation('c-a', spaceId: 'sp-a')
      ..conversation('c-x', spaceId: 'sp-x', workspaceId: PeerKit.other);
    await kit.asks.insert(ask('ask-1', PeerKit.ws));
    await kit.asks.insert(ask('ask-x', PeerKit.other, conversation: 'c-x'));
    await kit.start();
    unreadableSpaces = {};
    final pack = buildPeerAskOps(
      service: kit.service,
      asks: kit.asks,
      conversations: kit.conversationRepository,
      requireSpace: (ws, user, space) async {
        if (unreadableSpaces.contains(space)) {
          throw const ValidationException('space_access_denied');
        }
      },
      guardSpace: (ws, user, space, source) => source,
    );
    ops = pack.ops;
    watches = pack.watches;
  });

  RepoOpContext ctx(Map<String, dynamic> args, {String ws = PeerKit.ws}) =>
      RepoOpContext(
        args: args,
        workspaceId: ws,
        deviceId: 'device-1',
        userId: 'user-1',
      );

  Future<Map<String, dynamic>> cancel(
    String id, {
    String ws = PeerKit.ws,
  }) async => Map<String, dynamic>.from(
    await ops.single.handler(ctx({'ask_id': id}, ws: ws)) as Map,
  );

  Stream<dynamic> watch(String conversation, {String ws = PeerKit.ws}) =>
      watches.single.handler(
        WatchQueryContext(
          args: {'conversation_id': conversation},
          workspaceId: ws,
          deviceId: 'device-1',
          userId: 'user-1',
        ),
      );

  test('the pack is cancel and the watch, open to members', () {
    expect(ops.single.name, 'peerAsks.cancel');
    expect(ops.single.kind, RepoOpKind.mutate);
    expect(watches.single.name, 'peerAsks.watchForConversation');
  });

  test('no service, no ops', () {
    final pack = buildPeerAskOps(
      service: null,
      asks: null,
      conversations: kit.conversationRepository,
      requireSpace: (_, _, _) async {},
      guardSpace: (_, _, _, s) => s,
    );
    expect(pack.ops, isEmpty);
    expect(pack.watches, isEmpty);
  });

  test("cancel and watch refuse another workspace's ids", () async {
    await expectLater(
      cancel('ask-x'),
      throwsA(isA<WorkspaceMismatchException>()),
    );
    await expectLater(
      watch('c-x').first,
      throwsA(isA<WorkspaceMismatchException>()),
    );
    expect(
      (await kit.asks.getById(PeerKit.other, 'ask-x'))!.status,
      PeerAskStatus.pending,
    );
  });

  test('an unreadable space refuses both', () async {
    unreadableSpaces.add('sp-a');
    await expectLater(cancel('ask-1'), throwsA(isA<ValidationException>()));
    await expectLater(watch('c-a').first, throwsA(isA<ValidationException>()));
  });

  test('cancel settles the ask and wakes nobody; twice is false', () async {
    expect(await cancel('ask-1'), {'cancelled': true});
    expect(
      (await kit.asks.getById(PeerKit.ws, 'ask-1'))!.status,
      PeerAskStatus.cancelled,
    );
    await kit.deliver();
    expect(kit.wakes.all(PeerKit.ws), isEmpty);
    expect(kit.dispatched, isEmpty);
    expect(await cancel('ask-1'), {'cancelled': false});
  });

  test('the watch sends the outbound wire shape', () async {
    await kit.asks.markPromised(PeerKit.ws, id: 'ask-1', now: kit.now);
    final data = await watch('c-a').first as Map<String, dynamic>;
    final row = (data['asks'] as List).single as Map<String, dynamic>;
    expect(row, {
      'id': 'ask-1',
      'workspace_id': PeerKit.ws,
      'kind': 'ask',
      'mode': 'wait',
      'status': 'pending',
      'asker_agent_id': 'agent-a',
      'asker_conversation_id': 'c-a',
      'asker_space_id': 'sp-a',
      'recipient_agent_id': 'agent-b',
      'recipient_conversation_id': 'c-b',
      'reply_inline': false,
      'requested_by_user_id': 'user-1',
      'created_at': kit.now.toIso8601String(),
      'expires_at': kit.now.add(const Duration(hours: 24)).toIso8601String(),
      'promised_at': kit.now.toIso8601String(),
    });
    // The chain and the question hash are the server's.
    expect(row.containsKey('chain'), isFalse);
    expect(row.containsKey('question_hash'), isFalse);
  });
}
