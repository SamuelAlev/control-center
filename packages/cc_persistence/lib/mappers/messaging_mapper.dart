import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';

/// Maps database rows to messaging domain entities.
class MessagingMapper {
  /// Creates a new [MessagingMapper].
  const MessagingMapper();

  /// Converts a database space row to a domain [Space].
  Space spaceToDomain(SpacesTableData row) => Space(
    id: row.id,
    name: row.name,
    workspaceId: row.workspaceId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    mode: Mode.fromDbValue(row.mode),
    provisioningStatus: SpaceProvisioningStatus.fromDbValue(
      row.provisioningStatus,
    ),
    provisioningStep: SpaceProvisioningStep.fromDbValue(row.provisioningStep),
    pipelineRunId: row.pipelineRunId,
    kind: SpaceKind.fromWire(row.kind),
    archivedAt: row.archivedAt,
  );

  /// Converts a list of database space rows to domain [Space]s.
  List<Space> spacesToDomain(List<SpacesTableData> rows) =>
      rows.map(spaceToDomain).toList(growable: false);

  /// Converts a database participant row to a domain [SpaceParticipant].
  SpaceParticipant participantToDomain(SpaceParticipantsTableData row) =>
      SpaceParticipant(
        id: row.id,
        spaceId: row.spaceId,
        principalId: row.principalId,
        participantType:
            PrincipalType.fromWire(row.participantType) ?? PrincipalType.agent,
        role: row.role,
        joinedAt: row.joinedAt,
        lastReadAt: row.lastReadAt,
      );

  /// Converts a list of database participant rows to domain [SpaceParticipant]s.
  List<SpaceParticipant> participantsToDomain(
    List<SpaceParticipantsTableData> rows,
  ) => rows.map(participantToDomain).toList(growable: false);

  /// Converts a database space message row to a domain [Message].
  Message messageToDomain(ConversationMessagesTableData row) {
    MessageType messageType;
    switch (row.messageType) {
      case 'system':
        messageType = MessageType.system;
      case 'ticket_card':
        messageType = MessageType.ticketCard;
      case 'agent_turn':
        messageType = MessageType.agentTurn;
      case 'review_node':
        messageType = MessageType.reviewNode;
      case 'hire_proposal':
        messageType = MessageType.hireProposal;
      case 'review_summary':
        messageType = MessageType.reviewSummary;
      case 'plan':
        messageType = MessageType.plan;
      case 'user_question':
        messageType = MessageType.userQuestion;
      case 'orchestration_proposal':
        messageType = MessageType.orchestrationProposal;
      case 'artifact':
        messageType = MessageType.artifact;
      case 'compaction':
        messageType = MessageType.compaction;
      case 'steering':
        messageType = MessageType.steering;
      default:
        messageType = MessageType.text;
    }

    final senderType = row.senderType == 'user'
        ? SenderType.user
        : SenderType.agent;

    Map<String, dynamic>? metadata;
    if (row.metadata != null) {
      try {
        metadata = jsonDecode(row.metadata!) as Map<String, dynamic>;
      } catch (_) {
        metadata = null;
      }
    }

    return Message(
      id: row.id,
      spaceId: row.spaceId,
      conversationId: row.conversationId,
      senderId: row.senderId,
      senderType: senderType,
      content: row.content,
      messageType: messageType,
      metadata: metadata,
      compacted: row.compacted,
      reverted: row.reverted,
      revertedAt: row.revertedAt,
      createdAt: row.createdAt,
    );
  }

  /// Converts a list of database space message rows to domain [Message]s.
  List<Message> messagesToDomain(List<ConversationMessagesTableData> rows) =>
      rows.map(messageToDomain).toList(growable: false);

  /// Converts a DB row into an [EmbeddedMessage] carrying the raw
  /// embedding bytes alongside the domain entity.
  EmbeddedMessage embeddedMessageToDomain(ConversationMessagesTableData row) =>
      EmbeddedMessage(
        message: messageToDomain(row),
        embedding: row.embedding ?? Uint8List(0),
      );

  /// Converts a list of DB rows into [EmbeddedMessage]s.
  List<EmbeddedMessage> embeddedMessagesToDomain(
    List<ConversationMessagesTableData> rows,
  ) => rows.map(embeddedMessageToDomain).toList(growable: false);
}
