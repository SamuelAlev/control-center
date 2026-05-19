import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/memory/domain/value_objects/system_memory_domains.dart';

/// MCP tool that searches workspace memory facts and policies using
/// keyword, semantic, or hybrid mode.
class SearchMemoryTool extends McpTool {

  /// Creates a [SearchMemoryTool].
  SearchMemoryTool({
    required MemoryFactRepository factRepository,
    required MemoryPolicyRepository policyRepository,
    EmbeddingPort? embeddingService,
  })  : _factRepository = factRepository,
        _policyRepository = policyRepository,
        _embeddingService = embeddingService;

  final MemoryFactRepository _factRepository;
  final MemoryPolicyRepository _policyRepository;
  final EmbeddingPort? _embeddingService;

  @override
  String get name => 'search_memory';

  @override
  String get description =>
      'Searches workspace memory facts and policies. Supports keyword, semantic, and hybrid (default) modes.';

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
      'domain': {
        'type': 'string',
        'description': 'Optional domain filter to restrict results to a specific domain.',
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
      return CallResult.error('Missing workspace_id');
    }
    if (query is! String) {
      return CallResult.error('Missing query');
    }

    Float32List? queryEmbedding;
    if (mode != 'keyword' && _embeddingService != null && _embeddingService.isReady) {
      try {
        queryEmbedding = await _embeddingService.embed(query);
      } catch (_) {}
    }

    // hybrid (default) → full polyphonic 4-voice recall (vector + graph + fact +
    // temporal) with intent-aware weighting, Weibull decay, and MMR diversity.
    // semantic → BM25 + vector RRF. keyword → FTS5 only.
    var facts = mode == 'hybrid'
        ? await _factRepository.recallPolyphonic(
            workspaceId,
            query,
            queryEmbedding: queryEmbedding,
          )
        : await _factRepository.search(
            workspaceId,
            query,
            queryEmbedding: mode == 'keyword' ? null : queryEmbedding,
          );
    final policies = await _policyRepository.getActiveByWorkspace(
      workspaceId,
      domain: domainFilter,
    );

    if (domainFilter != null) {
      facts = facts.where((f) => f.domain == domainFilter).toList();
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
            !SystemMemoryDomains.all.contains(e.key))
          e.key,
    ];

    return CallResult.success(jsonEncode({
      'facts': activeFacts
          .map((f) => {
                'id': f.id,
                'domain': f.domain,
                'topic': f.topic,
                'content': f.content,
                'confidence': f.confidence,
              })
          .toList(),
      'policies': policies.map((p) => {
                'id': p.id,
                'domain': p.domain,
                'rule': p.rule,
              }).toList(),
      if (hintDomains.isNotEmpty)
        'hint': 'Domain(s) ${hintDomains.join(', ')} have several facts and no '
            'policy. If a normative rule has emerged, call propose_policy with '
            'the relevant source_fact_ids.',
    }));
  }
}
