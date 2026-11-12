import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:collection/collection.dart';

/// Per-space activity signals for the conversation list, computed
/// SERVER-side as one workspace-wide aggregate — the sidebar's unread dot,
/// needs-input badge and attention count read this instead of holding one
/// full message-list subscription per space row.
class SpaceActivity {
  /// Creates a [SpaceActivity].
  const SpaceActivity({
    required this.spaceId,
    this.lastMessageAt,
    this.lastAgentMessage,
    this.lastAgentMessageByConversation = const {},
    this.openQuestionCount = 0,
  });

  /// The space these signals describe.
  final String spaceId;

  /// When the newest (non-reverted) message landed, or null for empty.
  final DateTime? lastMessageAt;

  /// Position of the newest agent message in the space (any conversation —
  /// the signals are space-wide) — the unread-dot signal on a space that
  /// does not list its conversations. It is unseen when it
  /// [FeedPosition.isAfter] the user's read cursor.
  final FeedPosition? lastAgentMessage;

  /// Position of the newest agent message in each conversation. Empty when
  /// the space has no agent messages. The sidebar uses this to put the unread
  /// dot on the conversation that actually has unseen work, not on every
  /// child and not only on the parent space.
  final Map<String, FeedPosition> lastAgentMessageByConversation;

  /// Count of agent questions in the space still awaiting the user's answer —
  /// the needs-input signal.
  final int openQuestionCount;

  /// Whether an agent question awaits the user.
  bool get needsInput => openQuestionCount > 0;

  /// Whether the newest agent message is unseen by a reader whose cursor is
  /// [lastRead]. A null cursor (never opened) is never unread.
  bool unreadAfter(FeedPosition? lastRead) {
    final agent = lastAgentMessage;
    return lastRead != null && agent != null && agent.isAfter(lastRead);
  }

  /// Wire shape for the `messaging.watchSpaceActivity` subscription.
  Map<String, dynamic> toJson() => {
    'space_id': spaceId,
    'last_message_at': ?lastMessageAt?.toIso8601String(),
    'last_agent_message': ?lastAgentMessage?.toJson(),
    'open_question_count': openQuestionCount,
    if (lastAgentMessageByConversation.isNotEmpty)
      'conversations': [
        for (final e in lastAgentMessageByConversation.entries)
          {'conversation_id': e.key, 'last_agent_message': e.value.toJson()},
      ],
  };

  /// Decodes the wire shape; returns null when malformed.
  static SpaceActivity? fromJson(Map<String, dynamic> json) {
    final spaceId = json['space_id'];
    if (spaceId is! String) {
      return null;
    }
    final conversations = <String, FeedPosition>{};
    final raw = json['conversations'];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) {
          continue;
        }
        final id = item['conversation_id'];
        final position = FeedPosition.fromJson(item['last_agent_message']);
        if (id is String && position != null) {
          conversations[id] = position;
        }
      }
    }
    return SpaceActivity(
      spaceId: spaceId,
      lastMessageAt: DateTime.tryParse(
        json['last_message_at'] as String? ?? '',
      ),
      lastAgentMessage: FeedPosition.fromJson(json['last_agent_message']),
      lastAgentMessageByConversation: conversations,
      openQuestionCount: (json['open_question_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpaceActivity &&
          spaceId == other.spaceId &&
          lastMessageAt == other.lastMessageAt &&
          lastAgentMessage == other.lastAgentMessage &&
          openQuestionCount == other.openQuestionCount &&
          const MapEquality<String, FeedPosition>().equals(
            lastAgentMessageByConversation,
            other.lastAgentMessageByConversation,
          );

  @override
  int get hashCode => Object.hash(
    spaceId,
    lastMessageAt,
    lastAgentMessage,
    openQuestionCount,
    const MapEquality<String, FeedPosition>().hash(
      lastAgentMessageByConversation,
    ),
  );
}
