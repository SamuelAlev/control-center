/// Lifecycle status of a conversation (stream) inside a space.
///
/// Conversations in a space are flat equals — there is no primary stream.
enum ConversationStatus {
  /// Open and shown in the conversation switcher.
  active('active'),

  /// Closed by the user: kept (messages preserved, reopenable) but hidden from
  /// the default switcher until reopened.
  archived('archived');

  const ConversationStatus(this.wire);

  /// The stable wire/storage string.
  final String wire;

  /// Parses a [ConversationStatus] from its [wire] string, defaulting to
  /// [active].
  static ConversationStatus fromWire(String? value) =>
      ConversationStatus.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => ConversationStatus.active,
      );

  /// Whether the conversation is archived (closed).
  bool get isArchived => this == ConversationStatus.archived;
}
