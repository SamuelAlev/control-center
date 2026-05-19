import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/dispatch/domain/peer_delivery_outcome.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_mcp/src/tools/peer_agent_messaging.dart';

/// Sends a fire-and-forget peer message from one agent to another (PRD 22 §2).
///
/// The recipient is resolved exactly (by id or unique name), the ordered
/// sender→recipient pair is rate-limited to kill ping-pong storms, an agent-DM
/// channel between the two agents is reused (or created), the message is
/// persisted and the recipient is dispatched with it as the prompt. It does
/// NOT wait for a reply — use `ask_agent` for request/reply.
class SendToAgentTool extends McpTool {
  /// Creates a [SendToAgentTool]. [eventBus] lets a freshly minted DM channel
  /// announce itself so the background provisioner runs (see
  /// [PeerAgentMessaging]).
  SendToAgentTool({
    required AgentRepository agents,
    required MessagingRepository messaging,
    required MessagingPort messagingPort,
    required PairRateLimiter rateLimiter,
    DomainEventBus? eventBus,
  }) : _peers = PeerAgentMessaging(
         agents: agents,
         messaging: messaging,
         eventBus: eventBus,
       ),
       _messaging = messaging,
       _messagingPort = messagingPort,
       _rateLimiter = rateLimiter;

  final PeerAgentMessaging _peers;
  final MessagingRepository _messaging;
  final MessagingPort _messagingPort;
  final PairRateLimiter _rateLimiter;

  @override
  String get name => 'send_to_agent';
  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.workspaceMutation,
    ActionClass.processSpawn,
  };

  @override
  String get description =>
      'Send a one-way message to another agent in your workspace. Name the '
      'recipient by to_agent_id or exact to_agent_name (ambiguous or unknown '
      'names are rejected with the candidates — no fuzzy matching). The message '
      'is delivered into a shared agent-to-agent DM channel and the recipient '
      'is woken to act on it. Fire-and-forget: it does not wait for a reply '
      '(use ask_agent for that). The ordered sender→recipient pair is '
      'rate-limited to prevent runaway back-and-forth.';

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
        'description': 'Your own agent id (the sender), when known.',
      },
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
  Future<CallResult> run(Map<String, dynamic> arguments) async {
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
    final fromAgentId = arguments['from_agent_id'] as String?;

    final resolution = await _peers.resolveRecipient(
      workspaceId: workspaceId,
      toAgentId: arguments['to_agent_id'] as String?,
      toAgentName: arguments['to_agent_name'] as String?,
    );
    if (resolution is UnresolvedRecipient) {
      return CallResult.error(resolution.message);
    }
    final recipient = (resolution as ResolvedRecipient).agent;

    // Deterministic per-pair rate limit (PRD 22 §3): refuse loudly with a
    // visible notice rather than silently dropping the message.
    final fromKey = fromAgentId ?? 'system';
    if (!_rateLimiter.tryAcquire(fromKey, recipient.id, DateTime.now())) {
      return CallResult.error(
        'Rate limited: too many messages from "$fromKey" to '
        '"${recipient.name}" in a short window. Wait before sending again.',
      );
    }

    final channel = await _peers.resolveOrCreateAgentDm(
      workspaceId: workspaceId,
      toAgentId: recipient.id,
      toAgentName: recipient.name,
      fromAgentId: fromAgentId,
    );

    final messageId = await _messaging.sendMessage(
      workspaceId: workspaceId,
      channelId: channel.id,
      content: message,
      senderId: fromKey,
      senderType: 'agent',
    );

    final runLogId = await _messagingPort.dispatchAgent(
      channelId: channel.id,
      agentId: recipient.id,
      prompt: message,
      workspaceId: workspaceId,
      inReplyToAgentId: fromAgentId,
    );

    // A non-null run id means the recipient got a real wake turn; a null id
    // means it could not be dispatched now (the message stays in the channel).
    final delivery = runLogId != null
        ? PeerDeliveryOutcome.woken.name
        : 'queued';

    return CallResult.success(
      jsonEncode({
        'channel_id': channel.id,
        'message_id': messageId,
        'recipient_agent_id': recipient.id,
        'recipient_agent_name': recipient.name,
        'delivery_status': delivery,
      }),
    );
  }
}
