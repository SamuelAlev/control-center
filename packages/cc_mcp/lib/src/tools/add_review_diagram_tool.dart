import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/diagram_verifier.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_diagram.dart';

/// Resolves the code-graph corroborated edge-key set for a cohort's files.
/// Injected by the host (which owns the code graph): given (workspace, owner,
/// repo, filePaths), returns the `from→to` keys of real resolved edges.
typedef DiagramCorroborator =
    Future<Set<String>> Function({
      required String workspaceId,
      required String owner,
      required String repo,
      required List<String> filePaths,
    });

/// MCP tool: attaches a graph-verified diagram to a Review Studio cohort
/// (PRD 18 §3).
///
/// The agent emits a STRUCTURED diagram (sequence / ER / state-machine JSON),
/// NOT mermaid text. Every edge is cross-checked against real code-graph edges:
/// an edge the graph doesn't know is flagged (rendered dashed + "unverified")
/// or, when `drop_uncorroborated` is set, removed. This makes the diagram a
/// view of verified edges, never prose with arrows.
class AddReviewDiagramTool extends McpTool {
  /// Creates an [AddReviewDiagramTool].
  AddReviewDiagramTool({
    required ReviewCohortRepository cohorts,
    required DiagramCorroborator corroborate,
    ReviewPrNodeIdResolver? resolvePrNodeId,
  }) : _cohorts = cohorts,
       _corroborate = corroborate,
       _resolvePrNodeId = resolvePrNodeId;

  final ReviewCohortRepository _cohorts;
  final DiagramCorroborator _corroborate;

  /// Resolves the PR's real GitHub node-id key; null → synthetic fallback.
  final ReviewPrNodeIdResolver? _resolvePrNodeId;

  static const _verifier = DiagramVerifier();

  @override
  String get name => 'add_review_diagram';

  @override
  String get description =>
      'Attaches a graph-verified diagram to a PR review cohort in Review '
      'Studio. Provide a STRUCTURED diagram object (kind: sequence | '
      'entityRelation | stateMachine), not mermaid text — sequence/state edges '
      'are cross-checked against the real code graph and flagged if '
      'uncorroborated. Derive call flows from actual call edges (use '
      'code_callers / code_impact first).';

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
        'description': 'The cohort the diagram illustrates.',
      },
      'diagram': {
        'type': 'object',
        'description':
            'A typed diagram: {kind, title, ...}. sequence: '
            '{participants[], messages[{from,to,label,symbolRef?}]}; '
            'entityRelation: {entities[{name,fields[]}], relations[]}; '
            'stateMachine: {states[], transitions[{from,to,label}], '
            'initialState?}.',
      },
      'drop_uncorroborated': {
        'type': 'boolean',
        'description':
            'When true, drop edges the code graph does not corroborate '
            'instead of flagging them. Default false (flag).',
      },
    },
    'required': [
      'workspace_id',
      'owner',
      'repo',
      'pr_number',
      'cohort_key',
      'diagram',
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
    final rawDiagram = arguments['diagram'];
    if (owner is! String ||
        repo is! String ||
        prNumber is! int ||
        cohortKey is! String ||
        rawDiagram is! Map) {
      return CallResult.error(
        'Missing or invalid argument: owner/repo/pr_number/cohort_key/diagram',
      );
    }
    final dropUncorroborated = arguments['drop_uncorroborated'] == true;

    final ReviewDiagram diagram;
    try {
      diagram = ReviewDiagram.fromJson(rawDiagram.cast<String, dynamic>());
    } catch (e) {
      return CallResult.error('Invalid diagram JSON: $e');
    }

    final prNodeId =
        await _resolvePrNodeId?.call(
          workspaceId: workspaceId,
          owner: owner,
          repo: repo,
          prNumber: prNumber,
        ) ??
        reviewPrNodeKey(owner, repo, prNumber);
    final cohorts = await _cohorts.forPr(workspaceId, prNodeId);
    final cohort = cohorts.where((c) => c.cohortKey == cohortKey).firstOrNull;
    if (cohort == null) {
      return CallResult.error(
        'Cohort "$cohortKey" not found for this PR (or belongs to a different '
        'workspace).',
      );
    }

    final keys = await _corroborate(
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      filePaths: cohort.filePaths,
    );
    final verified = _verifier.verify(
      diagram,
      keys,
      dropUncorroborated: dropUncorroborated,
    );

    await _cohorts.updateDiagrams(workspaceId, cohort.id, [
      ...cohort.diagrams,
      verified,
    ]);

    return CallResult.success(
      jsonEncode({
        'cohort_key': cohortKey,
        'kind': verified.kind.wireName,
        'fully_corroborated': verified.isFullyCorroborated,
      }),
    );
  }
}
