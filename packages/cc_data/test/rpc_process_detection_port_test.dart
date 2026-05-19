import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcProcessDetectionPort] — the active-process dashboard over RPC.
/// Pins the detect/kill ops, the wire→entity mapping, the start_time parse and
/// the opUnknown degradation.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcProcessDetectionPort.detect', () {
    test('maps processes + start_time', () async {
      host.callResults['process.detect'] = {
        'processes': [
          {
            'agent_name': 'architect',
            'workspace_name': 'ws-1',
            'pid': 1234,
            'command': 'cc run',
            'start_time': '2026-07-01T09:00:00.000',
          },
        ],
      };
      final port = RpcProcessDetectionPort(client);
      final procs = await port.detect();
      expect(procs.length, 1);
      final p = procs.first;
      expect(p.agentName, 'architect');
      expect(p.workspaceName, 'ws-1');
      expect(p.pid, 1234);
      expect(p.command, 'cc run');
      expect(p.startTime, DateTime(2026, 7, 1, 9));
      expect(host.lastCall('process.detect')!.args, isEmpty);
    });

    test('defaults text fields to empty and pid to 0', () async {
      host.callResults['process.detect'] = {
        'processes': [{}],
      };
      final port = RpcProcessDetectionPort(client);
      final p = (await port.detect()).first;
      expect(p.agentName, '');
      expect(p.workspaceName, '');
      expect(p.pid, 0);
      expect(p.startTime, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('falls back to epoch on a non-parseable start_time', () async {
      host.callResults['process.detect'] = {
        'processes': [
          {'agent_name': 'a', 'start_time': 'not-a-date'},
        ],
      };
      final port = RpcProcessDetectionPort(client);
      final p = (await port.detect()).first;
      expect(p.startTime, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('ignores non-Map process entries', () async {
      host.callResults['process.detect'] = {
        'processes': [
          'nope',
          {'agent_name': 'a'},
        ],
      };
      final port = RpcProcessDetectionPort(client);
      expect((await port.detect()).length, 1);
    });

    test('degrades to an empty list on opUnknown', () async {
      host.errorCodes['process.detect'] = RpcErrorCodes.opUnknown;
      final port = RpcProcessDetectionPort(client);
      expect(await port.detect(), isEmpty);
    });

    test('rethrows a non-opUnknown error', () async {
      host.errorCodes['process.detect'] = RpcErrorCodes.unauthorized;
      final port = RpcProcessDetectionPort(client);
      expect(port.detect, throwsA(isA<RemoteRpcException>()));
    });
  });

  group('RpcProcessDetectionPort.killProcess', () {
    test('forwards the pid', () async {
      final port = RpcProcessDetectionPort(client);
      await port.killProcess(1234);
      expect(host.lastCall('process.kill')!.args['pid'], 1234);
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
        final errCode = errorCodes[op];
        if (errCode != null) {
          space.send({
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
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
