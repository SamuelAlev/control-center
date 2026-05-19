import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcAgentGoalRunRepository] over an in-process JSON-RPC host.
/// Pins the `agentGoalRuns.*` op names, the args shape, and the wire-map →
/// [AgentGoalRun] parsing — including every [AgentGoalStatus] wire name and
/// the fail-closed fallbacks for unknown values.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  Map<String, dynamic> wireGoal({
    String id = 'goal-1',
    String kind = 'goal',
    String status = 'active',
  }) => {
    'id': id,
    'workspace_id': 'ws-1',
    'channel_id': 'ch-1',
    'conversation_id': 'conv-1',
    'agent_id': 'a-1',
    'user_text': 'Keep the changelog current',
    'kind': kind,
    'status': status,
    'deadline_at': '2026-08-01T12:00:00.000',
    'cost_cap_cents': 500,
    'cost_cents': 125,
    'max_runs': 10,
    'run_count': 3,
    'consecutive_failures': 1,
    'active_run_id': 'run-7',
    'requested_by_user_id': 'u-1',
    'summary': null,
    'created_at': '2026-07-01T09:00:00.000',
    'updated_at': '2026-07-01T10:00:00.000',
  };

  group('watchForConversation', () {
    test(
      'maps the full wire shape + forwards workspace_id/conversation_id',
      () async {
        host.snapshotFor('agentGoalRuns.watchForConversation', {
          'goals': [wireGoal()],
        });
        final repo = RpcAgentGoalRunRepository(client);
        final goals = await repo.watchForConversation('ws-1', 'conv-1').first;
        final g = goals.single;
        expect(g.id, 'goal-1');
        expect(g.workspaceId, 'ws-1');
        expect(g.channelId, 'ch-1');
        expect(g.conversationId, 'conv-1');
        expect(g.agentId, 'a-1');
        expect(g.userText, 'Keep the changelog current');
        expect(g.kind, AgentGoalKind.goal);
        expect(g.status, AgentGoalStatus.active);
        expect(g.deadlineAt, DateTime(2026, 8, 1, 12));
        expect(g.costCapCents, 500);
        expect(g.costCents, 125);
        expect(g.maxRuns, 10);
        expect(g.runCount, 3);
        expect(g.consecutiveFailures, 1);
        expect(g.activeRunId, 'run-7');
        expect(g.requestedByUserId, 'u-1');
        expect(g.summary, isNull);
        expect(g.createdAt, DateTime(2026, 7, 1, 9));
        expect(g.updatedAt, DateTime(2026, 7, 1, 10));
        final sub = host.lastSubscribe!;
        expect(sub.query, 'agentGoalRuns.watchForConversation');
        expect(sub.args['workspace_id'], 'ws-1');
        expect(sub.args['conversation_id'], 'conv-1');
      },
    );

    test('parses every status wire name', () async {
      host.snapshotFor('agentGoalRuns.watchForConversation', {
        'goals': [
          wireGoal(id: 'g-active', status: 'active'),
          wireGoal(id: 'g-paused', status: 'paused'),
          wireGoal(id: 'g-completed', status: 'completed'),
          wireGoal(id: 'g-failed', status: 'failed'),
          wireGoal(id: 'g-cancelled', status: 'cancelled'),
          wireGoal(id: 'g-budget', status: 'budget_exhausted'),
        ],
      });
      final repo = RpcAgentGoalRunRepository(client);
      final goals = await repo.watchForConversation('ws-1', 'conv-1').first;
      expect(goals.map((g) => g.status), [
        AgentGoalStatus.active,
        AgentGoalStatus.paused,
        AgentGoalStatus.completed,
        AgentGoalStatus.failed,
        AgentGoalStatus.cancelled,
        AgentGoalStatus.budgetExhausted,
      ]);
    });

    test('maps the loop kind; unknown kind degrades to goal', () async {
      host.snapshotFor('agentGoalRuns.watchForConversation', {
        'goals': [
          wireGoal(id: 'g-loop', kind: 'loop'),
          wireGoal(id: 'g-unknown', kind: 'spiral'),
        ],
      });
      final repo = RpcAgentGoalRunRepository(client);
      final goals = await repo.watchForConversation('ws-1', 'conv-1').first;
      expect(goals[0].kind, AgentGoalKind.loop);
      expect(goals[1].kind, AgentGoalKind.goal);
    });

    test('unknown status fails closed to cancelled', () async {
      host.snapshotFor('agentGoalRuns.watchForConversation', {
        'goals': [wireGoal(status: 'resurrected')],
      });
      final repo = RpcAgentGoalRunRepository(client);
      final g =
          (await repo.watchForConversation('ws-1', 'conv-1').first).single;
      expect(g.status, AgentGoalStatus.cancelled);
    });

    test('tolerates epoch-millis dates and absent optional fields', () async {
      host.snapshotFor('agentGoalRuns.watchForConversation', {
        'goals': [
          {
            'id': 'goal-1',
            'workspace_id': 'ws-1',
            'user_text': 'Ship it',
            'kind': 'goal',
            'status': 'paused',
            'deadline_at': 1780000000000,
            'created_at': 0,
            'updated_at': 0,
          },
        ],
      });
      final repo = RpcAgentGoalRunRepository(client);
      final g =
          (await repo.watchForConversation('ws-1', 'conv-1').first).single;
      expect(g.deadlineAt, DateTime.fromMillisecondsSinceEpoch(1780000000000));
      expect(g.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(g.activeRunId, isNull);
      expect(g.requestedByUserId, isNull);
      expect(g.costCents, 0);
      expect(g.runCount, 0);
    });

    test('empty goals payload yields an empty list', () async {
      host.snapshotFor('agentGoalRuns.watchForConversation', const {});
      final repo = RpcAgentGoalRunRepository(client);
      final goals = await repo.watchForConversation('ws-1', 'conv-1').first;
      expect(goals, isEmpty);
    });
  });

  group('control mutations', () {
    for (final (method, op) in [
      ('pause', 'agentGoalRuns.pause'),
      ('resume', 'agentGoalRuns.resume'),
      ('cancel', 'agentGoalRuns.cancel'),
    ]) {
      test('$method calls $op with workspace_id + goal_id', () async {
        final repo = RpcAgentGoalRunRepository(client);
        switch (method) {
          case 'pause':
            await repo.pauseGoal('ws-1', 'goal-9');
          case 'resume':
            await repo.resumeGoal('ws-1', 'goal-9');
          case 'cancel':
            await repo.cancelGoal('ws-1', 'goal-9');
        }
        final call = host.lastCall(op)!;
        expect(call.args['workspace_id'], 'ws-1');
        expect(call.args['goal_id'], 'goal-9');
      });
    }
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
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
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
          channel.send({
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
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
