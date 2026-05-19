import 'dart:convert';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemoteTerminalRepository] — the server-hosted PTY handle over
/// RPC. Pins the spawn op + args (incl. optionals), the base64 chunk decode,
/// and the write/resize/kill ops.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteTerminalRepository.spawn', () {
    test('returns the session_id and forwards all args', () async {
      host.callResults['terminal.spawn'] = {'session_id': 's-1'};
      final repo = RemoteTerminalRepository(client);
      expect(
        await repo.spawn(
          rows: 30,
          cols: 120,
          channelId: 'c-1',
          cwd: '/srv',
          backend: 'seatbelt',
        ),
        's-1',
      );
      final call = host.lastCall('terminal.spawn')!;
      expect(call.args['rows'], 30);
      expect(call.args['cols'], 120);
      expect(call.args['channel_id'], 'c-1');
      expect(call.args['cwd'], '/srv');
      expect(call.args['backend'], 'seatbelt');
    });

    test('omits optional args when null', () async {
      host.callResults['terminal.spawn'] = {'session_id': 's-1'};
      final repo = RemoteTerminalRepository(client);
      await repo.spawn(rows: 24, cols: 80);
      final args = host.lastCall('terminal.spawn')!.args;
      expect(args.containsKey('channel_id'), isFalse);
      expect(args.containsKey('cwd'), isFalse);
      expect(args.containsKey('backend'), isFalse);
    });
  });

  group('RemoteTerminalRepository.output', () {
    test('decodes base64 chunks and forwards session_id', () async {
      final bytes = [104, 105]; // "hi"
      host.snapshotFor('terminal.output', {'chunk': base64Encode(bytes)});
      final repo = RemoteTerminalRepository(client);
      final out = await repo.output('s-1').first;
      expect(out, bytes);
      final sub = host.lastSubscribe!;
      expect(sub.query, 'terminal.output');
      expect(sub.args['session_id'], 's-1');
    });

    test('emits an empty list when chunk is absent', () async {
      host.snapshotFor('terminal.output', const {});
      final repo = RemoteTerminalRepository(client);
      expect(await repo.output('s-1').first, isEmpty);
    });
  });

  group('RemoteTerminalRepository writes', () {
    test('write frames data as base64 and forwards session_id', () async {
      final repo = RemoteTerminalRepository(client);
      await repo.write('s-1', [10, 20]);
      final call = host.lastCall('terminal.write')!;
      expect(call.args['session_id'], 's-1');
      expect(call.args['data'], base64Encode([10, 20]));
    });

    test('resize forwards rows + cols + session_id', () async {
      final repo = RemoteTerminalRepository(client);
      await repo.resize('s-1', 40, 100);
      final call = host.lastCall('terminal.resize')!;
      expect(call.args['session_id'], 's-1');
      expect(call.args['rows'], 40);
      expect(call.args['cols'], 100);
    });

    test('kill forwards the session_id', () async {
      final repo = RemoteTerminalRepository(client);
      await repo.kill('s-1');
      expect(host.lastCall('terminal.kill')!.args['session_id'], 's-1');
    });
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
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
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
          channel.send({
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
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
