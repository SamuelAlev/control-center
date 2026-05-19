import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:cc_infra/cc_infra.dart';

/// MCP tool used by the CEO to finalize a review. Gathers every
/// `review_node` message in the channel, classifies each as
/// `consensus_ready` (≥1 peer confirmation, author cannot self-confirm)
/// or `needs_adjudication`, computes the per-PR verdict from
/// finding priorities + confidence (escalated by the studio axis results),
/// posts an editorial summary that includes the verdict banner and
/// transitions the review-channel association to `awaiting_approval`.
/// Publishing to GitHub stays user-gated and is not performed here.
///
/// The mechanics live in [ReviewFinalizer] so the review hub runs the exact
/// same deterministic finalize; this class is only the MCP surface.
class FinalizeReviewTool extends McpTool {
  /// Creates a new [FinalizeReviewTool].
  FinalizeReviewTool({required ReviewFinalizer finalizer})
    : _finalizer = finalizer;

  final ReviewFinalizer _finalizer;

  @override
  String get name => 'finalize_review';

  @override
  String get description =>
      'Finalize the review for a channel. Gathers all review nodes, '
      'computes per-node consensus (peer confirmation, author cannot '
      'self-confirm), computes the per-PR verdict (ship/hold/block) from '
      'finding priorities + confidence, posts a review summary message, '
      'and transitions the review to awaiting_approval. Does NOT publish '
      'to GitHub — the user does that explicitly from the UI.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the review channel belongs to.',
      },
      'channel_id': {'type': 'string', 'description': 'The review channel ID.'},
      'finalizer_id': {
        'type': 'string',
        'description': 'The agent id closing the review (usually the CEO).',
      },
      'editorial_note': {
        'type': 'string',
        'description':
            'Optional editorial framing the finalizer wants in the summary.',
      },
      'headline': {
        'type': 'string',
        'description':
            'Optional one-line "what this PR does" for the structured '
            'walkthrough embedded in the summary.',
      },
    },
    'required': ['workspace_id', 'channel_id', 'finalizer_id'],
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
    final rawFinalizerId = arguments['finalizer_id'];
    if (rawFinalizerId is! String) {
      return CallResult.error(
        'Missing or invalid argument: finalizer_id (expected string)',
      );
    }
    final note = arguments['editorial_note'];
    final headline = arguments['headline'];

    final ReviewWalkthroughSummary? walkthrough;
    if (headline is String && headline.trim().isNotEmpty) {
      walkthrough = ReviewWalkthroughSummary(headline: headline.trim());
    } else {
      walkthrough = null;
    }

    try {
      final result = await _finalizer.finalize(
        workspaceId: rawWorkspaceId,
        channelId: rawChannelId,
        finalizerId: rawFinalizerId,
        editorialNote: note is String ? note : null,
        walkthrough: walkthrough,
      );
      final verdict = result.verdict;
      return CallResult.success(
        jsonEncode({
          'summary_message_id': result.summaryMessageId,
          'channel_id': result.channelId,
          'review_id': result.reviewId,
          'status': 'awaiting_approval',
          'verdict': verdict.overall.name,
          'verdict_confidence': verdict.confidence,
          'priority_counts': {
            'p0': verdict.p0Count,
            'p1': verdict.p1Count,
            'p2': verdict.p2Count,
            'p3': verdict.p3Count,
          },
          'consensus_ready': result.consensusReadyCount,
          'needs_adjudication': result.needsAdjudicationCount,
        }),
      );
    } on ArgumentError catch (e) {
      return CallResult.error(e.message ?? e.toString());
    }
  }
}
