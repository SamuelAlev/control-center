import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';

/// MCP tool that marks a review node finding fixed.
///
/// The sibling of `dismiss_review_node`, and the one that makes the review's
/// north-star metric mean anything. `actionRate` — the share of findings
/// somebody actually FIXED, as opposed to merely engaged with — is the only
/// number in the review that noise cannot inflate. Without this tool it depends
/// entirely on a human remembering to press "Fixed" after the fix has already
/// landed, which is the kind of bookkeeping nobody does; the agent that made
/// the change is the one that knows, and it knows at the moment it is true.
///
/// Deliberately takes no reason. A dismissal has to explain itself because it
/// becomes a suppression fact that silences the pattern on future pull
/// requests; a fix says the finding was RIGHT, and there is nothing to teach a
/// future reviewer except to keep reporting it.
class ResolveReviewNodeTool extends McpTool {
  /// Creates a new [ResolveReviewNodeTool].
  ResolveReviewNodeTool({required ReviewFindingStatusPort status})
    : _status = status;

  final ReviewFindingStatusPort _status;

  @override
  String get name => 'resolve_review_node';

  @override
  String get description =>
      'Marks a review node finding as fixed. Call this after actually making '
      'the change the finding asked for — it sets the status to "resolved" and '
      'posts a trace into the review space. Use dismiss_review_node instead '
      'when the finding does not apply; do not resolve a finding you did not '
      'fix.';

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
        'description': 'The message ID of the review node that was fixed.',
      },
      'agent_id': {
        'type': 'string',
        'description': 'The ID of the agent that made the fix.',
      },
      'note': {
        'type': 'string',
        'description':
            'Optional one line on what was changed, shown in the review space '
            'beside the finding.',
      },
    },
    'required': ['workspace_id', 'space_id', 'node_message_id', 'agent_id'],
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
    final rawNote = arguments['note'];

    try {
      final change = await _status.setStatus(
        workspaceId: rawWorkspaceId,
        spaceId: rawSpaceId,
        nodeMessageId: rawNodeMessageId,
        status: ReviewNodeStatus.resolved,
        actorLabel: rawAgentId,
        reason: rawNote is String ? rawNote : null,
      );
      return CallResult.success(
        jsonEncode({
          'node_message_id': change.nodeMessageId,
          'status': change.status.wireName,
          'previous_status': change.previousStatus.wireName,
          'resolved_by': rawAgentId,
        }),
      );
    } on Object catch (e) {
      return CallResult.error('$e');
    }
  }
}
