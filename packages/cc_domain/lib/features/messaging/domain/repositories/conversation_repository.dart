import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/thread_summary.dart';

/// Repository for space conversations (the [Conversation] streams inside a
/// space).
///
/// Every method is workspace-scoped: `workspaceId` is required and reads filter
/// on it, so a foreign conversation is simply not found (workspace-isolation
/// invariant). Conversation ids are UUIDs but that is NOT the isolation
/// boundary.
abstract interface class ConversationRepository {
  /// Idempotently ensures the space has at least one conversation, creating
  /// an UNTITLED one when empty (the title model names it from its first
  /// human message). Safe to call on every space open.
  Future<Conversation> ensure({
    required String workspaceId,
    required String spaceId,
  });

  /// Creates a new conversation in [spaceId]. When [anchorMessageId] is set
  /// the new conversation is a thread anchored to that sibling message (one
  /// level deep; the anchor must live in an unanchored conversation of the
  /// same space — validated at the RPC op).
  Future<Conversation> create({
    required String workspaceId,
    required String spaceId,
    required String title,
    String? anchorMessageId,
    String? createdByPrincipalId,
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

  /// All conversations in a space (active first, oldest first), scoped.
  Future<List<Conversation>> listForSpace({
    required String workspaceId,
    required String spaceId,
  });

  /// Watches the conversations in a space, scoped.
  Stream<List<Conversation>> watchForSpace({
    required String workspaceId,
    required String spaceId,
  });

  /// A live rollup of every thread in the space: reply count, newest reply and
  /// the distinct senders, each keyed by the message it is anchored to.
  ///
  /// ONE subscription for the whole space rather than one per thread — the
  /// feed renders an indicator under any message that started a thread, and a
  /// busy space can hold dozens.
  Stream<List<ThreadSummary>> watchThreadSummaries({
    required String workspaceId,
    required String spaceId,
  });
}
