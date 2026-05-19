import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';

/// Driven port: the ticket-workflow operations the pipeline engine and other
/// consumers need. Implemented by `TicketWorkflowService` in the ticketing
/// feature.
///
/// Defined here (consumer-owned, hexagonal "driven port") so pipelines depend
/// on this thin contract instead of the concrete `TicketWorkflowService`.
///
/// Tickets are dumb issue-tracking artifacts: creating / completing / failing
/// one is a pure status transition. The structured-output contract lives on the
/// agent run (`submit_output`), not here.
abstract interface class TicketWorkflowPort {
  /// Creates a ticket on the configured provider.
  Future<Ticket> createTicket({
    required String workspaceId,
    required String title,
    String? id,
    String? description,
    TicketProvider provider = TicketProvider.local,
    TicketPriority priority = TicketPriority.none,
    TicketStatus status = TicketStatus.open,
    List<String> labels = const [],
    String? assignedAgentId,
    String? assignedTeamId,
    String? delegatedByAgentId,
    String? parentTicketId,
    String? projectId,
    String? channelId,
    Map<String, String> providerExtras = const {},
  });

  /// Marks a ticket completed (done) — a plain status transition.
  Future<void> completeTicket(
    String ticketId, {
    required String workspaceId,
    bool force = false,
  });

  /// Marks a ticket failed with an error message.
  Future<void> failTicket(
    String ticketId,
    String errorMessage, {
    required String workspaceId,
    bool force = false,
  });

  /// Cancels a ticket.
  Future<void> cancelTicket(
    String ticketId, {
    required String workspaceId,
    bool force = false,
  });
}
