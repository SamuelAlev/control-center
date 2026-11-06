import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/backup/backup_rpc.dart';
import 'package:test/test.dart';

class _Backups implements DatabaseBackupPort {
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

  test('no port means no backup op at all', () {
    expect(buildBackupOps(databaseBackup: null), isEmpty);
  });
}
