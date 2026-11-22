import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show DelegationRefusedException;
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/cc_infra.dart' show PeerAskService, TicketSettledWakes;
import 'package:cc_mcp/src/mcp_scoped_tool.dart';
import 'package:cc_mcp/src/tools/hidden_spaces_for_caller.dart';
import 'package:cc_mcp/src/tools/peer_delegation_gate.dart';
import 'package:cc_mcp/src/tools/peer_tool_caller.dart';
import 'package:cc_mcp/src/tools/ticket_access.dart';

/// MCP tool that delegates a ticket through the same [PeerDelegationGate] as
/// `delegate_task` and `ask_agent`. The ticket records the conversation it
/// was delegated from and the delegating run, so its completion wakes the
/// delegator there (`TicketSettledWakes`).
class DelegateTicketTool extends McpScopedTool {
  /// Creates a [DelegateTicketTool].
  DelegateTicketTool({required this._service, required this._peerAsks})
    : _gate = PeerDelegationGate(service: _service);
  final TicketWorkflowService _service;
  final PeerAskService _peerAsks;
  final PeerDelegationGate _gate;

  /// The in-process harness's call carries its run's attested scope.
  @override
  Future<CallResult> callForRun(
    Map<String, dynamic> arguments,
    McpCallScope scope, {
    Future<void>? abandoned,
  }) =>
      callScoped(arguments, McpCallContext(scope: scope), abandoned: abandoned);

  @override
  String get name => 'delegate_ticket';

  /// Not for scripts: it hands a ticket to another agent to work on (see
  /// [McpTool.scriptCallable]).
  @override
  bool get scriptCallable => false;
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
      McpCallScope.callerConversationKey: callerConversationProperty,
    },
    'required': [
      'workspace_id',
      'title',
      'assigned_agent_id',
      'delegated_by_agent_id',
    ],
  };

  @override
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
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
    final parentTicketId = arguments['parent_ticket_id'] as String?;
    final spaceId = arguments['space_id'] as String?;
    final caller = PeerCaller.of(
      arguments,
      context,
      agentKey: 'delegated_by_agent_id',
    );
    final readOnly = caller.readOnlyRefusal(_peerAsks);
    if (readOnly != null) {
      return peerRefusalResult(readOnly);
    }
    final refusal = await _gate.refusal(
      workspaceId: workspaceId,
      fromAgentId: delegatedByAgentId,
      recipientId: assignedAgentId,
      chain: await _peerAsks.chainOf(
        workspaceId,
        delegatedByAgentId,
        runId: caller.runId,
        conversationId: caller.conversationId,
      ),
      handOff: PeerHandOff.ticket,
      parentTicketId: parentTicketId,
      spaceId: spaceId,
    );
    if (refusal != null) {
      return peerRefusalResult(refusal);
    }
    try {
      final ticket = await _service.createDelegatedTicket(
        workspaceId: workspaceId,
        title: title,
        description: arguments['description'] as String?,
        assignedAgentId: assignedAgentId,
        delegatedByAgentId: delegatedByAgentId,
        delegatedFromConversationId: caller.conversationId,
        parentTicketId: parentTicketId,
        spaceId: spaceId,
        metadata: {TicketSettledWakes.delegatingRunKey: ?caller.runId},
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
    if (missing != null) {
      return missing;
    }
    await _service.failTicket(ticketId, errorMessage, workspaceId: workspaceId);
    return CallResult.success(
      jsonEncode({'ticket_id': ticketId, 'status': 'failed'}),
    );
  }
}
