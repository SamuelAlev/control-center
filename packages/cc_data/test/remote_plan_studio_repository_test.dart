import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemotePlanStudioRepository] — the Plan Studio surface (PRD 17) —
/// over an in-process JSON-RPC host. Each method is a thin `_client.call(...)`
/// or `_client.subscribe(...)` delegate that parses the wire maps (the
/// `orchestration.*` / `plan.*` / `playbook.*` ops + their watch queries)
/// straight into the shipped domain entities. These tests pin the op name, the
/// args shape and the return-value mapping.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemotePlanStudioRepository revisions', () {
    test(
      'revisions maps the revision history + forwards orchestration_id',
      () async {
        host.callResults['orchestration.revisions'] = {
          'revisions': [
            {
              'id': 'r-1',
              'workspace_id': 'ws-1',
              'orchestration_id': 'o-1',
              'revision': 2,
              'proposal_json': '{"goal":"ship it"}',
              'authored_by': 'u-1',
              'author_kind': 'user',
              'created_at': '2026-07-01T09:00:00.000',
            },
          ],
        };
        final repo = RemotePlanStudioRepository(client);
        final revisions = await repo.revisions('o-1');
        expect(revisions.length, 1);
        final r = revisions.first;
        expect(r.id, 'r-1');
        expect(r.workspaceId, 'ws-1');
        expect(r.orchestrationId, 'o-1');
        expect(r.revision, 2);
        expect(r.proposal.goal, 'ship it');
        expect(r.authoredBy, 'u-1');
        expect(r.authorKind, 'user');
        expect(r.createdAt, DateTime(2026, 7, 1, 9));
        final call = host.lastCall('orchestration.revisions')!;
        expect(call.args['orchestration_id'], 'o-1');
      },
    );

    test('revisions tolerates a non-ISO created_at (epoch)', () async {
      host.callResults['orchestration.revisions'] = {
        'revisions': [
          {
            'id': 'r-1',
            'workspace_id': 'ws-1',
            'orchestration_id': 'o-1',
            'revision': 1,
            'proposal_json': '{}',
          },
        ],
      };
      final repo = RemotePlanStudioRepository(client);
      final r = (await repo.revisions('o-1')).first;
      expect(r.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(r.authorKind, 'user');
      expect(r.authoredBy, 'unknown');
    });

    test('watchRevisions streams the live history', () async {
      host.snapshotFor('orchestration.watchRevisions', {
        'revisions': [
          {
            'id': 'r-1',
            'workspace_id': 'ws-1',
            'orchestration_id': 'o-1',
            'revision': 1,
            'proposal_json': '{}',
          },
        ],
      });
      final repo = RemotePlanStudioRepository(client);
      final revisions = await repo.watchRevisions('o-1').first;
      expect(revisions.length, 1);
      final sub = host.lastSubscribe!;
      expect(sub.query, 'orchestration.watchRevisions');
      expect(sub.args['orchestration_id'], 'o-1');
    });

    test('saveRevision forwards the proposal_json + base_revision', () async {
      final repo = RemotePlanStudioRepository(client);
      await repo.saveRevision(
        orchestrationId: 'o-1',
        proposal: const OrchestrationProposal(
          goal: 'ship',
          roles: [],
          subTickets: [],
          synthesis: SynthesisSpec(
            roleKey: 'lead',
            prompt: 'synthesize',
            outputSchema: {'type': 'object'},
          ),
        ),
        baseRevision: 3,
      );
      final call = host.lastCall('orchestration.saveRevision')!;
      expect(call.args['orchestration_id'], 'o-1');
      expect(call.args['proposal_json'], isA<String>());
      expect(
        (call.args['proposal_json'] as String).contains('"goal":"ship"'),
        isTrue,
      );
      expect(call.args['base_revision'], 3);
    });
  });

  group('RemotePlanStudioRepository approval', () {
    test(
      'approve forwards the orchestration_id only when no nodes given',
      () async {
        final repo = RemotePlanStudioRepository(client);
        await repo.approve('o-1');
        final call = host.lastCall('orchestration.approve')!;
        expect(call.args['orchestration_id'], 'o-1');
        expect(call.args.containsKey('approved_node_keys'), isFalse);
      },
    );

    test('approve forwards the approved_node_keys when given', () async {
      final repo = RemotePlanStudioRepository(client);
      await repo.approve('o-1', approvedNodeKeys: {'n-1', 'n-2'});
      final call = host.lastCall('orchestration.approve')!;
      expect(call.args['approved_node_keys'], isA<List>());
      expect((call.args['approved_node_keys'] as List).toSet(), {'n-1', 'n-2'});
    });

    test('approveNodes forwards the node_keys as a list', () async {
      final repo = RemotePlanStudioRepository(client);
      await repo.approveNodes('o-1', {'n-1', 'n-2'});
      final call = host.lastCall('orchestration.approveNodes')!;
      expect(call.args['orchestration_id'], 'o-1');
      expect((call.args['node_keys'] as List).toSet(), {'n-1', 'n-2'});
    });

    test('cancel forwards the orchestration_id', () async {
      final repo = RemotePlanStudioRepository(client);
      await repo.cancel('o-1');
      final call = host.lastCall('orchestration.cancel')!;
      expect(call.args['orchestration_id'], 'o-1');
    });
  });

  group('RemotePlanStudioRepository estimate + drift', () {
    test('estimateOrchestration returns the estimate payload', () async {
      host.callResults['plan.estimate'] = {
        'estimate': {'nodes': [], 'total_cents': 100},
      };
      final repo = RemotePlanStudioRepository(client);
      final estimate = await repo.estimateOrchestration('o-1');
      expect(estimate['total_cents'], 100);
      final call = host.lastCall('plan.estimate')!;
      expect(call.args['orchestration_id'], 'o-1');
    });

    test('estimateOrchestration returns empty when no estimate key', () async {
      host.callResults['plan.estimate'] = const {};
      final repo = RemotePlanStudioRepository(client);
      expect(await repo.estimateOrchestration('o-1'), isEmpty);
    });

    test('estimatePlan forwards the plan_id + returns estimate', () async {
      host.callResults['plan.estimate'] = {
        'estimate': {'total_cents': 50},
      };
      final repo = RemotePlanStudioRepository(client);
      final estimate = await repo.estimatePlan('p-1');
      expect(estimate['total_cents'], 50);
      final call = host.lastCall('plan.estimate')!;
      expect(call.args['plan_id'], 'p-1');
    });

    test('estimatePlan returns empty when no estimate key', () async {
      host.callResults['plan.estimate'] = const {};
      final repo = RemotePlanStudioRepository(client);
      expect(await repo.estimatePlan('p-1'), isEmpty);
    });

    test('divergence returns the markers payload', () async {
      host.callResults['orchestration.divergence'] = {
        'markers': {
          'n-1': {
            'reasons': ['blocked'],
          },
        },
      };
      final repo = RemotePlanStudioRepository(client);
      final markers = await repo.divergence('o-1');
      expect(markers['n-1'], isA<Map>());
      final call = host.lastCall('orchestration.divergence')!;
      expect(call.args['orchestration_id'], 'o-1');
    });

    test('divergence returns empty when no markers key', () async {
      host.callResults['orchestration.divergence'] = const {};
      final repo = RemotePlanStudioRepository(client);
      expect(await repo.divergence('o-1'), isEmpty);
    });

    test('continueNode forwards the orchestration_id + node_key', () async {
      final repo = RemotePlanStudioRepository(client);
      await repo.continueNode('o-1', 'n-1');
      final call = host.lastCall('orchestration.continueNode')!;
      expect(call.args['orchestration_id'], 'o-1');
      expect(call.args['node_key'], 'n-1');
    });
  });

  group('RemotePlanStudioRepository plan documents', () {
    test('watchPlanDocuments streams the live list', () async {
      host.snapshotFor('plan.watchForWorkspace', {
        'plans': [
          {
            'id': 'p-1',
            'workspace_id': 'ws-1',
            'conversation_id': 'c-1',
            'agent_id': 'a-1',
            'plan_json': '{"goal":"x","graph":{"nodes":[]}}',
            'status': 'proposed',
            'revision': 1,
            'created_at': '2026-07-01T09:00:00.000',
            'updated_at': '2026-07-01T10:00:00.000',
          },
        ],
      });
      final repo = RemotePlanStudioRepository(client);
      final plans = await repo.watchPlanDocuments().first;
      expect(plans.length, 1);
      final p = plans.first;
      expect(p.id, 'p-1');
      expect(p.workspaceId, 'ws-1');
      expect(p.conversationId, 'c-1');
      expect(p.agentId, 'a-1');
      expect(p.goal, 'x');
      expect(p.status, PlanDocumentStatus.proposed);
      expect(p.revision, 1);
      expect(p.createdAt, DateTime(2026, 7, 1, 9));
      final sub = host.lastSubscribe!;
      expect(sub.query, 'plan.watchForWorkspace');
      expect(sub.args, isEmpty);
    });

    test('watchPlanById streams a single plan and nulls when absent', () async {
      host.snapshotFor('plan.watchById', {
        'plan': {
          'id': 'p-1',
          'workspace_id': 'ws-1',
          'conversation_id': 'c-1',
          'agent_id': 'a-1',
          'plan_json': '{}',
          'status': 'approved',
          'revision': 2,
        },
      });
      final repo = RemotePlanStudioRepository(client);
      final p = await repo.watchPlanById('p-1').first;
      expect(p, isNotNull);
      expect(p!.status, PlanDocumentStatus.approved);
      expect(p.revision, 2);
      final sub = host.lastSubscribe!;
      expect(sub.args['plan_id'], 'p-1');
    });

    test('watchPlanById emits null when the plan key is absent', () async {
      host.snapshotFor('plan.watchById', const {});
      final repo = RemotePlanStudioRepository(client);
      expect(await repo.watchPlanById('p-1').first, isNull);
    });

    test('getPlan maps a plan document', () async {
      host.callResults['plan.getById'] = {
        'plan': {
          'id': 'p-1',
          'workspace_id': 'ws-1',
          'conversation_id': 'c-1',
          'agent_id': 'a-1',
          'plan_json': '{}',
          'status': 'rejected',
          'revision': 1,
        },
      };
      final repo = RemotePlanStudioRepository(client);
      final p = await repo.getPlan('p-1');
      expect(p, isNotNull);
      expect(p!.status, PlanDocumentStatus.rejected);
      final call = host.lastCall('plan.getById')!;
      expect(call.args['plan_id'], 'p-1');
    });

    test('getPlan returns null when the plan key is absent', () async {
      host.callResults['plan.getById'] = const {};
      final repo = RemotePlanStudioRepository(client);
      expect(await repo.getPlan('p-1'), isNull);
    });

    test('approvePlan returns the orchestration_id + forwards args', () async {
      host.callResults['plan.approve'] = {'orchestration_id': 'o-9'};
      final repo = RemotePlanStudioRepository(client);
      final id = await repo.approvePlan('p-1');
      expect(id, 'o-9');
      final call = host.lastCall('plan.approve')!;
      expect(call.args['plan_id'], 'p-1');
      expect(call.args.containsKey('approved_node_keys'), isFalse);
      expect(call.args.containsKey('max_cost_cents'), isFalse);
    });

    test('approvePlan forwards approved_node_keys + max_cost_cents', () async {
      host.callResults['plan.approve'] = {'orchestration_id': 'o-9'};
      final repo = RemotePlanStudioRepository(client);
      await repo.approvePlan(
        'p-1',
        approvedNodeKeys: {'n-1'},
        maxCostCents: 500,
      );
      final call = host.lastCall('plan.approve')!;
      expect(call.args['approved_node_keys'], ['n-1']);
      expect(call.args['max_cost_cents'], 500);
    });

    test('approvePlan returns empty when no orchestration_id', () async {
      host.callResults['plan.approve'] = const {};
      final repo = RemotePlanStudioRepository(client);
      expect(await repo.approvePlan('p-1'), '');
    });

    test('updatePlanStatus forwards the status name', () async {
      final repo = RemotePlanStudioRepository(client);
      await repo.updatePlanStatus('p-1', PlanDocumentStatus.rejected);
      final call = host.lastCall('plan.updateStatus')!;
      expect(call.args['plan_id'], 'p-1');
      expect(call.args['status'], 'rejected');
    });

    test('deletePlan forwards the plan_id', () async {
      final repo = RemotePlanStudioRepository(client);
      await repo.deletePlan('p-1');
      final call = host.lastCall('plan.delete')!;
      expect(call.args['plan_id'], 'p-1');
    });
  });

  group('RemotePlanStudioRepository playbooks', () {
    test('watchPlaybooks streams the live list', () async {
      host.snapshotFor('playbook.watchForWorkspace', {
        'playbooks': [
          {
            'id': 'pb-1',
            'workspace_id': 'ws-1',
            'name': 'Daily Standup',
            'description': 'Runs a standup',
            'params_json': '[{"name":"team"}]',
            'source_proposal_json': '{}',
            'version': 1,
            'created_at': '2026-07-01T09:00:00.000',
            'updated_at': '2026-07-01T10:00:00.000',
          },
        ],
      });
      final repo = RemotePlanStudioRepository(client);
      final playbooks = await repo.watchPlaybooks().first;
      expect(playbooks.length, 1);
      final pb = playbooks.first;
      expect(pb.id, 'pb-1');
      expect(pb.workspaceId, 'ws-1');
      expect(pb.name, 'Daily Standup');
      expect(pb.description, 'Runs a standup');
      expect(pb.params.first.name, 'team');
      expect(pb.version, 1);
      expect(pb.createdAt, DateTime(2026, 7, 1, 9));
      final sub = host.lastSubscribe!;
      expect(sub.query, 'playbook.watchForWorkspace');
      expect(sub.args, isEmpty);
    });

    test('getPlaybook maps a playbook', () async {
      host.callResults['playbook.getById'] = {
        'playbook': {
          'id': 'pb-1',
          'workspace_id': 'ws-1',
          'name': 'Daily Standup',
          'params_json': '[]',
          'source_proposal_json': '{}',
        },
      };
      final repo = RemotePlanStudioRepository(client);
      final pb = await repo.getPlaybook('pb-1');
      expect(pb, isNotNull);
      expect(pb!.name, 'Daily Standup');
      final call = host.lastCall('playbook.getById')!;
      expect(call.args['playbook_id'], 'pb-1');
    });

    test('getPlaybook returns null when the playbook key is absent', () async {
      host.callResults['playbook.getById'] = const {};
      final repo = RemotePlanStudioRepository(client);
      expect(await repo.getPlaybook('pb-1'), isNull);
    });

    test('savePlaybook serializes + returns the saved playbook', () async {
      host.callResults['playbook.save'] = {
        'playbook': {
          'id': 'pb-1',
          'workspace_id': 'ws-1',
          'name': 'Saved',
          'params_json': '[]',
          'source_proposal_json': '{}',
          'version': 2,
        },
      };
      final repo = RemotePlanStudioRepository(client);
      final saved = await repo.savePlaybook(_playbook());
      expect(saved, isNotNull);
      expect(saved!.version, 2);
      final call = host.lastCall('playbook.save')!;
      final sent = (call.args['playbook'] as Map).cast<String, dynamic>();
      expect(sent['id'], 'pb-1');
      expect(sent['name'], 'Daily Standup');
      expect(sent['params_json'], isA<String>());
      expect(sent['source_proposal_json'], isA<String>());
    });

    test('savePlaybook returns null when no playbook returned', () async {
      host.callResults['playbook.save'] = const {};
      final repo = RemotePlanStudioRepository(client);
      expect(await repo.savePlaybook(_playbook()), isNull);
    });

    test('deletePlaybook forwards the playbook_id', () async {
      final repo = RemotePlanStudioRepository(client);
      await repo.deletePlaybook('pb-1');
      final call = host.lastCall('playbook.delete')!;
      expect(call.args['playbook_id'], 'pb-1');
    });

    test(
      'runPlaybook forwards the ids + args and returns the result',
      () async {
        host.callResults['playbook.run'] = {
          'orchestration_id': 'o-9',
          'revision': 1,
          'status': 'proposed',
          'message': 'ok',
        };
        final repo = RemotePlanStudioRepository(client);
        final result = await repo.runPlaybook(
          playbookId: 'pb-1',
          ticketId: 't-1',
          args: {'team': 'platform'},
        );
        expect(result['orchestration_id'], 'o-9');
        expect(result['status'], 'proposed');
        final call = host.lastCall('playbook.run')!;
        expect(call.args['playbook_id'], 'pb-1');
        expect(call.args['ticket_id'], 't-1');
        expect(call.args['args'], {'team': 'platform'});
      },
    );
  });
}

Playbook _playbook() => Playbook(
  id: 'pb-1',
  workspaceId: 'ws-1',
  name: 'Daily Standup',
  description: 'Runs a standup',
  params: [PlaybookParam(name: 'team')],
  sourceProposal: const OrchestrationProposal(
    goal: 'standup',
    roles: [],
    subTickets: [],
    synthesis: SynthesisSpec(
      roleKey: 'lead',
      prompt: 'synthesize',
      outputSchema: {'type': 'object'},
    ),
  ),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
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
        final data = callResults[op] ?? const <String, dynamic>{};
        _reply(id, {'op': op, 'data': data});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
