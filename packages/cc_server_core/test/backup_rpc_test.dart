import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/backup/backup_rpc.dart';
import 'package:test/test.dart';

class _Backups implements DatabaseBackupPort {
  final imported = <String>[];
  final importers = <String>[];
  final resolved = <({String holdId, bool accept})>[];

  @override
  Future<String> importWorkspace({
    required String workspaceId,
    required String sourcePath,
    required String importedBy,
  }) async {
    imported.add(sourcePath);
    importers.add(importedBy);
    return workspaceId;
  }

  @override
  Future<List<ImportedAuthorityHold>> listImportHolds(
    String workspaceId,
  ) async => [
    ImportedAuthorityHold(
      id: 'hold-1',
      kind: ImportHoldKind.membershipRole,
      payload: const {'user_id': 'u-2', 'role': 'admin'},
      importedAt: DateTime.utc(2026, 11, 12, 9),
      sourceInstallId: 'install-x',
    ),
  ];

  @override
  Future<bool> resolveImportHold({
    required String workspaceId,
    required String holdId,
    required bool accept,
  }) async {
    resolved.add((holdId: holdId, accept: accept));
    return accept;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final ops = {
    for (final op in buildBackupOps(databaseBackup: _Backups())) op.name: op,
  };

  test('workspace backups are gated like exporting the workspace', () {
    final list = ops['workspace.listBackups']!;
    final export = ops['workspace.export']!;

    expect(list.workspaceScoped, isTrue);
    expect(list.minRole, WorkspaceRole.admin);
    expect(list.minRole, export.minRole);
    expect(list.requiredCapability, SessionCapability.fullClient);
    expect(list.requiredCapability, export.requiredCapability);
  });

  test('deleting a workspace backup needs the owner, like restoring', () {
    final delete = ops['workspace.deleteBackup']!;

    expect(delete.workspaceScoped, isTrue);
    expect(delete.minRole, WorkspaceRole.owner);
    expect(delete.minRole, ops['workspace.import']!.minRole);
    expect(delete.requiredCapability, SessionCapability.fullClient);
    expect(delete.requiredArgs, ['name']);
  });

  test('backups of deleted workspaces belong to the install owner', () {
    for (final name in [
      'server.listOrphanedBackups',
      'server.deleteOrphanedBackup',
    ]) {
      final op = ops[name]!;
      expect(op.workspaceScoped, isFalse, reason: name);
      expect(op.serverAuthority, ServerAuthority.serverOwner, reason: name);
      expect(op.requiredCapability, SessionCapability.fullClient, reason: name);
    }
  });

  test('importing names a file on the host, so it needs the server owner '
      'as well as the workspace owner', () async {
    final backups = _Backups();
    final dispatcher = RepoOpDispatcher(
      registry: RepoOpRegistry(buildBackupOps(databaseBackup: backups)),
      resolveServerOwner: (userId) async => userId == 'server-owner',
      workspaceExists: (_) async => true,
      resolveRole: (_, userId) async => WorkspaceRole.owner,
    );
    Future<Map<String, dynamic>> import(String userId) => dispatcher.call(
      id: 1,
      params: {
        'op': 'workspace.import',
        'args': {
          'workspace_id': 'ws-1',
          // Another workspace's backup on the same host.
          'source_path': '/data/ws-2/backups/latest.db',
        },
      },
      deviceId: 'device',
      userId: userId,
      sessionCapability: SessionCapability.fullClient,
    );

    final refused = await import('workspace-owner');
    final error = refused['error'] as Map;
    expect(error['code'], RpcErrorCodes.unauthorized);
    expect((error['data'] as Map)['kind'], 'server_owner_required');
    expect(backups.imported, isEmpty);

    final allowed = await import('server-owner');
    expect(allowed['error'], isNull);
    expect(backups.imported, ['/data/ws-2/backups/latest.db']);
    // The import runs on behalf of the caller, who keeps the owner role in
    // the file it adopts.
    expect(backups.importers, ['server-owner']);
  });

  test('import holds are the server owner\'s to list and resolve, never a '
      'workspace admin\'s or owner\'s', () async {
    for (final name in [
      'workspace.importHolds.list',
      'workspace.importHolds.resolve',
    ]) {
      final op = ops[name]!;
      expect(op.workspaceScoped, isTrue, reason: name);
      expect(op.minRole, WorkspaceRole.owner, reason: name);
      expect(op.serverAuthority, ServerAuthority.serverOwner, reason: name);
      expect(op.requiredCapability, SessionCapability.fullClient, reason: name);
    }

    final backups = _Backups();
    final dispatcher = RepoOpDispatcher(
      registry: RepoOpRegistry(buildBackupOps(databaseBackup: backups)),
      resolveServerOwner: (userId) async => userId == 'server-owner',
      workspaceExists: (_) async => true,
      resolveRole: (_, userId) async => switch (userId) {
        'workspace-admin' => WorkspaceRole.admin,
        _ => WorkspaceRole.owner,
      },
    );
    Future<Map<String, dynamic>> call(
      String userId,
      String op, [
      Map<String, Object?> args = const {},
    ]) => dispatcher.call(
      id: 1,
      params: {
        'op': op,
        'args': {'workspace_id': 'ws-1', ...args},
      },
      deviceId: 'device',
      userId: userId,
      sessionCapability: SessionCapability.fullClient,
    );

    for (final userId in ['workspace-admin', 'workspace-owner']) {
      final listed = await call(userId, 'workspace.importHolds.list');
      final resolve = await call(userId, 'workspace.importHolds.resolve', {
        'hold_id': 'hold-1',
        'accept': true,
      });
      for (final refused in [listed, resolve]) {
        final error = refused['error'] as Map;
        expect(error['code'], RpcErrorCodes.unauthorized, reason: userId);
      }
      if (userId == 'workspace-owner') {
        expect(
          ((listed['error'] as Map)['data'] as Map)['kind'],
          'server_owner_required',
        );
      }
    }
    expect(backups.resolved, isEmpty);

    final listed = await call('server-owner', 'workspace.importHolds.list');
    expect(listed['error'], isNull);
    final holds = ((listed['result'] as Map)['data'] as Map)['holds'] as List;
    expect(holds.single, {
      'id': 'hold-1',
      'kind': 'membership_role',
      'payload': {'user_id': 'u-2', 'role': 'admin'},
      'imported_at': '2026-11-12T09:00:00.000Z',
      'source_install_id': 'install-x',
    });

    final accepted = await call(
      'server-owner',
      'workspace.importHolds.resolve',
      {'hold_id': 'hold-1', 'accept': true},
    );
    expect((accepted['result'] as Map)['data'], {'ok': true, 'applied': true});
    final discarded = await call(
      'server-owner',
      'workspace.importHolds.resolve',
      {'hold_id': 'hold-1', 'accept': false},
    );
    expect((discarded['result'] as Map)['data'], {
      'ok': true,
      'applied': false,
    });
    final malformed = await call(
      'server-owner',
      'workspace.importHolds.resolve',
      {'hold_id': 'hold-1', 'accept': 'yes'},
    );
    // Refused before the port is called (the mapper, absent here, makes it
    // a validation error).
    expect(malformed['error'], isNotNull);
    expect(backups.resolved, [
      (holdId: 'hold-1', accept: true),
      (holdId: 'hold-1', accept: false),
    ]);
  });

  test('a listed snapshot names why pruning keeps it', () {
    const snapshot = BackupSnapshot(
      path: '/data/backups/workspace-backups/ws-1/2026-11-12T09-00-00-000Z',
      name: '2026-11-12T09-00-00-000Z',
      bytes: 4096,
      workspaces: [],
      pinnedReason: BackupSnapshot.lastGoodCopyPin,
    );
    expect(backupToWire(snapshot)['pinned_reason'], 'last_good_copy');
    expect(
      backupToWire(
        const BackupSnapshot(path: '/p', name: 'n', bytes: 0, workspaces: []),
      ).containsKey('pinned_reason'),
      isFalse,
    );
  });

  test('no port means no backup op at all', () {
    expect(buildBackupOps(databaseBackup: null), isEmpty);
  });
}
