import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Edge-case coverage for [RemoteAgentRunLogRepository] and
/// [RpcAgentRunLogRepository]: the branches the broad
/// `remote_repositories_test.dart` host stub doesn't drive — non-Map log -> null,
/// empty/missing logs list, `getById` notFound -> null / rethrow, the
/// `watchByConversation` subscription and the `_toDto` round-trip.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  const logWire = {
    'id': 'rl1',
    'agent_id': 'a1',
    'workspace_id': 'ws1',
    'started_at': '2026-01-01T00:00:00.000',
    'status': 'running',
    'input_tokens': 10,
    'output_tokens': 20,
  };

  group('RemoteAgentRunLogRepository', () {
    test('get returns null when log is not a Map', () async {
      host.callResults['agent_run_log.get'] = {'log': 'nope'};
      expect(
        await RemoteAgentRunLogRepository(client).get('ws1', 'rl1'),
        isNull,
      );
    });

    test('get returns null when log is absent', () async {
      expect(
        await RemoteAgentRunLogRepository(client).get('ws1', 'rl1'),
        isNull,
      );
    });

    test('get names the workspace that owns the run id', () async {
      host.callResults['agent_run_log.get'] = {'log': logWire};
      final dto = await RemoteAgentRunLogRepository(client).get('ws1', 'rl1');
      expect(dto, isNotNull);
      expect(dto!.id, 'rl1');
      expect(dto.workspaceId, 'ws1');
      final args = host.lastCall('agent_run_log.get')!.args;
      expect(args['workspace_id'], 'ws1');
      expect(args['id'], 'rl1');
    });

    test('activeRunForAgent returns null when log is not a Map', () async {
      host.callResults['agent_run_log.activeRunForAgent'] = {'log': 5};
      expect(
        await RemoteAgentRunLogRepository(
          client,
        ).activeRunForAgent('ws1', 'a1'),
        isNull,
      );
    });

    test('forPipelineRun maps the logs list + skips non-Map rows', () async {
      host.callResults['agent_run_log.forPipelineRun'] = {
        'logs': [logWire, 'junk'],
      };
      final list = await RemoteAgentRunLogRepository(
        client,
      ).forPipelineRun('ws1', 'pr-1');
      expect(list.length, 1);
      expect(list.first.id, 'rl1');
      final args = host.lastCall('agent_run_log.forPipelineRun')!.args;
      expect(args['workspace_id'], 'ws1');
      expect(args['pipeline_run_id'], 'pr-1');
    });

    test('forPipelineRun tolerates a missing logs key', () async {
      expect(
        await RemoteAgentRunLogRepository(client).forPipelineRun('ws1', 'pr-1'),
        isEmpty,
      );
    });

    test('forPipelineStep forwards the workspace and both ids', () async {
      host.callResults['agent_run_log.forPipelineStep'] = {
        'logs': [logWire],
      };
      final list = await RemoteAgentRunLogRepository(
        client,
      ).forPipelineStep('ws1', 'pr-1', 'step-1');
      expect(list.single.id, 'rl1');
      final args = host.lastCall('agent_run_log.forPipelineStep')!.args;
      expect(args['workspace_id'], 'ws1');
      expect(args['pipeline_run_id'], 'pr-1');
      expect(args['pipeline_step_id'], 'step-1');
    });

    test('upsert forwards the log DTO + its own workspace', () async {
      await RemoteAgentRunLogRepository(client).upsert(
        AgentRunLogDto(
          id: 'rl9',
          agentId: 'a1',
          workspaceId: 'ws1',
          startedAt: '2026-01-01T00:00:00.000',
          status: 'completed',
        ),
      );
      final args = host.lastCall('agent_run_log.upsert')!.args;
      // The run's own workspace selects the database file — never a separately
      // threaded parameter that could disagree with the row.
      expect(args['workspace_id'], 'ws1');
      final wire = args['log'] as Map;
      expect(wire['id'], 'rl9');
    });

    test(
      'watchByConversation forwards the workspace + conversation_id',
      () async {
        host.snapshotFor('agent_run_log.watchByConversation', {
          'logs': [logWire],
        });
        final list = await RemoteAgentRunLogRepository(
          client,
        ).watchByConversation('ws1', 'conv-1').first;
        expect(list.single.id, 'rl1');
        expect(host.lastSubscribe!.args['workspace_id'], 'ws1');
        expect(host.lastSubscribe!.args['conversation_id'], 'conv-1');
      },
    );
  });

  group('RpcAgentRunLogRepository', () {
    test('getById returns null on notFound', () async {
      host.errorCodes['agent_run_log.get'] = RpcErrorCodes.notFound;
      expect(
        await RpcAgentRunLogRepository(client).getById('ws1', 'missing'),
        isNull,
      );
    });

    test('getById rethrows non-notFound errors', () async {
      host.errorCodes['agent_run_log.get'] = RpcErrorCodes.internalError;
      expect(
        () => RpcAgentRunLogRepository(client).getById('ws1', 'boom'),
        throwsA(isA<RemoteRpcException>()),
      );
    });

    test('getById returns null when the host reports no row', () async {
      expect(
        await RpcAgentRunLogRepository(client).getById('ws1', 'missing'),
        isNull,
      );
    });

    test('getById resolves a run id only inside the named workspace', () async {
      host.callResults['agent_run_log.get'] = {'log': logWire};
      expect(
        (await RpcAgentRunLogRepository(client).getById('ws1', 'rl1'))!.id,
        'rl1',
      );
      // A workspace id selects the database file, so it is not optional even
      // though the run id is a UUID.
      expect(host.lastCall('agent_run_log.get')!.args['workspace_id'], 'ws1');
    });

    test('activeRunForAgent returns null when no active run exists', () async {
      expect(
        await RpcAgentRunLogRepository(client).activeRunForAgent('ws1', 'a1'),
        isNull,
      );
    });

    test('watchByConversation maps the live stream', () async {
      host.snapshotFor('agent_run_log.watchByConversation', {
        'logs': [logWire],
      });
      final list = await RpcAgentRunLogRepository(
        client,
      ).watchByConversation('ws1', 'conv-1').first;
      expect(list.single.id, 'rl1');
    });

    test('upsert round-trips an AgentRunLog through a DTO', () async {
      final log = AgentRunLog(
        id: 'rl9',
        agentId: 'a1',
        workspaceId: 'ws1',
        startedAt: DateTime.utc(2026),
        status: RunStatus.completed,
      );
      await RpcAgentRunLogRepository(client).upsert(log);
      final args = host.lastCall('agent_run_log.upsert')!.args;
      expect(args['workspace_id'], 'ws1');
      final wire = args['log'] as Map;
      expect(wire['id'], 'rl9');
      expect(wire['status'], 'completed');
      expect(wire['workspace_id'], 'ws1');
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
  final Map<String, int> errorCodes = {};
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
        final err = errorCodes[op];
        if (err != null) {
          channel.send({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': err, 'message': 'scripted'},
          });
        } else {
          _reply(id, {
            'op': op,
            'data': callResults[op] ?? const <String, dynamic>{},
          });
        }
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
