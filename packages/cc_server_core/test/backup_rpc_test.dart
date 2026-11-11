import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/backup/backup_rpc.dart';
import 'package:test/test.dart';

class _Backups implements DatabaseBackupPort {
  final imported = <String>[];

  @override
  Future<String> importWorkspace({
    required String workspaceId,
    required String sourcePath,
  }) async {
    imported.add(sourcePath);
    return workspaceId;
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
  });

  test('no port means no backup op at all', () {
    expect(buildBackupOps(databaseBackup: null), isEmpty);
  });
}
