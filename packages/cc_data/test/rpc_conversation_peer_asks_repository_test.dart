import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// [RpcConversationPeerAsksRepository] over an in-process JSON-RPC host: the
/// `peerAsks.*` op names, the args (always the workspace) and the wire
/// decoding.
void main() {
  late _Host host;
  late RemoteRpcClient client;
  late RpcConversationPeerAsksRepository repo;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
    repo = RpcConversationPeerAsksRepository(client);
  });

  tearDown(() async => client.close());

  // The server's `peerAskToWire` shape.
  Map<String, dynamic> wire({
    String id = 'ask-1',
    String status = 'answered',
  }) => {
    'id': id,
    'workspace_id': 'ws-1',
    'kind': 'consult',
    'mode': 'background',
    'status': status,
    'asker_agent_id': 'agent-a',
    'asker_conversation_id': 'conv-a',
    'asker_space_id': 'sp-a',
    'recipient_agent_id': 'agent-b',
    'recipient_conversation_id': 'conv-b',
    'recipient_space_id': 'sp-b',
    'question_message_id': 'm-1',
    'reply_message_id': 'm-2',
    'reply_inline': false,
    'created_at': '2026-05-01T11:00:00.000Z',
    'expires_at': '2026-05-02T11:00:00.000Z',
    'settled_at': '2026-05-01T11:30:00.000Z',
    'promised_at': '2026-05-01T11:10:00.000Z',
    'stall_noticed_run_id': 'run-9',
  };

  test(
    'watchForConversation decodes each ask and names the workspace',
    () async {
      host.snapshotFor('peerAsks.watchForConversation', {
        'asks': [wire(), wire(id: 'ask-bad', status: 'not_a_status')],
      });
      final asks = await repo.watchForConversation('ws-1', 'conv-a').first;
      final a = asks.single;
      expect(a.id, 'ask-1');
      expect(a.kind, PeerAskKind.consult);
      expect(a.mode, PeerAskMode.background);
      expect(a.status, PeerAskStatus.answered);
      expect(a.askerAgentId, 'agent-a');
      expect(a.askerConversationId, 'conv-a');
      expect(a.recipientAgentId, 'agent-b');
      expect(a.recipientConversationId, 'conv-b');
      expect(a.questionMessageId, 'm-1');
      expect(a.replyMessageId, 'm-2');
      expect(a.replyInline, isFalse);
      expect(a.createdAt, DateTime.utc(2026, 5, 1, 11));
      expect(a.expiresAt, DateTime.utc(2026, 5, 2, 11));
      expect(a.settledAt, DateTime.utc(2026, 5, 1, 11, 30));
      expect(a.promisedAt, DateTime.utc(2026, 5, 1, 11, 10));
      expect(a.blockedNoticedAt, isNull);
      expect(host.lastSubscribe!.args, {
        'workspace_id': 'ws-1',
        'conversation_id': 'conv-a',
      });
    },
  );

  test('cancel calls its op with the workspace', () async {
    host.callResults['peerAsks.cancel'] = {'cancelled': true};
    expect(await repo.cancel('ws-1', 'ask-1'), isTrue);
    expect(host.lastCall('peerAsks.cancel')!.args, {
      'workspace_id': 'ws-1',
      'ask_id': 'ask-1',
    });
    host.callResults['peerAsks.cancel'] = {'cancelled': false};
    expect(await repo.cancel('ws-1', 'ask-1'), isFalse);
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

/// A recorded `sub/subscribe`.
class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
  final Map<String, dynamic> args;
}

/// In-process host that scripts `repo/call` results and `sub/subscribe`
/// snapshots. Mirrors the wire shape the server catalog emits.
class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];

  /// Scripted `repo/call` results keyed by op name.
  final Map<String, Map<String, dynamic>> callResults = {};

  /// Scripted snapshots keyed by watch query (pushed on subscribe).
  final Map<String, Map<String, dynamic>> snapshots = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );
  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

  /// Scripts the snapshot pushed to the next subscription for [query].
  void snapshotFor(String query, Map<String, dynamic> data) =>
      snapshots[query] = data;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        final query = params['query'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        subs.add(_Sub(query: query, args: args));
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
        // Immediately push the scripted snapshot for this query (if any).
        final snapshot = snapshots[query];
        if (snapshot != null) {
          space.send({
            'jsonrpc': '2.0',
            'method': RpcMethods.subSnapshot,
            'params': {
              'subscriptionId': 's1',
              'rev': 1,
              'full': true,
              'data': snapshot,
            },
          });
        }
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add(_Call(op: op, args: args));
        _reply(id, {'op': op, 'data': callResults[op] ?? const {}});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
