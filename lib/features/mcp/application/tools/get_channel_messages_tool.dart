import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';

/// Get channel messages tool.
class GetChannelMessagesTool extends McpTool {
  /// Creates a new [Get channel messages tool].
  GetChannelMessagesTool({required MessagingRepository repository})
    : _repository = repository;

  final MessagingRepository _repository;

  @override
  String get name => 'get_channel_messages';

  @override
  String get description =>
      'Fetches messages from a specific channel, optionally limited.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'channel_id': {
        'type': 'string',
        'description': 'The channel ID.',
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of messages to return (default 50).',
        'default': 50,
      },
    },
    'required': ['channel_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawChannelId = arguments['channel_id'];
    if (rawChannelId is! String) {
      return CallResult.error('Missing or invalid argument: channel_id (expected string)');
    }
    final rawLimit = arguments['limit'];
    final channelId = rawChannelId;
    final limit = rawLimit is int ? rawLimit : 50;

    final messages = await _repository.getMessages(channelId);

    final list = messages
        .take(limit)
        .map(
          (m) => {
            'id': m.id,
            'content': m.content,
            'sender_id': m.senderId,
            'sender_type': m.senderType.name,
            'message_type': m.messageType.name,
            'metadata': m.metadata,
            'created_at': m.createdAt.toIso8601String(),
          },
        )
        .toList();

    return CallResult.success(
      jsonEncode({'messages': list, 'count': list.length}),
    );
  }
}
