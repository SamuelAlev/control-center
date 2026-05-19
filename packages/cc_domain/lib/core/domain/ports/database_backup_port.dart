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
