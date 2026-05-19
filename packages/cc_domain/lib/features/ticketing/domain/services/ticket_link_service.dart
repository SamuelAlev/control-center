import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:uuid/uuid.dart';

/// Manages directional dependency links between tickets
/// (`blocks` / `relates_to` / `duplicate_of`). Parent / sub-issue links are
/// owned by `TicketWorkflowService.setParent` (they live on the ticket row),
/// not here.
///
/// Pure domain: depends on the [TicketLinkRepository] and [TicketRepository]
/// (the latter only to validate that both endpoints live in the caller's
/// workspace). Cross-workspace links are rejected with a
/// [WorkspaceMismatchException]; a ticket linking to itself is rejected with an
/// [ArgumentError].
class TicketLinkService {
  /// Creates a [TicketLinkService].
  TicketLinkService({
    required this.linkRepository,
    required this.ticketRepository,
  });

  /// Link persistence.
  final TicketLinkRepository linkRepository;

  /// Ticket persistence (endpoint validation only).
  final TicketRepository ticketRepository;

  static const _uuid = Uuid();

  /// Creates a canonical `source --type--> target` link after validating that
  /// both endpoints exist and belong to [workspaceId]. Idempotent.
  Future<void> link({
    required String workspaceId,
    required TicketLinkType type,
    required String sourceTicketId,
    required String targetTicketId,
  }) async {
    if (sourceTicketId == targetTicketId) {
      throw ArgumentError('A ticket cannot be linked to itself');
    }
    await _assertTicket(sourceTicketId, workspaceId);
    await _assertTicket(targetTicketId, workspaceId);
    await linkRepository.insert(TicketLink(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      sourceTicketId: sourceTicketId,
      targetTicketId: targetTicketId,
      type: type,
      createdAt: DateTime.now(),
    ));
  }

  /// Removes a `source --type--> target` link, scoped to [workspaceId].
  Future<void> unlink({
    required String workspaceId,
    required TicketLinkType type,
    required String sourceTicketId,
    required String targetTicketId,
  }) async {
    await linkRepository.deleteByEndpoints(
      workspaceId: workspaceId,
      sourceTicketId: sourceTicketId,
      targetTicketId: targetTicketId,
      type: type,
    );
  }

  /// Adds a link expressed from [subjectTicketId]'s point of view. The five
  /// link-based [TicketRelationKind]s are supported; parent / sub-issue kinds
  /// are rejected (use `TicketWorkflowService.setParent`).
  Future<void> addRelation({
    required String workspaceId,
    required String subjectTicketId,
    required String otherTicketId,
    required TicketRelationKind kind,
  }) {
    final (type, source, target) =
        _canonical(kind, subjectTicketId, otherTicketId);
    return link(
      workspaceId: workspaceId,
      type: type,
      sourceTicketId: source,
      targetTicketId: target,
    );
  }

  /// Removes a link expressed from [subjectTicketId]'s point of view.
  Future<void> removeRelation({
    required String workspaceId,
    required String subjectTicketId,
    required String otherTicketId,
    required TicketRelationKind kind,
  }) {
    final (type, source, target) =
        _canonical(kind, subjectTicketId, otherTicketId);
    return unlink(
      workspaceId: workspaceId,
      type: type,
      sourceTicketId: source,
      targetTicketId: target,
    );
  }

  /// Maps a perspective-relative [kind] to the canonical
  /// `(type, sourceId, targetId)` triple stored in the link table.
  (TicketLinkType, String, String) _canonical(
    TicketRelationKind kind,
    String subject,
    String other,
  ) {
    return switch (kind) {
      TicketRelationKind.blocking => (TicketLinkType.blocks, subject, other),
      TicketRelationKind.blockedBy => (TicketLinkType.blocks, other, subject),
      TicketRelationKind.relatedTo => (TicketLinkType.relatesTo, subject, other),
      TicketRelationKind.duplicateOf =>
        (TicketLinkType.duplicateOf, subject, other),
      TicketRelationKind.duplicatedBy =>
        (TicketLinkType.duplicateOf, other, subject),
      TicketRelationKind.subIssueOf ||
      TicketRelationKind.parentOf =>
        throw ArgumentError(
          'Parent/sub-issue relations are managed by TicketWorkflowService',
        ),
    };
  }

  Future<void> _assertTicket(String ticketId, String workspaceId) async {
    final ticket = await ticketRepository.getById(ticketId);
    if (ticket == null) {
      throw ArgumentError('Ticket $ticketId does not exist');
    }
    if (ticket.workspaceId != workspaceId) {
      throw WorkspaceMismatchException(
        'Ticket $ticketId belongs to a different workspace.',
      );
    }
  }
}
