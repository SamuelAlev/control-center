import 'package:control_center/features/ticketing/domain/entities/ticket_link.dart';

/// Persistence boundary for ticket dependency links.
abstract interface class TicketLinkRepository {
  /// Inserts a link (idempotent on `(source, target, type)`).
  Future<void> insert(TicketLink link);

  /// Deletes a link by id, scoped to [workspaceId]. Returns rows deleted.
  Future<int> deleteById(String id, {required String workspaceId});

  /// Deletes a link identified by its endpoints + type, scoped to
  /// [workspaceId]. Returns rows deleted.
  Future<int> deleteByEndpoints({
    required String workspaceId,
    required String sourceTicketId,
    required String targetTicketId,
    required TicketLinkType type,
  });

  /// All links touching [ticketId] (source or target), scoped to [workspaceId].
  Future<List<TicketLink>> getForTicket(String workspaceId, String ticketId);

  /// Watches all links touching [ticketId] (source or target), scoped to
  /// [workspaceId].
  Stream<List<TicketLink>> watchForTicket(String workspaceId, String ticketId);
}
