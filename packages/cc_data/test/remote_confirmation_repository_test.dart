import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemoteConfirmationRepository] — the phone approve/decline surface
/// over RPC. Pins the watch query, the respond op + args shape, the wire→DTO
/// mapping, and the ok-flag handling.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteConfirmationRepository.watchPending', () {
    test('maps the pending array', () async {
      host.snapshotFor('confirmation.watchPending', {
        'pending': [
          {
            'id': 'cf-1',
            'conversation_id': 'c-1',
            'title': 'Push to main',
            'detail': 'will overwrite',
            'severity': 'destructive',
            'command': 'git push',
            'created_at': '2026-07-01T09:00:00.000',
          },
        ],
      });
      final repo = RemoteConfirmationRepository(client);
      final pending = await repo.watchPending().first;
      expect(pending.length, 1);
      final r = pending.first;
      expect(r.id, 'cf-1');
      expect(r.conversationId, 'c-1');
      expect(r.title, 'Push to main');
      expect(r.detail, 'will overwrite');
      expect(r.severity, 'destructive');
      expect(r.command, 'git push');
      expect(r.createdAt, '2026-07-01T09:00:00.000');
      final sub = host.lastSubscribe!;
      expect(sub.query, 'confirmation.watchPending');
      expect(sub.args, isEmpty);
    });

    test('emits an empty list when the key is absent', () async {
      host.snapshotFor('confirmation.watchPending', const {});
      final repo = RemoteConfirmationRepository(client);
      expect(await repo.watchPending().first, isEmpty);
    });
  });

  group('RemoteConfirmationRepository.respond', () {
    test('forwards id + approved and returns ok=true', () async {
      host.callResults['confirmation.respond'] = {'ok': true};
      final repo = RemoteConfirmationRepository(client);
      expect(await repo.respond('cf-1', approved: true), isTrue);
      final call = host.lastCall('confirmation.respond')!;
      expect(call.args['id'], 'cf-1');
      expect(call.args['approved'], isTrue);
    });

    test('returns false when ok is missing or not true', () async {
      host.callResults['confirmation.respond'] = const {};
      final repo = RemoteConfirmationRepository(client);
      expect(await repo.respond('cf-1', approved: false), isFalse);
    });
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

/// A recorded `sub/subscribe`.
class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
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
