import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// Send space message tool.
class SendSpaceMessageTool extends McpTool {
  /// Creates a new [Send space message tool].
  SendSpaceMessageTool({required MessagingRepository repository})
    : _repository = repository;

  final MessagingRepository _repository;

  @override
  String get name => 'send_message';

  @override
  String get description =>
      'Sends a message into a space from a specific sender agent. The space '
      'must belong to the given workspace. Pass conversation_id to target a '
      'specific conversation (stream) inside the space — for example a thread '
      'opened with start-thread semantics; omit it to post into the space\'s '
      'standing conversation. Supersedes the old send_channel_message tool.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the space must belong to.',
      },
      'space_id': {'type': 'string', 'description': 'The space ID.'},
      'sender_id': {'type': 'string', 'description': 'The sender agent ID.'},
      'content': {'type': 'string', 'description': 'Message content.'},
      'conversation_id': {
        'type': 'string',
        'description':
            'Optional conversation (stream) id inside the space. Omit to use '
            'the standing conversation.',
      },
    },
    'required': ['workspace_id', 'space_id', 'sender_id', 'content'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String || rawWorkspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final rawSpaceId = arguments['space_id'];
    if (rawSpaceId is! String) {
      return CallResult.error(
        'Missing or invalid argument: space_id (expected string)',
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
    final spaceId = rawSpaceId;
    final senderId = rawSenderId;
    final content = rawContent;

    // A bare space_id proves nothing: reject a space that does not resolve
    // inside the caller's workspace instead of writing across the boundary.
    if (!await _repository.spaceExists(workspaceId, spaceId)) {
      return CallResult.error('Space belongs to a different workspace.');
    }

    await _repository.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      senderId: senderId,
      content: content,
      senderType: 'agent',
      conversationId: arguments['conversation_id'] is String
          ? arguments['conversation_id'] as String
          : null,
    );

    return CallResult.success(
      jsonEncode({
        'space_id': spaceId,
        'sender_id': senderId,
        'status': 'sent',
      }),
    );
  }
}
