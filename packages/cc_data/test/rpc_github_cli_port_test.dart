import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcGitHubCliPort] — the thin-client `gh` probe over RPC.
/// Pins the op name, the args shape, the wire→entity mapping, and the
/// `opUnknown` → "not installed" degradation.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcGitHubCliPort.probe', () {
    test('maps installed + authenticated + username', () async {
      host.callResults['github_cli.probe'] = {
        'is_installed': true,
        'is_authenticated': true,
        'username': 'sam',
      };
      final port = RpcGitHubCliPort(client);
      final status = await port.probe();
      expect(status.isInstalled, isTrue);
      expect(status.isAuthenticated, isTrue);
      expect(status.username, 'sam');
      // The host never ships its token to a remote client.
      expect(status.token, isEmpty);
      expect(host.lastCall('github_cli.probe')!.args, isEmpty);
    });

    test('defaults booleans to false and username to empty', () async {
      host.callResults['github_cli.probe'] = const {};
      final port = RpcGitHubCliPort(client);
      final status = await port.probe();
      expect(status.isInstalled, isFalse);
      expect(status.isAuthenticated, isFalse);
      expect(status.username, '');
    });

    test('degrades to a default status on opUnknown', () async {
      host.errorCodes['github_cli.probe'] = RpcErrorCodes.opUnknown;
      final port = RpcGitHubCliPort(client);
      final status = await port.probe();
      expect(status.isInstalled, isFalse);
      expect(status.isAuthenticated, isFalse);
      expect(status.username, '');
    });

    test('rethrows a non-opUnknown error', () async {
      host.errorCodes['github_cli.probe'] = RpcErrorCodes.unauthorized;
      final port = RpcGitHubCliPort(client);
      expect(port.probe, throwsA(isA<RemoteRpcException>()));
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
