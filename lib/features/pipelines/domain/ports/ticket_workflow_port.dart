import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';

/// Driven port: the ticket-workflow operations the pipeline engine and its step
/// bodies need. Implemented by `TicketWorkflowService` in the ticketing feature.
///
/// Defined here (consumer-owned, hexagonal "driven port") so pipelines depend
/// on this thin contract instead of the concrete `TicketWorkflowService` (which
/// pulls in the dispatcher, channel service, remote-sync handler, etc.).
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
    ConversationMode mode = ConversationMode.chat,
    String? pipelineRunId,
    String? pipelineStepId,
    Map<String, dynamic>? expectedOutputSchema,
    Map<String, String> providerExtras = const {},
  });

  /// Marks a ticket completed (done) with an optional output payload.
  Future<void> completeTicket(
    String ticketId, {
    required String workspaceId,
    Map<String, dynamic>? output,
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
