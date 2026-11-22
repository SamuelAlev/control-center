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
import 'package:cc_persistence/database/daos/messaging_dao.dart'
    show ListedMessageRow;
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
      );

  /// Converts a list of database participant rows to domain [SpaceParticipant]s.
  List<SpaceParticipant> participantsToDomain(
    List<SpaceParticipantsTableData> rows,
  ) => rows.map(participantToDomain).toList(growable: false);

  /// Converts a database space message row to a domain [Message].
  ///
  /// [segmentBodies], when the read loaded the message's transcript, become
  /// `metadata['segments']`, the shape every renderer reads. [listed] is what
  /// a list read knows about a transcript it did not load: the row gets
  /// `segments_elided` and, once the turn finished, `segment_count`.
  Message messageToDomain(
    ConversationMessagesTableData row, {
    List<String>? segmentBodies,
    ({bool hasTranscript, int? segmentCount})? listed,
  }) {
    final messageType = MessageType.fromWire(row.messageType);
    final senderType = SenderType.fromWire(row.senderType);

    Map<String, dynamic>? metadata;
    if (row.metadata != null) {
      try {
        metadata = jsonDecode(row.metadata!) as Map<String, dynamic>;
      } catch (_) {
        metadata = null;
      }
    }
    // Three keys live in their own columns, not in the stored JSON: the hot
    // queries filter on them. Domain code still reads them from the map.
    if (row.answered || row.planStatus != null || row.steerState != null) {
      metadata = {
        ...?metadata,
        if (row.answered) 'answered': true,
        'planStatus': ?row.planStatus,
        'steerState': ?row.steerState,
      };
    }
    if (segmentBodies != null) {
      metadata = {
        ...?metadata,
        'segments': [
          for (final body in segmentBodies)
            if (_decodeSegment(body) case final Map<String, dynamic> segment)
              segment,
        ],
      };
    } else if (listed != null && listed.hasTranscript) {
      metadata = {
        ...?metadata,
        'segments_elided': true,
        'segment_count': ?listed.segmentCount,
      };
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
      revision: row.revision,
    );
  }

  /// One stored segment body, or null for one that does not decode to an
  /// object: a damaged row costs that segment, not the turn.
  static Map<String, dynamic>? _decodeSegment(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Converts database space message rows to domain [Message]s, each with
  /// the transcript [segmentBodies] holds for it (by message id), if any.
  List<Message> messagesToDomain(
    List<ConversationMessagesTableData> rows, {
    Map<String, List<String>> segmentBodies = const {},
  }) => [
    for (final row in rows)
      messageToDomain(row, segmentBodies: segmentBodies[row.id]),
  ];

  /// Converts list rows to domain [Message]s: no transcript, but whether
  /// there is one and how long it is.
  List<Message> listedMessagesToDomain(List<ListedMessageRow> rows) => [
    for (final row in rows) listedMessageToDomain(row),
  ];

  /// Converts one list row to a domain [Message].
  Message listedMessageToDomain(ListedMessageRow row) => messageToDomain(
    row.data,
    listed: (hasTranscript: row.hasTranscript, segmentCount: row.segmentCount),
  );

  /// Converts a row and its vector into an [EmbeddedMessage].
  EmbeddedMessage embeddedMessageToDomain(
    ({ConversationMessagesTableData data, Uint8List embedding}) row,
  ) => EmbeddedMessage(
    message: messageToDomain(row.data),
    embedding: row.embedding,
  );

  /// Converts rows and their vectors into [EmbeddedMessage]s.
  List<EmbeddedMessage> embeddedMessagesToDomain(
    List<({ConversationMessagesTableData data, Uint8List embedding})> rows,
  ) => rows.map(embeddedMessageToDomain).toList(growable: false);
}
