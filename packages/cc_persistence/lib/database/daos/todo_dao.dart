import 'package:cc_persistence/database/tables/todos_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'todo_dao.g.dart';

/// Data access for per-space todo lists. Every read and mutation filters by
/// BOTH `workspaceId` and `spaceId` — an id-only query would leak across
/// spaces or workspaces.
@DriftAccessor(tables: [TodosTable])
class TodoDao extends DatabaseAccessor<WorkspaceDatabase> with _$TodoDaoMixin {
  /// Creates a [TodoDao].
  TodoDao(super.db);

  /// Watches the ordered todo list for a space.
  Stream<List<TodosTableData>> watchForSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(todosTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.spaceId.equals(spaceId),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.position),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  /// Returns the ordered todo list for a space.
  Future<List<TodosTableData>> getForSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(todosTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.spaceId.equals(spaceId),
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
  /// workspace + space. Returns rows affected.
  Future<int> updateStatus(
    String workspaceId,
    String spaceId,
    String id,
    String status,
    DateTime updatedAt,
  ) =>
      (update(todosTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId) &
                t.id.equals(id),
          ))
          .write(
            TodosTableCompanion(
              status: Value(status),
              updatedAt: Value(updatedAt),
            ),
          );

  /// Updates the [position] of item [id], scoped by workspace + space.
  Future<int> updatePosition(
    String workspaceId,
    String spaceId,
    String id,
    int position,
  ) =>
      (update(todosTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId) &
                t.id.equals(id),
          ))
          .write(TodosTableCompanion(position: Value(position)));

  /// Deletes item [id], scoped by workspace + space. Returns rows deleted
  /// (0 when the item belongs to another space/workspace).
  Future<int> deleteById(
    String workspaceId,
    String spaceId,
    String id,
  ) =>
      (delete(todosTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId) &
                t.id.equals(id),
          ))
          .go();

  /// Deletes all items for a space. Returns rows deleted.
  Future<int> deleteAll(String workspaceId, String spaceId) =>
      (delete(todosTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId),
          ))
          .go();

  /// Replaces the whole space list atomically.
  Future<void> replaceAll(
    String workspaceId,
    String spaceId,
    List<TodosTableCompanion> rows,
  ) => transaction(() async {
    await deleteAll(workspaceId, spaceId);
    await batch((b) => b.insertAll(todosTable, rows));
  });
}
