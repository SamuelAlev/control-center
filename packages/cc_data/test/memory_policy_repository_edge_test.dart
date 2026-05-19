import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Edge-case coverage for [RpcMemoryPolicyRepository] — the epoch timestamp
/// fallback branches in `_fromDto` and the `getById` notFound → null catch,
/// which the broad `remote_repositories_test.dart` round-trip leaves cold.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  Map<String, dynamic> policyJson(String id) => {
    'id': id,
    'workspace_id': 'ws1',
    'domain': 'coding',
    'rule': 'always cite sources',
    'source_fact_ids': ['f1'],
    'required_role': 'reviewer',
    'active': true,
  };

  group('RpcMemoryPolicyRepository epoch fallbacks', () {
    test(
      'getByWorkspace falls back to the epoch when timestamps are absent',
      () async {
        host.callResults['memory_policy.getByWorkspace'] = {
          'policies': [policyJson('p1')],
        };
        final policies = await RpcMemoryPolicyRepository(
          client,
        ).getByWorkspace('ws1');
        expect(
          policies.single.createdAt,
          DateTime.fromMillisecondsSinceEpoch(0),
        );
        expect(
          policies.single.updatedAt,
          DateTime.fromMillisecondsSinceEpoch(0),
        );
      },
    );

    test(
      'watchByWorkspace falls back to the epoch when timestamps are absent',
      () async {
        host.snapshotFor('memory_policy.watchForWorkspace', {
          'policies': [policyJson('p1')],
        });
        final policies = await RpcMemoryPolicyRepository(
          client,
        ).watchByWorkspace('ws1').first;
        expect(
          policies.single.createdAt,
          DateTime.fromMillisecondsSinceEpoch(0),
        );
        expect(
          policies.single.updatedAt,
          DateTime.fromMillisecondsSinceEpoch(0),
        );
      },
    );
  });

  group('RpcMemoryPolicyRepository getById', () {
    test('returns null when the host reports notFound', () async {
      host.errorCodes['memory_policy.getById'] = RpcErrorCodes.notFound;
      expect(
        await RpcMemoryPolicyRepository(client).getById('ws1', 'missing'),
        isNull,
      );
    });

    test('returns null when the policy payload is absent', () async {
      host.callResults['memory_policy.getById'] = const {};
      expect(
        await RpcMemoryPolicyRepository(client).getById('ws1', 'missing'),
        isNull,
      );
    });

    test('rethrows a non-notFound RPC error', () async {
      host.errorCodes['memory_policy.getById'] = RpcErrorCodes.internalError;
      expect(
        () => RpcMemoryPolicyRepository(client).getById('ws1', 'x'),
        throwsA(isA<RemoteRpcException>()),
      );
    });

    test('returns the mapped policy when present', () async {
      host.callResults['memory_policy.getById'] = {'policy': policyJson('p1')};
      final policy = await RpcMemoryPolicyRepository(
        client,
      ).getById('ws1', 'p1');
      expect(policy!.id, 'p1');
      expect(policy.rule, 'always cite sources');
    });
  });

  group('RpcMemoryPolicyRepository writes', () {
    test('upsert forwards the policy DTO', () async {
      await RpcMemoryPolicyRepository(client).upsert(
        MemoryPolicy(
          id: 'p9',
          workspaceId: 'ws1',
          domain: 'coding',
          rule: 'rule',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      final policy =
          host.lastCall('memory_policy.upsert')!.args['policy'] as Map;
      expect(policy['id'], 'p9');
    });

    test('delete forwards the policy id', () async {
      await RpcMemoryPolicyRepository(client).delete('ws1', 'p9');
      expect(host.lastCall('memory_policy.delete')!.args['id'], 'p9');
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
  final Map<String, int> errorCodes = {};

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
        final err = errorCodes[op];
        if (err != null) {
          space.send({
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
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
