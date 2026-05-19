import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';

/// A channel message paired with its embedding vector bytes.
class EmbeddedChannelMessage {
  /// Creates an [EmbeddedChannelMessage].
  EmbeddedChannelMessage({required this.message, required this.embedding});

  /// The domain message entity.
  final ChannelMessage message;

  /// Raw embedding bytes (Float32List stored as Uint8List view).
  final Uint8List embedding;
}

/// Repository interface for messaging channels.
///
/// **Conversations invariant:** every channel has a `main` conversation whose
/// id **equals the channel id**; parentheses (side conversations) get fresh
/// ids. So any code holding only a `channelId` can address the main
/// conversation by passing `channelId` as the `conversationId`.
///
/// **Workspace invariant:** every operation takes the `workspaceId` that owns
/// the channel. Channel, conversation and message ids are uuids, but a uuid is
/// not an access boundary: the workspace scopes the lookup, so an id from
/// another workspace is simply not found rather than read or written.
/// [watchChannels] is the single documented exception.
abstract class MessagingRepository {
  /// CROSS-WORKSPACE BY DESIGN: every channel the server knows about, for the
  /// dashboard's all-channels view. Workspace-scoped surfaces use
  /// [watchChannelsByWorkspace].
  Stream<List<Channel>> watchChannels();

  /// Watches participants for [channelId] within [workspaceId].
  Stream<List<ChannelParticipant>> watchParticipants(
    String workspaceId,
    String channelId,
  );

  /// Watches the messages of one conversation (stream) inside a channel.
  Stream<List<ChannelMessage>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  );

  /// Watches channels for a specific workspace.
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId);

  /// Watches the newest [limit] messages of a conversation (ascending for
  /// display), plus whether older messages exist beyond the window.
  Stream<({List<ChannelMessage> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String channelId,
    String conversationId, {
    required int limit,
  });

  /// Loads one cursor-based page of a conversation's history (oldest-first for
  /// display). Pass a prior page's [MessagePage.nextCursor] as [cursor] to load
  /// the page before it. The page is backfilled to a turn boundary so it never
  /// begins mid-exchange.
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String channelId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  });

  /// Returns a single message by id within [workspaceId], or null.
  Future<ChannelMessage?> getMessageById(String workspaceId, String messageId);

  /// One channel by id within [workspaceId], or null. Host-side loader for the
  /// sync delta feed; remote adapters may not support it.
  Future<Channel?> getChannelById(String workspaceId, String channelId);

  /// Creates a channel in [workspaceId] with zero or more agents. The optional
  /// [mode] sets the conversation mode at creation time so the dispatch pipeline
  /// picks it up on the first message (avoids a race with [setChannelMode]).
  /// [createdByUserId] records the creating human as a participant; system-
  /// created channels (pipelines) pass null and human rows are added lazily on
  /// first open.
  /// [repoIds] optionally scopes which of the workspace's repos this channel's
  /// conversation worktree provisions. Empty (the default) means all workspace
  /// repos, preserving pre-selection behaviour.
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
    List<String> repoIds = const [],
  });

  /// Updates the [Mode] for a channel within [workspaceId].
  Future<void> setChannelMode(String workspaceId, String channelId, Mode mode);

  /// Whether [channelId] exists in [workspaceId].
  Future<bool> channelExists(String workspaceId, String channelId);

  /// Adds a participant (agent by default, or a human user) to a channel.
  Future<void> addParticipant(
    String workspaceId,
    String channelId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  });

  /// Gets current participants for [channelId] within [workspaceId].
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  );

  /// Sends a message to a conversation inside a channel. Returns the message ID.
  /// [conversationId] defaults to the channel's `main` conversation (== the
  /// channel id).
  Future<String> sendMessage({
    required String workspaceId,
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String? conversationId,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
  });

  /// Updates an existing message. [idempotencyKey] (PRD 19 §3) dedupes retries
  /// of one logical edit — including an undo/redo inverse — server-side.
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  });

  /// Gets all (non-reverted) messages for a conversation. [conversationId]
  /// defaults to the channel's `main` conversation (== the channel id) — an
  /// agent run only ever sees its own conversation's history.
  Future<List<ChannelMessage>> getMessages(
    String workspaceId,
    String channelId, {
    String? conversationId,
  });

  /// Full-text search within a single channel: returns live (non-reverted)
  /// messages whose content matches [query], best-match first (newest for
  /// ties), capped at [limit]. An empty/stopword-only query returns nothing.
  Future<List<ChannelMessage>> searchInChannel(
    String workspaceId,
    String channelId,
    String query, {
    int limit,
  });

  /// Marks messages as compacted within [workspaceId].
  Future<void> markCompacted(String workspaceId, List<String> ids);

  /// Reverts (rolls back) the live conversation to [messageId]: every message
  /// after it is hidden (and the message itself when [inclusive]). Reverted
  /// messages are kept so [unrevertConversation] can restore them. Returns the
  /// ids that were reverted.
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String channelId,
    String messageId, {
    bool inclusive = false,
  });

  /// Restores the most-recently-reverted batch (undo a revert). Returns the
  /// restored ids, or empty when there is nothing to restore.
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String channelId,
  );

  /// Deletes a channel and all its data.
  Future<void> deleteChannel(String workspaceId, String channelId);

  /// Updates a channel's name.
  Future<void> updateChannelName(
    String workspaceId,
    String channelId,
    String name,
  );

  /// Clears all messages from a channel.
  Future<void> clearChannelMessages(String workspaceId, String channelId);

  /// Removes a participant (agent or user) from a channel.
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String principalId,
  );

  /// Updates the embedding vector for a message.
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  );

  /// Gets messages with non-null embeddings for a channel.
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String channelId,
  );

  /// Gets messages without embeddings for backfill (text/system only), within
  /// [workspaceId]. The backfill runs one workspace at a time so each embedding
  /// is written back to the file its message came from.
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  });
}
