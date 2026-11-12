import 'package:drift/drift.dart';

/// Drift table for code symbols (functions, classes, methods, fields, …)
/// extracted from a repository's source by the tree-sitter indexer.
///
/// One row per symbol. [id] is deterministic, so re-indexing the same symbol
/// updates in place.
/// [kind] stores a `CodeSymbolKind.name`. The symbol's vector, when the
/// on-device embedding model has produced one, is a row of
/// `code_symbol_embeddings`; without it search degrades to FTS-only.
///
/// Lives in a workspace's `code_index.db`, which holds that one workspace's
/// index and nothing else, so the rows carry no workspace column. [repoId]
/// and [checkoutId] name rows of `workspace.db`; they are not foreign keys
/// because a key cannot cross files. Removing a repo or a checkout deletes
/// its partition here explicitly.
@TableIndex(
  name: 'idx_code_symbols_partition_file',
  columns: {#repoId, #checkoutId, #filePath},
)
@TableIndex(name: 'idx_code_symbols_name', columns: {#name})
@TableIndex(name: 'idx_code_symbols_qualifiedName', columns: {#qualifiedName})
class CodeSymbolsTable extends Table {
  /// Deterministic content-addressed id (see `code_graph_ids`); the
  /// worktree partition's ids add a checkoutId segment.
  TextColumn get id => text()();

  /// The repository (`repos.id` in `workspace.db`).
  TextColumn get repoId => text()();

  /// The checkout partition: NULL = the linked checkout, otherwise an
  /// `isolated_repos` row id of `workspace.db` (one conversation/PR worktree).
  TextColumn get checkoutId => text().nullable()();

  /// `CodeSymbolKind.name`.
  TextColumn get kind => text()();

  /// Simple (unqualified) symbol name.
  TextColumn get name => text()();

  /// Fully-qualified name (e.g. `PipelineEngine.start`).
  TextColumn get qualifiedName => text()();

  /// Repo-relative source file path.
  TextColumn get filePath => text()();

  /// Source language id (e.g. `dart`).
  TextColumn get language => text()();

  /// 1-based start line of the symbol's span.
  IntColumn get startLine => integer()();

  /// 1-based end line of the symbol's span.
  IntColumn get endLine => integer()();

  /// Declaration signature, when extractable.
  TextColumn get signature => text().withDefault(const Constant(''))();

  /// Leading doc comment, when present.
  TextColumn get docstring => text().nullable()();

  /// Qualified name of the lexically enclosing symbol, when any.
  TextColumn get parentName => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'code_symbols';

  @override
  Set<Column> get primaryKey => {id};
}
