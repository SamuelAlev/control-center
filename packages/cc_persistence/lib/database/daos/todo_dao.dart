import 'package:cc_persistence/database/tables/todos_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'todo_dao.g.dart';

/// Data access for per-conversation todo lists. Every read and mutation filters
/// by BOTH `workspaceId` and `conversationId` — an id-only query would leak
/// across conversations or workspaces.
@DriftAccessor(tables: [TodosTable])
class TodoDao extends DatabaseAccessor<WorkspaceDatabase> with _$TodoDaoMixin {
  /// Creates a [TodoDao].
  TodoDao(super.db);

  /// Watches the ordered todo list for a conversation.
  Stream<List<TodosTableData>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) =>
      (select(todosTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.conversationId.equals(conversationId),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.position),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  /// Returns the ordered todo list for a conversation.
  Future<List<TodosTableData>> getForConversation(
    String workspaceId,
    String conversationId,
  ) =>
      (select(todosTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.conversationId.equals(conversationId),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.position),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .get();

  /// Inserts or updates an item.
  Future<void> upsert(TodosTableCompanion entry) =>
      into(todosTable).insertOnConflictUpdate(entry);

  /// Updates the [status] (and touches [updatedAt]) of item [id], scoped by
  /// workspace + conversation. Returns rows affected.
  Future<int> updateStatus(
    String workspaceId,
    String conversationId,
    String id,
    String status,
    DateTime updatedAt,
  ) =>
      (update(todosTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.conversationId.equals(conversationId) &
                t.id.equals(id),
          ))
          .write(
            TodosTableCompanion(
              status: Value(status),
              updatedAt: Value(updatedAt),
            ),
          );

  /// Updates the [position] of item [id], scoped by workspace + conversation.
  Future<int> updatePosition(
    String workspaceId,
    String conversationId,
    String id,
    int position,
  ) =>
      (update(todosTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.conversationId.equals(conversationId) &
                t.id.equals(id),
          ))
          .write(TodosTableCompanion(position: Value(position)));

  /// Deletes item [id], scoped by workspace + conversation. Returns rows
  /// deleted (0 when the item belongs to another conversation/workspace).
  Future<int> deleteById(
    String workspaceId,
    String conversationId,
    String id,
  ) =>
      (delete(todosTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.conversationId.equals(conversationId) &
                t.id.equals(id),
          ))
          .go();

  /// Deletes all items for a conversation. Returns rows deleted.
  Future<int> deleteAll(String workspaceId, String conversationId) =>
      (delete(todosTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.conversationId.equals(conversationId),
          ))
          .go();

  /// Replaces the whole conversation list atomically.
  Future<void> replaceAll(
    String workspaceId,
    String conversationId,
    List<TodosTableCompanion> rows,
  ) => transaction(() async {
    await deleteAll(workspaceId, conversationId);
    await batch((b) => b.insertAll(todosTable, rows));
  });
}
