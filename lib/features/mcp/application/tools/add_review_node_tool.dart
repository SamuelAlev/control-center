import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:uuid/uuid.dart';

/// MCP tool that adds a structured review node (finding) to a review channel.
///
/// Posts a `ChannelMessage` with `messageType: 'review_node'` and structured
/// metadata containing node type, file path, line number, P0–P3 priority,
/// reviewer confidence, and confirmation tracking.
class AddReviewNodeTool extends McpTool {
  /// Creates a new [AddReviewNodeTool].
  AddReviewNodeTool({required MessagingRepository repository})
    : _repository = repository;

  final MessagingRepository _repository;

  @override
  String get name => 'add_review_node';

  @override
  String get description =>
      'Adds a structured review finding to a review channel. The finding '
      'appears as a review node in the channel with metadata for file path, '
      'line number, P0–P3 priority, reviewer confidence (0..1), and '
      'confirmation tracking.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'channel_id': {
        'type': 'string',
        'description': 'The review channel ID.',
      },
      'sender_id': {
        'type': 'string',
        'description': 'The agent ID adding this finding.',
      },
      'node_type': {
        'type': 'string',
        'description':
            'Type of finding: bug, suggestion, recommendation, question, or ticket.',
        'enum': ['bug', 'suggestion', 'recommendation', 'question', 'ticket'],
      },
      'content': {
        'type': 'string',
        'description': 'The finding description (markdown).',
      },
      'priority': {
        'type': 'string',
        'description':
            'Action-ordering priority. p0=blocks release, p1=fix next cycle, '
            'p2=fix eventually, p3=nice-to-have.',
        'enum': ['p0', 'p1', 'p2', 'p3'],
      },
      'confidence': {
        'type': 'number',
        'description':
            'Reviewer self-assessed confidence in this finding, in [0.0, 1.0].',
        'minimum': 0,
        'maximum': 1,
      },
      'file_path': {
        'type': 'string',
        'description': 'Optional file path the finding refers to.',
      },
      'line_number': {
        'type': 'integer',
        'description': 'Optional starting line number.',
      },
      'line_end': {
        'type': 'integer',
        'description': 'Optional ending line number.',
      },
    },
    'required': [
      'channel_id',
      'sender_id',
      'node_type',
      'content',
      'priority',
      'confidence',
    ],
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
    final rawNodeType = arguments['node_type'];
    if (rawNodeType is! String) {
      return CallResult.error('Missing or invalid argument: node_type (expected string)');
    }
    final rawContent = arguments['content'];
    if (rawContent is! String) {
      return CallResult.error('Missing or invalid argument: content (expected string)');
    }
    final rawPriorityArg = arguments['priority'];
    // Accept any case (`P0` → `p0`); a pure-case mismatch is not worth bouncing
    // an agent turn over.
    final rawPriority =
        rawPriorityArg is String ? rawPriorityArg.toLowerCase() : rawPriorityArg;
    if (rawPriority is! String ||
        !const {'p0', 'p1', 'p2', 'p3'}.contains(rawPriority)) {
      return CallResult.error(
        'Missing or invalid argument: priority (expected one of p0,p1,p2,p3)',
      );
    }
    final rawConfidence = arguments['confidence'];
    if (rawConfidence is! num) {
      return CallResult.error(
        'Missing or invalid argument: confidence (expected number in [0,1])',
      );
    }
    final confidence = rawConfidence.toDouble();
    if (confidence.isNaN || confidence < 0.0 || confidence > 1.0) {
      return CallResult.error(
        'Invalid argument: confidence out of range [0,1]: $confidence',
      );
    }
    final rawFilePath = arguments['file_path'];
    final rawLineNumber = arguments['line_number'];
    final rawLineEnd = arguments['line_end'];
    final channelId = rawChannelId;
    final senderId = rawSenderId;
    final nodeType = rawNodeType;
    final content = rawContent;
    final priority = rawPriority;
    final filePath = rawFilePath is String ? rawFilePath : null;
    final lineNumber = rawLineNumber is int ? rawLineNumber : null;
    final lineEnd = rawLineEnd is int ? rawLineEnd : null;

    final messageId = const Uuid().v4();

    final metadata = <String, dynamic>{
      'nodeType': nodeType,
      'priority': priority,
      'confidence': confidence,
      'confirmedBy': <String>[],
      'status': 'open',
    };
    if (filePath != null) {
      metadata['filePath'] = filePath;
    }
    if (lineNumber != null) {
      metadata['lineNumber'] = lineNumber;
    }
    if (lineEnd != null) {
      metadata['lineEnd'] = lineEnd;
    }

    await _repository.sendMessage(
      channelId: channelId,
      content: content,
      senderId: senderId,
      senderType: 'agent',
      messageType: 'review_node',
      metadata: metadata,
      id: messageId,
    );

    return CallResult.success(
      jsonEncode({
        'message_id': messageId,
        'channel_id': channelId,
        'node_type': nodeType,
        'priority': priority,
        'confidence': confidence,
        'status': 'open',
      }),
    );
  }
}
