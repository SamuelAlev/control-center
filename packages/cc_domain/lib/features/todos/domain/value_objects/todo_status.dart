/// Lifecycle status of a single todo item in a conversation's task list.
///
/// The [storage] strings deliberately match the vocabulary the agent-facing
/// `todo_write` tool has always used (`pending`, `in_progress`, `completed`),
/// so the tool schema and model prompts are unchanged when the list became
/// persisted.
enum TodoStatus {
  /// Not started yet.
  pending('pending'),

  /// Actively being worked on. Exactly one item is usually in progress.
  inProgress('in_progress'),

  /// Finished.
  completed('completed');

  /// Creates a [TodoStatus] with its wire/DB [storage] representation.
  const TodoStatus(this.storage);

  /// The value serialized to the database and the RPC wire.
  final String storage;

  /// Whether this is a terminal status.
  bool get isDone => this == TodoStatus.completed;

  /// Parses a stored value, defaulting to [pending] for anything unknown.
  static TodoStatus fromStorage(String? value) =>
      TodoStatus.values.where((s) => s.storage == value).firstOrNull ??
      TodoStatus.pending;
}
