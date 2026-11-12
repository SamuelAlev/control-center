import 'package:drift/drift.dart';

/// Drift table tracking indexed source files, for incremental re-indexing.
///
/// One row per indexed file. [contentHash] (SHA-256) lets the indexer skip
/// files whose content is unchanged since the last run. Partitioned by
/// [repoId] and by [checkoutId], so each conversation/PR worktree tracks its
/// own file state. Lives in a workspace's `code_index.db`: no workspace
/// column, no foreign key into `workspace.db`.
@TableIndex(
  name: 'idx_code_files_partition_path',
  columns: {#repoId, #checkoutId, #path},
)
class CodeFilesTable extends Table {
  /// Deterministic content-addressed id (see `code_graph_ids`); the
  /// worktree partition's ids add a checkoutId segment.
  TextColumn get id => text()();

  /// The repository (`repos.id` in `workspace.db`).
  TextColumn get repoId => text()();

  /// The checkout partition: NULL = the linked checkout, otherwise an
  /// `isolated_repos` row id.
  TextColumn get checkoutId => text().nullable()();

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
