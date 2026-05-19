import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';

/// MCP tool that starts the `pr_review` pipeline for a pull request.
///
/// Mirrors the in-app "Ask AI" button: kicks off the seeded `pr_review`
/// template, which clones the branch, runs reviewers in parallel,
/// consolidates findings, and posts a PR comment.
class StartAiReviewTool extends McpTool {
  /// Creates a new [StartAiReviewTool].
  StartAiReviewTool({required PipelineEngine engine}) : _engine = engine;

  final PipelineEngine _engine;

  @override
  String get name => 'start_ai_review';

  @override
  String get description =>
      'Starts the AI review pipeline for a pull request. Clones the PR '
      'branch, fans out specialist reviewers, consolidates findings, and '
      'posts a GitHub review comment. Returns the pipeline run ID.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace ID where the PR lives.',
      },
      'pr_node_id': {
        'type': 'string',
        'description': 'The GitHub PR node ID.',
      },
      'pr_number': {
        'type': 'integer',
        'description': 'The GitHub PR number.',
      },
      'repo_full_name': {
        'type': 'string',
        'description': 'Repository full name, e.g. "owner/repo".',
      },
    },
    'required': [
      'workspace_id',
      'pr_node_id',
      'pr_number',
      'repo_full_name',
    ],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error(
          'Missing or invalid argument: workspace_id (expected string)');
    }
    final rawPrNodeId = arguments['pr_node_id'];
    if (rawPrNodeId is! String) {
      return CallResult.error(
          'Missing or invalid argument: pr_node_id (expected string)');
    }
    final rawPrNumber = arguments['pr_number'];
    if (rawPrNumber is! int) {
      return CallResult.error(
          'Missing or invalid argument: pr_number (expected integer)');
    }
    final rawRepoFullName = arguments['repo_full_name'];
    if (rawRepoFullName is! String) {
      return CallResult.error(
          'Missing or invalid argument: repo_full_name (expected string)');
    }
    final repoParts = rawRepoFullName.split('/');
    if (repoParts.length != 2) {
      return CallResult.error(
          'repo_full_name must be in "owner/repo" form');
    }

    final run = await _engine.start(
      'pr_review',
      workspaceId: rawWorkspaceId,
      triggerEventType: 'mcp',
      triggerPayload: {
        'workspaceId': rawWorkspaceId,
        'repoOwner': repoParts[0],
        'repoName': repoParts[1],
        'repoFullName': rawRepoFullName,
        'prNodeId': rawPrNodeId,
        'prNumber': rawPrNumber,
      },
      dedupKey: '$rawRepoFullName#$rawPrNumber',
    );

    if (run == null) {
      return CallResult.success(jsonEncode({
        'status': 'duplicate',
        'message': 'A pr_review run is already active for this PR.',
      }));
    }

    return CallResult.success(jsonEncode({
      'pipeline_run_id': run.id,
      'status': 'started',
    }));
  }
}
