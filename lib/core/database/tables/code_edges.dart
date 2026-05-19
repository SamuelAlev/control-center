import 'package:control_center/core/database/tables/repos.dart'
    show ReposTable;
import 'package:control_center/core/database/tables/workspaces.dart'
    show WorkspacesTable;
import 'package:drift/drift.dart';

/// Drift table for relationships between code symbols (the code graph's edges).
///
/// [sourceSymbolId] / [targetSymbolId] are logical references to
/// `code_symbols.id` — intentionally NOT hard foreign keys, because a target
/// may live in an unindexed file or external package and is resolved
/// best-effort. When the target is unresolved, [targetSymbolId] is NULL and
/// [targetName] carries the raw callee name / import URI for a later
/// name-resolution pass. [kind] stores a `CodeEdgeKind.name`.
///
/// Scoped by [workspaceId] as well as [repoId] so edges never cross workspace
/// boundaries (workspaces are isolated worktrees that may share a repo).
@TableIndex(name: 'idx_code_edges_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_code_edges_repoId', columns: {#repoId})
@TableIndex(name: 'idx_code_edges_source', columns: {#sourceSymbolId})
@TableIndex(name: 'idx_code_edges_target', columns: {#targetSymbolId})
@TableIndex(name: 'idx_code_edges_kind', columns: {#kind})
class CodeEdgesTable extends Table {
  /// Deterministic id: hash(workspaceId | repoId | source | target-or-name | kind).
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// Owning repository.
  TextColumn get repoId =>
      text().references(ReposTable, #id, onDelete: KeyAction.cascade)();

  /// `code_symbols.id` of the edge source (or a `<file>` pseudo-id for imports).
  TextColumn get sourceSymbolId => text()();

  /// Repo-relative path of the file the source symbol lives in. Lets the
  /// indexer delete a file's edges in one statement during incremental
  /// re-index (edges otherwise carry no file path).
  TextColumn get sourceFilePath => text().withDefault(const Constant(''))();

  /// Resolved `code_symbols.id` of the target, when known.
  TextColumn get targetSymbolId => text().nullable()();

  /// Unresolved target name / import URI (set when [targetSymbolId] is NULL).
  TextColumn get targetName => text().nullable()();

  /// `CodeEdgeKind.name`.
  TextColumn get kind => text()();

  /// Optional JSON metadata (e.g. call-site line).
  TextColumn get metadata => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'code_edges';

  @override
  Set<Column> get primaryKey => {id};
}
