import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:uuid/uuid.dart';

/// MCP tool used by a reviewer agent to ask a teammate for a second
/// opinion on a specific review node. Posts a thread reply tagging the
/// target agent with the question. Distinct from `request_confirmation`
/// (which prompts the *user* for UI confirmation of a destructive
/// action).
class RequestPeerReviewTool extends McpTool {
  /// Creates a new [RequestPeerReviewTool].
  RequestPeerReviewTool({required MessagingRepository messaging})
    : _messaging = messaging;

  final MessagingRepository _messaging;

  @override
  String get name => 'request_peer_review';

  @override
  String get description =>
      'Ask another reviewer agent to take a second look at a review node. '
      'Posts a thread reply on the target node tagging the teammate with '
      'your question. Use when you are unsure about a finding and want a '
      'peer confirmation before it lands in the final review.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'channel_id': {
        'type': 'string',
        'description': 'The review channel ID.',
      },
      'node_message_id': {
        'type': 'string',
        'description':
            'The review-node message id the question is attached to.',
      },
      'requester_id': {
        'type': 'string',
        'description': 'The asking agent id.',
      },
      'target_agent_id': {
        'type': 'string',
        'description': 'The teammate being asked.',
      },
      'question': {
        'type': 'string',
        'description': 'The question or context for the peer review.',
      },
    },
    'required': [
      'channel_id',
      'node_message_id',
      'requester_id',
      'target_agent_id',
      'question',
    ],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawChannelId = arguments['channel_id'];
    if (rawChannelId is! String) {
      return CallResult.error(
        'Missing or invalid argument: channel_id (expected string)',
      );
    }
    final rawNodeMessageId = arguments['node_message_id'];
    if (rawNodeMessageId is! String) {
      return CallResult.error(
        'Missing or invalid argument: node_message_id (expected string)',
      );
    }
    final rawRequester = arguments['requester_id'];
    if (rawRequester is! String) {
      return CallResult.error(
        'Missing or invalid argument: requester_id (expected string)',
      );
    }
    final rawTarget = arguments['target_agent_id'];
    if (rawTarget is! String) {
      return CallResult.error(
        'Missing or invalid argument: target_agent_id (expected string)',
      );
    }
    final rawQuestion = arguments['question'];
    if (rawQuestion is! String) {
      return CallResult.error(
        'Missing or invalid argument: question (expected string)',
      );
    }

    final replyId = const Uuid().v4();
    await _messaging.sendMessage(
      channelId: rawChannelId,
      content: '@$rawTarget $rawQuestion',
      senderId: rawRequester,
      senderType: 'agent',
      messageType: 'text',
      parentMessageId: rawNodeMessageId,
      id: replyId,
      metadata: {
        'peerReviewRequest': true,
        'requester': rawRequester,
        'target': rawTarget,
      },
    );

    return CallResult.success(
      jsonEncode({
        'reply_id': replyId,
        'thread_root': rawNodeMessageId,
        'target_agent_id': rawTarget,
      }),
    );
  }
}
