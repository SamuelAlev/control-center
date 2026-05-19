import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_conflicts_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_memory_conflicts_factA', columns: {#factAId})
/// Workspace-scoped record of a detected contradiction between two facts.
class MemoryConflictsTable extends Table {
  /// Unique conflict identifier.
  TextColumn get id => text()();
  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  /// One side of the conflict (the loser, by convention, once resolved).
  TextColumn get factAId => text()();
  /// The other side (the winner, by convention, once resolved).
  TextColumn get factBId => text()();
  /// Conflict kind. Currently always `contradiction`.
  TextColumn get conflictType =>
      text().withDefault(const Constant('contradiction'))();
  /// How it was resolved (e.g. `superseded`), or null while open.
  TextColumn get resolution => text().nullable()();
  /// The fact that won, or null while open.
  TextColumn get winningFactId => text().nullable()();
  /// When it was resolved, or null while open.
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  /// When the conflict was first detected.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}