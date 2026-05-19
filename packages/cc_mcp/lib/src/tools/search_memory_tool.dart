import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/memory/domain/services/memory_repo_scope_resolver.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';
import 'package:cc_domain/features/memory/domain/value_objects/system_memory_domains.dart';
import 'package:cc_mcp/src/tools/memory_repo_scope_arg.dart';

/// MCP tool that searches workspace memory facts and policies using
/// keyword, semantic, or hybrid mode.
class SearchMemoryTool extends McpTool {
  /// Creates a [SearchMemoryTool].
  SearchMemoryTool({
    required MemoryFactRepository factRepository,
    required MemoryPolicyRepository policyRepository,
    required MemoryRepoScopeResolver repoScope,
    EmbeddingPort? embeddingService,
  }) : _factRepository = factRepository,
       _policyRepository = policyRepository,
       _repoScope = repoScope,
       _embeddingService = embeddingService;

  final MemoryFactRepository _factRepository;
  final MemoryPolicyRepository _policyRepository;
  final MemoryRepoScopeResolver _repoScope;
  final EmbeddingPort? _embeddingService;

  @override
  String get name => 'search_memory';

  @override
  String get description =>
      'Searches workspace memory facts and policies. Supports keyword, '
      'semantic and hybrid (default) modes. Pass `repo` to favour memory about '
      'the codebase you are working in — it ranks, it does not filter, so '
      'workspace-wide memory still comes back.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
      'query': {'type': 'string', 'description': 'Search query.'},
      'mode': {
        'type': 'string',
        'enum': ['keyword', 'semantic', 'hybrid'],
        'description': 'Search mode. Default: hybrid.',
      },
      'repo': kMemoryRepoBoostArg,
      'domain': {
        'type': 'string',
        'description':
            'Optional domain filter. A bare name like "architecture" matches '
            'that domain in EVERY scope — workspace-wide and each repo\'s. '
            'Pass a full scope slug to narrow to one repo.',
      },
    },
    'required': ['workspace_id', 'query'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final query = arguments['query'];
    final mode = arguments['mode'] as String? ?? 'hybrid';
    final domainFilter = arguments['domain'] as String?;
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (query is! String) {
      return CallResult.error('Missing query');
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

    Float32List? queryEmbedding;
    if (mode != 'keyword' &&
        _embeddingService != null &&
        _embeddingService.isReady) {
      try {
        queryEmbedding = await _embeddingService.embed(query);
      } catch (_) {}
    }

    // hybrid (default) → full polyphonic 4-voice recall (vector + graph + fact +
    // temporal) with intent-aware weighting, Weibull decay and MMR diversity.
    // semantic → BM25 + vector RRF. keyword → FTS5 only.
    var facts = mode == 'hybrid'
        ? await _factRepository.recallPolyphonic(
            workspaceId,
            query,
            queryEmbedding: queryEmbedding,
            boostRepoSlug: repoSlug,
          )
        : await _factRepository.search(
            workspaceId,
            query,
            queryEmbedding: mode == 'keyword' ? null : queryEmbedding,
            boostRepoSlug: repoSlug,
          );
    // Both filters run here rather than in SQL because they are scope-aware:
    // an unqualified `architecture` must match the repo-scoped copies, which an
    // equality predicate on the stored slug cannot express.
    final policies = sortByRepoAffinity<MemoryPolicy>(
      await _policyRepository
          .getActiveByWorkspace(workspaceId)
          .then(
            (all) => domainFilter == null
                ? all
                : all
                      .where((p) => matchesDomainFilter(p.domain, domainFilter))
                      .toList(),
          ),
      repoSlug,
      domainOf: (p) => p.domain,
    );

    // Only a MISSING `domain` means "no filter"; an empty string stays a filter
    // that matches nothing, as it did when this was an equality test.
    if (domainFilter != null) {
      facts = facts
          .where((f) => matchesDomainFilter(f.domain, domainFilter))
          .toList();
    }

    final activeFacts = facts.where((f) => !f.isSuperseded).toList();

    // Nudge: when a non-system domain has accumulated several facts but no
    // policy, suggest distilling a normative rule. Deterministic; uses data
    // already loaded.
    final policyDomains = policies.map((p) => p.domain).toSet();
    final factsByDomain = <String, int>{};
    for (final f in activeFacts) {
      factsByDomain[f.domain] = (factsByDomain[f.domain] ?? 0) + 1;
    }
    final hintDomains = [
      for (final e in factsByDomain.entries)
        if (e.value >= 4 &&
            !policyDomains.contains(e.key) &&
            !SystemMemoryDomains.isSystem(e.key))
          e.key,
    ];

    return CallResult.success(
      jsonEncode({
        'facts': activeFacts
            .map(
              (f) => {
                'id': f.id,
                'domain': f.domain,
                'domain_name': MemoryDomainScope.bareName(f.domain),
                'repo': MemoryDomainScope.repoSlugOf(f.domain),
                'topic': f.topic,
                'content': f.content,
                'confidence': f.confidence,
              },
            )
            .toList(),
        'policies': policies
            .map(
              (p) => {
                'id': p.id,
                'domain': p.domain,
                'domain_name': MemoryDomainScope.bareName(p.domain),
                'repo': MemoryDomainScope.repoSlugOf(p.domain),
                'rule': p.rule,
              },
            )
            .toList(),
        if (hintDomains.isNotEmpty)
          'hint':
              'Domain(s) ${hintDomains.join(', ')} have several facts and no '
              'policy. If a normative rule has emerged, call propose_policy with '
              'the relevant source_fact_ids.',
      }),
    );
  }
}
