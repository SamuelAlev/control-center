import 'package:cc_domain/features/chat_bridge/domain/entities/chat_channel_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_user_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';

/// Persistence for external conversation ↔ Control Center channel links.
///
/// **Workspace invariant:** every method takes the owning `workspaceId`, which
/// selects the database file the rows live in. A thread id from another
/// workspace resolves to nothing rather than being read.
///
/// **Provider invariant:** every lookup is scoped by [ChatProvider] too, so two
/// providers whose id spaces happen to collide cannot resolve each other's
/// conversations.
abstract interface class ChatChannelLinkRepository {
  /// Inserts or updates a link (idempotent on the external tuple).
  Future<void> upsert(ChatChannelLink link);

  /// The link anchored on an external conversation/thread, or null.
  ///
  /// [externalThreadId] null addresses the conversation-level link (bot DMs).
  Future<ChatChannelLink?> forExternalThread(
    String workspaceId, {
    required ChatProvider provider,
    required String externalChannelId,
    String? externalThreadId,
  });

  /// The link whose Control Center channel is [ccChannelId], or null. The
  /// reverse direction: where an agent turn in this channel should stream to.
  Future<ChatChannelLink?> forCcChannel(String workspaceId, String ccChannelId);

  /// Every link in the workspace, optionally narrowed to one [provider] — how a
  /// bridge arms its outbound relay for the provider it serves.
  Future<List<ChatChannelLink>> forWorkspace(
    String workspaceId, {
    ChatProvider? provider,
  });

  /// Deletes a link. Returns the number of rows removed.
  Future<int> delete(String id, {required String workspaceId});
}

/// Persistence for external chat member ↔ Control Center user links.
abstract interface class ChatUserLinkRepository {
  /// Inserts or updates a link (idempotent on the external pair).
  Future<void> upsert(ChatUserLink link);

  /// The link for an external member, or null when they have never linked.
  Future<ChatUserLink?> forExternalUser(
    String workspaceId, {
    required ChatProvider provider,
    required String externalTeamId,
    required String externalUserId,
  });

  /// The link for a Control Center user on [provider], or null.
  Future<ChatUserLink?> forUser(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  });

  /// Every link in the workspace, optionally narrowed to one [provider] (the
  /// settings roster).
  Future<List<ChatUserLink>> forWorkspace(
    String workspaceId, {
    ChatProvider? provider,
  });

  /// Watches every link in the workspace, optionally narrowed to one [provider].
  Stream<List<ChatUserLink>> watchForWorkspace(
    String workspaceId, {
    ChatProvider? provider,
  });

  /// Removes a Control Center user's link on [provider]. Returns rows removed.
  Future<int> deleteForUser(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  });
}
