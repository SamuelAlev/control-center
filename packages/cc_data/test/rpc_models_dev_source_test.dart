import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

void main() {
  late _Host host;
  late RemoteRpcClient client;

  const document = {
    'anthropic': {
      'id': 'anthropic',
      'name': 'Anthropic',
      'models': {
        'claude-opus-4-5': {'id': 'claude-opus-4-5', 'name': 'Claude Opus 4.5'},
      },
    },
  };

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  test('load maps models.catalog to the document', () async {
    host.callResults['models.catalog'] = {'document': document};
    final source = RpcModelsDevSource(client);
    final json = await source.load();
    expect(json?['anthropic'], isA<Map>());
    expect(host.lastCall('models.catalog'), isNotNull);
  });

  test('load returns null for an empty document', () async {
    host.callResults['models.catalog'] = {'document': <String, dynamic>{}};
    expect(await RpcModelsDevSource(client).load(), isNull);
  });

  test('refresh forwards force to models.refreshCatalog', () async {
    host.callResults['models.refreshCatalog'] = {'document': document};
    final json = await RpcModelsDevSource(client).refresh(force: true);
    expect(json?['anthropic'], isA<Map>());
    expect(host.lastCall('models.refreshCatalog')!.args['force'], isTrue);
  });
}

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
