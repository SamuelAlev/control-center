import 'package:cc_persistence/database/tables/repos.dart'
    show ReposTable;
import 'package:cc_persistence/database/tables/workspaces.dart'
    show WorkspacesTable;
import 'package:drift/drift.dart';

/// Drift table tracking indexed source files, for incremental re-indexing.
///
/// One row per indexed file. [contentHash] (SHA-256) lets the indexer skip
/// files whose content is unchanged since the last run. Scoped by
/// [workspaceId] as well as [repoId] so each workspace tracks its own
/// worktree's file state independently.
@TableIndex(name: 'idx_code_files_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_code_files_repoId', columns: {#repoId})
class CodeFilesTable extends Table {
  /// Deterministic id: hash(workspaceId | repoId | path).
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// Owning repository.
  TextColumn get repoId =>
      text().references(ReposTable, #id, onDelete: KeyAction.cascade)();

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
