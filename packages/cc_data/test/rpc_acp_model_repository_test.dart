import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcAcpModelRepository] — the thin-client ACP model list over RPC.
/// Pins the op name, the args shape, the wire→entity mapping, and the
/// `opUnknown` → empty-list degradation.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcAcpModelRepository.listModels', () {
    test('maps models and forwards adapter_id + cli_path', () async {
      host.callResults['acp.listModels'] = {
        'models': [
          {
            'id': 'anthropic/claude-opus-4-7',
            'name': 'Opus',
            'description': 'big',
            'context_window': 200000,
          },
          {'id': 'glm/glm-4.6', 'name': 'GLM', 'context_window': 128000},
        ],
      };
      final repo = RpcAcpModelRepository(client);
      final models = await repo.listModels(
        'claude',
        cliPath: '/usr/bin/claude',
      );
      expect(models.length, 2);
      expect(models.first.id, 'anthropic/claude-opus-4-7');
      expect(models.first.name, 'Opus');
      expect(models.first.contextWindow, 200000);
      expect(models.last.id, 'glm/glm-4.6');
      final call = host.lastCall('acp.listModels')!;
      expect(call.args['adapter_id'], 'claude');
      expect(call.args['cli_path'], '/usr/bin/claude');
    });

    test('skips models with an empty id', () async {
      host.callResults['acp.listModels'] = {
        'models': [
          {'id': '', 'name': 'empty'},
          {'id': 'real', 'name': 'Real'},
        ],
      };
      final repo = RpcAcpModelRepository(client);
      final models = await repo.listModels('claude');
      expect(models.length, 1);
      expect(models.first.id, 'real');
    });

    test('ignores non-Map entries', () async {
      host.callResults['acp.listModels'] = {
        'models': [
          'not-a-map',
          {'id': 'ok', 'name': 'Ok'},
        ],
      };
      final repo = RpcAcpModelRepository(client);
      final models = await repo.listModels('claude');
      expect(models.length, 1);
      expect(models.first.id, 'ok');
    });

    test('does not send cli_path when it is empty', () async {
      host.callResults['acp.listModels'] = const {'models': []};
      final repo = RpcAcpModelRepository(client);
      await repo.listModels('claude', cliPath: '');
      expect(
        host.lastCall('acp.listModels')!.args.containsKey('cli_path'),
        isFalse,
      );
    });

    test('degrades to an empty list on opUnknown', () async {
      host.errorCodes['acp.listModels'] = RpcErrorCodes.opUnknown;
      final repo = RpcAcpModelRepository(client);
      expect(await repo.listModels('claude'), isEmpty);
    });

    test('rethrows a non-opUnknown error', () async {
      host.errorCodes['acp.listModels'] = RpcErrorCodes.unauthorized;
      final repo = RpcAcpModelRepository(client);
      expect(
        () => repo.listModels('claude'),
        throwsA(isA<RemoteRpcException>()),
      );
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
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final Map<String, Map<String, dynamic>> callResults = {};
  final Map<String, int> errorCodes = {};

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
        final errCode = errorCodes[op];
        if (errCode != null) {
          channel.send({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': errCode, 'message': 'scripted error'},
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
