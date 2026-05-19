/// The kind of a conversation (stream) inside a channel.
///
/// Every channel has exactly one [main] conversation — its primary,
/// notification-bearing stream. Users can open additional [parenthesis]
/// conversations: temporary side streams that share the channel's worktree,
/// participants and autonomy but keep their own message history and agent
/// sessions, so a reviewer can "open a parenthesis" to quickly fix something
/// mid-review, then return. Parentheses are quiet: they never bump the channel
/// unread badge or fire an OS notification.
enum ConversationKind {
  /// The channel's primary conversation (exactly one per channel). Drives the
  /// channel unread badge and notifications.
  main('main'),

  /// A parallel side conversation ("parenthesis"): shares the channel worktree
  /// but has its own history + agent sessions; muted for badges/notifications.
  parenthesis('parenthesis');

  const ConversationKind(this.wire);

  /// The stable wire/storage string.
  final String wire;

  /// Parses a [ConversationKind] from its [wire] string, defaulting to [main].
  static ConversationKind fromWire(String? value) => ConversationKind.values
      .firstWhere((k) => k.wire == value, orElse: () => ConversationKind.main);

  /// Whether this is the channel's primary conversation.
  bool get isMain => this == ConversationKind.main;

  /// Whether this is a parenthesis (side conversation).
  bool get isParenthesis => this == ConversationKind.parenthesis;
}

/// Lifecycle status of a conversation.
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
