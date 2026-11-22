import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart'
    show PairRateLimiter;
import 'package:cc_domain/features/messaging/domain/services/peer_message_limits.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        PeerAskPending,
        PeerAskRefusal,
        PeerAskRefused,
        PeerAskRequest,
        PeerAskService,
        PeerAskSettledInline,
        PeerChain;
import 'package:cc_mcp/src/mcp_scoped_tool.dart';
import 'package:cc_mcp/src/tools/hidden_spaces_for_caller.dart';
import 'package:cc_mcp/src/tools/peer_agent_messaging.dart';
import 'package:cc_mcp/src/tools/peer_delegation_gate.dart';
import 'package:cc_mcp/src/tools/peer_tool_caller.dart';

/// MCP tool used by a plan-mode agent to consult a specialist agent for
/// expert confirmation on a specific topic.
///
/// Lightweight: no review associations, no review nodes, no PR context. The
/// consulted agent is added as a space participant, a consult notice is
/// posted, and the specialist is woken through the wake queue with a
/// focused brief (a `peerMessage` wake that expects a reply). A consult from
/// an agent is a durable ask (`PeerAsk`, kind `consult`, background): the
/// requester is woken in its conversation when the specialist finishes.
///
/// The consulting agent is the caller (`agent_id` is forced from the call
/// scope), and the hand-off passes the same [PeerDelegationGate], the ask
/// limits and the shared per-pair [PairRateLimiter] as `ask_agent`, before
/// anything is posted.
class ConsultAgentTool extends McpScopedTool {
  /// Creates a new [ConsultAgentTool]. [service], `peerAsks` and
  /// `rateLimiter` are the instances every peer tool shares.
  ConsultAgentTool({
    required AgentRepository agents,
    required this._messaging,
    required TicketWorkflowService service,
    required this._peerAsks,
    required this._rateLimiter,
  }) : _peers = PeerAgentMessaging(agents: agents, messaging: _messaging),
       _agents = agents,
       _gate = PeerDelegationGate(service: service);

  final PeerAgentMessaging _peers;
  final AgentRepository _agents;
  final MessagingRepository _messaging;
  final PeerAskService _peerAsks;
  final PeerDelegationGate _gate;
  final PairRateLimiter _rateLimiter;

  @override
  String get name => 'consult_agent';

  /// Not for scripts: it starts another agent run (see
  /// [McpTool.scriptCallable]).
  @override
  bool get scriptCallable => false;
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.processSpawn};

  /// `agent_id` is the consulting agent: the caller, never a model's choice.
  @override
  Set<String> get forcedScopeKeys => const {'agent_id'};

  /// The in-process harness's call carries its run's attested scope.
  @override
  Future<CallResult> callForRun(
    Map<String, dynamic> arguments,
    McpCallScope scope, {
    Future<void>? abandoned,
  }) =>
      callScoped(arguments, McpCallContext(scope: scope), abandoned: abandoned);

  @override
  String get description =>
      'Consult a specialist agent for expert input on a specific topic. Name '
      'the specialist by to_agent_id or exact to_agent_name (use list_agents '
      'to find one; ambiguous or unknown names are rejected with the '
      'candidates; no fuzzy matching). The agent is added as a space '
      'participant and woken with a focused brief; you are woken in this '
      'conversation when it answers. Use when you need confirmation or '
      'specialist input for a planning decision. If no suitable agent exists, '
      'suggest hiring one. Message another agent only with a question that '
      'blocks you or a decision it must make, and send it to the one agent '
      'that can answer. Never send status, progress or completion notes: '
      'your result reaches whoever started you without a message.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'space_id': {'type': 'string', 'description': 'The plan space ID.'},
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace whose agents are eligible.',
      },
      'to_agent_id': {
        'type': 'string',
        'description': 'The specialist agent id (preferred).',
      },
      'to_agent_name': {
        'type': 'string',
        'description':
            'The specialist agent name (an exact, unique match in the '
            'workspace). Provide this OR to_agent_id.',
      },
      'topic': {
        'type': 'string',
        'description':
            'The expertise you are consulting them for (e.g. "security", '
            '"performance"). Framing for the brief, not used to pick the agent.',
      },
      'question': {
        'type': 'string',
        'description':
            'The specific question or decision you need specialist input on.',
      },
      'rationale': {
        'type': 'string',
        'description': 'Why this input is needed for the plan (optional).',
      },
      'agent_id': {
        'type': 'string',
        'description':
            'Set by Control Center to the calling agent (the requester); '
            'any value you pass is replaced.',
      },
      McpCallScope.callerConversationKey: callerConversationProperty,
    },
    'required': ['space_id', 'workspace_id', 'topic', 'question'],
  };

  @override
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
    final rawSpaceId = arguments['space_id'];
    if (rawSpaceId is! String) {
      return CallResult.error(
        'Missing or invalid argument: space_id (expected string)',
      );
    }
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final rawTopic = arguments['topic'];
    if (rawTopic is! String) {
      return CallResult.error(
        'Missing or invalid argument: topic (expected string)',
      );
    }
    final rawQuestion = arguments['question'];
    if (rawQuestion is! String) {
      return CallResult.error(
        'Missing or invalid argument: question (expected string)',
      );
    }

    final spaceId = rawSpaceId;
    final workspaceId = rawWorkspaceId;
    final topic = rawTopic;
    final question = rawQuestion;
    final rationale = arguments['rationale'] as String?;
    final caller = PeerCaller.of(arguments, context, agentKey: 'agent_id');
    final requesterId = caller.agentId;
    final tooLong = peerMessageSizeRefusal(
      [question, ?rationale].join('\n'),
      label: 'question',
    );
    if (tooLong != null) {
      return CallResult.error(tooLong);
    }
    final readOnly = caller.readOnlyRefusal(_peerAsks);
    if (readOnly != null) {
      return peerRefusalResult(readOnly);
    }

    if (!await _messaging.spaceExists(workspaceId, spaceId)) {
      return CallResult.error('Space belongs to a different workspace.');
    }
    final resolution = await _peers.resolveRecipient(
      workspaceId: workspaceId,
      toAgentId: arguments['to_agent_id'] as String?,
      toAgentName: arguments['to_agent_name'] as String?,
    );
    if (resolution is UnresolvedRecipient) {
      return CallResult.error(resolution.message);
    }
    final match = (resolution as ResolvedRecipient).agent;
    // Every guard runs BEFORE any side effect, as for `ask_agent`. A call with
    // no calling agent (a person's own MCP client) is no agent hand-off.
    var chain = PeerChain.none;
    if (requesterId != null) {
      chain = await _peerAsks.chainOf(
        workspaceId,
        requesterId,
        runId: caller.runId,
        conversationId: caller.conversationId,
      );
      final refusal =
          await _gate.refusal(
            workspaceId: workspaceId,
            fromAgentId: requesterId,
            recipientId: match.id,
            chain: chain,
            spaceId: spaceId,
          ) ??
          await _peerAsks.refusalFor(
            workspaceId: workspaceId,
            askerAgentId: requesterId,
            askerConversationId: caller.conversationId,
            recipientAgentId: match.id,
            question: question,
            chain: chain,
          );
      if (refusal != null) {
        return peerRefusalResult(refusal);
      }
      if (!_rateLimiter.tryAcquire(requesterId, match.id, DateTime.now())) {
        return peerRefusalResult(
          PeerAskRefusal(
            PeerGateRefusals.rateLimited,
            'Rate limited: too many messages from "$requesterId" to '
            '"${match.name}" in a short window. Wait before consulting again.',
          ),
        );
      }
    }
    final existingParticipants = await _messaging.getParticipants(
      workspaceId,
      spaceId,
    );
    final existingAgentIds = {
      for (final p in existingParticipants)
        if (!p.isUser) p.principalId,
    };

    if (!existingAgentIds.contains(match.id)) {
      await _messaging.addParticipant(workspaceId, spaceId, match.id);
    }

    final noticeId = await _messaging.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content: '@${match.name} you are being consulted as "$topic". $question',
      senderId: 'system',
      senderType: 'system',
      messageType: 'system',
    );
    final conversationId = (await _messaging.getMessageById(
      workspaceId,
      noticeId,
    ))?.conversationId;
    if (conversationId == null) {
      return CallResult.error(
        'The consult was posted in space $spaceId but its conversation could '
        'not be read; the specialist was not woken.',
      );
    }

    final brief = _buildConsultationBrief(
      agentName: match.name,
      topic: topic,
      question: question,
      rationale: rationale,
    );
    final base = <String, Object?>{
      'space_id': spaceId,
      'consulted_agent_id': match.id,
      'consulted_agent_name': match.name,
      'topic': topic,
      'question': question,
    };
    if (requesterId == null) {
      final receipt = await _peerAsks.deliver(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        recipientAgentId: match.id,
        payload: brief,
        messageId: noticeId,
        chain: const [],
      );
      return CallResult.success(
        jsonEncode({
          ...base,
          'delivery_status': peerDeliveryStatus(receipt).status,
        }),
      );
    }
    final requester = await _agents.getById(workspaceId, requesterId);
    final result = await _peerAsks.ask(
      PeerAskRequest(
        workspaceId: workspaceId,
        kind: PeerAskKind.consult,
        mode: PeerAskMode.background,
        askerAgentId: requesterId,
        askerName: requester?.name ?? requesterId,
        askerRunId: caller.runId,
        askerConversationId: caller.conversationId!,
        recipientAgentId: match.id,
        recipientSpaceId: spaceId,
        recipientConversationId: conversationId,
        questionMessageId: noticeId,
        question: question,
        payload: brief,
        chain: chain.extendedBy(requesterId),
      ),
    );
    return switch (result) {
      PeerAskRefused(:final refusal) => peerRefusalResult(refusal),
      PeerAskSettledInline(:final ask, :final status, :final error) =>
        CallResult.success(
          jsonEncode({
            ...base,
            'ask_id': ask.id,
            'status': status.wire,
            'error': ?error,
          }),
        ),
      PeerAskPending(:final ask) => CallResult.success(
        jsonEncode({
          ...base,
          'ask_id': ask.id,
          'status': 'pending',
          'note':
              'You are woken in this conversation when ${match.name} answers. '
              'Keep working on what the answer does not block, then end your '
              'turn.',
        }),
      ),
    };
  }

  String _buildConsultationBrief({
    required String agentName,
    required String topic,
    required String question,
    required String? rationale,
  }) {
    final rationaleSection = rationale != null ? '\nContext: $rationale\n' : '';
    return 'You have been consulted as the "$topic" specialist for a '
        'planning discussion.$rationaleSection\n'
        'The planning agent asks:\n$question\n\n'
        'Please respond with your expert assessment. Be concise and '
        'actionable. The planning agent will incorporate your input into '
        'the written plan.';
  }
}
