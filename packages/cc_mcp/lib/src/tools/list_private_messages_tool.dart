import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// List private messages tool.
class ListPrivateMessagesTool extends McpTool {
  /// Creates a new [List private messages tool].
  ListPrivateMessagesTool({required MessagingRepository repository})
    : _repository = repository;

  final MessagingRepository _repository;

  @override
  String get name => 'list_private_messages';

  @override
  String get description =>
      'Lists private messages in a workspace\'s DM channels. '
      'DMs are channels with exactly 2 participants (user + 1 agent).';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace ID to list DMs for.',
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum total messages to return (default 50). Messages are truncated to 500 characters.',
        'default': 50,
      },
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    final rawLimit = arguments['limit'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final limit = rawLimit is int ? rawLimit : 50;

    // Workspace-scoped at the query level — never fetch every workspace's
    // channels and filter in memory.
    final channels =
        await _repository.watchChannelsByWorkspace(rawWorkspaceId).first;
    final filtered = channels.where((c) => c.isDm).toList();

    final result = <Map<String, dynamic>>[];
    for (final channel in filtered) {
      final messages = await _repository.getMessages(channel.id);

      for (final msg in messages) {
        if (result.length >= limit) {
          break;
        }
        result.add({
          'id': msg.id,
          'channel_id': msg.channelId,
          'sender_id': msg.senderId,
          'sender_type': msg.senderType.name,
          'content': msg.content.length > 500
              ? '${msg.content.substring(0, 500)}...'
              : msg.content,
          'created_at': msg.createdAt.toIso8601String(),
        });
      }
      if (result.length >= limit) {
        break;
      }
    }

    return CallResult.success(
      jsonEncode({'messages': result, 'count': result.length}),
    );
  }
}
