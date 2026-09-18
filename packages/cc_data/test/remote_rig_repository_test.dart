import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() => client.close());

  test('decodes unavailable iOS surface and owner setup action', () async {
    host.results['rig.detect'] = {
      'backends': [
        {
          'backend': 'ios-simulator',
          'label': 'iOS Simulator',
          'available': false,
          'surfaces': ['ios'],
          'enforcedEgress': false,
          'setupAction': 'ios-automation',
          'version': 'Xcode 16.4 / iOS 18.2 / WDA v16.12.8',
        },
      ],
    };
    final backend = (await RemoteRigRepository(client).detect()).single;
    expect(backend.surfaces, ['ios']);
    expect(backend.available, isFalse);
    expect(backend.enforcedEgress, isFalse);
    expect(backend.setupAction, RigBackendSetupAction.iosAutomation);
  });

  test('unknown future setup action decodes to null', () {
    final backend = RigBackendView.fromWire({
      'backend': 'future',
      'surfaces': ['ios'],
      'setupAction': 'future-action',
    });
    expect(backend.setupAction, isNull);
  });

  test('old-server egress fallback is false for both device surfaces', () {
    for (final surface in ['mobile', 'ios']) {
      final view = RigView.fromWire({'surface': surface});
      expect(view.egressEnforced, isFalse, reason: surface);
    }
    expect(RigView.fromWire({'surface': 'computer'}).egressEnforced, isTrue);
  });

  test('install setup calls the global op with only the stable action', () async {
    final repository = RemoteRigRepository(client);
    await repository.installBackendSetup(
      RigBackendSetupAction.iosAutomation,
    );
    expect(host.calls.single.op, 'rig.installBackendSetup');
    expect(host.calls.single.args, {'action': 'ios-automation'});
  });
}

class _Call {
  const _Call(this.op, this.args);
  final String op;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.port) {
    port.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort port;
  final Map<String, Map<String, dynamic>> results = {};
  final List<_Call> calls = [];

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'];
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    if (method == 'initialize') {
      _reply(id, {'capabilities': <String, dynamic>{}});
      return;
    }
    if (method == RpcMethods.repoCall) {
      final op = params['op'] as String;
      final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
      calls.add(_Call(op, args));
      _reply(id, {'op': op, 'data': results[op] ?? <String, dynamic>{}});
      return;
    }
    _reply(id, const <String, dynamic>{});
  }

  void _reply(Object? id, Map<String, dynamic> result) {
    port.send({'jsonrpc': '2.0', 'id': id, 'result': result});
  }
}
