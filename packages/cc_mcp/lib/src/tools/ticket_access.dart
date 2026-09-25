import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';

/// Rejects missing or out-of-workspace tickets before an MCP mutation can
/// mistake the workflow service's no-op for a successful update.
Future<CallResult?> ticketMutationError(
  TicketWorkflowService service,
  String workspaceId,
  String ticketId,
) async {
  final ticket = await service.repository.getById(workspaceId, ticketId);
  if (ticket == null) {
    return CallResult.error('Ticket not found.');
  }
  if (ticket.workspaceId != workspaceId) {
    return CallResult.error('Ticket belongs to a different workspace.');
  }
  return null;
}
