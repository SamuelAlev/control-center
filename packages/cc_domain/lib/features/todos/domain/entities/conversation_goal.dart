/// A single working goal for a space.
///
/// A space has at most ONE goal at a time (the store is keyed by [spaceId]).
/// Set via `/goal`, it is the objective the space's todos work toward — the
/// todos render nested beneath it in the General pane. It is deliberately NOT
/// a todo row (the agent's `todo_write` replaces the whole todo list and would
/// clobber it) and NOT a field on the space row itself (that rides the
/// messaging sync/serialization backbone). Scoped to exactly one workspace
/// ([workspaceId], the isolation boundary).
class ConversationGoal {
  /// Creates a [ConversationGoal].
  ConversationGoal({
    required this.spaceId,
    required this.workspaceId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Goal title must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError('workspaceId must not be empty');
    }
    if (spaceId.isEmpty) {
      throw ArgumentError('spaceId must not be empty');
    }
  }

  /// Owning space — the primary key (one goal per space).
  final String spaceId;

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
    String? spaceId,
    String? workspaceId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationGoal(
      spaceId: spaceId ?? this.spaceId,
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
          spaceId == other.spaceId &&
          workspaceId == other.workspaceId &&
          title == other.title &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(spaceId, workspaceId, title, createdAt, updatedAt);
}
