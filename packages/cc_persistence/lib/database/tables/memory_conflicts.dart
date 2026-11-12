import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:cc_persistence/database/tables/memory_facts.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_conflicts_factA', columns: {#factAId})
@TableIndex(name: 'idx_memory_conflicts_factB', columns: {#factBId})
@TableIndex(name: 'idx_memory_conflicts_winner', columns: {#winningFactId})
/// Workspace-scoped record of a detected contradiction between two facts.
class MemoryConflictsTable extends Table {
  /// Unique conflict identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// One side of the conflict (the loser, by convention, once resolved).
  /// `ON DELETE CASCADE`: a conflict is about both facts and means nothing
  /// once either is gone.
  @ReferenceName('conflictsAsA')
  TextColumn get factAId =>
      text().references(MemoryFactsTable, #id, onDelete: KeyAction.cascade)();

  /// The other side (the winner, by convention, once resolved).
  /// `ON DELETE CASCADE`, as [factAId].
  @ReferenceName('conflictsAsB')
  TextColumn get factBId =>
      text().references(MemoryFactsTable, #id, onDelete: KeyAction.cascade)();

  /// Conflict kind: `contradiction` or `cross_agent` (`MemoryConflict.types`).
  TextColumn get conflictType => text()
      .check(
        // ignore: recursive_getters
        conflictType.isIn(SpacesStoredValues.conflictType),
      )
      .withDefault(const Constant('contradiction'))();

  /// How it was resolved (`superseded`, `MemoryConflict.resolutions`), or
  /// null while open.
  TextColumn get resolution => text().nullable().check(
    // ignore: recursive_getters
    resolution.isIn(SpacesStoredValues.conflictResolution),
  )();

  /// The fact that won, or null while open. `ON DELETE SET NULL`, though
  /// the winner is one of the two sides, whose delete already removes the
  /// conflict.
  @ReferenceName('conflictsWon')
  TextColumn get winningFactId => text().nullable().references(
    MemoryFactsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// When it was resolved, or null while open.
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  /// When the conflict was first detected.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'memory_conflicts';

  @override
  Set<Column> get primaryKey => {id};
}
