import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/services/memory_consolidation_service.dart';

/// MCP tool that runs a memory consolidation (`sleep`) pass: TTL/count eviction
/// of the hot working tier, then rolling consolidatable items into durable
/// long-term facts.
class ConsolidateMemoryTool extends McpTool {
  /// Creates a [ConsolidateMemoryTool].
  ConsolidateMemoryTool({required MemoryConsolidationService service})
      : _service = service;

  final MemoryConsolidationService _service;

  @override
  String get name => 'consolidate_memory';

  @override
  String get description =>
      'Runs a memory consolidation pass ("sleep"): evicts expired/overflowing '
      'hot working-memory items and rolls durable ones into long-term facts '
      '(with conflict detection). Scope to one agent with "agent_id" or run for '
      'the whole workspace.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
          'agent_id': {
            'type': 'string',
            'description':
                'Optional: consolidate only this agent\'s working memory.',
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
    final agentId = arguments['agent_id'] as String?;
    final report = await _service.sleep(workspaceId: workspaceId, agentId: agentId);
    return CallResult.success(jsonEncode({
      'items_considered': report.itemsConsidered,
      'facts_created': report.factsCreated,
      'facts_updated': report.factsUpdated,
      'conflicts_detected': report.conflictsDetected,
      'evicted': report.evicted,
    }));
  }
}