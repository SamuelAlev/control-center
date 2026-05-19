import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';

/// Repository for per-conversation todo lists.
///
/// Every method is double-scoped: it requires both a `workspaceId` (the
/// isolation boundary) and a `conversationId` (the channel the list belongs
/// to). Neither is ever optional or implicitly resolved — a foreign row must
/// simply not be found.
abstract interface class TodoRepository {
  /// Watches the ordered todo list for a conversation.
  Stream<List<TodoItem>> watch(String workspaceId, String conversationId);

  /// Returns the ordered todo list for a conversation.
  Future<List<TodoItem>> list(String workspaceId, String conversationId);

  /// Replaces the conversation's entire list with [items] (full-list
  /// semantics). Positions are assigned by list order.
  Future<void> replaceAll(
    String workspaceId,
    String conversationId,
    List<TodoItem> items,
  );

  /// Appends a new pending item with [content] at the end of the list and
  /// returns it.
  Future<TodoItem> append(
    String workspaceId,
    String conversationId,
    String content,
  );

  /// Sets the [status] of the item [id] within the conversation.
  Future<void> updateStatus(
    String workspaceId,
    String conversationId,
    String id,
    TodoStatus status,
  );

  /// Removes the item [id] from the conversation.
  Future<void> remove(String workspaceId, String conversationId, String id);

  /// Reorders the conversation's items to match [orderedIds].
  Future<void> reorder(
    String workspaceId,
    String conversationId,
    List<String> orderedIds,
  );

  /// Removes all items from the conversation.
  Future<void> clear(String workspaceId, String conversationId);

  /// Watches the conversation's working goal, or null when none is set. The
  /// todos render nested beneath it in the General pane.
  Stream<ConversationGoal?> watchGoal(
    String workspaceId,
    String conversationId,
  );

  /// Sets (creating or replacing) the conversation's goal to [title]. A blank
  /// [title] clears the goal instead. A conversation has at most one goal.
  Future<void> setGoal(String workspaceId, String conversationId, String title);

  /// Clears the conversation's goal (the todos fall back to the flat list).
  Future<void> clearGoal(String workspaceId, String conversationId);
}
