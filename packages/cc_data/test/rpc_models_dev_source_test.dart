import 'dart:convert';

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

  test('load parses the document models.catalog relays as text', () async {
    host.callResults['models.catalog'] = {
      'document_json': jsonEncode(document),
    };
    final source = RpcModelsDevSource(client);
    final providers = await source.load();
    expect(providers?['anthropic']?.provider.name, 'Anthropic');
    expect(providers?['anthropic']?.models.keys, ['claude-opus-4-5']);
    expect(host.lastCall('models.catalog'), isNotNull);
  });

  test('documentText is the relayed text itself', () async {
    host.callResults['models.catalog'] = {
      'document_json': jsonEncode(document),
    };
    expect(
      await RpcModelsDevSource(client).documentText(),
      jsonEncode(document),
    );
  });

  test('load returns null when the host has no document', () async {
    host.callResults['models.catalog'] = {'document_json': ''};
    expect(await RpcModelsDevSource(client).load(), isNull);
  });

  test('load returns null for an empty or unreadable document', () async {
    host.callResults['models.catalog'] = {'document_json': '{}'};
    expect(await RpcModelsDevSource(client).load(), isNull);
    host.callResults['models.catalog'] = {'document_json': 'not json'};
    expect(await RpcModelsDevSource(client).load(), isNull);
  });

  test('refresh forwards force to models.refreshCatalog', () async {
    host.callResults['models.refreshCatalog'] = {
      'document_json': jsonEncode(document),
    };
    final providers = await RpcModelsDevSource(client).refresh(force: true);
    expect(providers?['anthropic']?.provider.name, 'Anthropic');
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
