import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/mappers/wake_mapper.dart';
import 'package:drift/drift.dart';

/// Maps between [PeerAsk] and `peer_asks` rows. A row the entity refuses
/// reads as null and is left out of lists.
class PeerAskMapper {
  /// Creates a [PeerAskMapper].
  const PeerAskMapper();

  /// The ask [row] holds, or null when it is not a valid ask.
  PeerAsk? tryToDomain(PeerAsksTableData row) {
    final kind = PeerAskKindWire.tryParse(row.kind);
    final mode = PeerAskModeWire.tryParse(row.mode);
    final status = PeerAskStatusWire.tryParse(row.status);
    if (kind == null || mode == null || status == null) {
      return null;
    }
    try {
      return PeerAsk(
        id: row.id,
        workspaceId: row.workspaceId,
        kind: kind,
        mode: mode,
        askerAgentId: row.askerAgentId,
        askerRunId: row.askerRunId,
        askerConversationId: row.askerConversationId,
        askerSpaceId: row.askerSpaceId,
        recipientAgentId: row.recipientAgentId,
        recipientConversationId: row.recipientConversationId,
        recipientSpaceId: row.recipientSpaceId,
        questionMessageId: row.questionMessageId,
        questionHash: row.questionHash,
        dispatchedRunId: row.dispatchedRunId,
        chain: WakeMapper.decodeIds(row.chain),
        status: status,
        replyMessageId: row.replyMessageId,
        replyInline: row.replyInline,
        error: row.error,
        requestedByUserId: row.requestedByUserId,
        // Drift reads `dateTime()` columns back as local times.
        createdAt: row.createdAt.toUtc(),
        expiresAt: row.expiresAt.toUtc(),
        settledAt: row.settledAt?.toUtc(),
        promisedAt: row.promisedAt?.toUtc(),
        blockedNoticedAt: row.blockedNoticedAt?.toUtc(),
        stallNoticedRunId: row.stallNoticedRunId,
      );
    } on ArgumentError {
      return null;
    }
  }

  /// The valid asks among [rows], in order.
  List<PeerAsk> toDomainList(Iterable<PeerAsksTableData> rows) => [
    for (final row in rows) ?tryToDomain(row),
  ];

  /// Every column of [ask].
  PeerAsksTableCompanion toCompanion(PeerAsk ask) => PeerAsksTableCompanion(
    id: Value(ask.id),
    workspaceId: Value(ask.workspaceId),
    kind: Value(ask.kind.wire),
    mode: Value(ask.mode.wire),
    askerAgentId: Value(ask.askerAgentId),
    askerRunId: Value(ask.askerRunId),
    askerConversationId: Value(ask.askerConversationId),
    askerSpaceId: Value(ask.askerSpaceId),
    recipientAgentId: Value(ask.recipientAgentId),
    recipientConversationId: Value(ask.recipientConversationId),
    recipientSpaceId: Value(ask.recipientSpaceId),
    questionMessageId: Value(ask.questionMessageId),
    questionHash: Value(ask.questionHash),
    dispatchedRunId: Value(ask.dispatchedRunId),
    chain: Value(jsonEncode(ask.chain)),
    status: Value(ask.status.wire),
    replyMessageId: Value(ask.replyMessageId),
    replyInline: Value(ask.replyInline),
    error: Value(ask.error),
    requestedByUserId: Value(ask.requestedByUserId),
    createdAt: Value(ask.createdAt),
    expiresAt: Value(ask.expiresAt),
    settledAt: Value(ask.settledAt),
    promisedAt: Value(ask.promisedAt),
    blockedNoticedAt: Value(ask.blockedNoticedAt),
    stallNoticedRunId: Value(ask.stallNoticedRunId),
  );
}
