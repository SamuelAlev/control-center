import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:uuid/uuid.dart';

/// MCP tool that sends a threaded reply to a specific message.
///
/// Posts a message with `parentMessageId` set, creating a thread reply.
class SendThreadReplyTool extends McpTool {
  /// Creates a new [SendThreadReplyTool].
  SendThreadReplyTool({required MessagingRepository repository})
    : _repository = repository;

  final MessagingRepository _repository;

  @override
  String get name => 'send_thread_reply';

  @override
  String get description =>
      'Sends a threaded reply to a specific message in a channel. Used for '
      'agent-to-agent discussion on review findings.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'channel_id': {
        'type': 'string',
        'description': 'The channel ID.',
      },
      'parent_message_id': {
        'type': 'string',
        'description': 'The message ID to reply to.',
      },
      'sender_id': {
        'type': 'string',
        'description': 'The sender agent ID.',
      },
      'content': {
        'type': 'string',
        'description': 'Reply content (markdown).',
      },
    },
    'required': ['channel_id', 'parent_message_id', 'sender_id', 'content'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawChannelId = arguments['channel_id'];
    if (rawChannelId is! String) {
      return CallResult.error('Missing or invalid argument: channel_id (expected string)');
    }
    final rawParentMessageId = arguments['parent_message_id'];
    if (rawParentMessageId is! String) {
      return CallResult.error('Missing or invalid argument: parent_message_id (expected string)');
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
    final parentMessageId = rawParentMessageId;
    final senderId = rawSenderId;
    final content = rawContent;

    final messageId = const Uuid().v4();

    await _repository.sendMessage(
      channelId: channelId,
      content: content,
      senderId: senderId,
      senderType: 'agent',
      id: messageId,
      metadata: {'parentMessageId': parentMessageId},
    );

    return CallResult.success(
      jsonEncode({
        'message_id': messageId,
        'channel_id': channelId,
        'parent_message_id': parentMessageId,
        'status': 'sent',
      }),
    );
  }
}
