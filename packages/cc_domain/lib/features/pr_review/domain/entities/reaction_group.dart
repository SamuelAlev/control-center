/// Reaction group.
class ReactionGroup {
  /// Creates a [ReactionGroup].
  const ReactionGroup({
    required this.content,
    required this.emoji,
    required this.count,
    required this.userReacted,
    this.usernames = const [],
  });

  /// Reaction content key.
  final String content;

  /// Reaction emoji.
  final String emoji;

  /// Number of users who reacted.
  final int count;

  /// Whether the current user has reacted.
  final bool userReacted;

  /// Usernames of users who reacted.
  final List<String> usernames;

  /// Returns a copy with the given overrides applied.
  ReactionGroup copyWith({
    int? count,
    bool? userReacted,
    List<String>? usernames,
  }) => ReactionGroup(
    content: content,
    emoji: emoji,
    count: count ?? this.count,
    userReacted: userReacted ?? this.userReacted,
    usernames: usernames ?? this.usernames,
  );

  /// Supported reaction types.
  static const supportedReactions = <({String content, String emoji})>[
    (content: '+1', emoji: '👍'),
    (content: '-1', emoji: '👎'),
    (content: 'laugh', emoji: '😄'),
    (content: 'hooray', emoji: '🎉'),
    (content: 'confused', emoji: '😕'),
    (content: 'heart', emoji: '❤️'),
    (content: 'rocket', emoji: '🚀'),
    (content: 'eyes', emoji: '👀'),
  ];

  /// Returns the emoji for a given reaction content key.
  static String emojiForContent(String content) {
    for (final r in supportedReactions) {
      if (r.content == content) {
        return r.emoji;
      }
    }
    return '';
  }

  /// Equality comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReactionGroup &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          emoji == other.emoji &&
          count == other.count &&
          userReacted == other.userReacted &&
          _listEquals(usernames, other.usernames);

  /// Hash code.

  @override
  int get hashCode => Object.hash(
    content,
    emoji,
    count,
    userReacted,
    Object.hashAll(usernames),
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
