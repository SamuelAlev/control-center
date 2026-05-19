import 'package:drift/drift.dart';

/// Drift table recording every execution of a per-repo lifecycle script
/// (setup after a space's worktree is provisioned, archive before it is
/// destroyed).
///
/// **Workspace-scoped**: like `repos` this lives in the workspace's own
/// database file, which is why the `workspace_id` column is redundant inside
/// the file — it keeps the row self-describing and lets server-side services
/// log without threading the database handle into every layer.
///
/// A row exists only when a script was actually configured and executed;
/// unset scripts produce no rows. [outputText] is a bounded tail written by
/// the executor (throttled while live, final write on exit), not the full
/// stream.
@TableIndex(
  name: 'idx_repo_script_runs_repo',
  columns: {#workspaceId, #repoId, #startedAt},
)
@TableIndex(name: 'idx_repo_script_runs_space', columns: {#workspaceId, #spaceId})
class RepoScriptRunsTable extends Table {
  /// Unique run identifier.
  TextColumn get id => text()();

  /// Owning workspace (never null — the isolation boundary).
  TextColumn get workspaceId => text()();

  /// The space whose worktree the script ran in.
  TextColumn get spaceId => text()();

  /// The registered repo the script belongs to.
  TextColumn get repoId => text()();

  /// Display name of the repo at run time (rows outlive repo renames).
  TextColumn get repoName => text()();

  /// Which lifecycle moment: `setup` | `archive`.
  TextColumn get kind => text()();

  /// Outcome: `running` | `succeeded` | `failed` | `timed_out`.
  TextColumn get status => text()();

  /// When the script started.
  DateTimeColumn get startedAt => dateTime()();

  /// When the script finished, or null while running.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Process exit code (null while running or when killed by a signal).
  IntColumn get exitCode => integer().nullable()();

  /// Short failure summary (timeout, spawn error); not the output tail.
  TextColumn get error => text().nullable()();

  /// Bounded captured stdout+stderr tail, interleaved.
  TextColumn get outputText => text().nullable()();

  @override
  String get tableName => 'repo_script_runs';

  @override
  Set<Column> get primaryKey => {id};
}
