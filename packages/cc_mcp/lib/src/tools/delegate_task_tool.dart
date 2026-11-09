import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show DelegationRefusedException;
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_mcp/src/tools/peer_delegation_gate.dart';
import 'package:cc_mcp/src/tools/pending_delegation_hops.dart';

/// Delegates a task to another agent as a tracked child ticket, enforcing the
/// deterministic delegation guards (PRD 22 §3) through [PeerDelegationGate] —
/// the one chokepoint every agent hand-off shares — before the child ticket
/// exists. The gate checks the persisted delegation ancestry and the pending
/// asks together, so the recipient cannot delegate back to the agent
/// currently waiting for its answer.
class DelegateTaskTool extends McpTool {
  /// Creates a [DelegateTaskTool].
  DelegateTaskTool({
    required this._service,
    required PendingDelegationHops pendingHops,
  }) : _gate = PeerDelegationGate(service: _service, pendingHops: pendingHops);

  final TicketWorkflowService _service;
  final PeerDelegationGate _gate;

  @override
  String get name => 'delegate_task';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.vendorSyncWrite};

  @override
  String get description =>
      'Delegate a task to another agent as a tracked child ticket. Enforces '
      'server-side delegation guards (max chain depth + cycle detection): a hop '
      'that would loop back to an agent already in the chain, or exceed the '
      'depth cap, is refused with the reason. Provide parent_ticket_id when this '
      'sub-task belongs under an existing task so the chain depth is tracked.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace id.'},
      'title': {'type': 'string', 'description': 'Short task title.'},
      'to_agent_id': {
        'type': 'string',
        'description': 'The agent to delegate the task to.',
      },
      'description': {
        'type': 'string',
        'description': 'Detailed instructions for the delegate.',
      },
      'acceptance_criteria': {
        'type': 'string',
        'description':
            'What "done" looks like — appended to the task description so '
            'the delegate knows the completion bar.',
      },
      'parent_ticket_id': {
        'type': 'string',
        'description':
            'Parent task this is a sub-task of. Sets the delegation depth '
            'and root so the chain is bounded.',
      },
      'from_agent_id': {
        'type': 'string',
        'description':
            'Your own agent id (the delegator). Required for cycle and policy guards.',
      },
      'space_id': {
        'type': 'string',
        'description':
            'Optional space to associate the sub-task with (e.g. the '
            'space the parent task runs in).',
      },
    },
    'required': ['workspace_id', 'title', 'to_agent_id', 'from_agent_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final title = arguments['title'];
    if (title is! String || title.trim().isEmpty) {
      return CallResult.error(
        'Missing or invalid argument: title (expected non-empty string)',
      );
    }
    final toAgentId = arguments['to_agent_id'];
    if (toAgentId is! String || toAgentId.isEmpty) {
      return CallResult.error('Missing or invalid argument: to_agent_id');
    }

    final fromAgentId = arguments['from_agent_id'];
    if (fromAgentId is! String || fromAgentId.isEmpty) {
      return CallResult.error('Missing or invalid argument: from_agent_id');
    }
    final parentTicketId = arguments['parent_ticket_id'] as String?;
    final spaceId = arguments['space_id'] as String?;
    final refusal = await _gate.refusal(
      workspaceId: workspaceId,
      fromAgentId: fromAgentId,
      recipientId: toAgentId,
      handOff: PeerHandOff.ticket,
      parentTicketId: parentTicketId,
      spaceId: spaceId,
    );
    if (refusal != null) {
      return CallResult.error(refusal);
    }
    final description = _composeDescription(
      arguments['description'] as String?,
      arguments['acceptance_criteria'] as String?,
    );

    try {
      final ticket = await _service.createDelegatedTicket(
        workspaceId: workspaceId,
        title: title.trim(),
        assignedAgentId: toAgentId,
        parentTicketId: parentTicketId,
        delegatedByAgentId: fromAgentId,
        description: description,
        spaceId: spaceId,
      );
      return CallResult.success(
        jsonEncode({
          'ticket_id': ticket.id,
          'status': ticket.status.toStorageString(),
          'delegation_depth': ticket.delegationDepth,
          'delegation_root_ticket_id':
              ticket.delegationRootTicketId ?? ticket.id,
          'assigned_agent_id': ticket.assignedAgentId,
        }),
      );
    } on DelegationRefusedException catch (e) {
      // The parent vanished after the gate ran; the reason is client-safe.
      return CallResult.error(e.message);
    }
  }

  /// Folds optional acceptance criteria into the task description (tickets have
  /// no dedicated criteria field). Returns null when both are absent.
  String? _composeDescription(String? description, String? acceptanceCriteria) {
    final hasDescription = description != null && description.trim().isNotEmpty;
    final hasCriteria =
        acceptanceCriteria != null && acceptanceCriteria.trim().isNotEmpty;
    if (!hasDescription && !hasCriteria) {
      return null;
    }
    final buffer = StringBuffer();
    if (hasDescription) {
      buffer.write(description.trim());
    }
    if (hasCriteria) {
      if (hasDescription) {
        buffer.write('\n\n');
      }
      buffer
        ..write('Acceptance criteria:\n')
        ..write(acceptanceCriteria.trim());
    }
    return buffer.toString();
  }
}
