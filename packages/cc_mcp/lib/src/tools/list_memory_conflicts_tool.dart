import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_conflict_repository.dart';

/// MCP tool that lists detected memory conflicts (contradictions between facts)
/// in a workspace.
class ListMemoryConflictsTool extends McpTool {
  /// Creates a [ListMemoryConflictsTool].
  ListMemoryConflictsTool({required MemoryConflictRepository repository})
      : _repository = repository;

  final MemoryConflictRepository _repository;

  @override
  String get name => 'list_memory_conflicts';

  @override
  String get description =>
      'Lists detected contradictions between memory facts in the workspace, '
      'including how each was resolved (which fact won). Use to audit memory '
      'health before relying on a fact.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
          'unresolved_only': {
            'type': 'boolean',
            'description': 'Only return open (unresolved) conflicts.',
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
    final unresolvedOnly = arguments['unresolved_only'] == true;
    final conflicts = unresolvedOnly
        ? await _repository.getUnresolved(workspaceId)
        : await _repository.getByWorkspace(workspaceId);
    return CallResult.success(jsonEncode({
      'conflicts': [
        for (final c in conflicts)
          {
            'id': c.id,
            'fact_a': c.factAId,
            'fact_b': c.factBId,
            'type': c.conflictType,
            'resolution': c.resolution,
            'winning_fact': c.winningFactId,
          },
      ],
    }));
  }
}