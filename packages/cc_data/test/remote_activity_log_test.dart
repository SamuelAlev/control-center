import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemoteActivityLog] — the workspace audit-trail over RPC. Pins the
/// watch query + args, the wire→entity mapping (incl. epoch fallback) and the
/// workspaceId stamping.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteActivityLog.watchForEntity', () {
    test('maps entries + stamps the workspaceId + forwards args', () async {
      host.snapshotFor('activity.watchForEntity', {
        'entries': [
          {
            'id': 'e-1',
            'actor_type': 'agent',
            'action': 'run_completed',
            'entity_type': 'run',
            'created_at': '2026-07-01T09:00:00.000',
            'actor_id': 'a-1',
            'entity_id': 'run-1',
            'details': '{"k":1}',
            'run_id': 'run-1',
          },
        ],
      });
      final log = RemoteActivityLog(client);
      final entries = await log.watchForEntity('ws-1', 'run', 'run-1').first;
      expect(entries.length, 1);
      final e = entries.first;
      expect(e.id, 'e-1');
      expect(e.actorType, 'agent');
      expect(e.action, 'run_completed');
      expect(e.entityType, 'run');
      expect(e.createdAt, DateTime(2026, 7, 1, 9));
      expect(e.actorId, 'a-1');
      expect(e.entityId, 'run-1');
      expect(e.details, '{"k":1}');
      expect(e.workspaceId, 'ws-1');
      expect(e.runId, 'run-1');
      final sub = host.lastSubscribe!;
      expect(sub.query, 'activity.watchForEntity');
      expect(sub.args['entity_type'], 'run');
      expect(sub.args['entity_id'], 'run-1');
    });

    test('falls back to epoch when created_at is empty', () async {
      host.snapshotFor('activity.watchForEntity', {
        'entries': [
          {
            'id': 'e-2',
            'actor_type': 'user',
            'action': 'x',
            'entity_type': 't',
          },
        ],
      });
      final log = RemoteActivityLog(client);
      final e = (await log.watchForEntity('ws-1', 't', 'x').first).first;
      expect(e.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('emits an empty list when the key is absent', () async {
      host.snapshotFor('activity.watchForEntity', const {});
      final log = RemoteActivityLog(client);
      expect(await log.watchForEntity('ws-1', 't', 'x').first, isEmpty);
    });
  });
}

/// A recorded `sub/subscribe`.
class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  final List<_Sub> subs = [];
  final Map<String, Map<String, dynamic>> snapshots = {};

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
        _reply(id, const <String, dynamic>{});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
