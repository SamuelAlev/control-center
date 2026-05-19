import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcAccountPoolsRepository] — the client half of account pools,
/// shared by the Claude Code adapter and every harness provider.
void main() {
  late _Host host;
  late RemoteRpcClient client;
  late RpcAccountPoolsRepository repo;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
    repo = RpcAccountPoolsRepository(client);
  });

  tearDown(() async => client.close());

  test('lane strings name the two lanes distinctly', () {
    expect(RpcAccountPoolsRepository.claudeLane, 'claude-code');
    expect(RpcAccountPoolsRepository.harnessLane('openai'), 'harness:openai');
    expect(
      RpcAccountPoolsRepository.harnessLane('kimi-code'),
      isNot(RpcAccountPoolsRepository.harnessLane('openai')),
    );
  });

  group('get', () {
    test('maps the pool and what an agent would inherit', () async {
      host.callResults['account_pools.get'] = {
        'pool': {
          'account_ids': ['b', 'a'],
          'strategy': 'round_robin',
        },
        'inherited': {
          'account_ids': ['a', 'b', 'c'],
          'strategy': 'serial',
        },
      };
      final view = await repo.get(
        RpcAccountPoolsRepository.claudeLane,
        agentId: 'agent-1',
      );
      expect(view.pool.accountIds, ['b', 'a']);
      expect(view.pool.strategy, AccountRotationStrategy.roundRobin);
      expect(view.inherited?.accountIds, ['a', 'b', 'c']);

      final call = host.lastCall('account_pools.get')!;
      expect(call.args['lane'], 'claude-code');
      expect(call.args['agent_id'], 'agent-1');
    });

    test('a workspace read sends no agent and inherits nothing', () async {
      host.callResults['account_pools.get'] = {
        'pool': {'account_ids': <String>[], 'strategy': 'pinned'},
      };
      final view = await repo.get(RpcAccountPoolsRepository.claudeLane);
      expect(view.pool.isEmpty, isTrue);
      expect(view.inherited, isNull);
      expect(
        host.lastCall('account_pools.get')!.args.containsKey('agent_id'),
        isFalse,
      );
    });

    test('a malformed payload reads as unconfigured', () async {
      host.callResults['account_pools.get'] = const {'pool': 'nope'};
      expect((await repo.get('claude-code')).pool.isEmpty, isTrue);
    });
  });

  group('set', () {
    test('writes the pool with its order preserved', () async {
      await repo.set(
        RpcAccountPoolsRepository.harnessLane('openai'),
        const AccountPool(
          accountIds: ['k2', 'k1'],
          strategy: AccountRotationStrategy.serial,
        ),
      );
      final call = host.lastCall('account_pools.set')!;
      expect(call.args['lane'], 'harness:openai');
      final pool = call.args['pool'] as Map<String, dynamic>;
      // Order IS the configuration: serial drains top-down.
      expect(pool['account_ids'], ['k2', 'k1']);
      expect(pool['strategy'], 'serial');
    });

    test('a null pool OMITS the key, which is how an agent re-inherits',
        () async {
      await repo.set('claude-code', null, agentId: 'agent-1');
      final call = host.lastCall('account_pools.set')!;
      expect(call.args['agent_id'], 'agent-1');
      expect(call.args.containsKey('pool'), isFalse);
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
