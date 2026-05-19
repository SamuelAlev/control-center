import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcDictationControl] — the dictation thin-client over RPC.
/// Pins the ops, base64 PCM framing, args shape and partial-text decoding.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcDictationControl', () {
    test('start returns the dictation_id', () async {
      host.callResults['dictation.start'] = {'dictation_id': 'd-1'};
      final ctrl = RpcDictationControl(client);
      expect(await ctrl.start(), 'd-1');
      expect(host.lastCall('dictation.start')!.args, isEmpty);
    });

    test('ingestAudio frames PCM as base64 and sends dictation_id', () async {
      final ctrl = RpcDictationControl(client);
      final pcm = Uint8List.fromList([1, 2, 3, 4]);
      await ctrl.ingestAudio(dictationId: 'd-1', seq: 7, pcm: pcm);
      final call = host.lastCall('dictation.ingestAudio')!;
      expect(call.args['dictation_id'], 'd-1');
      expect(call.args['pcm'], base64Encode(pcm));
      // seq is a client-side diagnostic the host does not read.
      expect(call.args.containsKey('seq'), isFalse);
    });

    test('stop forwards the dictation_id', () async {
      final ctrl = RpcDictationControl(client);
      await ctrl.stop(dictationId: 'd-1');
      expect(host.lastCall('dictation.stop')!.args['dictation_id'], 'd-1');
    });

    test('watchPartials maps the partial stream', () async {
      host.snapshotFor('dictation.watchPartials', {
        'text': 'hello',
        'is_final': false,
      });
      final ctrl = RpcDictationControl(client);
      final p = await ctrl.watchPartials('d-1').first;
      expect(p.text, 'hello');
      expect(p.isFinal, isFalse);
      final sub = host.lastSubscribe!;
      expect(sub.query, 'dictation.watchPartials');
      expect(sub.args['dictation_id'], 'd-1');
    });

    test(
      'watchPartials defaults text to empty and is_final to false',
      () async {
        host.snapshotFor('dictation.watchPartials', const {});
        final ctrl = RpcDictationControl(client);
        final p = await ctrl.watchPartials('d-1').first;
        expect(p.text, '');
        expect(p.isFinal, isFalse);
      },
    );
  });
}

/// A recorded `sub/subscribe`.
class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
  final Map<String, dynamic> args;
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
  final List<_Sub> subs = [];
  final Map<String, Map<String, dynamic>> callResults = {};
  final Map<String, Map<String, dynamic>> snapshots = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );
  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

  void snapshotFor(String query, Map<String, dynamic> data) =>
      snapshots[query] = data;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        final query = params['query'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        subs.add(_Sub(query: query, args: args));
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
        final snapshot = snapshots[query];
        if (snapshot != null) {
          space.send({
            'jsonrpc': '2.0',
            'method': RpcMethods.subSnapshot,
            'params': {
              'subscriptionId': 's1',
              'rev': 1,
              'full': true,
              'data': snapshot,
            },
          });
        }
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
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
