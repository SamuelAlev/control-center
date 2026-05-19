/// Port for taking an on-demand, consistent snapshot of the server's databases.
///
/// The implementation (cc_persistence) uses SQLite `VACUUM INTO`, which is safe
/// on a live WAL database — it produces a defragmented, transactionally
/// consistent copy without the corruption risk of a raw file copy. The server
/// binds it so a `server.backupNow` RPC op can trigger a snapshot; a client
/// never touches the DB directly.
///
/// A snapshot is a DIRECTORY, not a file: persistence is split into `global.db`
/// plus one file per workspace, so a backup is that set of files alongside a
/// manifest describing them.
abstract interface class DatabaseBackupPort {
  /// Writes a fresh, consistent snapshot of every database and returns the
  /// absolute path of the directory that was written. Throws on failure.
  Future<String> backupNow();

  /// Every snapshot [backupNow] has left behind, newest first.
  ///
  /// A snapshot the operator cannot find is a snapshot they do not have: the
  /// ops that make one and adopt one existed long before anything listed them,
  /// so restoring meant knowing the data directory's layout by heart. Reading
  /// is best-effort by design — a directory whose manifest is missing or
  /// unreadable is still REPORTED, with [BackupSnapshot.complete] false, since
  /// a half-written snapshot is exactly what an operator needs to see.
  Future<List<BackupSnapshot>> listBackups();

  /// Writes a snapshot of a single workspace and returns the absolute path of
  /// the `.db` file that was written.
  ///
  /// One workspace is one file, so exporting it is a single `VACUUM INTO`
  /// rather than a table-by-table dump. Throws if the workspace has no database.
  Future<String> exportWorkspace(String workspaceId);

  /// Adopts [sourcePath] — a file produced by [exportWorkspace] — as the
  /// database of [workspaceId], replacing any existing one and returns the
  /// workspace id.
  ///
  /// The file is validated before it is adopted: it must be a readable SQLite
  /// database carrying a `workspace_meta` row. Its recorded workspace id may
  /// differ from [workspaceId] (importing a copy under a new id is legitimate);
  /// its recorded install id may differ too (a file from another install) and
  /// both are reported rather than silently accepted. Throws if the file is not
  /// a workspace database.
  Future<String> importWorkspace({
    required String workspaceId,
    required String sourcePath,
  });
}

/// One snapshot directory written by [DatabaseBackupPort.backupNow].
///
/// The shape mirrors the manifest, because the manifest is what makes a set of
/// files a snapshot rather than a pile of them.
class BackupSnapshot {
  /// Creates a [BackupSnapshot].
  const BackupSnapshot({
    required this.path,
    required this.name,
    required this.bytes,
    required this.workspaces,
    this.createdAt,
    this.skippedWorkspaceIds = const [],
    this.complete = true,
  });

  /// Absolute path of the snapshot directory on the SERVER host.
  final String path;

  /// The directory's own name — the timestamp the snapshot was written under.
  final String name;

  /// When the snapshot was taken, from the manifest. Null when it could not be
  /// read, which is also why [complete] would be false.
  final DateTime? createdAt;

  /// Total size of every file in the snapshot.
  final int bytes;

  /// The workspaces captured in it.
  final List<BackupSnapshotWorkspace> workspaces;

  /// Workspaces the backup could not capture (never written to, or a failed
  /// `VACUUM INTO`). Recorded so a thin snapshot is legible as such.
  final List<String> skippedWorkspaceIds;

  /// Whether the manifest parsed and every file it names is present.
  ///
  /// False marks a snapshot that died halfway — a backup interrupted by a
  /// crash or a full disk. It is still listed: hiding it is how an operator
  /// comes to believe they have a backup they do not.
  final bool complete;
}

/// One workspace's file inside a [BackupSnapshot].
class BackupSnapshotWorkspace {
  /// Creates a [BackupSnapshotWorkspace].
  const BackupSnapshotWorkspace({
    required this.workspaceId,
    required this.path,
    required this.bytes,
  });

  /// The workspace this file holds.
  final String workspaceId;

  /// Absolute path of the `.db` file on the server host — what
  /// [DatabaseBackupPort.importWorkspace] takes as its `sourcePath`, which is
  /// what makes "restore this workspace from this snapshot" the existing
  /// import op rather than a second mechanism.
  final String path;

  /// Size of the file.
  final int bytes;
}
