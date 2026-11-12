import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:crypto/crypto.dart';

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

  /// Backs up only [workspaceId] into a workspace-scoped snapshot, without
  /// copying global data or any other workspace. Returns the `.db` file path.
  Future<String> backupWorkspace(String workspaceId);

  /// Deletes one whole-install snapshot by its listed directory [name].
  ///
  /// A path is never accepted; incomplete snapshots are deletable too.
  Future<void> deleteBackup(String name);

  /// Removes snapshots strictly older than [age]. With [workspaceId], only
  /// that workspace's scoped backups are touched; without it, only install
  /// snapshots are touched. Returns the number of directories removed.
  Future<int> deleteBackupsOlderThan({
    required Duration age,
    String? workspaceId,
  });

  /// Every snapshot [backupNow] has left behind, newest first.
  ///
  /// A snapshot the operator cannot find is a snapshot they do not have: the
  /// ops that make one and adopt one existed long before anything listed them,
  /// so restoring meant knowing the data directory's layout by heart. Reading
  /// is best-effort by design — a directory whose manifest is missing or
  /// unreadable is still REPORTED, with [BackupSnapshot.complete] false, since
  /// a half-written snapshot is exactly what an operator needs to see.
  Future<List<BackupSnapshot>> listBackups();

  /// Every scoped backup [backupWorkspace] has left for [workspaceId], newest
  /// first.
  ///
  /// Reuses [BackupSnapshot]: its [BackupSnapshot.workspaces] holds the one
  /// restorable file, or nothing when that file is missing or empty, which also
  /// makes [BackupSnapshot.complete] false.
  Future<List<BackupSnapshot>> listWorkspaceBackups(String workspaceId);

  /// The database file of scoped backup [name], or null when there is no
  /// such backup or it holds no real file. Names a backup, never a path.
  Future<String?> workspaceBackupFile(String workspaceId, String name);

  /// Deletes one scoped backup of [workspaceId] by its listed directory [name].
  Future<void> deleteWorkspaceBackup(String workspaceId, String name);

  /// Scoped backups left by workspaces that are no longer live, grouped by
  /// workspace. Nothing prunes these: a deleted workspace's schedule stops, so
  /// they stay until the install owner removes them.
  Future<List<OrphanedWorkspaceBackups>> listOrphanedWorkspaceBackups();

  /// [deleteWorkspaceBackup] for a workspace that is no longer live. Throws
  /// when [workspaceId] is live: those backups belong to that workspace's own
  /// roles, and being the install owner does not grant them.
  Future<void> deleteOrphanedWorkspaceBackup(String workspaceId, String name);

  /// Writes a snapshot of a single workspace and returns the absolute path of
  /// the `.db` file that was written.
  ///
  /// One workspace is one file, so exporting it is a single `VACUUM INTO`
  /// rather than a table-by-table dump. Throws if the workspace has no database.
  Future<String> exportWorkspace(String workspaceId);

  /// Adopts [sourcePath] (an export, or a workspace file of a snapshot) as the
  /// database of [workspaceId] and returns the workspace id.
  ///
  /// The file is somebody's bytes, not authority, even when it is this
  /// server's own snapshot: it is checked, brought to the declared schema
  /// and stripped of every grant it could have given itself before it
  /// replaces anything ([WorkspaceImportRefusedException] otherwise, with
  /// the workspace untouched). Grants it carried wait in
  /// [listImportHolds] for the server owner. [importedBy] (the server owner
  /// running the import) keeps or receives the owner membership.
  ///
  /// The workspace's current file is first copied into its own backups, so a
  /// restore can be undone. Everything else in the workspace directory
  /// (blobs, transcripts, sessions, checkouts) stays where it is.
  Future<String> importWorkspace({
    required String workspaceId,
    required String sourcePath,
    required String importedBy,
  });

  /// Grants an imported file carried that wait for the server owner, oldest
  /// first. Inert until accepted.
  Future<List<ImportedAuthorityHold>> listImportHolds(String workspaceId);

  /// Accepts ([accept] true: the grant becomes live again) or discards hold
  /// [holdId] of [workspaceId]. Throws `NotFoundException` for a hold that
  /// does not exist. Returns whether the grant was applied: a hold whose
  /// subject is gone (a member who left, a deleted repository) is dropped
  /// without applying anything.
  Future<bool> resolveImportHold({
    required String workspaceId,
    required String holdId,
    required bool accept,
  });
}

/// Why an import was refused. [kind] is the `data.kind` clients localize.
enum WorkspaceImportRefusal {
  /// No file at the source path.
  missingSource('import.missing_source'),

  /// SQLite cannot read the file, or its own check found it damaged.
  damaged('import.damaged'),

  /// The file differs from the checksum its snapshot manifest recorded.
  checksumMismatch('import.checksum_mismatch'),

  /// A newer server version wrote the file.
  newerSchema('import.newer_schema'),

  /// Not a workspace database this server could have written.
  foreignFile('import.foreign_file'),

  /// The file could not be brought to the declared schema.
  schemaMismatch('import.schema_mismatch'),

  /// A webhook, invite or other pre-auth key in the file already belongs to
  /// another workspace on this server.
  routeConflict('import.route_conflict');

  const WorkspaceImportRefusal(this.kind);

  /// The stable `data.kind`.
  final String kind;
}

/// An import refused before anything was replaced.
///
/// A validation failure whose [code] is [WorkspaceImportRefusal.kind], so
/// every lane that maps an [AppException] to a `data.kind` carries it.
/// [message] names neither paths nor ids: it reaches the client.
class WorkspaceImportRefusedException extends ValidationException {
  /// Creates the refusal.
  const WorkspaceImportRefusedException(
    this.refusal,
    super.message, {
    this.fileVersion,
    this.serverVersion,
  });

  /// Why.
  final WorkspaceImportRefusal refusal;

  @override
  String get code => refusal.kind;

  /// The file's schema version, for [WorkspaceImportRefusal.newerSchema].
  final int? fileVersion;

  /// This server's schema version, for [WorkspaceImportRefusal.newerSchema].
  final int? serverVersion;
}

/// What an imported grant would have granted.
enum ImportHoldKind {
  /// A rule of `action_policies` that allows or prompts.
  actionPolicy('action_policy'),

  /// A path of `sandbox_exec_grants` a sandbox may execute.
  sandboxExecGrant('sandbox_exec_grant'),

  /// A repository grant above read.
  repoGrant('repo_grant'),

  /// A membership role above member.
  membershipRole('membership_role'),

  /// An unredeemed invite to a role above member, or with repository
  /// grants above read.
  invite('invite');

  const ImportHoldKind(this.wire);

  /// Stored and wire name.
  final String wire;

  /// The kind named [wire], or null.
  static ImportHoldKind? fromWire(String wire) {
    for (final kind in values) {
      if (kind.wire == wire) {
        return kind;
      }
    }
    return null;
  }
}

/// A grant an imported workspace file carried, held out of its live table
/// until the server owner accepts or discards it.
class ImportedAuthorityHold {
  /// Creates a hold.
  const ImportedAuthorityHold({
    required this.id,
    required this.kind,
    required this.payload,
    required this.importedAt,
    required this.sourceInstallId,
  });

  /// Hold id.
  final String id;

  /// What it grants.
  final ImportHoldKind kind;

  /// The row as the file held it, by column name. An invite's code hash is
  /// left out: it is the key that redeems the invite.
  final Map<String, Object?> payload;

  /// When the import ran.
  final DateTime importedAt;

  /// The install the file says it came from.
  final String sourceInstallId;
}

/// The SHA-256 a snapshot manifest records per file, as lowercase hex.
Future<String> backupFileDigest(Stream<List<int>> bytes) async =>
    (await sha256.bind(bytes).first).toString();

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
    this.pinnedReason,
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

  /// Workspaces the backup did not capture (never written to, a damaged file
  /// that would not be copied over good ones, or a failed copy). Recorded so
  /// a thin snapshot is legible as such.
  final List<String> skippedWorkspaceIds;

  /// Whether the manifest is complete and of this format, and every file it
  /// names is present at its recorded size and passed its check when written.
  ///
  /// False marks a snapshot that died halfway — a backup interrupted by a
  /// crash or a full disk. It is still listed: hiding it is how an operator
  /// comes to believe they have a backup they do not.
  final bool complete;

  /// Why pruning keeps this snapshot whatever its age, or null when it ages
  /// out like any other. [lastGoodCopyPin]: it holds the newest verified copy
  /// of a workspace whose live file is damaged.
  final String? pinnedReason;

  /// [pinnedReason] of the newest verified copy of a damaged workspace.
  static const lastGoodCopyPin = 'last_good_copy';
}

/// The scoped backups of one workspace that is no longer live.
class OrphanedWorkspaceBackups {
  /// Creates an [OrphanedWorkspaceBackups].
  const OrphanedWorkspaceBackups({
    required this.workspaceId,
    required this.backups,
    this.workspaceName,
  });

  /// The workspace these backups hold.
  final String workspaceId;

  /// Its name, or null when the registry no longer knows the workspace.
  final String? workspaceName;

  /// Its backups, newest first.
  final List<BackupSnapshot> backups;
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
