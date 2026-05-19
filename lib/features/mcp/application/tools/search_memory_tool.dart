import 'dart:convert';
import 'dart:typed_data';

import 'package:control_center/core/domain/ports/embedding_port.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';

class SearchMemoryTool extends McpTool {
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

    var facts = await _factRepository.search(
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

    return CallResult.success(jsonEncode({
      'facts': facts
          .where((f) => !f.isSuperseded)
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
    }));
  }
}
