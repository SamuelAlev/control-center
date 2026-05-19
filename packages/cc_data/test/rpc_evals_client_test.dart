import 'package:cc_data/src/repositories/rpc_evals_client.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises the evals view classes' `fromWire` parsing.
void main() {
  group('EvalSuiteView.fromWire', () {
    test('parses a full payload', () {
      final s = EvalSuiteView.fromWire({
        'id': 's-1',
        'name': 'Core',
        'description': 'core suite',
        'defaultBatchSize': 10,
        'isStarter': true,
      });
      expect(s.id, 's-1');
      expect(s.name, 'Core');
      expect(s.defaultBatchSize, 10);
      expect(s.isStarter, isTrue);
    });

    test('tolerates missing fields', () {
      final s = EvalSuiteView.fromWire({});
      expect(s.id, '');
      expect(s.defaultBatchSize, 1);
      expect(s.isStarter, isFalse);
    });
  });

  group('EvalRunView.fromWire', () {
    test('parses a full payload', () {
      final r = EvalRunView.fromWire({
        'id': 'r-1',
        'suiteId': 's-1',
        'configHash': 'abc',
        'batchSize': 50,
        'passRate': 0.85,
        'status': 'done',
        'costCents': 100,
        'triggeredBy': 'ci',
        'createdAt': '2026-01-01T00:00:00.000',
        'scorecardJson': '{}',
      });
      expect(r.id, 'r-1');
      expect(r.suiteId, 's-1');
      expect(r.configHash, 'abc');
      expect(r.batchSize, 50);
      expect(r.passRate, 0.85);
      expect(r.status, 'done');
      expect(r.costCents, 100);
      expect(r.triggeredBy, 'ci');
      expect(r.scorecardJson, '{}');
    });

    test('tolerates missing fields', () {
      final r = EvalRunView.fromWire({});
      expect(r.id, '');
      expect(r.batchSize, 0);
      expect(r.passRate, 0);
      expect(r.status, 'queued');
      expect(r.triggeredBy, 'manual');
    });
  });

  group('ReliabilityView.fromWire', () {
    test('parses a full payload', () {
      final r = ReliabilityView.fromWire({
        'score': 0.92,
        'recommended': 'act_with_approval',
        'rationale': ['passed 10/10', 'no regressions'],
      });
      expect(r.score, 0.92);
      expect(r.recommended, 'act_with_approval');
      expect(r.rationale, ['passed 10/10', 'no regressions']);
    });

    test('tolerates missing fields', () {
      final r = ReliabilityView.fromWire({});
      expect(r.score, 0);
      expect(r.recommended, 'observe_only');
      expect(r.rationale, isEmpty);
    });
  });

  group('RpcEvalsClient', () {
    late _Host host;
    late RemoteRpcClient client;

    setUp(() {
      final (server, clientChannel) = InProcessRpcChannel.pair();
      host = _Host(server);
      client = RemoteRpcClient(clientChannel)..start();
    });

    tearDown(() async => client.close());

    test('watchSuites maps the suites snapshot', () async {
      host.snapshotFor('evals.watchSuites', {
        'suites': [
          {'id': 's-1', 'name': 'Core', 'isStarter': true},
        ],
      });
      final c = RpcEvalsClient(client);
      final suites = await c.watchSuites().first;
      expect(suites.first.id, 's-1');
      expect(suites.first.isStarter, isTrue);
    });

    test('watchRunsForSuite forwards the suite_id', () async {
      host.snapshotFor('evals.watchRunsForSuite', {
        'runs': [
          {'id': 'r-1', 'suiteId': 's-1', 'status': 'done'},
        ],
      });
      final c = RpcEvalsClient(client);
      final runs = await c.watchRunsForSuite('s-1').first;
      expect(runs.first.id, 'r-1');
      expect(host.lastSubscribe!.args['suite_id'], 's-1');
    });

    test('upsertSuite forwards the suite fields and returns the id', () async {
      host.callResults['evals.upsertSuite'] = {'id': 's-9'};
      final c = RpcEvalsClient(client);
      expect(
        await c.upsertSuite(
          id: 's-9',
          name: 'Core',
          description: 'desc',
          defaultBatchSize: 4,
        ),
        's-9',
      );
      final call = host.lastCall('evals.upsertSuite')!;
      expect(call.args['id'], 's-9');
      expect(call.args['name'], 'Core');
      expect(call.args['description'], 'desc');
      expect(call.args['default_batch_size'], 4);
    });

    test('upsertSuite returns empty string when id absent', () async {
      final c = RpcEvalsClient(client);
      expect(await c.upsertSuite(name: 'X'), '');
    });

    test('deleteSuite forwards the suite_id', () async {
      final c = RpcEvalsClient(client);
      await c.deleteSuite('s-1');
      expect(host.lastCall('evals.deleteSuite')!.args['suite_id'], 's-1');
    });

    test(
      'runSuite forwards suite_id + optional fields and returns scorecard',
      () async {
        host.callResults['evals.runSuite'] = {
          'scorecard': {'passRate': 0.9},
        };
        final c = RpcEvalsClient(client);
        final card = await c.runSuite('s-1', batchSize: 5, configHash: 'abc');
        expect(card['passRate'], 0.9);
        final call = host.lastCall('evals.runSuite')!;
        expect(call.args['suite_id'], 's-1');
        expect(call.args['batch_size'], 5);
        expect(call.args['config_hash'], 'abc');
      },
    );

    test('runSuite returns empty map when scorecard absent', () async {
      final c = RpcEvalsClient(client);
      expect(await c.runSuite('s-1'), isEmpty);
    });

    test('blessGolden forwards the fields and returns the id', () async {
      host.callResults['evals.blessGolden'] = {'id': 'g-1'};
      final c = RpcEvalsClient(client);
      expect(
        await c.blessGolden(agentId: 'a-1', recordingId: 'r-1', name: 'n'),
        'g-1',
      );
      final call = host.lastCall('evals.blessGolden')!;
      expect(call.args['agent_id'], 'a-1');
      expect(call.args['recording_id'], 'r-1');
      expect(call.args['mode'], 'deterministic');
      expect(call.args['name'], 'n');
    });

    test('reliability forwards agent_id and maps the result', () async {
      host.callResults['evals.reliability'] = {
        'reliability': {'score': 0.5, 'recommended': 'act_with_approval'},
      };
      final c = RpcEvalsClient(client);
      final r = await c.reliability('a-1');
      expect(r.score, 0.5);
      expect(r.recommended, 'act_with_approval');
      expect(host.lastCall('evals.reliability')!.args['agent_id'], 'a-1');
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

class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];
  final Map<String, Map<String, dynamic>> callResults = {};
  final Map<String, Map<String, dynamic>> snapshots = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );
  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

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
        _reply(id, {
          'op': op,
          'data': callResults[op] ?? const <String, dynamic>{},
        });
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
