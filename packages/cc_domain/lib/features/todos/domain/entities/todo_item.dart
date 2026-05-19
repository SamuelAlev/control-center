import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';

/// A single item in a conversation's persisted task list.
///
/// Todos are scoped to exactly one conversation ([conversationId] == the
/// channel id) inside exactly one workspace ([workspaceId], the isolation
/// boundary). Ordering within a conversation is stable via [position].
class TodoItem {
  /// Creates a [TodoItem].
  TodoItem({
    required this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.content,
    this.status = TodoStatus.pending,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (content.trim().isEmpty) {
      throw ArgumentError('Todo content must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError('workspaceId must not be empty');
    }
    if (conversationId.isEmpty) {
      throw ArgumentError('conversationId must not be empty');
    }
  }

  /// Unique item identifier.
  final String id;

  /// Owning workspace (the isolation boundary).
  final String workspaceId;

  /// Owning conversation (channel id).
  final String conversationId;

  /// The task description.
  final String content;

  /// Lifecycle status.
  final TodoStatus status;

  /// Stable sort order within the conversation (ascending).
  final int position;

  /// When the item was created.
  final DateTime createdAt;

  /// When the item was last updated.
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  TodoItem copyWith({
    String? id,
    String? workspaceId,
    String? conversationId,
    String? content,
    TodoStatus? status,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      status: status ?? this.status,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          conversationId == other.conversationId &&
          content == other.content &&
          status == other.status &&
          position == other.position &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    conversationId,
    content,
    status,
    position,
    createdAt,
    updatedAt,
  );
}
