import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// Send channel message tool.
class SendChannelMessageTool extends McpTool {
  /// Creates a new [Send channel message tool].
  SendChannelMessageTool({required MessagingRepository repository})
    : _repository = repository;

  final MessagingRepository _repository;

  @override
  String get name => 'send_channel_message';

  @override
  String get description =>
      'Sends a message to a channel from a specific sender agent. The channel '
      'must belong to the given workspace.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the channel must belong to.',
      },
      'channel_id': {'type': 'string', 'description': 'The channel ID.'},
      'sender_id': {'type': 'string', 'description': 'The sender agent ID.'},
      'content': {'type': 'string', 'description': 'Message content.'},
    },
    'required': ['workspace_id', 'channel_id', 'sender_id', 'content'],
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
    final rawSenderId = arguments['sender_id'];
    if (rawSenderId is! String) {
      return CallResult.error(
        'Missing or invalid argument: sender_id (expected string)',
      );
    }
    final rawContent = arguments['content'];
    if (rawContent is! String) {
      return CallResult.error(
        'Missing or invalid argument: content (expected string)',
      );
    }
    final workspaceId = rawWorkspaceId;
    final channelId = rawChannelId;
    final senderId = rawSenderId;
    final content = rawContent;

    // A bare channel_id proves nothing: reject a channel that does not resolve
    // inside the caller's workspace instead of writing across the boundary.
    if (!await _repository.channelExists(workspaceId, channelId)) {
      return CallResult.error('Channel belongs to a different workspace.');
    }

    await _repository.sendMessage(
      workspaceId: workspaceId,
      channelId: channelId,
      senderId: senderId,
      content: content,
      senderType: 'agent',
    );

    return CallResult.success(
      jsonEncode({
        'channel_id': channelId,
        'sender_id': senderId,
        'status': 'sent',
      }),
    );
  }
}
