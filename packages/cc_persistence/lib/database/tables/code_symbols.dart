import 'package:cc_persistence/database/tables/repos.dart'
    show ReposTable;
import 'package:cc_persistence/database/tables/workspaces.dart'
    show WorkspacesTable;
import 'package:drift/drift.dart';

/// Drift table for code symbols (functions, classes, methods, fields, …)
/// extracted from a repository's source by the tree-sitter indexer.
///
/// One row per symbol. [id] is a deterministic hash of
/// `workspaceId | repoId | filePath | qualifiedName` so re-indexing the same
/// symbol updates in place. [kind] stores a `CodeSymbolKind.name`. [embedding]
/// is an optional 384-d float32 vector (mirrors `memory_facts.embedding`)
/// populated when the on-device embedding model is available; NULL degrades
/// search to FTS-only.
///
/// Scoped by [workspaceId] as well as [repoId]: workspaces are isolated
/// worktrees that can share a repo (on different branches), so each workspace
/// owns its own graph rows — they must never collide or leak across workspaces.
@TableIndex(name: 'idx_code_symbols_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_code_symbols_repoId', columns: {#repoId})
@TableIndex(name: 'idx_code_symbols_filePath', columns: {#filePath})
@TableIndex(name: 'idx_code_symbols_qualifiedName', columns: {#qualifiedName})
@TableIndex(name: 'idx_code_symbols_kind', columns: {#kind})
class CodeSymbolsTable extends Table {
  /// Deterministic id: hash(workspaceId | repoId | filePath | qualifiedName).
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// Owning repository.
  TextColumn get repoId =>
      text().references(ReposTable, #id, onDelete: KeyAction.cascade)();

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

  /// Optional 384-d float32 embedding (bytes view of a Float32List buffer).
  BlobColumn get embedding => blob().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'code_symbols';

  @override
  Set<Column> get primaryKey => {id};
}
