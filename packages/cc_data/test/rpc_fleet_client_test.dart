import 'package:cc_data/src/repositories/rpc_fleet_client.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises the fleet view classes' `fromWire` parsing — the wire-shape
/// decoders that turn `fleet.watch*` snapshots into typed views.
void main() {
  group('FleetWorkerView.fromWire', () {
    test('parses a full payload', () {
      final w = FleetWorkerView.fromWire({
        'id': 'w-1',
        'name': 'node-1',
        'status': 'online',
        'capabilityKeys': ['git', 'docker'],
        'caps': {'os': 'linux', 'cores': 8},
        'lastHeartbeatAt': '2026-01-01T00:00:00.000',
        'lastError': 'oops',
      });
      expect(w.id, 'w-1');
      expect(w.name, 'node-1');
      expect(w.status, WorkerStatus.online);
      expect(w.capabilityKeys, ['git', 'docker']);
      expect(w.platform, 'linux');
      expect(w.cores, 8);
      expect(w.lastHeartbeatAt, isNotNull);
      expect(w.lastError, 'oops');
    });

    test('tolerates missing fields with defaults', () {
      final w = FleetWorkerView.fromWire({});
      expect(w.id, '');
      expect(w.status, WorkerStatus.offline);
      expect(w.platform, 'unknown');
      expect(w.cores, 0);
      expect(w.capabilityKeys, isEmpty);
      expect(w.lastError, isNull);
    });

    test('an unknown wire status degrades to offline, never crashes', () {
      // Parsed at the wire boundary now (it used to travel as a raw string
      // that every UI switched over with a `_ =>` fallthrough), so a status a
      // newer server introduces reads as offline rather than as a mystery
      // badge.
      final w = FleetWorkerView.fromWire({'status': 'quantum-superposition'});
      expect(w.status, WorkerStatus.offline);
    });
  });

  group('FleetJobView.fromWire', () {
    test('parses a full payload', () {
      final j = FleetJobView.fromWire({
        'id': 'j-1',
        'kind': 'agentRun',
        'status': 'running',
        'requiredCaps': ['git'],
        'workerId': 'w-1',
        'pinnedWorkerId': 'w-2',
        'priority': 5,
        'attempts': 2,
        'maxAttempts': 3,
        'costCents': 42,
        'error': 'retry',
        'createdAt': '2026-01-01T00:00:00.000',
      });
      expect(j.id, 'j-1');
      expect(j.kind, 'agentRun');
      expect(j.status, 'running');
      expect(j.requiredCaps, ['git']);
      expect(j.workerId, 'w-1');
      expect(j.pinnedWorkerId, 'w-2');
      expect(j.priority, 5);
      expect(j.attempts, 2);
      expect(j.maxAttempts, 3);
      expect(j.costCents, 42);
    });

    test('tolerates missing fields with defaults', () {
      final j = FleetJobView.fromWire({});
      expect(j.id, '');
      expect(j.kind, '');
      expect(j.status, 'queued');
      expect(j.priority, 0);
      expect(j.maxAttempts, 1);
      expect(j.costCents, 0);
    });
  });

  group('FleetPlacementView.fromWire', () {
    test('parses a full payload', () {
      final p = FleetPlacementView.fromWire({
        'decision': 'leased',
        'reason': 'matched caps',
        'workerId': 'w-1',
        'createdAt': '2026-01-01T00:00:00.000',
      });
      expect(p.decision, 'leased');
      expect(p.reason, 'matched caps');
      expect(p.workerId, 'w-1');
      expect(p.createdAt, isNotNull);
    });

    test('tolerates missing fields with defaults', () {
      final p = FleetPlacementView.fromWire({});
      expect(p.decision, 'queued');
      expect(p.reason, '');
      expect(p.workerId, isNull);
    });
  });

  group('RpcFleetClient', () {
    late _Host host;
    late RemoteRpcClient client;

    setUp(() {
      final (server, clientChannel) = InProcessRpcChannel.pair();
      host = _Host(server);
      client = RemoteRpcClient(clientChannel)..start();
    });

    tearDown(() async => client.close());

    test('watchWorkers maps the workers snapshot', () async {
      host.snapshotFor('fleet.watchWorkers', {
        'workers': [
          {'id': 'w-1', 'name': 'node-1', 'status': 'online'},
        ],
      });
      final c = RpcFleetClient(client);
      final workers = await c.watchWorkers().first;
      expect(workers.first.id, 'w-1');
    });

    test('watchJobs maps the jobs snapshot', () async {
      host.snapshotFor('fleet.watchJobs', {
        'jobs': [
          {'id': 'j-1', 'kind': 'agentRun', 'status': 'running'},
        ],
      });
      final c = RpcFleetClient(client);
      final jobs = await c.watchJobs().first;
      expect(jobs.first.id, 'j-1');
    });

    test('watchPlacements forwards job_id', () async {
      host.snapshotFor('fleet.watchPlacements', {
        'placements': [
          {'decision': 'leased', 'workerId': 'w-1'},
        ],
      });
      final c = RpcFleetClient(client);
      final placements = await c.watchPlacements('j-1').first;
      expect(placements.first.workerId, 'w-1');
      expect(host.lastSubscribe!.args['job_id'], 'j-1');
    });

    test('submitJob forwards all fields and returns the jobId', () async {
      host.callResults['fleet.submitJob'] = {'jobId': 'j-9'};
      final c = RpcFleetClient(client);
      expect(
        await c.submitJob(
          kind: 'agentRun',
          spec: {'a': 1},
          priority: 3,
          pinnedWorkerId: 'w-2',
          requiredCaps: ['git'],
          preferredCaps: ['docker'],
          maxAttempts: 2,
        ),
        'j-9',
      );
      final call = host.lastCall('fleet.submitJob')!;
      expect(call.args['kind'], 'agentRun');
      expect(call.args['spec'], {'a': 1});
      expect(call.args['priority'], 3);
      expect(call.args['pinned_worker_id'], 'w-2');
      expect(call.args['required_caps'], ['git']);
      expect(call.args['preferred_caps'], ['docker']);
      expect(call.args['max_attempts'], 2);
    });

    test('submitJob returns empty string when jobId absent', () async {
      final c = RpcFleetClient(client);
      expect(await c.submitJob(kind: 'agentRun'), '');
    });

    test('cancelJob forwards the job_id', () async {
      final c = RpcFleetClient(client);
      await c.cancelJob('j-1');
      expect(host.lastCall('fleet.cancelJob')!.args['job_id'], 'j-1');
    });

    test('drainWorker forwards the worker_id', () async {
      final c = RpcFleetClient(client);
      await c.drainWorker('w-1');
      expect(host.lastCall('fleet.drainWorker')!.args['worker_id'], 'w-1');
    });

    test('resumeWorker forwards the worker_id', () async {
      final c = RpcFleetClient(client);
      await c.resumeWorker('w-1');
      expect(host.lastCall('fleet.resumeWorker')!.args['worker_id'], 'w-1');
    });

    test('revokeWorker forwards the worker_id', () async {
      final c = RpcFleetClient(client);
      await c.revokeWorker('w-1');
      expect(host.lastCall('fleet.revokeWorker')!.args['worker_id'], 'w-1');
    });

    test('removeWorker forwards the worker_id', () async {
      final c = RpcFleetClient(client);
      await c.removeWorker('w-1');
      expect(host.lastCall('fleet.removeWorker')!.args['worker_id'], 'w-1');
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
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
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
        _reply(id, {
          'op': op,
          'data': callResults[op] ?? const <String, dynamic>{},
        });
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
