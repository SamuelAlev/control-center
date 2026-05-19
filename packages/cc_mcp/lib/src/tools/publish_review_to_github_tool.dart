import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_publisher_port.dart';

/// MCP tool that publishes a finalized review to GitHub as a single
/// pull-request review: inline line-anchored comments for each anchored
/// finding plus a verdict summary body, with the event derived from the
/// ship/hold/block verdict.
///
/// This is the user-gated publish step `finalize_review` defers. By default it
/// publishes only consensus-confirmed findings (the precision-first wedge):
/// a finding is posted only after a second agent confirmed it.
class PublishReviewToGithubTool extends McpTool {
  /// Creates a [PublishReviewToGithubTool].
  PublishReviewToGithubTool({required ReviewPublisherPort service})
      : _service = service;

  final ReviewPublisherPort _service;

  @override
  String get name => 'publish_review_to_github';

  @override
  String get description =>
      'Publishes a finalized PR review to GitHub. Maps each consensus-ready '
      'review node with a file+line anchor into an inline review comment, '
      'folds the rest into a summary body with the ship/hold/block verdict, '
      'and submits one review (REQUEST_CHANGES on block, otherwise COMMENT). '
      'If GitHub rejects an anchor that is not part of the diff, the findings '
      'are folded into the body instead. Marks the review completed.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {
            'type': 'string',
            'description': 'The workspace the review channel belongs to.',
          },
          'channel_id': {
            'type': 'string',
            'description': 'The review channel ID to publish.',
          },
          'selection': {
            'type': 'string',
            'enum': ['consensus', 'all_open'],
            'description':
                'Which findings to publish. "consensus" (default) posts only '
                'peer-confirmed findings; "all_open" posts every non-dismissed, '
                'non-resolved finding.',
          },
          'approve_on_ship': {
            'type': 'boolean',
            'description':
                'When the verdict is "ship", submit an APPROVE review instead '
                'of a COMMENT review. Defaults to false.',
          },
        },
        'required': ['workspace_id', 'channel_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error(
        'Missing or invalid argument: workspace_id (expected string)',
      );
    }
    final rawChannelId = arguments['channel_id'];
    if (rawChannelId is! String) {
      return CallResult.error(
        'Missing or invalid argument: channel_id (expected string)',
      );
    }
    final rawSelection = arguments['selection'];
    final selection = switch (rawSelection) {
      'all_open' => ReviewPublishSelection.allOpen,
      _ => ReviewPublishSelection.consensus,
    };
    final approveOnShip = arguments['approve_on_ship'] == true;

    try {
      final result = await _service.publish(
        workspaceId: rawWorkspaceId,
        channelId: rawChannelId,
        selection: selection,
        approveOnShip: approveOnShip,
      );
      return CallResult.success(
        jsonEncode({
          'review_id': result.reviewId,
          'event': result.event,
          'finding_count': result.findingCount,
          'inline_count': result.inlineCount,
          'used_body_fallback': result.usedFallback,
          'status': 'published',
        }),
      );
    } on WorkspaceMismatchException catch (e) {
      return CallResult.error(e.message);
    } on ArgumentError catch (e) {
      return CallResult.error(e.message?.toString() ?? 'Invalid argument');
    } on AppException catch (e) {
      return CallResult.error('Failed to publish review: ${e.message}');
    }
  }
}
