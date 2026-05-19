import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcTicketSyncConfigRepository] and [RpcTicketSyncLogRepository]
/// — the sync-health surface over RPC. Pins the watch queries, the wire→entity
/// mapping and the server-owned write guards.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcTicketSyncConfigRepository', () {
    test('watchForWorkspace maps configs', () async {
      host.snapshotFor('ticket_sync_config.watchForWorkspace', {
        'configs': [
          {
            'id': 'cfg-1',
            'workspace_id': 'ws-1',
            'vendor': 'linear',
            'vendor_project_id': 'p-1',
            'direction': 'bidirectional',
            'enabled': true,
            'created_at': '2026-07-01T09:00:00.000',
            'updated_at': '2026-07-01T09:00:00.000',
          },
        ],
      });
      final repo = RpcTicketSyncConfigRepository(client);
      final configs = await repo.watchForWorkspace('ws-1').first;
      expect(configs.length, 1);
      final c = configs.first;
      expect(c.id, 'cfg-1');
      expect(c.vendor, 'linear');
      expect(c.vendorProjectId, 'p-1');
      expect(c.direction, SyncDirection.bidirectional);
      expect(c.enabled, isTrue);
      expect(c.createdAt, DateTime(2026, 7, 1, 9));
      final sub = host.lastSubscribe!;
      expect(sub.query, 'ticket_sync_config.watchForWorkspace');
      // The workspace rides in the args: a long-lived subscription must not
      // depend on the client's ambient active workspace, which flips under it
      // on a switch.
      expect(sub.args, {'workspace_id': 'ws-1'});
    });

    test('defaults direction to bidirectional for an unknown value', () async {
      host.snapshotFor('ticket_sync_config.watchForWorkspace', {
        'configs': [
          {
            'id': 'cfg-1',
            'workspace_id': 'ws-1',
            'vendor': 'linear',
            'vendor_project_id': '',
            'direction': 'weird',
            'enabled': false,
            'created_at': 'not-a-date',
            'updated_at': '',
          },
        ],
      });
      final repo = RpcTicketSyncConfigRepository(client);
      final c = (await repo.watchForWorkspace('ws-1').first).first;
      expect(c.direction, SyncDirection.bidirectional);
      expect(c.enabled, isFalse);
      expect(c.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('emits an empty list when the key is absent', () async {
      host.snapshotFor('ticket_sync_config.watchForWorkspace', const {});
      final repo = RpcTicketSyncConfigRepository(client);
      expect(await repo.watchForWorkspace('ws-1').first, isEmpty);
    });

    test('server-owned writes throw UnsupportedError', () async {
      final repo = RpcTicketSyncConfigRepository(client);
      expect(
        () => repo.upsert(
          TicketSyncConfig(
            id: 'c',
            workspaceId: 'ws-1',
            vendor: 'linear',
            vendorProjectId: '',
            direction: SyncDirection.bidirectional,
            enabled: true,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ),
        throwsUnsupportedError,
      );
      expect(() => repo.enabledForWorkspace('ws-1'), throwsUnsupportedError);
      expect(() => repo.forVendor('ws-1', 'linear'), throwsUnsupportedError);
      expect(() => repo.forWorkspace('ws-1'), throwsUnsupportedError);
      expect(
        () => repo.delete('c', workspaceId: 'ws-1'),
        throwsUnsupportedError,
      );
    });
  });

  group('RpcTicketSyncLogRepository', () {
    test('watchForWorkspace maps log entries', () async {
      host.snapshotFor('ticket_sync_log.watchForWorkspace', {
        'logs': [
          {
            'id': 'l-1',
            'workspace_id': 'ws-1',
            'ticket_id': 't-1',
            'vendor': 'linear',
            'direction': 'push',
            'outcome': 'ok',
            'message': 'synced',
            'created_at': '2026-07-01T09:00:00.000',
          },
        ],
      });
      final repo = RpcTicketSyncLogRepository(client);
      final logs = await repo.watchForWorkspace('ws-1').first;
      expect(logs.length, 1);
      final l = logs.first;
      expect(l.id, 'l-1');
      expect(l.ticketId, 't-1');
      expect(l.vendor, 'linear');
      expect(l.direction, SyncDirection.push);
      expect(l.outcome, SyncOutcome.ok);
      expect(l.message, 'synced');
      final sub = host.lastSubscribe!;
      expect(sub.query, 'ticket_sync_log.watchForWorkspace');
      expect(sub.args, {'workspace_id': 'ws-1'});
    });

    test('defaults outcome to ok for an unknown value', () async {
      host.snapshotFor('ticket_sync_log.watchForWorkspace', {
        'logs': [
          {
            'id': 'l-1',
            'workspace_id': 'ws-1',
            'vendor': 'linear',
            'direction': 'pull',
            'outcome': 'weird',
            'created_at': '',
          },
        ],
      });
      final repo = RpcTicketSyncLogRepository(client);
      final l = (await repo.watchForWorkspace('ws-1').first).first;
      expect(l.outcome, SyncOutcome.ok);
      expect(l.direction, SyncDirection.pull);
      expect(l.ticketId, isNull);
      expect(l.message, isNull);
      expect(l.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('server-owned writes throw UnsupportedError', () async {
      final repo = RpcTicketSyncLogRepository(client);
      expect(
        () => repo.append(
          TicketSyncLogEntry(
            id: 'l',
            workspaceId: 'ws-1',
            vendor: 'linear',
            direction: SyncDirection.push,
            outcome: SyncOutcome.ok,
            createdAt: DateTime(2026),
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => repo.hasProcessed('ws-1', 'linear', 'k'),
        throwsUnsupportedError,
      );
      expect(() => repo.recentForWorkspace('ws-1'), throwsUnsupportedError);
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
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
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
        _reply(id, const <String, dynamic>{});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
