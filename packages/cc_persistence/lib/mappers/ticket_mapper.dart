import 'dart:convert';

import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:drift/drift.dart';

/// Maps between [Ticket] / [TicketCollaborator] domain entities and their
/// Drift rows. Stateless (`static const`), like the other repo mappers.
class TicketMapper {
  /// Creates a [TicketMapper].
  const TicketMapper();

  /// Full companion writing every column (used by insert / full update).
  TicketsTableCompanion toCompanion(Ticket t) {
    return TicketsTableCompanion(
      id: Value(t.id),
      workspaceId: Value(t.workspaceId),
      provider: Value(t.provider.toStorageString()),
      externalKey: Value(t.externalKey),
      url: Value(t.url),
      title: Value(t.title),
      description: Value(t.description),
      priority: Value(t.priority.toStorageInt()),
      labels: Value(jsonEncode(t.labels)),
      status: Value(t.status.toStorageString()),
      rawStatus: Value(t.rawStatus),
      parentTicketId: Value(t.parentTicketId),
      projectId: Value(t.projectId),
      assignedAgentId: Value(t.assignedAgentId),
      assignedTeamId: Value(t.assignedTeamId),
      delegatedByAgentId: Value(t.delegatedByAgentId),
      channelId: Value(t.channelId),
      errorMessage: Value(t.errorMessage),
      linkedPrIds: Value(jsonEncode(t.linkedPrIds)),
      metadata: Value(jsonEncode(t.metadata)),
      version: Value(t.version),
      originKind: Value(t.originKind.name),
      createdAt: Value(t.createdAt),
      startedAt: Value(t.startedAt),
      blockedAt: Value(t.blockedAt),
      cancelledAt: Value(t.cancelledAt),
      completedAt: Value(t.completedAt),
      finishedAt: Value(t.finishedAt),
      updatedAt: Value(t.updatedAt),
    );
  }

  /// Companion writing only the provider-owned mirror columns, leaving the
  /// Control-Center overlay untouched (used by remote sync upserts).
  TicketsTableCompanion toMirrorCompanion(Ticket t) {
    return TicketsTableCompanion(
      provider: Value(t.provider.toStorageString()),
      externalKey: Value(t.externalKey),
      url: Value(t.url),
      title: Value(t.title),
      description: Value(t.description),
      priority: Value(t.priority.toStorageInt()),
      labels: Value(jsonEncode(t.labels)),
      status: Value(t.status.toStorageString()),
      rawStatus: Value(t.rawStatus),
      updatedAt: Value(t.updatedAt),
    );
  }

  /// Builds a domain [Ticket] from a row. Collaborators are hydrated
  /// separately by the repository.
  Ticket fromRow(
    TicketsTableData row, {
    List<TicketCollaborator> collaborators = const [],
  }) {
    return Ticket(
      id: row.id,
      workspaceId: row.workspaceId,
      provider: TicketProvider.fromStorage(row.provider),
      externalKey: row.externalKey,
      url: row.url,
      title: row.title,
      description: row.description,
      priority: TicketPriority.fromStorage(row.priority),
      labels: _decodeStringList(row.labels),
      status: TicketStatus.fromStorage(row.status),
      rawStatus: row.rawStatus,
      parentTicketId: row.parentTicketId,
      projectId: row.projectId,
      assignedAgentId: row.assignedAgentId,
      assignedTeamId: row.assignedTeamId,
      delegatedByAgentId: row.delegatedByAgentId,
      channelId: row.channelId,
      errorMessage: row.errorMessage,
      linkedPrIds: _decodeStringList(row.linkedPrIds),
      metadata: _decodeMap(row.metadata),
      version: row.version,
      originKind: _parseOriginKind(row.originKind),
      createdAt: row.createdAt,
      blockedAt: row.blockedAt,
      cancelledAt: row.cancelledAt,
      completedAt: row.completedAt,
      finishedAt: row.finishedAt,
      updatedAt: row.updatedAt,
      collaborators: collaborators,
    );
  }

  static TicketOriginKind _parseOriginKind(String value) {
    return TicketOriginKind.values.where((k) => k.name == value).firstOrNull ??
        TicketOriginKind.manual;
  }

  /// Maps a collaborator domain entity to a companion.
  TicketCollaboratorsTableCompanion collaboratorToCompanion(
    TicketCollaborator c,
  ) {
    return TicketCollaboratorsTableCompanion(
      id: Value(c.id),
      ticketId: Value(c.ticketId),
      agentId: Value(c.agentId),
      role: Value(c.role.toStorageString()),
      joinedAt: Value(c.joinedAt),
    );
  }

  /// Maps a collaborator row to a domain entity.
  TicketCollaborator collaboratorFromRow(TicketCollaboratorsTableData row) {
    return TicketCollaborator(
      id: row.id,
      ticketId: row.ticketId,
      agentId: row.agentId,
      role: TicketCollaboratorRole.fromStorage(row.role),
      joinedAt: row.joinedAt,
    );
  }

  List<String> _decodeStringList(String raw) {
    if (raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    return decoded is List ? decoded.cast<String>() : const [];
  }

  Map<String, dynamic> _decodeMap(String raw) {
    if (raw.isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }
}
