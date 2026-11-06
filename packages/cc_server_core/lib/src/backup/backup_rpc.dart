import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart';

/// The whole-install snapshot lane and the per-workspace export/import pair
/// (`server.backupNow`, `server.listBackups`, `server.deleteBackup`,
/// `server.listOrphanedBackups`, `server.deleteOrphanedBackup`,
/// `workspace.listBackups`, `workspace.deleteBackup`, `workspace.export`,
/// `workspace.import`).
///
/// Extracted from `remote_rpc_catalog.dart` into an `extraOps` pack so the
/// catalog does not grow (QUALITY.md R10). Empty when the host wires no
/// [DatabaseBackupPort] (default-deny; the demo runtime wires none).
List<RepoOp> buildBackupOps({required DatabaseBackupPort? databaseBackup}) {
  if (databaseBackup == null) {
    return const [];
  }
  return [
    // Writes a consistent snapshot of every database (VACUUM INTO per file) and
    // returns the snapshot DIRECTORY's path. NOT workspace-scoped — it captures
    // the whole install — and fullClient-only so a companion phone can never
    // trigger it.
    RepoOp(
      name: 'server.backupNow',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      // A snapshot captures EVERY workspace's database, so it is owner-only
      // like the `/backup/snapshot` HTTP route — being an admin of one
      // workspace must not be a way to copy all the others. This lane
      // shipped with no owner gate at all: any paired full client could
      // snapshot the whole install over RPC while the HTTP twin was gated.
      serverAuthority: ServerAuthority.serverOwner,
      handler: (ctx) async {
        final path = await databaseBackup.backupNow();
        return {'ok': true, 'path': path};
      },
    ),
    // Lists the snapshots already on disk, newest first. Same lane and same
    // gate as taking one: a caller allowed to write a whole-install snapshot is
    // not further protected by being unable to see the ones that exist — and
    // without this, restoring meant knowing the data directory by heart, which
    // is why the backup surface had no UI for years.
    RepoOp(
      name: 'server.listBackups',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      // Same authority as taking one: the listing names whole-install
      // snapshot paths on the server's disk.
      serverAuthority: ServerAuthority.serverOwner,
      handler: (ctx) async {
        final snapshots = await databaseBackup.listBackups();
        return {
          'backups': [for (final s in snapshots) backupSnapshotToWire(s)],
        };
      },
    ),
    // Removes one listed install snapshot, including interrupted snapshots.
    // Never accepts a path from the client: persistence validates the immutable
    // timestamp name and resolves it strictly under its configured backup root.
    RepoOp(
      name: 'server.deleteBackup',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      serverAuthority: ServerAuthority.serverOwner,
      requiredArgs: ['name'],
      handler: (ctx) async {
        await databaseBackup.deleteBackup(ctx.args['name'] as String);
        return {'ok': true};
      },
    ),
    // Lists the scheduled backups of ONE workspace, newest first. Same gate as
    // exporting it: each entry names a file holding that workspace's entire
    // history, so the install-wide `server.listBackups` lane stays out of it.
    // Each entry's `workspaces[0].path` is what `workspace.import` takes back.
    RepoOp(
      name: 'workspace.listBackups',
      kind: RepoOpKind.read,
      minRole: WorkspaceRole.admin,
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        final backups = await databaseBackup.listWorkspaceBackups(
          ctx.workspaceId!,
        );
        return {
          'backups': [for (final b in backups) backupSnapshotToWire(b)],
        };
      },
    ),
    // Removes one scheduled backup. Owner, like restoring: it destroys a
    // recovery point. Takes the listed name, never a path; persistence resolves
    // it strictly under this workspace's own backups.
    RepoOp(
      name: 'workspace.deleteBackup',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.owner,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: ['name'],
      handler: (ctx) async {
        await databaseBackup.deleteWorkspaceBackup(
          ctx.workspaceId!,
          ctx.args['name'] as String,
        );
        return {'ok': true};
      },
    ),
    // Backups left by workspaces that are no longer live. A deleted workspace
    // cannot pass a workspace-scoped gate, and its schedule has stopped, so
    // without this lane the files stay on disk with nobody able to see them.
    // Owner-only for the same reason as the snapshot lane above.
    RepoOp(
      name: 'server.listOrphanedBackups',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      serverAuthority: ServerAuthority.serverOwner,
      handler: (ctx) async {
        final orphans = await databaseBackup.listOrphanedWorkspaceBackups();
        return {
          'workspaces': [
            for (final o in orphans)
              {
                'workspace_id': o.workspaceId,
                if (o.workspaceName != null) 'workspace_name': o.workspaceName,
                'backups': [for (final b in o.backups) backupSnapshotToWire(b)],
              },
          ],
        };
      },
    ),
    // Refuses a live workspace in persistence: this lane has no workspace role
    // check, so it must not reach backups that have one.
    RepoOp(
      name: 'server.deleteOrphanedBackup',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      serverAuthority: ServerAuthority.serverOwner,
      requiredArgs: ['workspace_id', 'name'],
      handler: (ctx) async {
        await databaseBackup.deleteOrphanedWorkspaceBackup(
          ctx.args['workspace_id'] as String,
          ctx.args['name'] as String,
        );
        return {'ok': true};
      },
    ),
    // Exports ONE workspace as a single file. Workspace-scoped (the operator
    // exports the workspace they are in) and fullClient-only: the file contains
    // that workspace's entire history, so handing out its path is an operator
    // action, not something a companion phone does.
    RepoOp(
      name: 'workspace.export',
      kind: RepoOpKind.read,
      minRole: WorkspaceRole.admin,
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        final path = await databaseBackup.exportWorkspace(ctx.workspaceId!);
        return {'ok': true, 'path': path};
      },
    ),
    // Adopts a previously exported file as this workspace's database, REPLACING
    // whatever is there. Destructive and irreversible for the target workspace,
    // so it is owner-only on top of fullClient. The file is validated as a
    // workspace database before anything is replaced.
    RepoOp(
      name: 'workspace.import',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.owner,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: ['source_path'],
      handler: (ctx) async {
        final id = await databaseBackup.importWorkspace(
          workspaceId: ctx.workspaceId!,
          sourcePath: ctx.args['source_path'] as String,
        );
        return {'ok': true, 'workspace_id': id};
      },
    ),
  ];
}
