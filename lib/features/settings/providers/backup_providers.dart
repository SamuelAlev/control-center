import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One snapshot as `server.listBackups` or `workspace.listBackups` reports it.
///
/// Every path in here is a path on the SERVER's filesystem. That distinction is
/// load-bearing rather than pedantic: a phone or a browser tab talking to a
/// server across the house cannot open any of them, so the UI shows a path to
/// copy and never offers to reveal one. It is also why the client does no file
/// work of its own — the databases belong to `cc_server` and so does every
/// operation on them.
class BackupSnapshotView {
  /// Creates a [BackupSnapshotView].
  const BackupSnapshotView({
    required this.path,
    required this.name,
    this.createdAt,
    this.bytes = 0,
    this.complete = true,
    this.workspaces = const [],
    this.skippedWorkspaceIds = const [],
  });

  /// Decodes one `server.listBackups` entry.
  factory BackupSnapshotView.fromJson(Map<String, dynamic> json) =>
      BackupSnapshotView(
        path: json['path'] as String? ?? '',
        name: json['name'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
        bytes: (json['bytes'] as num?)?.toInt() ?? 0,
        complete: json['complete'] as bool? ?? false,
        workspaces: [
          for (final entry in (json['workspaces'] as List?) ?? const [])
            if (entry is Map)
              BackupSnapshotWorkspaceView.fromJson(
                entry.cast<String, dynamic>(),
              ),
        ],
        skippedWorkspaceIds: [
          for (final id in (json['skipped_workspace_ids'] as List?) ?? const [])
            if (id is String) id,
        ],
      );

  /// Absolute path of the snapshot directory on the server host.
  final String path;

  /// The directory's own name — the timestamp it was written under.
  final String name;

  /// When it was taken, or null when the manifest could not be read.
  final DateTime? createdAt;

  /// Total bytes on disk.
  final int bytes;

  /// Whether the manifest parsed and every file it names is present. False
  /// marks a snapshot that died halfway, which is shown rather than hidden.
  final bool complete;

  /// The workspaces captured in it, each restorable on its own.
  final List<BackupSnapshotWorkspaceView> workspaces;

  /// Workspaces the backup could not capture.
  final List<String> skippedWorkspaceIds;
}

/// One workspace's file inside a [BackupSnapshotView].
class BackupSnapshotWorkspaceView {
  /// Creates a [BackupSnapshotWorkspaceView].
  const BackupSnapshotWorkspaceView({
    required this.workspaceId,
    required this.path,
    this.bytes = 0,
  });

  /// Decodes one entry of a snapshot's `workspaces` list.
  factory BackupSnapshotWorkspaceView.fromJson(Map<String, dynamic> json) =>
      BackupSnapshotWorkspaceView(
        workspaceId: json['workspace_id'] as String? ?? '',
        path: json['path'] as String? ?? '',
        bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      );

  /// The workspace this file holds.
  final String workspaceId;

  /// Absolute path of the `.db` file on the server host — what a restore hands
  /// straight back to `workspace.import`.
  final String path;

  /// Size of the file.
  final int bytes;
}

/// Every snapshot on the server, newest first.
///
/// Deliberately a plain [FutureProvider] rather than a watch stream: snapshots
/// change only when someone takes or removes one, and the server publishes no
/// change feed for the backups directory. The actions below invalidate it, so
/// the list is fresh exactly when it can have changed.
final backupSnapshotsProvider =
    FutureProvider.autoDispose<List<BackupSnapshotView>>((ref) async {
      final data = await ref
          .watch(rpcClientProvider)
          .call('server.listBackups', const {});
      return [
        for (final entry in (data['backups'] as List?) ?? const [])
          if (entry is Map)
            BackupSnapshotView.fromJson(entry.cast<String, dynamic>()),
      ];
    });

/// One workspace's scheduled backups, newest first.
///
/// Per workspace because the server gates it per workspace: a refused one fails
/// its own row and leaves the others readable. Pipelines write these with no
/// change feed, so like [backupSnapshotsProvider] it reloads with the page.
final workspaceBackupsProvider = FutureProvider.autoDispose
    .family<List<BackupSnapshotView>, String>((ref, workspaceId) async {
      final data = await ref.watch(rpcClientProvider).call(
        'workspace.listBackups',
        {'workspace_id': workspaceId},
      );
      return [
        for (final entry in (data['backups'] as List?) ?? const [])
          if (entry is Map)
            BackupSnapshotView.fromJson(entry.cast<String, dynamic>()),
      ];
    });

/// Scheduled backups left by a workspace that is no longer live.
class OrphanedWorkspaceBackupsView {
  /// Creates an [OrphanedWorkspaceBackupsView].
  const OrphanedWorkspaceBackupsView({
    required this.workspaceId,
    required this.backups,
    this.workspaceName,
  });

  /// Decodes one `server.listOrphanedBackups` entry.
  factory OrphanedWorkspaceBackupsView.fromJson(Map<String, dynamic> json) =>
      OrphanedWorkspaceBackupsView(
        workspaceId: json['workspace_id'] as String? ?? '',
        workspaceName: json['workspace_name'] as String?,
        backups: [
          for (final entry in (json['backups'] as List?) ?? const [])
            if (entry is Map)
              BackupSnapshotView.fromJson(entry.cast<String, dynamic>()),
        ],
      );

  /// The workspace these backups hold.
  final String workspaceId;

  /// Its name, or null when the registry no longer knows it.
  final String? workspaceName;

  /// Its backups, newest first.
  final List<BackupSnapshotView> backups;
}

/// Every deleted workspace that still has scheduled backups on the server.
///
/// Install-owner only: anyone else is refused, which is the normal answer for
/// them rather than a failure.
final orphanedWorkspaceBackupsProvider =
    FutureProvider.autoDispose<List<OrphanedWorkspaceBackupsView>>((ref) async {
      final data = await ref
          .watch(rpcClientProvider)
          .call('server.listOrphanedBackups', const {});
      return [
        for (final entry in (data['workspaces'] as List?) ?? const [])
          if (entry is Map)
            OrphanedWorkspaceBackupsView.fromJson(
              entry.cast<String, dynamic>(),
            ),
      ];
    });

/// The backup, export, import and delete actions, in one place.
final backupActionsProvider = Provider<BackupActions>(BackupActions.new);

/// Server-side data operations the operator can trigger.
///
/// Thin by construction: each method is one RPC call and an invalidation. The
/// server owns the databases, so it owns snapshotting, exporting, adopting and
/// deleting them — the client's whole job is to ask and to say what happened.
class BackupActions {
  /// Creates a [BackupActions] bound to [_ref].
  BackupActions(this._ref);

  final Ref _ref;

  /// Snapshots the whole install. Returns the snapshot directory's path.
  Future<String> backupNow() async {
    final data = await _ref
        .read(rpcClientProvider)
        .call('server.backupNow', const {});
    _ref.invalidate(backupSnapshotsProvider);
    return data['path'] as String? ?? '';
  }

  /// Deletes one listed whole-install snapshot by immutable name, not path.
  Future<void> deleteBackup(String name) async {
    try {
      await _ref.read(rpcClientProvider).call('server.deleteBackup', {
        'name': name,
      });
    } finally {
      // A partial filesystem removal may fail after changing the listing.
      _ref.invalidate(backupSnapshotsProvider);
    }
  }

  /// Deletes one scheduled backup of a live workspace by its listed name.
  Future<void> deleteWorkspaceBackup({
    required String workspaceId,
    required String name,
  }) async {
    try {
      await _ref.read(rpcClientProvider).call('workspace.deleteBackup', {
        'workspace_id': workspaceId,
        'name': name,
      });
    } finally {
      _ref.invalidate(workspaceBackupsProvider(workspaceId));
    }
  }

  /// Deletes one scheduled backup of a workspace that is no longer live.
  Future<void> deleteOrphanedBackup({
    required String workspaceId,
    required String name,
  }) async {
    try {
      await _ref.read(rpcClientProvider).call('server.deleteOrphanedBackup', {
        'workspace_id': workspaceId,
        'name': name,
      });
    } finally {
      _ref.invalidate(orphanedWorkspaceBackupsProvider);
    }
  }

  /// Exports [workspaceId] as a single file. Returns the file's path.
  ///
  /// Requires admin on that workspace, which is why the id travels explicitly
  /// rather than riding the client's active workspace: this page lists every
  /// workspace, and the one being exported is rarely the one being viewed.
  Future<String> exportWorkspace(String workspaceId) async {
    final data = await _ref.read(rpcClientProvider).call('workspace.export', {
      'workspace_id': workspaceId,
    });
    return data['path'] as String? ?? '';
  }

  /// Adopts [sourcePath] as [workspaceId]'s database, replacing what is there.
  ///
  /// Owner-only server-side and irreversible for the target, so every caller
  /// confirms first. [sourcePath] is a path on the SERVER host — either one
  /// this page read out of a snapshot, or one the operator supplied.
  Future<void> importWorkspace({
    required String workspaceId,
    required String sourcePath,
  }) async {
    await _ref.read(rpcClientProvider).call('workspace.import', {
      'workspace_id': workspaceId,
      'source_path': sourcePath,
    });
  }

  /// Soft-deletes [workspaceId].
  ///
  /// The registry row is marked and the workspace leaves every list and lookup,
  /// but its directory and database file stay on disk — backups and retention
  /// sweeps still visit them and nothing reclaims the space automatically. The
  /// confirmation copy says so; a "delete" that silently keeps the data is the
  /// one thing this surface must not imply.
  Future<void> deleteWorkspace(String workspaceId) =>
      _ref.read(workspaceRepositoryProvider).delete(workspaceId);
}
