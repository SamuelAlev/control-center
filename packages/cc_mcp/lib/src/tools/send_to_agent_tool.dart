import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart'
    show peerMessageGuidance;
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_message_limits.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/cc_infra.dart'
    show PeerAskRefusal, PeerAskService, PeerChain;
import 'package:cc_mcp/src/mcp_scoped_tool.dart';
import 'package:cc_mcp/src/tools/hidden_spaces_for_caller.dart';
import 'package:cc_mcp/src/tools/peer_agent_messaging.dart';
import 'package:cc_mcp/src/tools/peer_delegation_gate.dart';
import 'package:cc_mcp/src/tools/peer_tool_caller.dart';

/// Sends a one-way peer message from one agent to another (PRD 22 §2;
/// plan section 10, D19).
///
/// The recipient is resolved exactly (by id or unique name), the ordered
/// sender→recipient pair is rate-limited to kill ping-pong storms, an
/// agent-DM space between the two agents is reused (or created), the message
/// is persisted there and the recipient is woken through the wake queue (a
/// `peerMessage` wake, no requester: a run a peer starts is the bot's). It
/// does NOT wait for a reply: use `ask_agent` for that.
///
/// `delivery_status` is the queue's receipt: `woken`, `queued_behind_run`
/// (the recipient runs in that conversation; the wake waits) or `refused`
/// (with `delivery_kind`).
///
/// A message from an agent passes the same [PeerDelegationGate] (depth,
/// cycle, autonomy ceiling, budget; chains read from rows) as `ask_agent`
/// before anything is posted, then the shared pair rate limit.
class SendToAgentTool extends McpScopedTool {
  /// Creates a [SendToAgentTool]. [eventBus] lets a freshly minted DM space
  /// announce itself so the background provisioner runs (see
  /// [PeerAgentMessaging]). [service], `peerAsks` and `rateLimiter` are the
  /// instances every peer tool shares.
  SendToAgentTool({
    required AgentRepository agents,
    required MessagingRepository messaging,
    required this._rateLimiter,
    required TicketWorkflowService service,
    required this._peerAsks,
    DomainEventBus? eventBus,
  }) : _peers = PeerAgentMessaging(
         agents: agents,
         messaging: messaging,
         eventBus: eventBus,
       ),
       _gate = PeerDelegationGate(service: service),
       _agents = agents,
       _messaging = messaging;

  final PeerAgentMessaging _peers;
  final AgentRepository _agents;
  final MessagingRepository _messaging;
  final PairRateLimiter _rateLimiter;
  final PeerDelegationGate _gate;
  final PeerAskService _peerAsks;

  @override
  String get name => 'send_to_agent';

  /// Not for scripts: it messages another agent run (see
  /// [McpTool.scriptCallable]).
  @override
  bool get scriptCallable => false;
  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.workspaceMutation,
    ActionClass.processSpawn,
  };

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
      'Send a one-way message to another agent in your workspace. Name the '
      'recipient by to_agent_id or exact to_agent_name (ambiguous or unknown '
      'names are rejected with the candidates; no fuzzy matching). The '
      'message is posted in your DM space with that agent and wakes it. It '
      'does not wait for a reply (use ask_agent for that). The ordered '
      'sender→recipient pair is rate-limited. $peerMessageGuidance';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace both agents belong to.',
      },
      'to_agent_id': {
        'type': 'string',
        'description': 'Recipient agent id (preferred).',
      },
      'to_agent_name': {
        'type': 'string',
        'description':
            'Recipient agent name (must be an exact, unique match in the '
            'workspace). Provide this OR to_agent_id.',
      },
      'message': {
        'type': 'string',
        'description': 'The message to send to the recipient agent.',
      },
      'from_agent_id': {
        'type': 'string',
        'description': 'Set by Control Center to you (the sender), when known.',
      },
      McpCallScope.callerConversationKey: callerConversationProperty,
      'context_refs': {
        'type': 'array',
        'items': {'type': 'string'},
        'description':
            'Optional ids of tickets/PRs/messages that give the recipient '
            'context for the message.',
      },
    },
    'required': ['workspace_id', 'message'],
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
    final message = arguments['message'];
    if (message is! String || message.trim().isEmpty) {
      return CallResult.error(
        'Missing or invalid argument: message (expected non-empty string)',
      );
    }
    final tooLong = peerMessageSizeRefusal(message, label: 'message');
    if (tooLong != null) {
      return CallResult.error(tooLong);
    }
    final caller = PeerCaller.of(
      arguments,
      context,
      agentKey: 'from_agent_id',
    );
    final fromAgentId = caller.agentId;
    final readOnly = caller.readOnlyRefusal(_peerAsks);
    if (readOnly != null) {
      return peerRefusalResult(readOnly);
    }

    final resolution = await _peers.resolveRecipient(
      workspaceId: workspaceId,
      toAgentId: arguments['to_agent_id'] as String?,
      toAgentName: arguments['to_agent_name'] as String?,
    );
    if (resolution is UnresolvedRecipient) {
      return CallResult.error(resolution.message);
    }
    final recipient = (resolution as ResolvedRecipient).agent;

    // Every guard, before any side effect, as for `ask_agent`: waking an
    // agent that (through a pending ask) already waits on the sender starts
    // a loop, and a message starts a run of the recipient like any other
    // hand-off. A message with no calling agent (a person's own MCP client)
    // is no agent hand-off. Autonomy resolves in the pair's existing DM.
    var chain = PeerChain.none;
    if (fromAgentId != null) {
      chain = await _peerAsks.chainOf(
        workspaceId,
        fromAgentId,
        runId: caller.runId,
        conversationId: caller.conversationId,
      );
      final existingDm = await _peers.findAgentDm(
        workspaceId: workspaceId,
        toAgentId: recipient.id,
        fromAgentId: fromAgentId,
      );
      final refusal = await _gate.refusal(
        workspaceId: workspaceId,
        fromAgentId: fromAgentId,
        recipientId: recipient.id,
        chain: chain,
        spaceId: existingDm?.id,
      );
      if (refusal != null) {
        return peerRefusalResult(refusal);
      }
    }

    // Deterministic per-pair rate limit (PRD 22 §3): refuse loudly with a
    // visible notice rather than silently dropping the message.
    final fromKey = fromAgentId ?? 'system';
    if (!_rateLimiter.tryAcquire(fromKey, recipient.id, DateTime.now())) {
      return peerRefusalResult(
        PeerAskRefusal(
          PeerGateRefusals.rateLimited,
          'Rate limited: too many messages from "$fromKey" to '
          '"${recipient.name}" in a short window. Wait before sending again.',
        ),
      );
    }

    final space = await _peers.resolveOrCreateAgentDm(
      workspaceId: workspaceId,
      toAgentId: recipient.id,
      toAgentName: recipient.name,
      fromAgentId: fromAgentId,
    );
    final messageId = await _messaging.sendMessage(
      workspaceId: workspaceId,
      spaceId: space.id,
      content: message,
      senderId: fromKey,
      senderType: fromAgentId == null ? 'system' : 'agent',
    );
    final conversationId = (await _messaging.getMessageById(
      workspaceId,
      messageId,
    ))?.conversationId;
    if (conversationId == null) {
      return CallResult.error(
        'The message was posted in space ${space.id} but its conversation '
        'could not be read; the recipient was not woken.',
      );
    }
    final receipt = await _peerAsks.deliver(
      workspaceId: workspaceId,
      spaceId: space.id,
      conversationId: conversationId,
      recipientAgentId: recipient.id,
      payload: message,
      messageId: messageId,
      chain: fromAgentId == null ? const [] : chain.extendedBy(fromAgentId),
      senderAgentId: fromAgentId,
      senderName: fromAgentId == null
          ? null
          : (await _agents.getById(workspaceId, fromAgentId))?.name,
      senderRunId: caller.runId,
      senderConversationId: caller.conversationId,
    );
    final delivery = peerDeliveryStatus(receipt);
    return CallResult.success(
      jsonEncode({
        'space_id': space.id,
        'message_id': messageId,
        'recipient_agent_id': recipient.id,
        'recipient_agent_name': recipient.name,
        'delivery_status': delivery.status,
        'delivery_kind': ?delivery.kind,
      }),
    );
  }
}
