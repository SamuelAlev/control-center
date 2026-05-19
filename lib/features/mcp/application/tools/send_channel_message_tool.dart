import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';

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
      'Sends a message to a channel from a specific sender agent.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'channel_id': {'type': 'string', 'description': 'The channel ID.'},
      'sender_id': {'type': 'string', 'description': 'The sender agent ID.'},
      'content': {'type': 'string', 'description': 'Message content.'},
    },
    'required': ['channel_id', 'sender_id', 'content'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawChannelId = arguments['channel_id'];
    if (rawChannelId is! String) {
      return CallResult.error('Missing or invalid argument: channel_id (expected string)');
    }
    final rawSenderId = arguments['sender_id'];
    if (rawSenderId is! String) {
      return CallResult.error('Missing or invalid argument: sender_id (expected string)');
    }
    final rawContent = arguments['content'];
    if (rawContent is! String) {
      return CallResult.error('Missing or invalid argument: content (expected string)');
    }
    final channelId = rawChannelId;
    final senderId = rawSenderId;
    final content = rawContent;

    await _repository.sendMessage(
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

