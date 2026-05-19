import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';

/// Repository for per-space todo lists.
///
/// Every method is double-scoped: it requires both a `workspaceId` (the
/// isolation boundary) and a `spaceId` (the space the list belongs to).
/// Neither is ever optional or implicitly resolved — a foreign row must
/// simply not be found.
abstract interface class TodoRepository {
  /// Watches the ordered todo list for a space.
  Stream<List<TodoItem>> watch(String workspaceId, String spaceId);

  /// Returns the ordered todo list for a space.
  Future<List<TodoItem>> list(String workspaceId, String spaceId);

  /// Replaces the space's entire list with [items] (full-list semantics).
  /// Positions are assigned by list order.
  Future<void> replaceAll(
    String workspaceId,
    String spaceId,
    List<TodoItem> items,
  );

  /// Appends a new pending item with [content] at the end of the list and
  /// returns it.
  Future<TodoItem> append(String workspaceId, String spaceId, String content);

  /// Sets the [status] of the item [id] within the space.
  Future<void> updateStatus(
    String workspaceId,
    String spaceId,
    String id,
    TodoStatus status,
  );

  /// Removes the item [id] from the space.
  Future<void> remove(String workspaceId, String spaceId, String id);

  /// Reorders the space's items to match [orderedIds].
  Future<void> reorder(
    String workspaceId,
    String spaceId,
    List<String> orderedIds,
  );

  /// Removes all items from the space.
  Future<void> clear(String workspaceId, String spaceId);

  /// Watches the space's working goal, or null when none is set. The todos
  /// render nested beneath it in the General pane.
  Stream<ConversationGoal?> watchGoal(String workspaceId, String spaceId);

  /// Sets (creating or replacing) the space's goal to [title]. A blank
  /// [title] clears the goal instead. A space has at most one goal.
  Future<void> setGoal(String workspaceId, String spaceId, String title);

  /// Clears the space's goal (the todos fall back to the flat list).
  Future<void> clearGoal(String workspaceId, String spaceId);
}
