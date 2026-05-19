/// Per-channel activity signals for the conversation list, computed
/// SERVER-side as one workspace-wide aggregate — the sidebar's unread dot,
/// needs-input badge, and attention count read this instead of holding one
/// full message-list subscription per channel row.
class ChannelActivity {
  /// Creates a [ChannelActivity].
  const ChannelActivity({
    required this.channelId,
    this.lastMessageAt,
    this.lastAgentMessageAt,
    this.openQuestionCount = 0,
  });

  /// The channel these signals describe.
  final String channelId;

  /// When the newest (non-reverted) message landed, or null for empty.
  final DateTime? lastMessageAt;

  /// When the newest agent message in the channel's `main` conversation landed
  /// — the unread-dot signal (compared against the user's read cursor).
  final DateTime? lastAgentMessageAt;

  /// Count of agent questions in the `main` conversation still awaiting the
  /// user's answer — the needs-input signal.
  final int openQuestionCount;

  /// Whether an agent question awaits the user.
  bool get needsInput => openQuestionCount > 0;

  /// Wire shape for the `messaging.watchChannelActivity` subscription.
  Map<String, dynamic> toJson() => {
    'channel_id': channelId,
    'last_message_at': ?lastMessageAt?.toIso8601String(),
    'last_agent_message_at': ?lastAgentMessageAt?.toIso8601String(),
    'open_question_count': openQuestionCount,
  };

  /// Decodes the wire shape; returns null when malformed.
  static ChannelActivity? fromJson(Map<String, dynamic> json) {
    final channelId = json['channel_id'];
    if (channelId is! String) {
      return null;
    }
    return ChannelActivity(
      channelId: channelId,
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
      other is ChannelActivity &&
          channelId == other.channelId &&
          lastMessageAt == other.lastMessageAt &&
          lastAgentMessageAt == other.lastAgentMessageAt &&
          openQuestionCount == other.openQuestionCount;

  @override
  int get hashCode => Object.hash(
    channelId,
    lastMessageAt,
    lastAgentMessageAt,
    openQuestionCount,
  );
}
