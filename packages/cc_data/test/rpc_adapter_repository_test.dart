import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcAdapterRepository] — the thin-client adapter detection
/// adapter, including the `opUnknown` → notFound degradation.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  const adapter = Adapter(
    id: 'pi',
    name: 'Pi',
    description: 'd',
    cliName: 'pi',
  );

  group('RpcAdapterRepository.detectOne', () {
    test('decodes a found adapter with capabilities', () async {
      host.callResults['adapter.detectOne'] = {
        'status': 'found',
        'version': '1.2.3',
        'path': '/usr/bin/pi',
        'capabilities': {
          'supports_json_mode': true,
          'supports_model_selection': false,
        },
      };
      final repo = RpcAdapterRepository(client);
      final d = await repo.detectOne(adapter);
      expect(d.status, DetectionStatus.found);
      expect(d.version, '1.2.3');
      expect(d.path, '/usr/bin/pi');
      expect(d.capabilities?.supportsJsonMode, isTrue);
    });

    test('decodes a notFound status', () async {
      host.callResults['adapter.detectOne'] = {'status': 'notFound'};
      final repo = RpcAdapterRepository(client);
      final d = await repo.detectOne(adapter);
      expect(d.status, DetectionStatus.notFound);
    });

    test('degrades to notFound when the op is unknown (opUnknown)', () async {
      host.errorCodes['adapter.detectOne'] = RpcErrorCodes.opUnknown;
      final repo = RpcAdapterRepository(client);
      final d = await repo.detectOne(adapter);
      expect(d.status, DetectionStatus.notFound);
    });

    test('sends the adapter wire shape', () async {
      host.callResults['adapter.detectOne'] = {'status': 'found'};
      final repo = RpcAdapterRepository(client);
      await repo.detectOne(adapter);
      final call = host.lastCall('adapter.detectOne')!;
      final adapterArg = call.args['adapter'] as Map<String, dynamic>;
      expect(adapterArg['id'], 'pi');
      expect(adapterArg['cli_name'], 'pi');
    });
  });

  group('RpcAdapterRepository.detectAll', () {
    test('decodes a list of detected adapters', () async {
      host.callResults['adapter.detectAll'] = {
        'detected': [
          {'adapter_id': 'pi', 'status': 'found', 'version': '1.0'},
          {'adapter_id': 'claude', 'status': 'notFound'},
        ],
      };
      final repo = RpcAdapterRepository(client);
      final results = await repo.detectAll([
        adapter,
        const Adapter(
          id: 'claude',
          name: 'Claude',
          description: '',
          cliName: 'claude',
        ),
      ]);
      expect(results.length, 2);
      expect(results.first.status, DetectionStatus.found);
      expect(results.last.status, DetectionStatus.notFound);
    });

    test('degrades all to notFound on opUnknown', () async {
      host.errorCodes['adapter.detectAll'] = RpcErrorCodes.opUnknown;
      final repo = RpcAdapterRepository(client);
      final results = await repo.detectAll([adapter]);
      expect(results.length, 1);
      expect(results.first.status, DetectionStatus.notFound);
    });
  });
}

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
