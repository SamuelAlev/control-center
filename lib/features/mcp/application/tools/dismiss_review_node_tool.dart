import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';

/// MCP tool that dismisses a review node finding.
///
/// Updates the node metadata to `status: 'dismissed'` and posts a thread
/// reply with the dismissal reason.
class DismissReviewNodeTool extends McpTool {
  /// Creates a new [DismissReviewNodeTool].
  DismissReviewNodeTool({required MessagingRepository repository})
    : _repository = repository;

  final MessagingRepository _repository;

  @override
  String get name => 'dismiss_review_node';

  @override
  String get description =>
      'Dismisses a review node finding. Updates the node status to '
      '"dismissed" and posts a dismissal reason as a system message.';

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
        'description': 'The message ID of the review node to dismiss.',
      },
      'agent_id': {
        'type': 'string',
        'description': 'The ID of the agent dismissing the finding.',
      },
      'reason': {
        'type': 'string',
        'description': 'Reason for dismissing the finding.',
      },
    },
    'required': ['channel_id', 'node_message_id', 'agent_id', 'reason'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawChannelId = arguments['channel_id'];
    if (rawChannelId is! String) {
      return CallResult.error('Missing or invalid argument: channel_id (expected string)');
    }
    final rawNodeMessageId = arguments['node_message_id'];
    if (rawNodeMessageId is! String) {
      return CallResult.error('Missing or invalid argument: node_message_id (expected string)');
    }
    final rawAgentId = arguments['agent_id'];
    if (rawAgentId is! String) {
      return CallResult.error('Missing or invalid argument: agent_id (expected string)');
    }
    final rawReason = arguments['reason'];
    if (rawReason is! String) {
      return CallResult.error('Missing or invalid argument: reason (expected string)');
    }
    final channelId = rawChannelId;
    final nodeMessageId = rawNodeMessageId;
    final agentId = rawAgentId;
    final reason = rawReason;

    final messages = await _repository.getMessages(channelId);
    final target = messages.where((m) => m.id == nodeMessageId).firstOrNull;

    if (target == null) {
      return CallResult.error('Review node not found: $nodeMessageId');
    }

    final metadata = Map<String, dynamic>.from(target.metadata ?? {});
    metadata['status'] = 'dismissed';

    await _repository.updateMessage(nodeMessageId, metadata: metadata);

    await _repository.sendMessage(
      channelId: channelId,
      content: '❌ Agent `$agentId` dismissed this finding: $reason',
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
    );

    return CallResult.success(
      jsonEncode({
        'node_message_id': nodeMessageId,
        'status': 'dismissed',
        'dismissed_by': agentId,
        'reason': reason,
      }),
    );
  }
}
