/// Who performed or authored something recorded in a workspace: the stored
/// `*_actor_type` / `author_type` / `author_kind` values of governance and
/// work-product rows.
enum ActorKind {
  /// A person.
  user,

  /// An agent.
  agent,

  /// The server itself (a scheduler, a materializer, a sweep).
  system;

  /// Stable storage string.
  String get wire => name;

  /// The value stored as [value]; throws [ArgumentError] for any other
  /// string, so a writer cannot store a value the column refuses.
  static ActorKind parse(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'not a ActorKind'),
  );
}
