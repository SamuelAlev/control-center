import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:uuid/uuid.dart';

/// Optional MCP tool a reviewer subagent calls at the end of its pass to
/// attach a per-reviewer ship/hold/block verdict to the channel.
///
/// `finalize_review` synthesizes the CEO verdict from finding priorities
/// when no per-reviewer verdicts exist, so this tool is informational only.
class SubmitReviewerVerdictTool extends McpTool {
  /// Creates a [SubmitReviewerVerdictTool].
  SubmitReviewerVerdictTool({required MessagingRepository repository})
      : _repository = repository;

  final MessagingRepository _repository;

  @override
  String get name => 'submit_reviewer_verdict';

  @override
  String get description =>
      'Post a per-reviewer ship/hold/block verdict with confidence and an '
      'explanation. Optional — finalize_review computes the CEO verdict '
      'from finding priorities alone when no per-reviewer verdicts exist.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'channel_id': {
        'type': 'string',
        'description': 'The review channel ID.',
      },
      'reviewer_id': {
        'type': 'string',
        'description': 'The reviewer agent ID submitting the verdict.',
      },
      'verdict': {
        'type': 'string',
        'enum': ['ship', 'hold', 'block'],
        'description': 'The reviewer\'s overall judgment.',
      },
      'confidence': {
        'type': 'number',
        'minimum': 0,
        'maximum': 1,
        'description': 'Self-assessed confidence in the verdict, in [0,1].',
      },
      'explanation': {
        'type': 'string',
        'description': 'One-paragraph rationale.',
      },
    },
    'required': [
      'channel_id',
      'reviewer_id',
      'verdict',
      'confidence',
      'explanation',
    ],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawChannelId = arguments['channel_id'];
    if (rawChannelId is! String) {
      return CallResult.error(
        'Missing or invalid argument: channel_id (expected string)',
      );
    }
    final rawReviewerId = arguments['reviewer_id'];
    if (rawReviewerId is! String) {
      return CallResult.error(
        'Missing or invalid argument: reviewer_id (expected string)',
      );
    }
    final rawVerdict = arguments['verdict'];
    if (rawVerdict is! String ||
        !const {'ship', 'hold', 'block'}.contains(rawVerdict)) {
      return CallResult.error(
        'Missing or invalid argument: verdict (expected ship|hold|block)',
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
    final rawExplanation = arguments['explanation'];
    if (rawExplanation is! String) {
      return CallResult.error(
        'Missing or invalid argument: explanation (expected string)',
      );
    }

    final id = const Uuid().v4();
    await _repository.sendMessage(
      channelId: rawChannelId,
      content: rawExplanation,
      senderId: rawReviewerId,
      senderType: 'agent',
      messageType: 'system',
      id: id,
      metadata: {
        'reviewerVerdict': true,
        'verdict': rawVerdict,
        'confidence': confidence,
      },
    );

    return CallResult.success(jsonEncode({
      'message_id': id,
      'channel_id': rawChannelId,
      'reviewer_id': rawReviewerId,
      'verdict': rawVerdict,
      'confidence': confidence,
    }));
  }
}
