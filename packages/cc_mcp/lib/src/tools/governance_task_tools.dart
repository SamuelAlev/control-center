import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_harness/tools.dart';

/// Atomically checks out a task to an agent for exclusive work (single-assignee
/// lock). A second agent attempting to check out the same task gets a conflict.
class CheckoutTaskTool extends McpTool {
  /// Creates a [CheckoutTaskTool].
  CheckoutTaskTool({required TicketWorkflowService service})
    : _service = service;

  final TicketWorkflowService _service;

  @override
  String get name => 'checkout_task';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.vendorSyncWrite};

  @override
  String get description =>
      'Atomically claims a task (ticket) for exclusive work and moves it to '
      'in_progress. A task is assigned to exactly one agent; if another agent '
      'already holds it, this returns a conflict so you can pick up other work.';

  @override
  bool get requiresApproval => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'ticket_id': {'type': 'string', 'description': 'Task (ticket) id.'},
      'agent_id': {'type': 'string', 'description': 'Agent claiming the task.'},
    },
    'required': ['workspace_id', 'ticket_id', 'agent_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final ticketId = arguments['ticket_id'];
    if (ticketId is! String) {
      return CallResult.error('Missing or invalid argument: ticket_id');
    }
    final agentId = arguments['agent_id'];
    if (agentId is! String) {
      return CallResult.error('Missing or invalid argument: agent_id');
    }
    final acquired = await _service.tryCheckout(
      ticketId,
      workspaceId: workspaceId,
      agentId: agentId,
    );
    return CallResult.success(
      jsonEncode({
        'ticket_id': ticketId,
        'agent_id': agentId,
        'acquired': acquired,
        'status': acquired ? 'in_progress' : 'unavailable',
      }),
    );
  }
}

/// Releases a task checkout, returning it to open so another agent can claim it.
class ReleaseTaskTool extends McpTool {
  /// Creates a [ReleaseTaskTool].
  ReleaseTaskTool({required TicketWorkflowService service})
    : _service = service;

  final TicketWorkflowService _service;

  @override
  String get name => 'release_task';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.vendorSyncWrite};

  @override
  String get description =>
      'Releases a task you previously checked out, returning it to open so '
      'another agent can claim it. Only the current holder may release.';

  @override
  bool get requiresApproval => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'ticket_id': {'type': 'string', 'description': 'Task (ticket) id.'},
      'agent_id': {
        'type': 'string',
        'description': 'Agent releasing the task.',
      },
    },
    'required': ['workspace_id', 'ticket_id', 'agent_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final ticketId = arguments['ticket_id'];
    if (ticketId is! String) {
      return CallResult.error('Missing or invalid argument: ticket_id');
    }
    final agentId = arguments['agent_id'];
    if (agentId is! String) {
      return CallResult.error('Missing or invalid argument: agent_id');
    }
    final released = await _service.releaseCheckout(
      ticketId,
      workspaceId: workspaceId,
      agentId: agentId,
    );
    return CallResult.success(
      jsonEncode({'ticket_id': ticketId, 'released': released}),
    );
  }
}
