import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_evaluation_summary.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// [RpcImprovementInboxRepository] over an in-process JSON-RPC host: the
/// `improvements.*` op names and args, the decoding (a row the client cannot
/// read is dropped) and the server's `needs_admin`.
void main() {
  late _Host host;
  late RemoteRpcClient client;
  late RpcImprovementInboxRepository repo;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
    repo = RpcImprovementInboxRepository(client);
  });

  tearDown(() async => client.close());

  Map<String, dynamic> wire({
    String id = 'p-1',
    String kind = 'skill_edit',
    bool? needsAdmin,
    Map<String, dynamic>? evaluation,
  }) => {
    'id': id,
    'workspace_id': 'ws-1',
    'agent_id': 'agent-1',
    'kind': kind,
    'scope': 'workspace',
    'operation': 'replace',
    'target_ref': 'release-notes',
    'change': 'Say what changed first.',
    'evidence': {
      'runIds': ['run-1'],
      'messageIds': <String>[],
      'checkResults': <Object>[],
    },
    'expected': 'Shorter release notes.',
    'status': 'proposed',
    'before_text': 'old',
    'after_text': 'new',
    'campaign_state': 'passed',
    'created_at': '2026-11-19T12:00:00.000Z',
    'expires_at': '2026-12-19T12:00:00.000Z',
    'needs_admin': ?needsAdmin,
    'evaluation': ?evaluation,
  };

  test('watchForWorkspace decodes needs_admin and drops a bad row', () async {
    host.snapshotFor('improvements.watchForWorkspace', {
      'proposals': [
        wire(needsAdmin: true),
        wire(id: 'p-2', kind: 'memory_fact'),
        wire(id: 'p-bad', kind: 'not_a_kind'),
      ],
    });
    final views = await repo
        .watchForWorkspace('ws-1', status: ImprovementStatus.proposed)
        .first;
    expect(views.map((v) => v.proposal.id), ['p-1', 'p-2']);
    expect(views.first.needsAdmin, isTrue);
    expect(views.first.proposal.campaignState, ImprovementCampaignState.passed);
    expect(views.last.needsAdmin, isFalse);
    expect(host.lastSubscribe!.args, {
      'workspace_id': 'ws-1',
      'status': 'proposed',
    });
  });

  test('evaluation decodes as a typed value, absent when not sent', () async {
    host.snapshotFor('improvements.watchForWorkspace', {
      'proposals': [
        wire(
          evaluation: {
            'paired_runs': 12,
            'candidate_solved': 9,
            'baseline_solved': 8,
            'verdict': 'non_inferior',
            'regressions': {
              'quality_loss': 2,
              'cost_regression': 1,
              'harness_error': 0,
            },
            'coverage_complete': true,
            'plan_violations': 0,
          },
        ),
        wire(
          id: 'p-2',
          evaluation: {
            'paired_runs': 3,
            'candidate_solved': 1,
            'baseline_solved': 2,
            'regressions': {
              'quality_loss': 0,
              'cost_regression': 0,
              'harness_error': 1,
            },
            'coverage_complete': false,
          },
        ),
        wire(id: 'p-3'),
      ],
    });
    final views = await repo
        .watchForWorkspace('ws-1', status: ImprovementStatus.proposed)
        .first;
    expect(
      views[0].evaluation,
      ImprovementEvaluationSummary(
        pairedRuns: 12,
        candidateSolved: 9,
        baselineSolved: 8,
        verdict: ImprovementVerdict.nonInferior,
        qualityLosses: 2,
        costRegressions: 1,
        harnessErrors: 0,
        coverageComplete: true,
        planViolations: 0,
      ),
    );
    // No verdict and no plan_violations read as null, not as a guess.
    final partial = views[1].evaluation!;
    expect(partial.verdict, isNull);
    expect(partial.planViolations, isNull);
    expect(partial.harnessErrors, 1);
    expect(partial.coverageComplete, isFalse);
    expect(views[2].evaluation, isNull);
  });

  test('the decisions and the campaign call their ops', () async {
    for (final op in [
      'improvements.accept',
      'improvements.reject',
      'improvements.rollback',
      'improvements.startCampaign',
    ]) {
      host.callResults[op] = {'proposal': wire(needsAdmin: true)};
    }
    expect((await repo.accept('ws-1', 'p-1')).needsAdmin, isTrue);
    await repo.reject('ws-1', 'p-1');
    await repo.rollback('ws-1', 'p-1');
    await repo.startCampaign(
      'ws-1',
      'p-1',
      corpusId: 'c-1',
      providerId: 'anthropic',
      modelId: 'm-1',
      repetitions: 3,
      budgetMicros: 2000000,
    );
    expect(host.calls.map((c) => c.op), [
      'improvements.accept',
      'improvements.reject',
      'improvements.rollback',
      'improvements.startCampaign',
    ]);
    expect(host.lastCall('improvements.startCampaign')!.args, {
      'workspace_id': 'ws-1',
      'proposal_id': 'p-1',
      'corpus_id': 'c-1',
      'provider_id': 'anthropic',
      'model_id': 'm-1',
      'repetitions': 3,
      'budget_micros': 2000000,
    });
  });
}

class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
  final Map<String, dynamic> args;
}

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
