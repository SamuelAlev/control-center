import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_harness/tools.dart';

/// Starts the canonical AI review flow for a PR (the Review Hub).
///
/// Mirrors the in-app "Ask AI" action: ensures the PR space, computes the
/// deterministic review context, fans out reviewers into the space, authors
/// the walkthrough and finalizes. Returns immediately with the space id —
/// progress streams through the review space.
typedef ReviewHubStartFn =
    Future<Map<String, dynamic>> Function({
      required String workspaceId,
      required String owner,
      required String repo,
      required int prNumber,
      String? requestedByUserId,
      String? level,
    });

/// MCP tool that starts the AI review for a pull request.
class StartAiReviewTool extends McpTool {
  /// Creates a new [StartAiReviewTool].
  StartAiReviewTool({required ReviewHubStartFn start}) : _start = start;

  final ReviewHubStartFn _start;

  @override
  String get name => 'start_ai_review';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.processSpawn};

  @override
  String get description =>
      'Starts the AI review for a pull request: computes the deterministic '
      'review areas, fans out specialist reviewers into the PR space, '
      'authors a structured walkthrough and finalizes the verdict. Returns '
      'the review space id — follow the review in that space.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace ID where the PR lives.',
      },
      'pr_number': {'type': 'integer', 'description': 'The GitHub PR number.'},
      'repo_full_name': {
        'type': 'string',
        'description': 'Repository full name, e.g. "owner/repo".',
      },
      'level': {
        'type': 'string',
        'enum': ['light', 'balanced', 'thorough'],
        'description':
            'How deep this review should go, overriding the workspace default '
            'for this run only. "light" runs one reviewer and reports only '
            'what materially matters; "balanced" runs the standard three; '
            '"thorough" adds the security and performance specialists and '
            'reports everything found. Omit to use the workspace default.',
      },
    },
    'required': ['workspace_id', 'pr_number', 'repo_full_name'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String || rawWorkspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final rawPrNumber = arguments['pr_number'];
    if (rawPrNumber is! int) {
      return CallResult.error(
        'Missing or invalid argument: pr_number (expected integer)',
      );
    }
    final rawRepoFullName = arguments['repo_full_name'];
    if (rawRepoFullName is! String) {
      return CallResult.error(
        'Missing or invalid argument: repo_full_name (expected string)',
      );
    }
    final repoParts = rawRepoFullName.split('/');
    if (repoParts.length != 2) {
      return CallResult.error('repo_full_name must be in "owner/repo" form');
    }
    final rawLevel = arguments['level'];
    if (rawLevel != null &&
        (rawLevel is! String || ReviewLevel.fromWire(rawLevel) == null)) {
      return CallResult.error(
        'Invalid argument: level (expected one of '
        '${ReviewLevel.values.map((l) => l.wireName).join(', ')})',
      );
    }

    final result = await _start(
      workspaceId: rawWorkspaceId,
      owner: repoParts[0],
      repo: repoParts[1],
      prNumber: rawPrNumber,
      level: rawLevel as String?,
    );
    return CallResult.success(jsonEncode(result));
  }
}
