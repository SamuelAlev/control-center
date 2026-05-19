import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/memory/domain/services/memory_repo_scope_resolver.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';

/// MCP tool that lists all memory domains in a workspace with fact and
/// policy counts.
class ListMemoryDomainsTool extends McpTool {
  /// Creates a [ListMemoryDomainsTool].
  ListMemoryDomainsTool({
    required MemoryDomainRepository domainRepository,
    required MemoryFactRepository factRepository,
    required MemoryPolicyRepository policyRepository,
    required MemoryRepoScopeResolver repoScope,
  }) : _domainRepository = domainRepository,
       _factRepository = factRepository,
       _policyRepository = policyRepository,
       _repoScope = repoScope;

  final MemoryDomainRepository _domainRepository;
  final MemoryFactRepository _factRepository;
  final MemoryPolicyRepository _policyRepository;
  final MemoryRepoScopeResolver _repoScope;

  @override
  String get name => 'list_memory_domains';

  @override
  String get description =>
      'Lists all memory domains in the workspace with fact and policy counts. '
      'Call this before proposing facts or policies to discover existing '
      'domains.\n\n'
      'A domain is either workspace-wide (`repo` is null) or scoped to one '
      'repository. The same `name` can exist in both — they are separate '
      'scopes. To write into one, pass its `name` plus its `repo` to '
      'propose_fact / propose_policy.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
      'repo': {
        'type': 'string',
        'description':
            'OPTIONAL. Limit the listing to this repository\'s domains plus '
            'the workspace-wide ones — the set that applies while working in '
            'that codebase. Omit to list every scope.',
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

    final String? repoSlug;
    try {
      repoSlug = await _repoScope.resolve(
        workspaceId,
        arguments['repo'] as String?,
      );
    } on UnknownMemoryRepoScope catch (e) {
      return CallResult.error(e.toString());
    }

    final allDomains = await _domainRepository.getByWorkspace(workspaceId);
    final facts = await _factRepository.getByWorkspace(workspaceId);
    final policies = await _policyRepository.getActiveByWorkspace(workspaceId);

    // Narrowing keeps the workspace-wide domains: they apply while working in
    // any repo, so hiding them would make a general convention look absent.
    final domains = repoSlug == null
        ? allDomains
        : allDomains
              .where(
                (d) =>
                    !MemoryDomainScope.parse(d.name).isRepoScoped ||
                    MemoryDomainScope.matchesRepo(d.name, repoSlug),
              )
              .toList();

    final result =
        sortByRepoAffinity<MemoryDomain>(
          domains,
          repoSlug,
          domainOf: (d) => d.name,
        ).map((d) {
          final scope = MemoryDomainScope.parse(d.name);
          final factCount = facts
              .where((f) => f.domain == d.name && !f.isSuperseded)
              .length;
          final policyCount = policies.where((p) => p.domain == d.name).length;
          return {
            // `slug` is the stored value; `name` is what a caller passes back as
            // `domain`, paired with `repo`. Emitting only the slug would make an
            // agent echo `repo:x/architecture` into `domain` and re-prefix it.
            'slug': d.name,
            'name': scope.name,
            'repo': scope.repoSlug,
            'label': d.label,
            'description': d.description,
            'fact_count': factCount,
            'policy_count': policyCount,
          };
        }).toList();

    return CallResult.success(jsonEncode({'domains': result}));
  }
}
