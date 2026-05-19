import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemoteSandboxDetector] — the sandbox-backend probe over RPC.
/// Pins the op name, the wire→entity mapping, and the opUnknown degradation.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteSandboxDetector.detect', () {
    test('maps platform + recommendation + capabilities', () async {
      host.callResults['sandbox.detect'] = {
        'platform': 'macos',
        'recommendation': 'native',
        'capabilities': [
          {
            'backend': 'native',
            'available': true,
            'requires_install': false,
            'install_hint': null,
            'note': 'built-in',
          },
          {'backend': 'none', 'available': true, 'requires_install': false},
        ],
      };
      final detector = RemoteSandboxDetector(client);
      final result = await detector.detect();
      expect(result.platform, 'macos');
      expect(result.recommendation, SandboxBackend.native);
      expect(result.capabilities.length, 2);
      final caps = result.capabilities[SandboxBackend.native]!;
      expect(caps.available, isTrue);
      expect(caps.requiresInstall, isFalse);
      expect(caps.note, 'built-in');
      final none = result.capabilities[SandboxBackend.none]!;
      expect(none.available, isTrue);
      expect(host.lastCall('sandbox.detect')!.args, isEmpty);
    });

    test('defaults platform to empty and unknown backend to none', () async {
      host.callResults['sandbox.detect'] = {
        'recommendation': 'nope-unknown',
        'capabilities': [
          {'backend': 'also-unknown', 'available': true},
        ],
      };
      final detector = RemoteSandboxDetector(client);
      final result = await detector.detect();
      expect(result.platform, '');
      expect(result.recommendation, SandboxBackend.none);
      expect(result.capabilities[SandboxBackend.none]?.available, isTrue);
    });

    test('defaults booleans to false when absent', () async {
      host.callResults['sandbox.detect'] = {
        'capabilities': [
          {'backend': 'native'},
        ],
      };
      final detector = RemoteSandboxDetector(client);
      final result = await detector.detect();
      final caps = result.capabilities[SandboxBackend.native]!;
      expect(caps.available, isFalse);
      expect(caps.requiresInstall, isFalse);
    });

    test('skips non-Map capability entries', () async {
      host.callResults['sandbox.detect'] = {
        'capabilities': [
          'nope',
          {'backend': 'native', 'available': true},
        ],
      };
      final detector = RemoteSandboxDetector(client);
      final result = await detector.detect();
      expect(result.capabilities.length, 1);
    });

    test('degrades to a safe no-isolation-only result on opUnknown', () async {
      host.errorCodes['sandbox.detect'] = RpcErrorCodes.opUnknown;
      final detector = RemoteSandboxDetector(client);
      final result = await detector.detect();
      expect(result.platform, '');
      expect(result.recommendation, SandboxBackend.none);
      expect(result.capabilities[SandboxBackend.none]!.available, isTrue);
    });

    test('rethrows a non-opUnknown error', () async {
      host.errorCodes['sandbox.detect'] = RpcErrorCodes.unauthorized;
      final detector = RemoteSandboxDetector(client);
      expect(detector.detect, throwsA(isA<RemoteRpcException>()));
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
