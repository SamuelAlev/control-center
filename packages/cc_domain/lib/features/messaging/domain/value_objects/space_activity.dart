import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:collection/collection.dart';

/// Per-space activity signals for the conversation list, computed
/// SERVER-side as one workspace-wide aggregate — the sidebar's unread dots,
/// needs-input badge and attention count read this instead of holding one
/// full message-list subscription per space row. Read state is per person
/// and per conversation (`ConversationReadRepository`); the client compares
/// it against [lastAgentMessageByConversation].
class SpaceActivity {
  /// Creates a [SpaceActivity].
  const SpaceActivity({
    required this.spaceId,
    this.lastMessageAt,
    this.lastAgentMessageByConversation = const {},
    this.openQuestionCount = 0,
    this.conversationsNeedingInput = const {},
  });

  /// The space these signals describe.
  final String spaceId;

  /// When the newest (non-reverted) message landed, or null for empty.
  final DateTime? lastMessageAt;

  /// Position of the newest agent message in each listed (not archived)
  /// conversation. Empty when the space has no agent messages. A
  /// conversation is unread when this is after the person's cursor there or
  /// they have none; the space is unread when any of its conversations is.
  final Map<String, FeedPosition> lastAgentMessageByConversation;

  /// Count of agent questions in the space still awaiting the user's answer —
  /// the needs-input signal.
  final int openQuestionCount;

  /// Whether an agent question awaits the user.
  bool get needsInput => openQuestionCount > 0;

  /// The conversations holding at least one of those open questions, so the
  /// sidebar can mark the conversation that asked, not every child.
  final Set<String> conversationsNeedingInput;

  /// Whether [conversationId] has an agent message unseen by a reader whose
  /// cursor there is [lastRead]. A conversation they never read is unread
  /// once an agent has written in it.
  bool conversationUnread(String conversationId, FeedPosition? lastRead) {
    final agent = lastAgentMessageByConversation[conversationId];
    return agent != null && (lastRead == null || agent.isAfter(lastRead));
  }

  /// Whether any listed conversation is unread for a reader with the cursors
  /// [reads], keyed by conversation id. The space keeps no read state of its
  /// own.
  bool unreadFor(Map<String, FeedPosition> reads) =>
      lastAgentMessageByConversation.keys.any(
        (id) => conversationUnread(id, reads[id]),
      );

  /// Wire shape for the `messaging.watchSpaceActivity` subscription.
  Map<String, dynamic> toJson() => {
    'space_id': spaceId,
    'last_message_at': ?lastMessageAt?.toIso8601String(),
    'open_question_count': openQuestionCount,
    if (lastAgentMessageByConversation.isNotEmpty)
      'conversations': [
        for (final e in lastAgentMessageByConversation.entries)
          {'conversation_id': e.key, 'last_agent_message': e.value.toJson()},
      ],
    if (conversationsNeedingInput.isNotEmpty)
      'needs_input_conversations': [...conversationsNeedingInput],
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
      lastAgentMessageByConversation: conversations,
      openQuestionCount: (json['open_question_count'] as num?)?.toInt() ?? 0,
      conversationsNeedingInput: {
        if (json['needs_input_conversations'] case final List ids)
          for (final id in ids)
            if (id is String) id,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpaceActivity &&
          spaceId == other.spaceId &&
          lastMessageAt == other.lastMessageAt &&
          openQuestionCount == other.openQuestionCount &&
          const SetEquality<String>().equals(
            conversationsNeedingInput,
            other.conversationsNeedingInput,
          ) &&
          const MapEquality<String, FeedPosition>().equals(
            lastAgentMessageByConversation,
            other.lastAgentMessageByConversation,
          );

  @override
  int get hashCode => Object.hash(
    spaceId,
    lastMessageAt,
    openQuestionCount,
    const SetEquality<String>().hash(conversationsNeedingInput),
    const MapEquality<String, FeedPosition>().hash(
      lastAgentMessageByConversation,
    ),
  );
}
