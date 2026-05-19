import 'dart:convert';

import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';

/// MCP tool that delegates a ticket to an agent (creates a child ticket with a
/// delegating agent + optional pipeline coupling).
class DelegateTicketTool extends McpTool {
  /// Creates a [DelegateTicketTool].
  DelegateTicketTool({required TicketWorkflowService service})
      : _service = service;
  final TicketWorkflowService _service;

  @override
  String get name => 'delegate_ticket';

  @override
  String get description =>
      'Delegate a ticket to an agent. Creates a tracked ticket and returns its '
      'ID. The assigned agent should call `complete_ticket` or `fail_ticket` '
      'when done.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'title': {'type': 'string', 'description': 'Short ticket title.'},
          'description': {
            'type': 'string',
            'description': 'Detailed instructions.',
          },
          'assigned_agent_id': {
            'type': 'string',
            'description': 'Agent to assign.',
          },
          'delegated_by_agent_id': {
            'type': 'string',
            'description': 'Delegating agent ID.',
          },
          'parent_ticket_id': {
            'type': 'string',
            'description': 'Parent ticket ID for sub-tickets.',
          },
          'channel_id': {
            'type': 'string',
            'description': 'Optional channel to run the sub-ticket in (e.g. the '
                "parent ticket's channel, to keep the discussion in one thread). "
                'Omit to give the sub-ticket its own channel.',
          },
          'pipeline_run_id': {
            'type': 'string',
            'description': 'Optional pipeline run that owns this ticket.',
          },
          'pipeline_step_id': {
            'type': 'string',
            'description':
                'Optional pipeline step (paired with pipeline_run_id).',
          },
        },
        'required': ['workspace_id', 'title', 'assigned_agent_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'] as String?;
    final title = arguments['title'] as String?;
    final assignedAgentId = arguments['assigned_agent_id'] as String?;
    if (workspaceId == null || title == null || assignedAgentId == null) {
      return CallResult.error('Missing required arguments.');
    }
    final ticket = await _service.createTicket(
      workspaceId: workspaceId,
      title: title,
      description: arguments['description'] as String?,
      assignedAgentId: assignedAgentId,
      delegatedByAgentId: arguments['delegated_by_agent_id'] as String?,
      parentTicketId: arguments['parent_ticket_id'] as String?,
      channelId: arguments['channel_id'] as String?,
      pipelineRunId: arguments['pipeline_run_id'] as String?,
      pipelineStepId: arguments['pipeline_step_id'] as String?,
    );
    return CallResult.success(jsonEncode({
      'ticket_id': ticket.id,
      'status': ticket.status.toStorageString(),
    }));
  }
}

/// MCP tool to mark a ticket completed with optional output payload.
class CompleteTicketTool extends McpTool {
  /// Creates a [CompleteTicketTool].
  CompleteTicketTool({required TicketWorkflowService service})
      : _service = service;
  final TicketWorkflowService _service;

  @override
  String get name => 'complete_ticket';

  @override
  String get description =>
      'Mark a ticket as done with an optional output payload. If the ticket '
      'declares an expected output schema, the payload MUST validate against '
      'it: a non-conforming payload is rejected with the exact list of '
      'violations — fix it and call complete_ticket again.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'ticket_id': {
            'type': 'string',
            'description': 'The ticket ID to complete.',
          },
          'output': {
            'type': 'object',
            'description': 'Output payload as a JSON object. Required (and '
                'schema-validated) when the ticket declares an expected '
                'output schema.',
          },
        },
        'required': ['workspace_id', 'ticket_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'] as String?;
    final ticketId = arguments['ticket_id'] as String?;
    if (workspaceId == null) {
      return CallResult.error('Missing workspace_id.');
    }
    if (ticketId == null) {
      return CallResult.error('Missing ticket_id.');
    }
    final output = arguments['output'] as Map<String, dynamic>?;
    try {
      await _service.completeTicket(
        ticketId,
        workspaceId: workspaceId,
        output: output,
      );
    } on OutputContractViolationException catch (e) {
      return CallResult.error(e.message);
    }
    return CallResult.success(
        jsonEncode({'ticket_id': ticketId, 'status': 'done'}));
  }
}

/// MCP tool to mark a ticket failed with an error message.
class FailTicketTool extends McpTool {
  /// Creates a [FailTicketTool].
  FailTicketTool({required TicketWorkflowService service}) : _service = service;
  final TicketWorkflowService _service;

  @override
  String get name => 'fail_ticket';

  @override
  String get description => 'Mark a ticket as failed with an error message.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'ticket_id': {
            'type': 'string',
            'description': 'The ticket ID to fail.',
          },
          'error_message': {
            'type': 'string',
            'description': 'Why the ticket failed.',
          },
        },
        'required': ['workspace_id', 'ticket_id', 'error_message'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'] as String?;
    final ticketId = arguments['ticket_id'] as String?;
    final errorMessage = arguments['error_message'] as String?;
    if (workspaceId == null) {
      return CallResult.error('Missing workspace_id.');
    }
    if (ticketId == null || errorMessage == null) {
      return CallResult.error('Missing ticket_id or error_message.');
    }
    await _service.failTicket(ticketId, errorMessage, workspaceId: workspaceId);
    return CallResult.success(
        jsonEncode({'ticket_id': ticketId, 'status': 'failed'}));
  }
}
