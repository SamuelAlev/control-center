import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show DelegationRefusedException;
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_message_limits.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_domain/features/ticketing/domain/value_objects/delegation_brief.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/cc_infra.dart' show PeerAskService, TicketSettledWakes;
import 'package:cc_mcp/src/mcp_scoped_tool.dart';
import 'package:cc_mcp/src/tools/hidden_spaces_for_caller.dart';
import 'package:cc_mcp/src/tools/peer_delegation_gate.dart';
import 'package:cc_mcp/src/tools/peer_tool_caller.dart';

/// Delegates a task to another agent as a tracked child ticket, enforcing the
/// deterministic delegation guards (PRD 22 §3) through [PeerDelegationGate] —
/// the one chokepoint every agent hand-off shares — before the child ticket
/// exists. The gate checks the persisted delegation ancestry and the pending
/// asks together, so the recipient cannot delegate back to the agent
/// currently waiting for its answer.
///
/// The ticket records the conversation it was delegated from (the attested
/// `caller_conversation_id`) and the delegating run, so its completion
/// wakes the delegator there (`TicketSettledWakes`).
class DelegateTaskTool extends McpScopedTool {
  /// Creates a [DelegateTaskTool].
  DelegateTaskTool({required this._service, required this._peerAsks})
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
  String get name => 'delegate_task';

  /// Not for scripts: it starts another agent run (see
  /// [McpTool.scriptCallable]).
  @override
  bool get scriptCallable => false;
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.vendorSyncWrite};

  @override
  String get description =>
      'Delegate a task to another agent as a tracked child ticket. Enforces '
      'server-side delegation guards (max chain depth + cycle detection): a hop '
      'that would loop back to an agent already in the chain, or exceed the '
      'depth cap, is refused with the reason. Provide parent_ticket_id when this '
      'sub-task belongs under an existing task so the chain depth is tracked. '
      'The recipient works from the brief alone, so make it self-contained, '
      'with acceptance criteria in done_means.';

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
      'done_means': {
        'type': 'array',
        'items': {
          'type': 'string',
          'maxLength': DelegationBrief.maxDoneMeansChars,
        },
        'maxItems': DelegationBrief.maxDoneMeans,
        'description':
            'What finished looks like, one checkable statement each. '
            'Rendered as a numbered "Done means" list in the brief.',
      },
      'constraints': {
        'type': 'string',
        'maxLength': DelegationBrief.maxConstraintsChars,
        'description':
            'What the delegate must not do or must stay within (scope, '
            'files to leave alone, budget).',
      },
      'references': {
        'type': 'array',
        'items': {
          'type': 'string',
          'maxLength': DelegationBrief.maxReferenceChars,
        },
        'maxItems': DelegationBrief.maxReferences,
        'description':
            'Paths, ticket ids and pull request links the delegate starts '
            'from.',
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
      McpCallScope.callerConversationKey: callerConversationProperty,
    },
    'required': ['workspace_id', 'title', 'to_agent_id', 'from_agent_id'],
  };

  @override
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
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
    final (parsed, problem) = _briefOf(arguments);
    if (parsed == null) {
      return CallResult.error(problem ?? 'Invalid brief.');
    }
    final brief = parsed;
    final description = brief.render(
      _composeDescription(
        arguments['description'] as String?,
        arguments['acceptance_criteria'] as String?,
      ),
    );
    if (description != null) {
      final tooLong = peerMessageSizeRefusal(description, label: 'brief');
      if (tooLong != null) {
        return CallResult.error(tooLong);
      }
    }
    final caller = PeerCaller.of(
      arguments,
      context,
      agentKey: 'from_agent_id',
    );
    final readOnly = caller.readOnlyRefusal(_peerAsks);
    if (readOnly != null) {
      return peerRefusalResult(readOnly);
    }
    final refusal = await _gate.refusal(
      workspaceId: workspaceId,
      fromAgentId: fromAgentId,
      recipientId: toAgentId,
      chain: await _peerAsks.chainOf(
        workspaceId,
        fromAgentId,
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
        title: title.trim(),
        assignedAgentId: toAgentId,
        parentTicketId: parentTicketId,
        delegatedByAgentId: fromAgentId,
        delegatedFromConversationId: caller.conversationId,
        description: description,
        spaceId: spaceId,
        // Kept apart from the prose so a completion notice can echo what
        // "done" meant without parsing the description; the delegating run
        // names whom the completion wake acts for.
        metadata: {
          if (!brief.isEmpty) DelegationBrief.metadataKey: brief.toMetadata(),
          TicketSettledWakes.delegatingRunKey: ?caller.runId,
        },
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

  /// The structured brief in [arguments] (`done_means`, `constraints`,
  /// `references`), or the reason it cannot be used.
  static (DelegationBrief?, String?) _briefOf(Map<String, dynamic> arguments) {
    List<String>? strings(Object? value) => value == null
        ? const []
        : value is List && value.every((e) => e is String)
        ? value.cast<String>()
        : null;
    final doneMeans = strings(arguments['done_means']);
    if (doneMeans == null) {
      return (null, 'Invalid argument: done_means (expected a list of strings)');
    }
    final references = strings(arguments['references']);
    if (references == null) {
      return (null, 'Invalid argument: references (expected a list of strings)');
    }
    final constraints = arguments['constraints'];
    if (constraints != null && constraints is! String) {
      return (null, 'Invalid argument: constraints (expected a string)');
    }
    try {
      return (
        DelegationBrief(
          doneMeans: doneMeans,
          constraints: constraints as String?,
          references: references,
        ),
        null,
      );
    } on ArgumentError catch (e) {
      return (null, 'Invalid brief: ${e.message}');
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
