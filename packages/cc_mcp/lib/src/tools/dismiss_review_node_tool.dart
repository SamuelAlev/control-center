import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';

/// MCP tool that dismisses a review node finding.
///
/// Delegates to the same service the human-facing RPC op uses, so an agent
/// dismissing a finding and a person pressing "Dismiss" leave identical state:
/// the status written through the typed payload, a trace in the room naming
/// who did it and why, and a suppression fact in the `review-suppressions`
/// memory domain so the pattern is not re-flagged on the next pull request.
///
/// That last part is what makes a dismissal worth capturing rather than just
/// hiding a row — it is the clearest feedback a reviewer ever receives.
class DismissReviewNodeTool extends McpTool {
  /// Creates a new [DismissReviewNodeTool].
  DismissReviewNodeTool({required ReviewFindingStatusPort status})
    : _status = status;

  final ReviewFindingStatusPort _status;

  @override
  String get name => 'dismiss_review_node';

  @override
  String get description =>
      'Dismisses a review node finding. Sets the status to "dismissed", posts '
      'the reason into the review space and records a suppression fact so '
      'reviewers stop re-flagging this pattern on future PRs.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the review space belongs to.',
      },
      'space_id': {'type': 'string', 'description': 'The review space ID.'},
      'node_message_id': {
        'type': 'string',
        'description': 'The message ID of the review node to dismiss.',
      },
      'agent_id': {
        'type': 'string',
        'description': 'The ID of the agent dismissing the finding.',
      },
      'reason': {
        'type': 'string',
        'description':
            'Why this finding does not apply. This becomes the suppression '
            'fact future reviewers read, so state the general rule ("the '
            'framework handles this automatically") rather than "not a '
            'problem here".',
      },
    },
    'required': [
      'workspace_id',
      'space_id',
      'node_message_id',
      'agent_id',
      'reason',
    ],
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
    final rawNodeMessageId = arguments['node_message_id'];
    if (rawNodeMessageId is! String) {
      return CallResult.error(
        'Missing or invalid argument: node_message_id (expected string)',
      );
    }
    final rawAgentId = arguments['agent_id'];
    if (rawAgentId is! String) {
      return CallResult.error(
        'Missing or invalid argument: agent_id (expected string)',
      );
    }
    final rawReason = arguments['reason'];
    if (rawReason is! String) {
      return CallResult.error(
        'Missing or invalid argument: reason (expected string)',
      );
    }

    try {
      final change = await _status.setStatus(
        workspaceId: rawWorkspaceId,
        spaceId: rawSpaceId,
        nodeMessageId: rawNodeMessageId,
        status: ReviewNodeStatus.dismissed,
        actorLabel: rawAgentId,
        reason: rawReason,
      );
      return CallResult.success(
        jsonEncode({
          'node_message_id': change.nodeMessageId,
          'status': change.status.wireName,
          'previous_status': change.previousStatus.wireName,
          'dismissed_by': rawAgentId,
          'reason': rawReason,
          'suppression_recorded': change.suppressionRecorded,
        }),
      );
    } on Object catch (e) {
      return CallResult.error('$e');
    }
  }
}
