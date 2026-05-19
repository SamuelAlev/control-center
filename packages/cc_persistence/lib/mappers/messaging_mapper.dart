import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_persistence/database/app_database.dart';

/// Maps database rows to messaging domain entities.
class MessagingMapper {
  /// Creates a new [MessagingMapper].
  const MessagingMapper();

  /// Converts a database channel row to a domain [Channel].
  Channel channelToDomain(ChannelsTableData row, {required bool isDm}) =>
      Channel(
        id: row.id,
        name: row.name,
        isDm: isDm,
        workspaceId: row.workspaceId,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        mode: ConversationMode.fromDbValue(row.mode),
        pipelineRunId: row.pipelineRunId,
      );

  /// Converts a list of database channel rows to domain [Channel]s.
  List<Channel> channelsToDomain(List<({ChannelsTableData data, bool isDm})> rows) =>
      rows.map((r) => channelToDomain(r.data, isDm: r.isDm)).toList(growable: false);

  /// Converts a database participant row to a domain [ChannelParticipant].
  ChannelParticipant participantToDomain(ChannelParticipantsTableData row) =>
      ChannelParticipant(
        id: row.id,
        channelId: row.channelId,
        agentId: row.agentId,
        role: row.role,
        joinedAt: row.joinedAt,
        lastReadAt: row.lastReadAt,
      );

  /// Converts a list of database participant rows to domain [ChannelParticipant]s.
  List<ChannelParticipant> participantsToDomain(
    List<ChannelParticipantsTableData> rows,
  ) => rows.map(participantToDomain).toList(growable: false);

  /// Converts a database channel message row to a domain [ChannelMessage].
  ChannelMessage messageToDomain(ChannelMessagesTableData row) {
    ChannelMessageType messageType;
    switch (row.messageType) {
      case 'system':
        messageType = ChannelMessageType.system;
      case 'ticket_card':
        messageType = ChannelMessageType.ticketCard;
      case 'agent_turn':
        messageType = ChannelMessageType.agentTurn;
      case 'review_node':
        messageType = ChannelMessageType.reviewNode;
      case 'hire_proposal':
        messageType = ChannelMessageType.hireProposal;
      case 'review_summary':
        messageType = ChannelMessageType.reviewSummary;
      case 'plan':
        messageType = ChannelMessageType.plan;
      case 'user_question':
        messageType = ChannelMessageType.userQuestion;
      case 'orchestration_proposal':
        messageType = ChannelMessageType.orchestrationProposal;
      case 'compaction':
        messageType = ChannelMessageType.compaction;
      default:
        messageType = ChannelMessageType.text;
    }

    final senderType = row.senderType == 'user'
        ? ChannelSenderType.user
        : ChannelSenderType.agent;

    Map<String, dynamic>? metadata;
    if (row.metadata != null) {
      try {
        metadata = jsonDecode(row.metadata!) as Map<String, dynamic>;
      } catch (_) {
        metadata = null;
      }
    }

    return ChannelMessage(
      id: row.id,
      channelId: row.channelId,
      senderId: row.senderId,
      senderType: senderType,
      content: row.content,
      messageType: messageType,
      metadata: metadata,
      parentMessageId: row.parentMessageId,
      compacted: row.compacted,
      reverted: row.reverted,
      revertedAt: row.revertedAt,
      createdAt: row.createdAt,
    );
  }

  /// Converts a list of database channel message rows to domain [ChannelMessage]s.
  List<ChannelMessage> messagesToDomain(List<ChannelMessagesTableData> rows) =>
      rows.map(messageToDomain).toList(growable: false);

  /// Converts a DB row into an [EmbeddedChannelMessage] carrying the raw
  /// embedding bytes alongside the domain entity.
  EmbeddedChannelMessage embeddedMessageToDomain(
    ChannelMessagesTableData row,
  ) =>
      EmbeddedChannelMessage(
        message: messageToDomain(row),
        embedding: row.embedding ?? Uint8List(0),
      );

  /// Converts a list of DB rows into [EmbeddedChannelMessage]s.
  List<EmbeddedChannelMessage> embeddedMessagesToDomain(
    List<ChannelMessagesTableData> rows,
  ) =>
      rows.map(embeddedMessageToDomain).toList(growable: false);
}
