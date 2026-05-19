import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

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
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the channel must belong to.',
      },
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
    'required': ['workspace_id', 'channel_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final rawChannelId = arguments['channel_id'];
    if (rawChannelId is! String) {
      return CallResult.error('Missing or invalid argument: channel_id (expected string)');
    }
    final workspaceId = rawWorkspaceId;
    final channelId = rawChannelId;
    final rawLimit = arguments['limit'];
    final limit = rawLimit is int ? rawLimit : 50;

    // Workspace isolation (hard invariant): the channel MUST belong to the
    // caller's workspace. A bare channel_id is NOT proof of ownership — scope
    // it against the workspace's channels (same pattern as ListChannelsTool /
    // ListPrivateMessagesTool). Reject loudly on a foreign/unknown channel.
    final channels =
        await _repository.watchChannelsByWorkspace(workspaceId).first;
    if (!channels.any((c) => c.id == channelId)) {
      return CallResult.error('Channel belongs to a different workspace.');
    }

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
