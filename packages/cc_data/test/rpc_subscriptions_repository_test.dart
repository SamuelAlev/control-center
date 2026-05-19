import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/subscriptions/domain/entities/subscription_usage.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcSubscriptionsRepository] — the usage-pill data path over RPC.
/// Pins the op name, the argless call (the host resolves every credential
/// server-side), the wire→entity mapping and the empty/non-list degradation.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcSubscriptionsRepository.fetchUsage', () {
    test('maps providers and calls the op with no args', () async {
      host.callResults['subscriptions.usage'] = {
        'providers': [
          {
            'provider_id': 'claude',
            'display_name': 'Claude',
            'status': 'ok',
            'windows': [
              {
                'id': '5h',
                'label': 'Session',
                'used_fraction': 0.4,
                'resets_at': '2026-07-01T09:00:00.000',
              },
            ],
          },
          {
            'provider_id': 'zai',
            'display_name': 'z.ai',
            'status': 'unconfigured',
          },
        ],
      };
      final repo = RpcSubscriptionsRepository(client);
      final usage = await repo.fetchUsage();
      expect(usage.length, 2);
      expect(usage.first.providerId, 'claude');
      expect(usage.first.status, SubscriptionStatus.ok);
      expect(usage.first.windows.first.usedFraction, 0.4);
      expect(usage.last.status, SubscriptionStatus.unconfigured);
      // No credential ever crosses the wire — the host resolves the z.ai key
      // from its harness provider credential store.
      expect(host.lastCall('subscriptions.usage')!.args, isEmpty);
    });

    test('returns an empty list when providers is absent', () async {
      host.callResults['subscriptions.usage'] = const {};
      final repo = RpcSubscriptionsRepository(client);
      expect(await repo.fetchUsage(), isEmpty);
    });

    test('returns an empty list when providers is not a List', () async {
      host.callResults['subscriptions.usage'] = {'providers': 'nope'};
      final repo = RpcSubscriptionsRepository(client);
      expect(await repo.fetchUsage(), isEmpty);
    });

    test('ignores non-Map providers', () async {
      host.callResults['subscriptions.usage'] = {
        'providers': [
          'nope',
          {'provider_id': 'ok', 'display_name': 'OK', 'status': 'ok'},
        ],
      };
      final repo = RpcSubscriptionsRepository(client);
      final usage = await repo.fetchUsage();
      expect(usage.length, 1);
      expect(usage.first.providerId, 'ok');
    });
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  final List<_Call> calls = [];
  final Map<String, Map<String, dynamic>> callResults = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
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
