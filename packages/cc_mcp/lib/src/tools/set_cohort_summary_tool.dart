import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';

/// MCP tool: sets a Review Studio cohort's AI summary (PRD 18 §2).
///
/// A reviewer agent, after reading a semantic cohort, records a range-specific
/// summary that the context rail renders (and auto-scrolls to). Workspace-
/// scoped: the summary only lands on a cohort the caller's workspace owns.
class SetCohortSummaryTool extends McpTool {
  /// Creates a [SetCohortSummaryTool]. [resolvePrExternalId] resolves the PR's real
  /// GitHub node-id key; when null the tool falls back to the synthetic key.
  SetCohortSummaryTool({
    required ReviewCohortRepository cohorts,
    ReviewPrExternalIdResolver? resolvePrExternalId,
  }) : _cohorts = cohorts,
       _resolvePrExternalId = resolvePrExternalId;

  final ReviewCohortRepository _cohorts;
  final ReviewPrExternalIdResolver? _resolvePrExternalId;

  @override
  String get name => 'set_cohort_summary';

  @override
  String get description =>
      'Sets the AI summary (markdown) for a PR review cohort in Review Studio. '
      'Call after reading a semantic cohort to give the reviewer a "read this '
      'first" narrative that the context rail shows.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'owner': {'type': 'string'},
      'repo': {'type': 'string'},
      'pr_number': {'type': 'integer'},
      'cohort_key': {
        'type': 'string',
        'description': 'The stable cohort key to summarize.',
      },
      'summary_markdown': {
        'type': 'string',
        'description': 'The cohort summary, in markdown.',
      },
    },
    'required': [
      'workspace_id',
      'owner',
      'repo',
      'pr_number',
      'cohort_key',
      'summary_markdown',
    ],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final owner = arguments['owner'];
    final repo = arguments['repo'];
    final prNumber = arguments['pr_number'];
    final cohortKey = arguments['cohort_key'];
    final summary = arguments['summary_markdown'];
    if (owner is! String ||
        repo is! String ||
        prNumber is! int ||
        cohortKey is! String ||
        summary is! String) {
      return CallResult.error(
        'Missing or invalid argument: owner/repo/pr_number/cohort_key/'
        'summary_markdown',
      );
    }

    final prExternalId =
        await _resolvePrExternalId?.call(
          workspaceId: workspaceId,
          owner: owner,
          repo: repo,
          prNumber: prNumber,
        ) ??
        reviewPrNodeKey(owner, repo, prNumber);
    final cohorts = await _cohorts.forPr(workspaceId, prExternalId);
    final cohort = cohorts.where((c) => c.cohortKey == cohortKey).firstOrNull;
    if (cohort == null) {
      return CallResult.error(
        'Cohort "$cohortKey" not found for this PR (or belongs to a different '
        'workspace).',
      );
    }
    await _cohorts.updateSummary(workspaceId, cohort.id, summary);
    return CallResult.success(
      jsonEncode({'cohort_key': cohortKey, 'updated': true}),
    );
  }
}
