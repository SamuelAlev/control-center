import 'dart:typed_data';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';

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
abstract class MessagingRepository {
  /// Watches all channels.
  Stream<List<Channel>> watchChannels();
  /// Watches participants for a channel.
  Stream<List<ChannelParticipant>> watchParticipants(String channelId);
  /// Watches messages for a channel.
  Stream<List<ChannelMessage>> watchMessages(String channelId);

  /// Watches channels for a specific workspace.
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId);
  /// Watches top-level messages (no parent) for a channel.
  Stream<List<ChannelMessage>> watchTopLevelMessages(String channelId);
  /// Watches threaded replies to a specific parent message.
  Stream<List<ChannelMessage>> watchThread(String parentMessageId);
  /// Returns a single message by ID or null.
  Future<ChannelMessage?> getMessageById(String messageId);

  /// Opens or creates a DM channel with an agent.
  Future<Channel> openDm(String agentId, {String? workspaceId});
  /// Creates a group channel. The optional [mode] sets the conversation mode
  /// at creation time so the dispatch pipeline picks it up on the first
  /// message (avoids a race with [setChannelMode]).
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  });

  /// Updates the [ConversationMode] for a channel.
  Future<void> setChannelMode(String channelId, ConversationMode mode);
  /// Adds a participant to a channel.
  Future<void> addParticipant(String channelId, String agentId);
  /// Gets current participants for a channel.
  Future<List<ChannelParticipant>> getParticipants(String channelId);

  /// Sends a message to a channel. Returns the message ID.
  Future<String> sendMessage({
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? parentMessageId,
  });

  /// Updates an existing message.
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  });

  /// Gets all messages for a channel.
  Future<List<ChannelMessage>> getMessages(String channelId);
  /// Marks messages as compacted.
  Future<void> markCompacted(List<String> ids);
  /// Deletes a channel and all its data.
  Future<void> deleteChannel(String channelId);
  /// Updates a channel's name.
  Future<void> updateChannelName(String channelId, String name);
  /// Clears all messages from a channel.
  Future<void> clearChannelMessages(String channelId);
  /// Removes a participant from a channel.
  Future<void> removeParticipant(String channelId, String agentId);
  /// Updates the embedding vector for a message.
  Future<void> updateMessageEmbedding(String messageId, Uint8List embedding);
  /// Gets messages with non-null embeddings for a channel.
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(String channelId);
  /// Gets messages without embeddings for backfill (text/system only).
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding({int limit = 200});
}
