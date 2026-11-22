import 'package:cc_domain/core/domain/value_objects/feed_position.dart';

/// Read-cursor port for conversations.
///
/// Each person keeps their own cursor per conversation, so one member reading
/// a conversation never clears another's unread state, and reading one
/// conversation of a space leaves its other conversations unread. A space
/// keeps no read state: it is unread when one of its listed conversations is.
abstract class ConversationReadRepository {
  /// Moves [userId]'s cursor in [conversationId] within [workspaceId] to the
  /// newest message in that conversation.
  Future<void> markConversationRead(
    String workspaceId,
    String conversationId,
    String userId,
  );

  /// Watches [userId]'s cursors across [workspaceId]'s conversations, keyed
  /// by conversation id. A conversation missing from the map has never been
  /// read by that user. An agent message is unseen when its position
  /// [FeedPosition.isAfter] the cursor.
  Stream<Map<String, FeedPosition>> watchUserConversationReads(
    String workspaceId,
    String userId,
  );
}
