import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_mcp/src/tools/peer_agent_messaging.dart';

/// Asks another agent a question and waits for its reply (PRD 22 §2, §4).
///
/// Shares recipient resolution, the per-pair rate limit and agent-DM channel
/// reuse with `send_to_agent`, then blocks on the recipient's next message in
/// the channel. The wait ALWAYS has a bounded, mandatory timeout (default 600s,
/// configurable up to 1800s) — it can never block forever. On a reply it
/// returns the reply text; on timeout it returns a structured (non-error)
/// result naming the still-pending channel + message so the caller can resume.
class AskAgentTool extends McpTool {
  /// Creates an [AskAgentTool]. [eventBus] lets a freshly minted DM channel
  /// announce itself so the background provisioner runs (see
  /// [PeerAgentMessaging]).
  AskAgentTool({
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

  /// Default reply timeout in seconds (10 minutes) when unspecified.
  static const int _defaultTimeoutSeconds = 600;

  /// Hard ceiling for a configured reply timeout in seconds (30 minutes). No
  /// configuration can remove the timeout — the wait always resumes.
  static const int _maxTimeoutSeconds = 1800;

  @override
  String get name => 'ask_agent';
  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.workspaceMutation,
    ActionClass.processSpawn,
  };

  @override
  String get description =>
      'Ask another agent a question and wait for its reply. Name the recipient '
      'by to_agent_id or exact to_agent_name (ambiguous or unknown names are '
      'rejected with the candidates — no fuzzy matching). The question is '
      'delivered into a shared agent-to-agent DM channel, the recipient is '
      'woken and this call blocks until it replies or the timeout elapses '
      '(default 600s, up to 1800s). It ALWAYS resumes on timeout, returning a '
      'pending status with the channel and message id. Note: recipients running '
      'on an external-CLI adapter reply on their next turn rather than '
      'instantly, so a timeout does not mean the question was lost.';

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
        'description': 'The question to ask the recipient agent.',
      },
      'from_agent_id': {
        'type': 'string',
        'description': 'Your own agent id (the asker), when known.',
      },
      'timeout_seconds': {
        'type': 'integer',
        'description':
            'How long to wait for a reply before returning a pending '
            'result. Defaults to 600, capped at 1800. The timeout can never '
            'be disabled.',
      },
      'context_refs': {
        'type': 'array',
        'items': {'type': 'string'},
        'description':
            'Optional ids of tickets/PRs/messages that give the recipient '
            'context for the question.',
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
    final timeoutSeconds = _resolveTimeoutSeconds(arguments['timeout_seconds']);

    final resolution = await _peers.resolveRecipient(
      workspaceId: workspaceId,
      toAgentId: arguments['to_agent_id'] as String?,
      toAgentName: arguments['to_agent_name'] as String?,
    );
    if (resolution is UnresolvedRecipient) {
      return CallResult.error(resolution.message);
    }
    final recipient = (resolution as ResolvedRecipient).agent;

    final fromKey = fromAgentId ?? 'system';
    if (!_rateLimiter.tryAcquire(fromKey, recipient.id, DateTime.now())) {
      return CallResult.error(
        'Rate limited: too many messages from "$fromKey" to '
        '"${recipient.name}" in a short window. Wait before asking again.',
      );
    }

    final channel = await _peers.resolveOrCreateAgentDm(
      workspaceId: workspaceId,
      toAgentId: recipient.id,
      toAgentName: recipient.name,
      fromAgentId: fromAgentId,
    );

    // Snapshot the existing message ids so the reply we wait for is strictly a
    // NEW message from the recipient (a reused channel may hold older replies).
    final before = await _messaging.getMessages(workspaceId, channel.id);
    final knownIds = {for (final m in before) m.id};

    final askMessageId = await _messaging.sendMessage(
      workspaceId: workspaceId,
      channelId: channel.id,
      content: message,
      senderId: fromKey,
      senderType: 'agent',
    );

    await _messagingPort.dispatchAgent(
      channelId: channel.id,
      agentId: recipient.id,
      prompt: message,
      workspaceId: workspaceId,
      inReplyToAgentId: fromAgentId,
    );

    final reply = await _awaitReply(
      workspaceId: workspaceId,
      channelId: channel.id,
      recipientId: recipient.id,
      knownIds: knownIds,
      timeout: Duration(seconds: timeoutSeconds),
    );

    if (reply == null) {
      // Mandatory-timeout contract: always resume, never error. The question
      // stays pending in the channel; the reply will land there.
      return CallResult.success(
        jsonEncode({
          'status': 'timeout',
          'channel_id': channel.id,
          'pending_message_id': askMessageId,
          'recipient_agent_id': recipient.id,
          'recipient_agent_name': recipient.name,
          'timeout_seconds': timeoutSeconds,
          'note':
              'No reply within ${timeoutSeconds}s. The question is still '
              'pending in the channel; poll get_channel_messages to collect the '
              'reply later. External-CLI recipients reply on their next turn.',
        }),
      );
    }

    return CallResult.success(
      jsonEncode({
        'status': 'replied',
        'channel_id': channel.id,
        'reply_message_id': reply.id,
        'reply': reply.content,
        'recipient_agent_id': recipient.id,
        'recipient_agent_name': recipient.name,
      }),
    );
  }

  /// Clamps the requested timeout to `[1, _maxTimeoutSeconds]`, defaulting to
  /// [_defaultTimeoutSeconds]. The timeout is never removable.
  int _resolveTimeoutSeconds(Object? raw) {
    var seconds = _defaultTimeoutSeconds;
    if (raw is int) {
      seconds = raw;
    } else if (raw is num) {
      seconds = raw.toInt();
    }
    if (seconds < 1) {
      seconds = 1;
    }
    if (seconds > _maxTimeoutSeconds) {
      seconds = _maxTimeoutSeconds;
    }
    return seconds;
  }

  /// Waits for the recipient's next completed message in the channel, or null
  /// when [timeout] elapses first. The wait has a single overall deadline (it
  /// does not reset on each streaming delta).
  Future<ChannelMessage?> _awaitReply({
    required String workspaceId,
    required String channelId,
    required String recipientId,
    required Set<String> knownIds,
    required Duration timeout,
  }) async {
    bool isReply(ChannelMessage m) {
      if (m.senderId != recipientId) {
        return false;
      }
      if (m.senderType != ChannelSenderType.agent) {
        return false;
      }
      if (knownIds.contains(m.id) || m.isSystem) {
        return false;
      }
      // An agent turn only counts once it has finished streaming.
      if (m.isAgentTurn) {
        return m.isStreamingComplete;
      }
      return m.content.trim().isNotEmpty;
    }

    final completer = Completer<ChannelMessage?>();
    // Watches the channel's `main` conversation (id == channel id).
    final subscription = _messaging
        .watchMessages(workspaceId, channelId, channelId)
        .listen((messages) {
          if (completer.isCompleted) {
            return;
          }
          for (final m in messages) {
            if (isReply(m)) {
              completer.complete(m);
              return;
            }
          }
        });
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });
    try {
      return await completer.future;
    } finally {
      await subscription.cancel();
      timer.cancel();
    }
  }
}
