import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';
import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/value_objects/agent_presence.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_level.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises the governance read surface — [RpcGoalRepository],
/// [RpcApprovalRepository] and [RpcAgentPresenceReader] — over an in-process
/// JSON-RPC host. Each adapter parses the server's wire maps (the `*ToWire`
/// shapes in the host catalog) straight into the domain types. These tests pin
/// the op name, the args shape, the entity-from-wire mapping, the notFound
/// short-circuit and the [UnsupportedError] write guards.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcGoalRepository reads', () {
    test(
      'watchByWorkspace maps OrgGoal wire maps + forwards workspace_id',
      () async {
        host.snapshotFor('goals.watchForWorkspace', {
          'goals': [
            {
              'id': 'g-1',
              'workspace_id': 'ws-1',
              'title': 'Ship v2',
              'level': 'company',
              'parent_goal_id': null,
              'description': 'The mission',
              'status': 'active',
              'owner_agent_id': 'a-1',
              'team_id': null,
              'target_ticket_id': null,
              'progress': 40,
              'created_at': '2026-07-01T09:00:00.000',
              'updated_at': '2026-07-01T10:00:00.000',
            },
          ],
        });
        final repo = RpcGoalRepository(client);
        final goals = await repo.watchByWorkspace('ws-1').first;
        final g = goals.first;
        expect(g.id, 'g-1');
        expect(g.workspaceId, 'ws-1');
        expect(g.title, 'Ship v2');
        expect(g.level, OrgGoalLevel.company);
        expect(g.parentGoalId, isNull);
        expect(g.description, 'The mission');
        expect(g.status, OrgGoalStatus.active);
        expect(g.ownerAgentId, 'a-1');
        expect(g.teamId, isNull);
        expect(g.targetTicketId, isNull);
        expect(g.progress, 40);
        expect(g.createdAt, DateTime(2026, 7, 1, 9));
        expect(g.updatedAt, DateTime(2026, 7, 1, 10));
        final sub = host.lastSubscribe!;
        expect(sub.query, 'goals.watchForWorkspace');
        expect(sub.args['workspace_id'], 'ws-1');
      },
    );

    test('watchByWorkspace tolerates a non-ISO created_at (epoch)', () async {
      host.snapshotFor('goals.watchForWorkspace', {
        'goals': [
          {'id': 'g-1', 'workspace_id': 'ws-1', 'title': 'X', 'level': 'team'},
        ],
      });
      final repo = RpcGoalRepository(client);
      final g = (await repo.watchByWorkspace('ws-1').first).first;
      expect(g.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(g.level, OrgGoalLevel.team);
    });

    test('listByWorkspace returns the first snapshot', () async {
      host.snapshotFor('goals.watchForWorkspace', {
        'goals': [
          {'id': 'g-1', 'workspace_id': 'ws-1', 'title': 'A'},
          {'id': 'g-2', 'workspace_id': 'ws-1', 'title': 'B'},
        ],
      });
      final repo = RpcGoalRepository(client);
      final goals = await repo.listByWorkspace('ws-1');
      expect(goals.length, 2);
    });

    test('childrenOf filters by parent_goal_id', () async {
      host.snapshotFor('goals.watchForWorkspace', {
        'goals': [
          {
            'id': 'g-1',
            'workspace_id': 'ws-1',
            'title': 'parent',
            'parent_goal_id': null,
          },
          {
            'id': 'g-2',
            'workspace_id': 'ws-1',
            'title': 'child',
            'parent_goal_id': 'g-1',
          },
          {
            'id': 'g-3',
            'workspace_id': 'ws-1',
            'title': 'unrelated',
            'parent_goal_id': 'g-9',
          },
        ],
      });
      final repo = RpcGoalRepository(client);
      final children = await repo.childrenOf('ws-1', 'g-1');
      expect(children.length, 1);
      expect(children.first.id, 'g-2');
    });

    test('getById maps the goal and forwards the ids', () async {
      host.callResults['goals.get'] = {
        'goal': {
          'id': 'g-1',
          'workspace_id': 'ws-1',
          'title': 'Ship v2',
          'level': 'company',
        },
      };
      final repo = RpcGoalRepository(client);
      final g = await repo.getById('ws-1', 'g-1');
      expect(g, isNotNull);
      expect(g!.id, 'g-1');
      final call = host.lastCall('goals.get')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['goal_id'], 'g-1');
    });

    test('getById returns null when the key is absent', () async {
      host.callResults['goals.get'] = const {};
      final repo = RpcGoalRepository(client);
      expect(await repo.getById('ws-1', 'g-1'), isNull);
    });

    test('getById returns null on a notFound error', () async {
      host.callErrors['goals.get'] = (
        code: RpcErrorCodes.notFound,
        message: 'no such goal',
      );
      final repo = RpcGoalRepository(client);
      expect(await repo.getById('ws-1', 'g-1'), isNull);
    });

    test('getById rethrows a non-notFound error', () async {
      host.callErrors['goals.get'] = (
        code: RpcErrorCodes.unauthorized,
        message: 'no access',
      );
      final repo = RpcGoalRepository(client);
      expect(
        () => repo.getById('ws-1', 'g-1'),
        throwsA(isA<RemoteRpcException>()),
      );
    });
  });

  group('RpcGoalRepository writes throw', () {
    test('upsert throws UnsupportedError', () async {
      final repo = RpcGoalRepository(client);
      expect(() => repo.upsert(_goal('ws-1')), throwsUnsupportedError);
    });

    test('delete throws UnsupportedError', () async {
      final repo = RpcGoalRepository(client);
      expect(() => repo.delete('ws-1', 'g-1'), throwsUnsupportedError);
    });
  });

  group('RpcApprovalRepository reads', () {
    test('watchByWorkspace maps Approval wire maps', () async {
      host.snapshotFor('approvals.watchForWorkspace', {
        'approvals': [
          {
            'id': 'ap-1',
            'workspace_id': 'ws-1',
            'title': 'Merge PR',
            'description': 'ship it',
            'kind': 'merge',
            'status': 'pending',
            'requested_by_actor_type': 'agent',
            'requested_by_id': 'a-1',
            'linked_ticket_ids': ['t-1', 't-2'],
            'linked_entity_type': 'ticket',
            'linked_entity_id': 't-1',
            'decided_by_actor_type': null,
            'decided_by_id': null,
            'decision_reason': null,
            'created_at': '2026-07-01T09:00:00.000',
            'decided_at': null,
            'updated_at': '2026-07-01T10:00:00.000',
          },
        ],
      });
      final repo = RpcApprovalRepository(client);
      final approvals = await repo.watchByWorkspace('ws-1').first;
      final a = approvals.first;
      expect(a.id, 'ap-1');
      expect(a.workspaceId, 'ws-1');
      expect(a.title, 'Merge PR');
      expect(a.description, 'ship it');
      expect(a.kind, ApprovalKind.merge);
      expect(a.status, ApprovalStatus.pending);
      expect(a.requestedByActorType, 'agent');
      expect(a.requestedById, 'a-1');
      expect(a.linkedTicketIds, ['t-1', 't-2']);
      expect(a.linkedEntityType, 'ticket');
      expect(a.linkedEntityId, 't-1');
      expect(a.decidedByActorType, isNull);
      expect(a.decidedAt, isNull);
      expect(a.decisionReason, isNull);
      expect(a.createdAt, DateTime(2026, 7, 1, 9));
      expect(a.updatedAt, DateTime(2026, 7, 1, 10));
      final sub = host.lastSubscribe!;
      expect(sub.args['workspace_id'], 'ws-1');
    });

    test('watchByWorkspace maps a decided approval with decided_at', () async {
      host.snapshotFor('approvals.watchForWorkspace', {
        'approvals': [
          {
            'id': 'ap-1',
            'workspace_id': 'ws-1',
            'title': 'Merge',
            'kind': 'merge',
            'status': 'approved',
            'decided_by_actor_type': 'user',
            'decided_by_id': 'u-1',
            'decision_reason': 'looks good',
            'decided_at': '2026-07-01T11:00:00.000',
          },
        ],
      });
      final repo = RpcApprovalRepository(client);
      final a = (await repo.watchByWorkspace('ws-1').first).first;
      expect(a.status, ApprovalStatus.approved);
      expect(a.decidedByActorType, 'user');
      expect(a.decidedById, 'u-1');
      expect(a.decisionReason, 'looks good');
      expect(a.decidedAt, DateTime(2026, 7, 1, 11));
    });

    test('watchByStatus filters by the storage status key', () async {
      host.snapshotFor('approvals.watchForWorkspace', {
        'approvals': [
          {
            'id': 'ap-1',
            'workspace_id': 'ws-1',
            'title': 'A',
            'kind': 'merge',
            'status': 'pending',
          },
          {
            'id': 'ap-2',
            'workspace_id': 'ws-1',
            'title': 'B',
            'kind': 'merge',
            'status': 'revision_requested',
          },
        ],
      });
      final repo = RpcApprovalRepository(client);
      final filtered = await repo
          .watchByStatus('ws-1', 'revision_requested')
          .first;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'ap-2');
      expect(filtered.first.status, ApprovalStatus.revisionRequested);
    });

    test('getById maps the approval', () async {
      host.callResults['approvals.get'] = {
        'approval': {
          'id': 'ap-1',
          'workspace_id': 'ws-1',
          'title': 'Merge',
          'kind': 'merge',
          'status': 'pending',
        },
      };
      final repo = RpcApprovalRepository(client);
      final a = await repo.getById('ws-1', 'ap-1');
      expect(a, isNotNull);
      expect(a!.id, 'ap-1');
      final call = host.lastCall('approvals.get')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['approval_id'], 'ap-1');
    });

    test('getById returns null when the key is absent', () async {
      host.callResults['approvals.get'] = const {};
      final repo = RpcApprovalRepository(client);
      expect(await repo.getById('ws-1', 'ap-1'), isNull);
    });

    test('getById returns null on a notFound error', () async {
      host.callErrors['approvals.get'] = (
        code: RpcErrorCodes.notFound,
        message: 'no such approval',
      );
      final repo = RpcApprovalRepository(client);
      expect(await repo.getById('ws-1', 'ap-1'), isNull);
    });

    test('getById rethrows a non-notFound error', () async {
      host.callErrors['approvals.get'] = (
        code: RpcErrorCodes.conflict,
        message: 'conflict',
      );
      final repo = RpcApprovalRepository(client);
      expect(
        () => repo.getById('ws-1', 'ap-1'),
        throwsA(isA<RemoteRpcException>()),
      );
    });

    test('getComments maps the comment thread', () async {
      host.callResults['approvals.getComments'] = {
        'comments': [
          {
            'id': 'cm-1',
            'approval_id': 'ap-1',
            'workspace_id': 'ws-1',
            'author_type': 'user',
            'author_id': 'u-1',
            'body': 'lgtm',
            'created_at': '2026-07-01T09:00:00.000',
          },
        ],
      };
      final repo = RpcApprovalRepository(client);
      final comments = await repo.getComments('ws-1', 'ap-1');
      expect(comments.length, 1);
      expect(comments.first.id, 'cm-1');
      expect(comments.first.approvalId, 'ap-1');
      expect(comments.first.authorType, 'user');
      expect(comments.first.authorId, 'u-1');
      expect(comments.first.body, 'lgtm');
      final call = host.lastCall('approvals.getComments')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['approval_id'], 'ap-1');
    });

    test('watchComments emits a single snapshot via getComments', () async {
      host.callResults['approvals.getComments'] = {
        'comments': [
          {
            'id': 'cm-1',
            'approval_id': 'ap-1',
            'workspace_id': 'ws-1',
            'author_type': 'user',
            'author_id': 'u-1',
            'body': 'lgtm',
          },
        ],
      };
      final repo = RpcApprovalRepository(client);
      final comments = await repo.watchComments('ws-1', 'ap-1').first;
      expect(comments.length, 1);
      expect(comments.first.body, 'lgtm');
    });
  });

  group('RpcApprovalRepository writes throw', () {
    test('upsert throws UnsupportedError', () async {
      final repo = RpcApprovalRepository(client);
      expect(() => repo.upsert(_approval('ws-1')), throwsUnsupportedError);
    });

    test('delete throws UnsupportedError', () async {
      final repo = RpcApprovalRepository(client);
      expect(() => repo.delete('ws-1', 'ap-1'), throwsUnsupportedError);
    });

    test('addComment throws UnsupportedError', () async {
      final repo = RpcApprovalRepository(client);
      expect(() => repo.addComment(_comment('ws-1')), throwsUnsupportedError);
    });
  });

  group('RpcAgentPresenceReader', () {
    test('presenceForWorkspace maps the presence map', () async {
      host.callResults['agent_presence.forWorkspace'] = {
        'presence': {
          'a-1': {
            'availability': 'online',
            'workload': 'working',
            'running_count': 2,
            'queued_count': 1,
            'capacity': 3,
          },
          'a-2': {'availability': 'offline', 'workload': 'idle'},
        },
      };
      final reader = RpcAgentPresenceReader(client);
      final presence = await reader.presenceForWorkspace('ws-1');
      expect(presence.length, 2);
      final p1 = presence['a-1']!;
      expect(p1.availability, AgentAvailability.online);
      expect(p1.workload, Workload.working);
      expect(p1.runningCount, 2);
      expect(p1.queuedCount, 1);
      expect(p1.capacity, 3);
      // Missing counts default to 0 and an unknown availability → offline.
      final p2 = presence['a-2']!;
      expect(p2.availability, AgentAvailability.offline);
      expect(p2.workload, Workload.idle);
      expect(p2.runningCount, 0);
      expect(p2.capacity, 0);
      final call = host.lastCall('agent_presence.forWorkspace')!;
      expect(call.args['workspace_id'], 'ws-1');
    });

    test('presenceForWorkspace returns empty when the key is absent', () async {
      host.callResults['agent_presence.forWorkspace'] = const {};
      final reader = RpcAgentPresenceReader(client);
      expect(await reader.presenceForWorkspace('ws-1'), isEmpty);
    });
  });
}

OrgGoal _goal(String workspaceId) => OrgGoal(
  id: 'g-1',
  workspaceId: workspaceId,
  title: 'Ship v2',
  level: OrgGoalLevel.company,
  status: OrgGoalStatus.active,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Approval _approval(String workspaceId) => Approval(
  id: 'ap-1',
  workspaceId: workspaceId,
  title: 'Merge',
  kind: ApprovalKind.merge,
  status: ApprovalStatus.pending,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

ApprovalComment _comment(String workspaceId) => ApprovalComment(
  id: 'cm-1',
  approvalId: 'ap-1',
  workspaceId: workspaceId,
  authorType: 'user',
  body: 'lgtm',
  createdAt: DateTime(2026),
);

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

/// A scripted `repo/call` error (the reply is a JSON-RPC error envelope).
typedef _Err = ({int code, String message});

/// In-process host that scripts `repo/call` results + errors and `sub/subscribe`
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

  /// Scripted `repo/call` errors keyed by op name (a result takes precedence).
  final Map<String, _Err> callErrors = {};

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
        if (callResults.containsKey(op)) {
          _reply(id, {'op': op, 'data': callResults[op]});
        } else if (callErrors.containsKey(op)) {
          final err = callErrors[op]!;
          channel.send({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': err.code, 'message': err.message},
          });
        } else {
          _reply(id, {'op': op, 'data': const <String, dynamic>{}});
        }
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
