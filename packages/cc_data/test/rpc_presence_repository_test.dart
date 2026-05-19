import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcPresenceRepository] — the ephemeral presence lane over RPC.
/// Pins the publish op + args, the watch query + tier arg and the roster
/// decoder (incl. malformed-entry skipping + non-List fallback).
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcPresenceRepository.publish', () {
    test('forwards workspace_id + presence map', () async {
      final repo = RpcPresenceRepository(client);
      await repo.publish(
        workspaceId: 'ws-1',
        presence: {'a': 'online', 'p': 'user:sam'},
      );
      final call = host.lastCall('presence.update')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['presence'], {'a': 'online', 'p': 'user:sam'});
    });
  });

  group('RpcPresenceRepository.watchRoster', () {
    test('maps the participants array and forwards tier', () async {
      host.snapshotFor('presence.watch', {
        'participants': [
          {'p': 'user:sam', 'n': 'Sam', 'a': 'online'},
          {'p': 'agent:bot', 'n': 'Bot', 'a': 'idle'},
        ],
      });
      final repo = RpcPresenceRepository(client);
      final roster = await repo
          .watchRoster(workspaceId: 'ws-1', tier: 'summary')
          .first;
      expect(roster.length, 2);
      expect(roster.first.principal.id, 'sam');
      expect(roster.first.principal.isAgent, isFalse);
      expect(roster.last.principal.isAgent, isTrue);
      final sub = host.lastSubscribe!;
      expect(sub.query, 'presence.watch');
      expect(sub.args['workspace_id'], 'ws-1');
      expect(sub.args['tier'], 'summary');
    });

    test('defaults the tier to full', () async {
      host.snapshotFor('presence.watch', const {'participants': []});
      final repo = RpcPresenceRepository(client);
      await repo.watchRoster(workspaceId: 'ws-1').first;
      expect(host.lastSubscribe!.args['tier'], 'full');
    });

    test('emits an empty list when participants is not a List', () async {
      host.snapshotFor('presence.watch', const {'participants': 'nope'});
      final repo = RpcPresenceRepository(client);
      expect(await repo.watchRoster(workspaceId: 'ws-1').first, isEmpty);
    });

    test('skips malformed entries (no principal) but keeps the rest', () async {
      host.snapshotFor('presence.watch', {
        'participants': [
          {'n': 'no-principal'},
          'not-a-map',
          {'p': 'user:ok', 'n': 'Ok'},
        ],
      });
      final repo = RpcPresenceRepository(client);
      final roster = await repo.watchRoster(workspaceId: 'ws-1').first;
      expect(roster.length, 1);
      expect(roster.first.principal.id, 'ok');
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
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];
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
        _reply(id, const <String, dynamic>{});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
