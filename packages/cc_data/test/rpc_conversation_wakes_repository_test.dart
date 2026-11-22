import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// [RpcConversationWakesRepository] over an in-process JSON-RPC host: the
/// `wakes.*` op names, the args (always the workspace), the wire decoding,
/// and the receipts.
void main() {
  late _Host host;
  late RemoteRpcClient client;
  late RpcConversationWakesRepository repo;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
    repo = RpcConversationWakesRepository(client);
  });

  tearDown(() async => client.close());

  Map<String, dynamic> wire({
    String id = 'wk-1',
    String reason = 'goal_continuation',
    bool? canRelease = true,
  }) => {
    'id': id,
    'workspace_id': 'ws-1',
    'space_id': 'sp-1',
    'conversation_id': 'conv-1',
    'agent_id': 'agent-1',
    'reason': reason,
    'origin': 'goal',
    'headline': 'your goal continues, segment 3',
    'state': 'held',
    'state_reason': 'stopped',
    'lane': 'follow_up',
    'not_before': '2026-05-01T12:00:00.000Z',
    'expires_at': '2026-05-02T12:00:00.000Z',
    'created_at': '2026-05-01T11:00:00.000Z',
    'requested_by_user_id': 'u-1',
    'attempt': 2,
    'can_release': ?canRelease,
  };

  test(
    'watchForConversation decodes each wake and names the workspace',
    () async {
      host.snapshotFor('wakes.watchForConversation', {
        'wakes': [wire(), wire(id: 'wk-bad', reason: 'not_a_reason')],
      });
      final wakes = await repo.watchForConversation('ws-1', 'conv-1').first;
      final w = wakes.single;
      expect(w.id, 'wk-1');
      expect(w.reason, WakeReason.goalContinuation);
      expect(w.origin, 'goal');
      expect(w.headline, 'your goal continues, segment 3');
      expect(w.state, WakeState.held);
      expect(w.stateReason, 'stopped');
      expect(w.lane, WakeLane.followUp);
      expect(w.notBefore, DateTime.utc(2026, 5, 1, 12));
      expect(w.expiresAt, DateTime.utc(2026, 5, 2, 12));
      expect(w.requestedByUserId, 'u-1');
      expect(w.attempt, 2);
      expect(w.canRelease, isTrue);
      expect(host.lastSubscribe!.args, {
        'workspace_id': 'ws-1',
        'conversation_id': 'conv-1',
      });
    },
  );

  test(
    "can_release is the server's answer; absent reads as not yours",
    () async {
      host.snapshotFor('wakes.watchForConversation', {
        'wakes': [
          wire(id: 'no', canRelease: false),
          wire(id: 'absent', canRelease: null),
        ],
      });
      final wakes = await repo.watchForConversation('ws-1', 'conv-1').first;
      expect([for (final w in wakes) w.canRelease], [false, false]);
    },
  );

  test('the ids of what raised a wake decode, and read null when absent', () async {
    host.snapshotFor('wakes.watchForConversation', {
      'wakes': [
        {
          ...wire(id: 'raised'),
          'source_agent_id': 'agent-2',
          'goal_id': 'goal-1',
          'rule_id': 'rule-1',
          'ask_id': 'ask-1',
        },
        wire(id: 'plain'),
      ],
    });
    final wakes = await repo.watchForConversation('ws-1', 'conv-1').first;
    final raised = wakes.firstWhere((w) => w.id == 'raised');
    expect(raised.sourceAgentId, 'agent-2');
    expect(raised.goalId, 'goal-1');
    expect(raised.ruleId, 'rule-1');
    expect(raised.askId, 'ask-1');
    final plain = wakes.firstWhere((w) => w.id == 'plain');
    expect(
      [plain.sourceAgentId, plain.goalId, plain.ruleId, plain.askId],
      everyElement(isNull),
    );
  });

  test('cancel, release and deliver now call their ops', () async {
    host.callResults['wakes.cancel'] = {'cancelled': true};
    host.callResults['wakes.release'] = {'released': 2};
    host.callResults['wakes.deliverNow'] = {
      'outcome': 'started',
      'run_id': 'run-1',
    };
    expect(await repo.cancel('ws-1', 'wk-1'), isTrue);
    expect(host.lastCall('wakes.cancel')!.args, {
      'workspace_id': 'ws-1',
      'wake_id': 'wk-1',
    });
    expect(await repo.release('ws-1', conversationId: 'conv-1'), 2);
    expect(host.lastCall('wakes.release')!.args, {
      'workspace_id': 'ws-1',
      'conversation_id': 'conv-1',
    });
    final receipt = await repo.deliverNow('ws-1', 'wk-1');
    expect(
      receipt,
      isA<WakeStarted>().having((r) => r.runId, 'runId', 'run-1'),
    );
    await expectLater(repo.release('ws-1'), throwsArgumentError);
  });

  test('held steering cards are released through steering.release with the '
      'workspace, space, conversation and the Stop holder', () async {
    host.callResults['steering.release'] = {'released': 2};
    final released = await RpcHeldSteeringRepository(
      client,
    ).release(workspaceId: 'ws-1', spaceId: 'sp-1', conversationId: 'conv-1');
    expect(released, 2);
    expect(host.lastCall('steering.release')!.args, {
      'workspace_id': 'ws-1',
      'space_id': 'sp-1',
      'conversation_id': 'conv-1',
      'held_by': 'stop',
    });
  });

  test('every receipt decodes', () {
    expect(
      wakeReceiptFromWire({'outcome': 'pushed', 'run_id': 'r'}),
      isA<WakePushed>(),
    );
    expect(
      wakeReceiptFromWire({'outcome': 'waiting', 'kind': 'held'}),
      isA<WakeWaiting>().having((r) => r.kind, 'kind', 'held'),
    );
    expect(
      wakeReceiptFromWire({'outcome': 'skipped', 'kind': 'budget_blocked'}),
      isA<WakeSkipped>(),
    );
    expect(wakeReceiptFromWire({'outcome': 'duplicate'}), isA<WakeDuplicate>());
    expect(
      () => wakeReceiptFromWire({'outcome': 'other'}),
      throwsFormatException,
    );
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
