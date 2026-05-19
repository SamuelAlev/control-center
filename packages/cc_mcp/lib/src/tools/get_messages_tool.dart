import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// Get space messages tool.
class GetSpaceMessagesTool extends McpTool {
  /// Creates a new [Get space messages tool].
  GetSpaceMessagesTool({required MessagingRepository repository})
    : _repository = repository;

  final MessagingRepository _repository;

  @override
  String get name => 'get_messages';

  @override
  String get description =>
      'Fetches messages from a space, optionally limited. Pass conversation_id '
      'to read a specific conversation (stream) inside the space — for '
      'example a thread; omit it to read the standing conversation.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the space must belong to.',
      },
      'space_id': {'type': 'string', 'description': 'The space ID.'},
      'conversation_id': {
        'type': 'string',
        'description':
            'The conversation (stream) to read, inside the space — for '
            'example a thread. Defaults to the space\'s standing '
            'conversation.',
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of messages to return (default 50).',
        'default': 50,
      },
    },
    'required': ['workspace_id', 'space_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final rawSpaceId = arguments['space_id'];
    if (rawSpaceId is! String) {
      return CallResult.error(
        'Missing or invalid argument: space_id (expected string)',
      );
    }
    final workspaceId = rawWorkspaceId;
    final spaceId = rawSpaceId;
    final limit = McpTool.clampLimit(arguments, 50);

    // Workspace isolation (hard invariant): the space MUST belong to the
    // caller's workspace. A bare space_id is NOT proof of ownership — scope
    // it against the workspace's spaces (same pattern as ListSpacesTool).
    // Reject loudly on a foreign/unknown space.
    final spaces = await _repository
        .watchSpacesByWorkspace(workspaceId)
        .first;
    if (!spaces.any((c) => c.id == spaceId)) {
      return CallResult.error('Space belongs to a different workspace.');
    }

    final messages = await _repository.getMessages(
      workspaceId,
      spaceId,
      conversationId: arguments['conversation_id'] is String
          ? arguments['conversation_id'] as String
          : null,
    );

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
