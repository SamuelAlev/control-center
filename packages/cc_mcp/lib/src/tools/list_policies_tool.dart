import 'dart:convert';

import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/memory/domain/services/memory_repo_scope_resolver.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';
import 'package:cc_mcp/src/tools/memory_repo_scope_arg.dart';

/// MCP tool that lists active memory policies for a workspace, optionally
/// filtered by domain.
class ListPoliciesTool extends McpTool {
  /// Creates a [ListPoliciesTool].
  ListPoliciesTool({
    required MemoryPolicyRepository repository,
    required MemoryRepoScopeResolver repoScope,
  }) : _repository = repository,
       _repoScope = repoScope;

  final MemoryPolicyRepository _repository;
  final MemoryRepoScopeResolver _repoScope;

  @override
  String get name => 'list_policies';

  @override
  String get description =>
      'Lists active memory policies for a workspace, optionally filtered by '
      'domain and ranked by repository. Policies scoped to a repo and '
      'workspace-wide policies are both returned; pass `repo` to float the '
      'ones for the codebase you are working in to the top.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
      'repo': kMemoryRepoBoostArg,
      'domain': {
        'type': 'string',
        'description':
            'Optional domain filter (slug). A bare name like "architecture" '
            'matches that domain in EVERY scope — workspace-wide and each '
            'repo\'s. Pass a full scope slug to narrow to one repo.',
      },
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }

    final domain = arguments['domain'] as String?;

    final String? repoSlug;
    try {
      repoSlug = await _repoScope.resolve(
        workspaceId,
        arguments['repo'] as String?,
      );
    } on UnknownMemoryRepoScope catch (e) {
      return CallResult.error(e.toString());
    }

    // The domain filter is applied here rather than in SQL because it must be
    // scope-aware: an unqualified `architecture` has to match the repo-scoped
    // copies too, which an equality predicate on the stored slug cannot do.
    // Only a MISSING `domain` means "no filter". An empty string stays a
    // filter that matches nothing, as it did when the predicate ran in SQL.
    final all = await _repository.getActiveByWorkspace(workspaceId);
    final filtered = domain == null
        ? all
        : all.where((p) => matchesDomainFilter(p.domain, domain)).toList();
    final policies = sortByRepoAffinity<MemoryPolicy>(
      filtered,
      repoSlug,
      domainOf: (p) => p.domain,
    );

    return CallResult.success(
      jsonEncode({
        'policies': policies
            .map(
              (p) => {
                'id': p.id,
                'domain': p.domain,
                'domain_name': MemoryDomainScope.bareName(p.domain),
                'repo': MemoryDomainScope.repoSlugOf(p.domain),
                'rule': p.rule,
                'required_role': p.requiredRole?.name,
                'source_fact_count': p.sourceFactIds.length,
                'active': p.active,
              },
            )
            .toList(),
      }),
    );
  }
}
