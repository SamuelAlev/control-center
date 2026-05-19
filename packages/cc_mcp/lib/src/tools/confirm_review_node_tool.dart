import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// MCP tool that confirms a review node finding by another agent.
///
/// Loads the target message's metadata, adds the confirming agent's ID to
/// `confirmedBy`, updates the message metadata, and posts a thread reply.
class ConfirmReviewNodeTool extends McpTool {
  /// Creates a new [ConfirmReviewNodeTool].
  ConfirmReviewNodeTool({required MessagingRepository repository})
    : _repository = repository;

  final MessagingRepository _repository;

  @override
  String get name => 'confirm_review_node';

  @override
  String get description =>
      'Confirms a review node finding by another agent (peer confirmation). '
      'The author cannot self-confirm. A finding moves to `consensus_ready` '
      'status after the first peer confirmation.';

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
        'description': 'The message ID of the review node to confirm.',
      },
      'agent_id': {
        'type': 'string',
        'description': 'The ID of the agent confirming the finding.',
      },
    },
    'required': ['channel_id', 'node_message_id', 'agent_id'],
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
    final channelId = rawChannelId;
    final nodeMessageId = rawNodeMessageId;
    final agentId = rawAgentId;

    final messages = await _repository.getMessages(channelId);
    final target = messages.where((m) => m.id == nodeMessageId).firstOrNull;

    if (target == null) {
      return CallResult.error('Review node not found: $nodeMessageId');
    }

    if (target.senderId == agentId) {
      return CallResult.error(
        'Authors cannot self-confirm their own review node.',
      );
    }

    final metadata = Map<String, dynamic>.from(target.metadata ?? {});
    final confirmedBy = List<String>.from(
      metadata['confirmedBy'] as List? ?? const [],
    );
    if (!confirmedBy.contains(agentId)) {
      confirmedBy.add(agentId);
    }
    metadata['confirmedBy'] = confirmedBy;

    // One peer confirmation is enough; CEO does the editorial pass.
    final current = metadata['status'] as String?;
    if (confirmedBy.isNotEmpty &&
        current != 'resolved' &&
        current != 'dismissed') {
      metadata['status'] = 'consensus_ready';
    }

    await _repository.updateMessage(nodeMessageId, metadata: metadata);

    await _repository.sendMessage(
      channelId: channelId,
      content: '✅ Agent `$agentId` confirmed this finding.',
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
      parentMessageId: nodeMessageId,
    );

    return CallResult.success(
      jsonEncode({
        'node_message_id': nodeMessageId,
        'confirmed_by': confirmedBy,
        'confirmation_count': confirmedBy.length,
        'status': metadata['status'],
      }),
    );
  }
}
