import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// Drift table for per-space working goals.
///
/// A space has at most ONE goal — [spaceId] is the primary key, so setting a
/// new goal replaces the prior one. The goal belongs to exactly one workspace
/// ([workspaceId], the isolation boundary); every read filters by both.
/// Deleting a space or workspace cascades its goal. Isolated from the `todos`
/// table on purpose: the agent's `todo_write` replaces the whole todo list and
/// would otherwise clobber the goal.
@TableIndex(name: 'idx_conversation_goals_workspaceId', columns: {#workspaceId})
class ConversationGoalsTable extends Table {
  /// Owning space — one goal per space.
  TextColumn get spaceId =>
      text().references(SpacesTable, #id, onDelete: KeyAction.cascade)();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The goal statement.
  TextColumn get title => text()();

  /// When the goal was first set.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the goal was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'conversation_goals';

  @override
  Set<Column> get primaryKey => {spaceId};
}
