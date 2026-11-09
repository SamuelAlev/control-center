import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Edge-case coverage for [RpcPipelineRunRepository] — the `getRun` notFound →
/// null catch the broad `remote_repositories_test.dart` host leaves cold.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcPipelineRunRepository getRun error handling', () {
    test('returns null when the host reports notFound', () async {
      host.errorCodes['pipeline_run.getRun'] = RpcErrorCodes.notFound;
      expect(await RpcPipelineRunRepository(client).getRun('missing'), isNull);
    });

    test('rethrows a non-notFound RPC error', () async {
      host.errorCodes['pipeline_run.getRun'] = RpcErrorCodes.internalError;
      expect(
        () => RpcPipelineRunRepository(client).getRun('x'),
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
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
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
