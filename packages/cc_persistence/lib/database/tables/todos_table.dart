import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:drift/drift.dart';

/// Drift table for per-conversation todo lists.
///
/// A todo belongs to exactly one conversation ([conversationId] references the
/// `conversations` table) inside exactly one workspace ([workspaceId], the
/// isolation boundary). Every read filters by both. Deleting a conversation
/// or workspace cascades its todos. Ordering within a conversation is stable
/// via [position].
@TableIndex(name: 'idx_todos_workspaceId', columns: {#workspaceId})
@TableIndex(
  name: 'idx_todos_conversation',
  columns: {#workspaceId, #conversationId},
)
class TodosTable extends Table {
  /// Unique item identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Owning conversation (a conversation owns one stream and one task list).
  TextColumn get conversationId => text().references(
    ConversationsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The task description.
  TextColumn get content => text()();

  /// Lifecycle status: `pending`, `in_progress`, or `completed`.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Stable ascending sort order within the conversation.
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
