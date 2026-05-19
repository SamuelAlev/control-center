/// A single working goal for a conversation.
///
/// A conversation has at most ONE goal at a time (the store is keyed by
/// [conversationId]). Set via `/goal`, it is the objective the conversation's
/// todos work toward — the todos render nested beneath it in the General pane.
/// It is deliberately NOT a todo row (the agent's `todo_write` replaces the
/// whole todo list and would clobber it) and NOT a field on the channel (that
/// rides the messaging sync/serialization backbone). Scoped to exactly one
/// workspace ([workspaceId], the isolation boundary).
class ConversationGoal {
  /// Creates a [ConversationGoal].
  ConversationGoal({
    required this.conversationId,
    required this.workspaceId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(title.trim() != '', 'Goal title must not be empty'),
       assert(workspaceId != '', 'workspaceId must not be empty'),
       assert(conversationId != '', 'conversationId must not be empty');

  /// Owning conversation (channel id) — the primary key (one goal per chat).
  final String conversationId;

  /// Owning workspace (the isolation boundary).
  final String workspaceId;

  /// The goal statement.
  final String title;

  /// When the goal was first set.
  final DateTime createdAt;

  /// When the goal was last updated.
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  ConversationGoal copyWith({
    String? conversationId,
    String? workspaceId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationGoal(
      conversationId: conversationId ?? this.conversationId,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationGoal &&
          runtimeType == other.runtimeType &&
          conversationId == other.conversationId &&
          workspaceId == other.workspaceId &&
          title == other.title &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(conversationId, workspaceId, title, createdAt, updatedAt);
}
