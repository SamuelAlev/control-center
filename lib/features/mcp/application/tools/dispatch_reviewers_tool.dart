import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/pipelines/domain/ports/dispatch_reviewers_port.dart';

/// Fans out a list of reviewer specs to matching agents in parallel.
///
/// Thin adapter over [DispatchReviewersPort]. Both this MCP tool and the
/// `pr_review` pipeline step body invoke the same service so dispatch logic
/// (skill matching, concurrency, channel participant management) lives in
/// exactly one place.
class DispatchReviewersTool extends McpTool {
  /// Creates a new [DispatchReviewersTool].
  DispatchReviewersTool({required DispatchReviewersPort service})
      : _service = service;

  final DispatchReviewersPort _service;

  @override
  String get name => 'dispatch_reviewers';

  @override
  String get description =>
      'Spawn reviewer subagents in parallel for a review channel. Each spec '
      '`{role, scope?, prompt_override?}` is matched to an agent and '
      'dispatched concurrently (up to `concurrency`, default from workspace). '
      'Returns dispatched + unmatched lists immediately; reviewer output '
      'lands as `review_node` messages.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'channel_id': {
        'type': 'string',
        'description': 'The review channel ID.',
      },
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace whose agents are eligible.',
      },
      'reviewers': {
        'type': 'array',
        'description': 'Specialist reviewer specs.',
        'items': {
          'type': 'object',
          'properties': {
            'role': {
              'type': 'string',
              'description':
                  'Role label (e.g. "security", "frontend"). Matched against '
                  'agent skills, title, and name.',
            },
            'scope': {
              'type': 'string',
              'description':
                  'Optional glob restricting the reviewer to specific files.',
            },
            'prompt_override': {
              'type': 'string',
              'description':
                  'Optional prompt override; replaces the default brief.',
            },
          },
          'required': ['role'],
        },
      },
      'concurrency': {
        'type': 'integer',
        'description':
            'Optional override. When omitted, uses the workspace\'s '
            'review_concurrency setting (default 3).',
        'minimum': 1,
        'maximum': 8,
      },
    },
    'required': ['channel_id', 'workspace_id', 'reviewers'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final channelId = arguments['channel_id'];
    if (channelId is! String) {
      return CallResult.error(
        'Missing or invalid argument: channel_id (expected string)',
      );
    }
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error(
        'Missing or invalid argument: workspace_id (expected string)',
      );
    }
    final reviewers = arguments['reviewers'];
    if (reviewers is! List) {
      return CallResult.error(
        'Missing or invalid argument: reviewers (expected array)',
      );
    }
    final concurrency = arguments['concurrency'];
    if (concurrency != null && concurrency is! int) {
      return CallResult.error(
        'Invalid argument: concurrency (expected integer)',
      );
    }

    final result = await _service.dispatch(
      channelId: channelId,
      workspaceId: workspaceId,
      reviewers: reviewers
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList(),
      concurrency: concurrency as int?,
    );

    final unmatched = result['unmatched'] as List;
    return CallResult.success(
      jsonEncode({
        ...result,
        'next_step': unmatched.isEmpty
            ? 'reviewers_ready'
            : 'call propose_hire for each unmatched role',
      }),
    );
  }
}
