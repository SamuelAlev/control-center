import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_rpc_client.dart';

/// The client half of the backup surface.
///
/// `server.backupNow`, `workspace.export` and `workspace.import` had no caller
/// in the app at all, so what these pin is mostly the wiring: that the list
/// decodes the shape the server sends, that a workspace id travels explicitly
/// (this page acts on workspaces other than the active one) and that taking a
/// snapshot refreshes the list rather than leaving the operator looking at a
/// stale one.
void main() {
  Map<String, dynamic> snapshotJson({
    String path = '/data/backups/2026-08-31T09-00-00-000Z',
    String name = '2026-08-31T09-00-00-000Z',
    String? createdAt = '2026-08-31T09:00:00.000Z',
    int bytes = 4096,
    bool complete = true,
    List<Map<String, dynamic>> workspaces = const [
      {'workspace_id': 'ws-1', 'path': '/data/backups/x/ws-1/workspace.db',
       'bytes': 2048},
    ],
    List<String> skipped = const [],
  }) => {
    'path': path,
    'name': name,
    'created_at': ?createdAt,
    'bytes': bytes,
    'complete': complete,
    'workspaces': workspaces,
    'skipped_workspace_ids': skipped,
  };

  ProviderContainer containerFor(FakeRpcHost host) {
    final container = ProviderContainer(
      overrides: [rpcClientProvider.overrideWithValue(host.client())],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('workspace backups are asked for by explicit workspace id', () async {
    final calls = <(String, Map<String, dynamic>)>[];
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      calls.add((op, args));
      return {
        'backups': [snapshotJson()],
      };
    };

    final backups = await containerFor(
      host,
    ).read(workspaceBackupsProvider('ws-2').future);

    expect(calls.single.$1, 'workspace.listBackups');
    expect(calls.single.$2['workspace_id'], 'ws-2');
    expect(backups.single.workspaces.single.workspaceId, 'ws-1');
  });

  test('deleting a backup names it and refreshes that workspace', () async {
    final ops = <String>[];
    final calls = <Map<String, dynamic>>[];
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      ops.add(op);
      if (op == 'workspace.deleteBackup') {
        calls.add(args);
        return {'ok': true};
      }
      return {'backups': const <Map<String, dynamic>>[]};
    };
    final container = containerFor(host);
    final keepAlive = container.listen(
      workspaceBackupsProvider('ws-1'),
      (_, _) {},
    );
    addTearDown(keepAlive.close);
    await container.read(workspaceBackupsProvider('ws-1').future);

    await container
        .read(backupActionsProvider)
        .deleteWorkspaceBackup(workspaceId: 'ws-1', name: 'snap');
    await container.read(workspaceBackupsProvider('ws-1').future);

    expect(calls.single['workspace_id'], 'ws-1');
    expect(calls.single['name'], 'snap');
    expect(ops.where((op) => op == 'workspace.listBackups'), hasLength(2));
  });

  test('decodes the backups of a deleted workspace', () async {
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      expect(op, 'server.listOrphanedBackups');
      return {
        'workspaces': [
          {
            'workspace_id': 'ws-gone',
            'workspace_name': 'Old project',
            'backups': [snapshotJson()],
          },
          {'workspace_id': 'ws-unknown', 'backups': <Map<String, dynamic>>[]},
        ],
      };
    };

    final orphans = await containerFor(
      host,
    ).read(orphanedWorkspaceBackupsProvider.future);

    expect(orphans.first.workspaceName, 'Old project');
    expect(orphans.first.backups, hasLength(1));
    expect(orphans.last.workspaceName, isNull);
  });

  test('decodes every field of a listed snapshot', () async {
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      expect(op, 'server.listBackups');
      return {
        'backups': [
          snapshotJson(),
          snapshotJson(
            name: 'half-written',
            createdAt: null,
            complete: false,
            workspaces: const [],
            skipped: const ['ws-2'],
          ),
        ],
      };
    };

    final snapshots = await containerFor(
      host,
    ).read(backupSnapshotsProvider.future);

    expect(snapshots, hasLength(2));
    final first = snapshots.first;
    expect(first.name, '2026-08-31T09-00-00-000Z');
    expect(first.createdAt, DateTime.utc(2026, 8, 31, 9));
    expect(first.bytes, 4096);
    expect(first.complete, isTrue);
    expect(first.workspaces.single.workspaceId, 'ws-1');
    expect(first.workspaces.single.path, '/data/backups/x/ws-1/workspace.db');

    // A snapshot that died halfway still decodes — the UI shows it rather than
    // letting an operator believe they have a backup they do not.
    final second = snapshots.last;
    expect(second.complete, isFalse);
    expect(second.createdAt, isNull);
    expect(second.workspaces, isEmpty);
    expect(second.skippedWorkspaceIds, <String>['ws-2']);
  });

  test('a snapshot refreshes the listing instead of leaving it stale', () async {
    final calls = <String>[];
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      calls.add(op);
      if (op == 'server.backupNow') {
        return {'ok': true, 'path': '/data/backups/new'};
      }
      return {'backups': <Map<String, dynamic>>[]};
    };
    final container = containerFor(host);
    // Keep the autoDispose provider alive across the invalidation, the way a
    // mounted page does.
    final sub = container.listen(backupSnapshotsProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(backupSnapshotsProvider.future);

    final path = await container.read(backupActionsProvider).backupNow();

    expect(path, '/data/backups/new');
    await container.read(backupSnapshotsProvider.future);
    expect(calls, [
      'server.listBackups',
      'server.backupNow',
      'server.listBackups',
    ]);
  });

  test('export names its workspace explicitly, not the active one', () async {
    Map<String, dynamic>? sent;
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      expect(op, 'workspace.export');
      sent = Map.of(args);
      return {'ok': true, 'path': '/data/backups/exports/ws-7.db'};
    };

    final path = await containerFor(
      host,
    ).read(backupActionsProvider).exportWorkspace('ws-7');

    expect(path, '/data/backups/exports/ws-7.db');
    expect(sent?['workspace_id'], 'ws-7');
  });

  test('import sends the target workspace and the server-side source', () async {
    Map<String, dynamic>? sent;
    final host = FakeRpcHost();
    host.onCall = (op, args) {
      expect(op, 'workspace.import');
      sent = Map.of(args);
      return {'ok': true, 'workspace_id': 'ws-7'};
    };

    await containerFor(host).read(backupActionsProvider).importWorkspace(
      workspaceId: 'ws-7',
      sourcePath: '/data/backups/x/ws-7/workspace.db',
    );

    expect(sent?['workspace_id'], 'ws-7');
    expect(sent?['source_path'], '/data/backups/x/ws-7/workspace.db');
  });
}
