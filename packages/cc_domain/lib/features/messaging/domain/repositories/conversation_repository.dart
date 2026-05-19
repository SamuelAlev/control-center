import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_kind.dart';

/// Repository for channel conversations (the [Conversation] streams inside a
/// channel).
///
/// Every method is workspace-scoped: `workspaceId` is required and reads filter
/// on it, so a foreign conversation is simply not found (workspace-isolation
/// invariant). Conversation ids are UUIDs but that is NOT the isolation
/// boundary.
abstract interface class ConversationRepository {
  /// Ensures the channel's `main` conversation exists and returns it. Idempotent
  /// (safe to call on every channel open); creates the `main` row on first use.
  Future<Conversation> ensureMain({
    required String workspaceId,
    required String channelId,
  });

  /// Creates a new conversation (typically a parenthesis) in [channelId].
  Future<Conversation> create({
    required String workspaceId,
    required String channelId,
    required String title,
    required Conversation conversation,
  });

  /// Renames a conversation. Rejects on cross-workspace mismatch.
  Future<void> rename({
    required String workspaceId,
    required String conversationId,
    required String title,
  });

  /// Archives (closes) a conversation. Messages are kept and the conversation
  /// is reopenable. Rejects on cross-workspace mismatch.
  Future<void> setStatus({
    required String workspaceId,
    required String conversationId,
    required ConversationStatus status,
  });

  /// One conversation by id, scoped to the workspace (null when not found /
  /// foreign).
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  });

  /// All conversations in a channel (active first, main first), scoped.
  Future<List<Conversation>> listForChannel({
    required String workspaceId,
    required String channelId,
  });

  /// Watches the conversations in a channel, scoped.
  Stream<List<Conversation>> watchForChannel({
    required String workspaceId,
    required String channelId,
  });
}
