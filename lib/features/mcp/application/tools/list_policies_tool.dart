import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';

/// MCP tool that lists active memory policies for a workspace, optionally
/// filtered by domain.
class ListPoliciesTool extends McpTool {

  /// Creates a [ListPoliciesTool].
  ListPoliciesTool({required MemoryPolicyRepository repository})
      : _repository = repository;

  final MemoryPolicyRepository _repository;

  @override
  String get name => 'list_policies';

  @override
  String get description =>
      'Lists active memory policies for a workspace, optionally filtered by domain.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
      'domain': {
        'type': 'string',
        'description': 'Optional domain filter (slug).',
      },
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }

    final domain = arguments['domain'] as String?;

    final policies =
        await _repository.getActiveByWorkspace(workspaceId, domain: domain);

    return CallResult.success(jsonEncode({
      'policies': policies.map((p) => {
            'id': p.id,
            'domain': p.domain,
            'rule': p.rule,
            'required_role': p.requiredRole?.name,
            'source_fact_count': p.sourceFactIds.length,
            'active': p.active,
          }).toList(),
    }));
  }
}
