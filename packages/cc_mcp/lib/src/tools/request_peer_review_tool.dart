import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
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
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the review channel belongs to.',
      },
      'channel_id': {'type': 'string', 'description': 'The review channel ID.'},
      'node_message_id': {
        'type': 'string',
        'description':
            'The review-node message id the question is attached to.',
      },
      'requester_id': {'type': 'string', 'description': 'The asking agent id.'},
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
      'workspace_id',
      'channel_id',
      'node_message_id',
      'requester_id',
      'target_agent_id',
      'question',
    ],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String || rawWorkspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
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
      workspaceId: rawWorkspaceId,
      channelId: rawChannelId,
      content: '@$rawTarget $rawQuestion',
      senderId: rawRequester,
      senderType: 'agent',
      messageType: 'text',
      id: replyId,
      // Link the discussion message to its review node via metadata (threading
      // was removed). The review accordion filters on `reviewNodeId`.
      metadata: {
        'peerReviewRequest': true,
        'reviewNodeId': rawNodeMessageId,
        'requester': rawRequester,
        'target': rawTarget,
      },
    );

    return CallResult.success(
      jsonEncode({
        'reply_id': replyId,
        'review_node_id': rawNodeMessageId,
        'target_agent_id': rawTarget,
      }),
    );
  }
}
