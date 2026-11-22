import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcAgentGoalRunRepository] over an in-process JSON-RPC host.
/// Pins the `agentGoalRuns.*` op names, the args shape and the wire-map →
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
    String status = 'active',
  }) => {
    'id': id,
    'workspace_id': 'ws-1',
    'space_id': 'ch-1',
    'conversation_id': 'conv-1',
    'agent_id': 'a-1',
    'user_text': 'Keep the changelog current',
    'status': status,
    'deadline_at': '2026-08-01T12:00:00.000',
    'cost_cap_micros': 5000000,
    'cost_micros': 1250000,
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
        final g = goals.single.goal;
        expect(g.id, 'goal-1');
        expect(g.workspaceId, 'ws-1');
        expect(g.spaceId, 'ch-1');
        expect(g.conversationId, 'conv-1');
        expect(g.agentId, 'a-1');
        expect(g.userText, 'Keep the changelog current');
        expect(g.status, AgentGoalStatus.active);
        expect(g.deadlineAt, DateTime(2026, 8, 1, 12).toUtc());
        expect(g.costCapMicros, 5000000);
        expect(g.costMicros, 1250000);
        expect(g.maxRuns, 10);
        expect(g.runCount, 3);
        expect(g.consecutiveFailures, 1);
        expect(g.activeRunId, 'run-7');
        expect(g.requestedByUserId, 'u-1');
        expect(g.summary, isNull);
        expect(g.createdAt, DateTime(2026, 7, 1, 9).toUtc());
        expect(g.updatedAt, DateTime(2026, 7, 1, 10).toUtc());
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
      expect(goals.map((v) => v.goal.status), [
        AgentGoalStatus.active,
        AgentGoalStatus.paused,
        AgentGoalStatus.completed,
        AgentGoalStatus.failed,
        AgentGoalStatus.cancelled,
        AgentGoalStatus.budgetExhausted,
      ]);
    });

    test('maps the verification state', () async {
      host.snapshotFor('agentGoalRuns.watchForConversation', {
        'goals': [
          {
            ...wireGoal(),
            'contract': {
              'criteria': ['the tests pass'],
              'checks': [
                {'run': 'make test', 'in': 'environment'},
              ],
            },
            'hold': 'needs_review',
            'hold_until': '2026-07-02T09:00:00.000',
            'hold_detail': 'stalled',
            'no_progress_streak': 3,
            'verification_rounds': 1,
            'last_fingerprint': 'fp',
            'park_count': 2,
            'fresh': true,
            'unattended': 'assume',
            'checker_agent_id': 'a-2',
            'verification': {
              'round': 1,
              'claimSummary': 'done',
              'at': '2026-07-01T11:00:00.000Z',
            },
          },
        ],
      });
      final repo = RpcAgentGoalRunRepository(client);
      final g =
          (await repo.watchForConversation('ws-1', 'conv-1').first).single.goal;
      expect(g.contract?.criteria, ['the tests pass']);
      expect(g.contract?.checks.single.where, GoalCheckLocation.environment);
      expect(g.hold, GoalHold.needsReview);
      expect(g.holdUntil, DateTime(2026, 7, 2, 9).toUtc());
      expect(g.holdDetail, 'stalled');
      expect(g.noProgressStreak, 3);
      expect(g.verificationRounds, 1);
      expect(g.lastFingerprint, 'fp');
      expect(g.parkCount, 2);
      expect(g.fresh, isTrue);
      expect(g.unattended, GoalUnattendedPolicy.assume);
      expect(g.checkerAgentId, 'a-2');
      expect(g.verification?.round, 1);
      expect(g.verification?.claimSummary, 'done');
    });

    test('a malformed verification state reads as absent', () async {
      host.snapshotFor('agentGoalRuns.watchForConversation', {
        'goals': [
          {
            ...wireGoal(),
            'contract': {'criteria': 'not a list'},
            'hold': 'sleeping',
            'unattended': 'shrug',
            'verification': {'round': 0},
            'park_count': -4,
          },
        ],
      });
      final repo = RpcAgentGoalRunRepository(client);
      final g =
          (await repo.watchForConversation('ws-1', 'conv-1').first).single.goal;
      expect(g.contract, isNull);
      expect(g.hold, isNull);
      expect(g.unattended, GoalUnattendedPolicy.wait);
      expect(g.verification, isNull);
      expect(g.parkCount, 0);
    });

    test('unknown status fails closed to cancelled', () async {
      host.snapshotFor('agentGoalRuns.watchForConversation', {
        'goals': [wireGoal(status: 'resurrected')],
      });
      final repo = RpcAgentGoalRunRepository(client);
      final g =
          (await repo.watchForConversation('ws-1', 'conv-1').first).single.goal;
      expect(g.status, AgentGoalStatus.cancelled);
    });

    test('tolerates epoch-millis dates and absent optional fields', () async {
      host.snapshotFor('agentGoalRuns.watchForConversation', {
        'goals': [
          {
            'id': 'goal-1',
            'workspace_id': 'ws-1',
            'user_text': 'Ship it',
            'status': 'paused',
            'deadline_at': 1780000000000,
            'created_at': 0,
            'updated_at': 0,
          },
        ],
      });
      final repo = RpcAgentGoalRunRepository(client);
      final g =
          (await repo.watchForConversation('ws-1', 'conv-1').first).single.goal;
      expect(
        g.deadlineAt,
        DateTime.fromMillisecondsSinceEpoch(1780000000000, isUtc: true),
      );
      expect(g.createdAt, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
      expect(g.activeRunId, isNull);
      expect(g.requestedByUserId, isNull);
      expect(g.costMicros, 0);
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

  group('can_resume', () {
    test('is the server\'s answer per goal; absent reads as false', () async {
      host.snapshotFor('agentGoalRuns.watchForWorkspace', {
        'goals': [
          {...wireGoal(id: 'mine'), 'can_resume': true},
          {...wireGoal(id: 'theirs'), 'can_resume': false},
          wireGoal(id: 'old'),
        ],
      });
      final views = await RpcAgentGoalRunRepository(
        client,
      ).watchForWorkspace('ws-1').first;
      expect({for (final v in views) v.goal.id: v.canResume}, {
        'mine': true,
        'theirs': false,
        'old': false,
      });
    });

    test('rides on a single goal too', () async {
      host.callResults['agentGoalRuns.get'] = {
        'goal': {...wireGoal(id: 'goal-9'), 'can_resume': true},
      };
      final view = await RpcAgentGoalRunRepository(
        client,
      ).getGoal('ws-1', 'goal-9');
      expect(view.canResume, isTrue);
    });
  });

  group('contract', () {
    test('getGoal calls agentGoalRuns.get and maps the goal', () async {
      host.callResults['agentGoalRuns.get'] = {'goal': wireGoal(id: 'goal-9')};
      final goal = await RpcAgentGoalRunRepository(
        client,
      ).getGoal('ws-1', 'goal-9');
      expect(goal.goal.id, 'goal-9');
      final call = host.lastCall('agentGoalRuns.get')!;
      expect(call.args, {'workspace_id': 'ws-1', 'goal_id': 'goal-9'});
    });

    test('setContract sends the contract JSON; null clears it', () async {
      host.callResults['agentGoalRuns.setContract'] = {
        'goal': wireGoal(status: 'paused'),
      };
      final repo = RpcAgentGoalRunRepository(client);
      final contract = GoalContract(
        criteria: const ['Tests pass'],
        checks: [GoalCheck(run: 'make test', timeoutSeconds: 600)],
      );
      final goal = await repo.setContract('ws-1', 'goal-1', contract);
      expect(goal.goal.status, AgentGoalStatus.paused);
      var call = host.lastCall('agentGoalRuns.setContract')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['goal_id'], 'goal-1');
      expect(call.args['contract'], {
        'criteria': ['Tests pass'],
        'checks': [
          {'run': 'make test', 'in': 'worktree', 'timeoutSeconds': 600},
        ],
      });
      await repo.setContract('ws-1', 'goal-1', null);
      call = host.lastCall('agentGoalRuns.setContract')!;
      expect(call.args.containsKey('contract'), isTrue);
      expect(call.args['contract'], isNull);
    });

    test('setChecker sends the agent id; null clears it', () async {
      host.callResults['agentGoalRuns.setChecker'] = {
        'goal': wireGoal(status: 'paused'),
      };
      final repo = RpcAgentGoalRunRepository(client);
      await repo.setChecker('ws-1', 'goal-1', 'agent-2');
      expect(
        host.lastCall('agentGoalRuns.setChecker')!.args['checker_agent_id'],
        'agent-2',
      );
      await repo.setChecker('ws-1', 'goal-1', null);
      final call = host.lastCall('agentGoalRuns.setChecker')!;
      expect(call.args.containsKey('checker_agent_id'), isTrue);
      expect(call.args['checker_agent_id'], isNull);
    });

    test('approveCompletion calls agentGoalRuns.approveCompletion and maps '
        'the closed goal', () async {
      host.callResults['agentGoalRuns.approveCompletion'] = {
        'goal': {...wireGoal(id: 'goal-9', status: 'completed')},
      };
      final view = await RpcAgentGoalRunRepository(
        client,
      ).approveCompletion('ws-1', 'goal-9');
      expect(view.goal.status, AgentGoalStatus.completed);
      final call = host.lastCall('agentGoalRuns.approveCompletion')!;
      expect(call.args, {'workspace_id': 'ws-1', 'goal_id': 'goal-9'});
    });

    test('a reply without a goal is an error', () async {
      expect(
        RpcAgentGoalRunRepository(client).getGoal('ws-1', 'goal-1'),
        throwsFormatException,
      );
    });
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
