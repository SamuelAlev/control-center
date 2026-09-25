import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show DelegationRefusedException;
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_mcp/src/tools/pending_delegation_hops.dart';
import 'package:cc_mcp/src/tools/ticket_access.dart';

/// MCP tool that delegates a ticket through the same guard as `delegate_task`.
class DelegateTicketTool extends McpTool {
  /// Creates a [DelegateTicketTool].
  DelegateTicketTool({
    required TicketWorkflowService service,
    required PendingDelegationHops pendingHops,
  }) : _service = service,
       _pendingHops = pendingHops;
  final TicketWorkflowService _service;
  final PendingDelegationHops _pendingHops;

  @override
  String get name => 'delegate_ticket';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.vendorSyncWrite};

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
      'space_id': {
        'type': 'string',
        'description':
            'Optional space to run the sub-ticket in (e.g. the '
            "parent ticket's space, to keep the discussion in one place). "
            'Omit to give the sub-ticket its own space.',
      },
      'pipeline_run_id': {
        'type': 'string',
        'description': 'Optional pipeline run that owns this ticket.',
      },
      'pipeline_step_id': {
        'type': 'string',
        'description': 'Optional pipeline step (paired with pipeline_run_id).',
      },
    },
    'required': [
      'workspace_id',
      'title',
      'assigned_agent_id',
      'delegated_by_agent_id',
    ],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'] as String?;
    final title = arguments['title'] as String?;
    final assignedAgentId = arguments['assigned_agent_id'] as String?;
    if (workspaceId == null || title == null || assignedAgentId == null) {
      return CallResult.error('Missing required arguments.');
    }
    final delegatedByAgentId = arguments['delegated_by_agent_id'];
    if (delegatedByAgentId is! String || delegatedByAgentId.isEmpty) {
      return CallResult.error(
        'Missing or invalid argument: delegated_by_agent_id',
      );
    }
    if (_pendingHops.wouldCycle(
      workspaceId,
      delegatedByAgentId,
      assignedAgentId,
    )) {
      return CallResult.error(
        'Delegation refused: cycle detected '
        '(${[..._pendingHops.chain(workspaceId, delegatedByAgentId), assignedAgentId].join(' → ')}).',
      );
    }
    try {
      final ticket = await _service.delegateGuarded(
        workspaceId: workspaceId,
        title: title,
        description: arguments['description'] as String?,
        assignedAgentId: assignedAgentId,
        delegatedByAgentId: delegatedByAgentId,
        parentTicketId: arguments['parent_ticket_id'] as String?,
        spaceId: arguments['space_id'] as String?,
      );
      return CallResult.success(
        jsonEncode({
          'ticket_id': ticket.id,
          'status': ticket.status.toStorageString(),
        }),
      );
    } on DelegationRefusedException catch (e) {
      return CallResult.error(e.message);
    }
  }
}

/// MCP tool to mark a ticket failed with an error message.
class FailTicketTool extends McpTool {
  /// Creates a [FailTicketTool].
  FailTicketTool({required this._service});
  final TicketWorkflowService _service;

  @override
  String get name => 'fail_ticket';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.vendorSyncWrite};

  @override
  String get description => 'Mark a ticket as failed with an error message.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'ticket_id': {'type': 'string', 'description': 'The ticket ID to fail.'},
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
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (ticketId == null || errorMessage == null) {
      return CallResult.error('Missing ticket_id or error_message.');
    }
    final missing = await ticketMutationError(_service, workspaceId, ticketId);
    if (missing != null) return missing;
    await _service.failTicket(ticketId, errorMessage, workspaceId: workspaceId);
    return CallResult.success(
      jsonEncode({'ticket_id': ticketId, 'status': 'failed'}),
    );
  }
}
