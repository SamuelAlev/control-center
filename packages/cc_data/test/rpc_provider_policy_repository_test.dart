import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/model_routing/domain/entities/provider_policy.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcProviderPolicyRepository] — the provider-governance surface
/// over RPC. Pins the ops + args, the watch query, the DTO→entity mapping, the
/// upsert JSON round-trip, and the engineFor builder.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  Map<String, dynamic> policyJson({
    String id = 'p-1',
    String effect = 'allow',
    String layer = 'workspace',
  }) => {
    'id': id,
    'workspace_id': 'ws-1',
    'action': 'provider.use',
    'resource': 'anthropic',
    'effect': effect,
    'layer': layer,
  };

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcProviderPolicyRepository.listForWorkspace', () {
    test('maps policies with effect + layer', () async {
      host.callResults['provider_policy.listForWorkspace'] = {
        'policies': [
          policyJson(id: 'p-1', effect: 'allow'),
          policyJson(id: 'p-2', effect: 'deny', layer: 'user'),
        ],
      };
      final repo = RpcProviderPolicyRepository(client);
      final policies = await repo.listForWorkspace('ws-1');
      expect(policies.length, 2);
      expect(policies.first.id, 'p-1');
      expect(policies.first.statement.effect, PolicyEffect.allow);
      expect(policies.first.statement.layer, PolicyLayer.workspace);
      expect(policies[1].statement.effect, PolicyEffect.deny);
      expect(policies[1].statement.layer, PolicyLayer.user);
      // Names the workspace it was asked about rather than relying on the
      // client's ambient active workspace, which follows the route.
      expect(host.lastCall('provider_policy.listForWorkspace')!.args, {
        'workspace_id': 'ws-1',
      });
    });

    test(
      'defaults an unknown effect to deny and an unknown layer to workspace',
      () async {
        host.callResults['provider_policy.listForWorkspace'] = {
          'policies': [policyJson(id: 'p-1', effect: 'weird', layer: 'nope')],
        };
        final repo = RpcProviderPolicyRepository(client);
        final p = (await repo.listForWorkspace('ws-1')).first;
        expect(p.statement.effect, PolicyEffect.deny);
        expect(p.statement.layer, PolicyLayer.workspace);
      },
    );
  });

  group('RpcProviderPolicyRepository.watchForWorkspace', () {
    test('maps the live stream', () async {
      host.snapshotFor('provider_policy.watchForWorkspace', {
        'policies': [policyJson()],
      });
      final repo = RpcProviderPolicyRepository(client);
      final policies = await repo.watchForWorkspace('ws-1').first;
      expect(policies.first.id, 'p-1');
      final sub = host.lastSubscribe!;
      expect(sub.query, 'provider_policy.watchForWorkspace');
      // The workspace rides in the args: a long-lived subscription must not
      // depend on the client's ambient active workspace, which flips under it
      // on a switch.
      expect(sub.args, {'workspace_id': 'ws-1'});
    });
  });

  group('RpcProviderPolicyRepository writes', () {
    test('upsert sends the policy JSON with workspace_id', () async {
      final repo = RpcProviderPolicyRepository(client);
      await repo.upsert(
        'ws-1',
        'p-1',
        const PolicyStatement(
          action: 'provider.use',
          resource: 'anthropic',
          effect: PolicyEffect.allow,
          layer: PolicyLayer.workspace,
        ),
      );
      final call = host.lastCall('provider_policy.upsert')!;
      final policy = (call.args['policy'] as Map).cast<String, dynamic>();
      expect(policy['id'], 'p-1');
      expect(policy['workspace_id'], 'ws-1');
      expect(policy['effect'], 'allow');
      expect(policy['layer'], 'workspace');
    });

    test('delete forwards the id', () async {
      final repo = RpcProviderPolicyRepository(client);
      await repo.delete('ws-1', 'p-9');
      expect(host.lastCall('provider_policy.delete')!.args['id'], 'p-9');
    });
  });

  group('RpcProviderPolicyRepository.engineFor', () {
    test('builds an engine from the workspace statements', () async {
      host.callResults['provider_policy.listForWorkspace'] = {
        'policies': [
          policyJson(id: 'p-1', effect: 'allow'),
          policyJson(id: 'p-2', effect: 'deny'),
        ],
      };
      final repo = RpcProviderPolicyRepository(client);
      final engine = await repo.engineFor('ws-1');
      expect(engine, isNotNull);
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
