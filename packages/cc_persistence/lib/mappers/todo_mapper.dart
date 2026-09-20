import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [TodoItem] domain entities and `todos` table rows.
class TodoMapper {
  /// Creates a [TodoMapper].
  const TodoMapper();

  /// To domain.
  TodoItem toDomain(TodosTableData row) => TodoItem(
    id: row.id,
    workspaceId: row.workspaceId,
    conversationId: row.conversationId,
    content: row.content,
    status: TodoStatus.fromStorage(row.status),
    position: row.position,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  /// To domain list.
  List<TodoItem> toDomainList(List<TodosTableData> rows) =>
      rows.map(toDomain).toList(growable: false);

  /// To companion.
  TodosTableCompanion toCompanion(TodoItem item) => TodosTableCompanion(
    id: Value(item.id),
    workspaceId: Value(item.workspaceId),
    conversationId: Value(item.conversationId),
    content: Value(item.content),
    status: Value(item.status.storage),
    position: Value(item.position),
    createdAt: Value(item.createdAt),
    updatedAt: Value(item.updatedAt),
  );
}
