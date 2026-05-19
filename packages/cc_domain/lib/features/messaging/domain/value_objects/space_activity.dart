/// Per-space activity signals for the conversation list, computed
/// SERVER-side as one workspace-wide aggregate — the sidebar's unread dot,
/// needs-input badge and attention count read this instead of holding one
/// full message-list subscription per space row.
class SpaceActivity {
  /// Creates a [SpaceActivity].
  const SpaceActivity({
    required this.spaceId,
    this.lastMessageAt,
    this.lastAgentMessageAt,
    this.openQuestionCount = 0,
  });

  /// The space these signals describe.
  final String spaceId;

  /// When the newest (non-reverted) message landed, or null for empty.
  final DateTime? lastMessageAt;

  /// When the newest agent message in the space landed (any conversation —
  /// the signals are space-wide) — the unread-dot signal (compared against
  /// the user's read cursor).
  final DateTime? lastAgentMessageAt;

  /// Count of agent questions in the space still awaiting the user's answer —
  /// the needs-input signal.
  final int openQuestionCount;

  /// Whether an agent question awaits the user.
  bool get needsInput => openQuestionCount > 0;

  /// Wire shape for the `messaging.watchSpaceActivity` subscription.
  Map<String, dynamic> toJson() => {
    'space_id': spaceId,
    'last_message_at': ?lastMessageAt?.toIso8601String(),
    'last_agent_message_at': ?lastAgentMessageAt?.toIso8601String(),
    'open_question_count': openQuestionCount,
  };

  /// Decodes the wire shape; returns null when malformed.
  static SpaceActivity? fromJson(Map<String, dynamic> json) {
    final spaceId = json['space_id'];
    if (spaceId is! String) {
      return null;
    }
    return SpaceActivity(
      spaceId: spaceId,
      lastMessageAt: DateTime.tryParse(
        json['last_message_at'] as String? ?? '',
      ),
      lastAgentMessageAt: DateTime.tryParse(
        json['last_agent_message_at'] as String? ?? '',
      ),
      openQuestionCount: (json['open_question_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpaceActivity &&
          spaceId == other.spaceId &&
          lastMessageAt == other.lastMessageAt &&
          lastAgentMessageAt == other.lastAgentMessageAt &&
          openQuestionCount == other.openQuestionCount;

  @override
  int get hashCode => Object.hash(
    spaceId,
    lastMessageAt,
    lastAgentMessageAt,
    openQuestionCount,
  );
}
