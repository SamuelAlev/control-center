import 'package:cc_persistence/database/tables/isolated_repos.dart'
    show IsolatedReposTable;
import 'package:cc_persistence/database/tables/repos.dart' show ReposTable;
import 'package:drift/drift.dart';

/// Drift table tracking indexed source files, for incremental re-indexing.
///
/// One row per indexed file. [contentHash] (SHA-256) lets the indexer skip
/// files whose content is unchanged since the last run. Scoped by
/// [workspaceId] as well as [repoId] so each workspace tracks its own
/// worktree's file state independently, and by [checkoutId] so each
/// conversation/PR worktree gets its own partition within that graph.
@TableIndex(name: 'idx_code_files_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_code_files_repoId', columns: {#repoId})
@TableIndex(name: 'idx_code_files_checkoutId', columns: {#checkoutId})
class CodeFilesTable extends Table {
  /// Deterministic id: hash(workspaceId | repoId | path) for the linked
  /// checkout; hash(workspaceId | repoId | checkoutId | path) for a worktree
  /// partition.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Owning repository.
  TextColumn get repoId =>
      text().references(ReposTable, #id, onDelete: KeyAction.cascade)();

  /// The checkout partition: NULL = the linked checkout, otherwise an
  /// `isolated_repos` row id. Cascades away with the worktree row, so a GC'd
  /// conversation/PR worktree takes its file-index state with it.
  TextColumn get checkoutId => text().nullable().references(
    IsolatedReposTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Repo-relative file path.
  TextColumn get path => text()();

  /// SHA-256 of the file content at last index time.
  TextColumn get contentHash => text()();

  /// Number of symbols extracted from this file.
  IntColumn get symbolCount => integer().withDefault(const Constant(0))();

  /// Source language id (e.g. `dart`).
  TextColumn get language => text().withDefault(const Constant(''))();

  /// Timestamp of the last successful index of this file.
  DateTimeColumn get indexedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'code_files';

  @override
  Set<Column> get primaryKey => {id};
}
