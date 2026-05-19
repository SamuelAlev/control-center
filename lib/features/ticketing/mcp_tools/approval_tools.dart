import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';

/// MCP tool to approve a suspended pipeline approval gate.
///
/// Completes the gate's ticket with `{result: 'approved', reason}` so the
/// engine harvests `approved` into the gate node's `outputKey`; a downstream
/// router then takes the `approved` branch. The tool name and `{result}`
/// output contract are load-bearing for the seeded pre-merge-gate pipeline.
class ApproveStepTool extends McpTool {
  /// Creates an [ApproveStepTool].
  ApproveStepTool({required TicketWorkflowService service}) : _service = service;
  final TicketWorkflowService _service;

  @override
  String get name => 'approve_step';

  @override
  String get description =>
      'Approve a suspended pipeline approval gate by its ticket ID.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'ticket_id': {
            'type': 'string',
            'description': 'The approval gate ticket ID to approve.',
          },
          'reason': {
            'type': 'string',
            'description': 'Optional rationale for the approval.',
          },
        },
        'required': ['workspace_id', 'ticket_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'] as String?;
    final ticketId = arguments['ticket_id'] as String?;
    if (workspaceId == null) return CallResult.error('Missing workspace_id.');
    if (ticketId == null) return CallResult.error('Missing ticket_id.');
    await _service.completeTicket(ticketId, workspaceId: workspaceId, output: {
      'result': 'approved',
      if (arguments['reason'] != null) 'reason': arguments['reason'],
    });
    return CallResult.success(
        jsonEncode({'ticket_id': ticketId, 'decision': 'approved'}));
  }
}

/// MCP tool to reject a suspended pipeline approval gate.
class RejectStepTool extends McpTool {
  /// Creates a [RejectStepTool].
  RejectStepTool({required TicketWorkflowService service}) : _service = service;
  final TicketWorkflowService _service;

  @override
  String get name => 'reject_step';

  @override
  String get description =>
      'Reject a suspended pipeline approval gate by its ticket ID.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'ticket_id': {
            'type': 'string',
            'description': 'The approval gate ticket ID to reject.',
          },
          'reason': {
            'type': 'string',
            'description': 'Optional rationale for the rejection.',
          },
        },
        'required': ['workspace_id', 'ticket_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'] as String?;
    final ticketId = arguments['ticket_id'] as String?;
    if (workspaceId == null) return CallResult.error('Missing workspace_id.');
    if (ticketId == null) return CallResult.error('Missing ticket_id.');
    await _service.completeTicket(ticketId, workspaceId: workspaceId, output: {
      'result': 'rejected',
      if (arguments['reason'] != null) 'reason': arguments['reason'],
    });
    return CallResult.success(
        jsonEncode({'ticket_id': ticketId, 'decision': 'rejected'}));
  }
}
