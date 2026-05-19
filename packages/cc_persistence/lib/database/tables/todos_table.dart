import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// Drift table for per-space todo lists.
///
/// A todo belongs to exactly one space ([spaceId] references the `spaces`
/// table) inside exactly one workspace ([workspaceId], the isolation
/// boundary). Every read filters by both. Deleting a space or workspace
/// cascades its todos. Ordering within a space is stable via [position].
@TableIndex(name: 'idx_todos_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_todos_space', columns: {#workspaceId, #spaceId})
class TodosTable extends Table {
  /// Unique item identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Owning space (a space owns one worktree and one task list).
  TextColumn get spaceId =>
      text().references(SpacesTable, #id, onDelete: KeyAction.cascade)();

  /// The task description.
  TextColumn get content => text()();

  /// Lifecycle status: `pending`, `in_progress`, or `completed`.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Stable ascending sort order within the space.
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// When the item was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the item was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'todos';

  @override
  Set<Column> get primaryKey => {id};
}
