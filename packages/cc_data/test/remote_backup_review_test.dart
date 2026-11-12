import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/repositories/server_notice_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// The client side of the storage review surfaces: the server owner's
/// notices (`server.notices`), the grants a restore held back
/// (`workspace.importHolds.*`) and a workspace's `storage_state` on
/// `workspace.watchAll`.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteServerNotices', () {
    test('decodes the open notices, oldest first', () async {
      host.callResults['server.notices'] = {
        'notices': [
          {
            'kind': 'workspace_read_only',
            'subject': 'ws-1',
            'detail': 'row 12 missing from index',
            'created_at': '2026-11-12T08:00:00.000Z',
          },
          {
            'kind': 'workspace_read_only',
            'subject': 'ws-2',
            'detail': '',
            'created_at': '2026-11-12T09:00:00.000Z',
          },
        ],
      };

      final notices = await RemoteServerNotices(client).open();

      expect(notices.map((n) => n.subject), ['ws-1', 'ws-2']);
      expect(notices.first.kind, ServerNoticeKind.workspaceReadOnly);
      expect(notices.first.detail, 'row 12 missing from index');
      expect(notices.first.createdAt, DateTime.utc(2026, 11, 12, 8));
      expect(host.lastCall('server.notices')?.args, isEmpty);
    });

    test('leaves out a kind this build does not know', () async {
      host.callResults['server.notices'] = {
        'notices': [
          {
            'kind': 'disk_almost_full',
            'subject': 'data',
            'detail': '95%',
            'created_at': '2026-11-12T08:00:00.000Z',
          },
          {'kind': 'workspace_read_only', 'subject': 'ws-1'},
        ],
      };

      expect(await RemoteServerNotices(client).open(), isEmpty);
    });
  });

  group('RemoteImportHolds', () {
    test('lists the holds of the named workspace', () async {
      host.callResults['workspace.importHolds.list'] = {
        'holds': [
          {
            'id': 'h1',
            'kind': 'repo_grant',
            'payload': {'user_id': 'u1', 'repo_id': 'r1', 'level': 'write'},
            'imported_at': '2026-11-12T08:00:00.000Z',
            'source_install_id': 'install-a',
          },
          {
            'id': 'h2',
            'kind': 'something_newer',
            'payload': {'x': 1},
            'imported_at': '2026-11-12T08:00:00.000Z',
            'source_install_id': 'install-a',
          },
          // Malformed: no id. Dropped, not fatal.
          {
            'kind': 'invite',
            'payload': <String, dynamic>{},
            'imported_at': '2026-11-12T08:00:00.000Z',
          },
        ],
      };

      final holds = await RemoteImportHolds(client).list('ws-7');

      expect(host.lastCall('workspace.importHolds.list')?.args, {
        'workspace_id': 'ws-7',
      });
      expect(holds.map((h) => h.id), ['h1', 'h2']);
      expect(holds.first.kind, ImportHoldKind.repoGrant);
      expect(holds.first.text('level'), 'write');
      expect(holds.first.sourceInstallId, 'install-a');
      // An unknown kind is kept, so it can still be dismissed.
      expect(holds.last.kind, isNull);
      expect(holds.last.wireKind, 'something_newer');
    });

    test('resolve forwards the decision and reads applied', () async {
      host.callResults['workspace.importHolds.resolve'] = {
        'ok': true,
        'applied': true,
      };
      final review = RemoteImportHolds(client);

      expect(
        await review.resolve(workspaceId: 'ws-7', holdId: 'h1', accept: true),
        isTrue,
      );
      expect(host.lastCall('workspace.importHolds.resolve')?.args, {
        'workspace_id': 'ws-7',
        'hold_id': 'h1',
        'accept': true,
      });

      host.callResults['workspace.importHolds.resolve'] = {
        'ok': true,
        'applied': false,
      };
      expect(
        await review.resolve(workspaceId: 'ws-7', holdId: 'h2', accept: false),
        isFalse,
      );
      expect(
        host.lastCall('workspace.importHolds.resolve')?.args['accept'],
        isFalse,
      );
    });
  });

  group('RpcWorkspaceRepository storage state', () {
    Map<String, dynamic> row(String id, {String? state}) => {
      'id': id,
      'name': 'Workspace $id',
      'created_at': '2026-11-01T00:00:00.000Z',
      'storage_state': ?state,
    };

    test('a read_only row is a read-only workspace', () async {
      host.snapshotFor('workspace.watchAll', {
        'workspaces': [
          row('ws-1', state: 'read_only'),
          row('ws-2', state: 'ok'),
          row('ws-3'),
        ],
      });

      final workspaces = await RpcWorkspaceRepository(client).watchAll().first;

      expect(workspaces.map((w) => w.storageState), [
        WorkspaceStorageState.readOnly,
        WorkspaceStorageState.ok,
        WorkspaceStorageState.ok,
      ]);
      expect(workspaces.first.isReadOnly, isTrue);
    });

    test('the state is never sent back on an upsert', () async {
      host.callResults['workspace.upsert'] = {'workspace_id': 'ws-1'};
      final now = DateTime.utc(2026, 11, 12);
      await RpcWorkspaceRepository(client).upsert(
        Workspace(
          id: 'ws-1',
          name: 'Renamed',
          createdAt: now,
          updatedAt: now,
          storageState: WorkspaceStorageState.readOnly,
        ),
      );

      final sent =
          host.lastCall('workspace.upsert')!.args['workspace']
              as Map<String, dynamic>;
      expect(sent.containsKey('storage_state'), isFalse);
    });
  });
}

class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<({String op, Map<String, dynamic> args})> calls = [];
  final Map<String, Map<String, dynamic>> callResults = {};
  final Map<String, Map<String, dynamic>> snapshots = {};

  ({String op, Map<String, dynamic> args})? lastCall(String op) {
    for (final call in calls.reversed) {
      if (call.op == op) {
        return call;
      }
    }
    return null;
  }

  void snapshotFor(String query, Map<String, dynamic> data) =>
      snapshots[query] = data;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (frame['method'] as String?) {
      case RpcMethods.subscribe:
        final query = params['query'] as String;
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
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add((op: op, args: args));
        _reply(id, {
          'op': op,
          'data': callResults[op] ?? const <String, dynamic>{},
        });
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(Object? id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
