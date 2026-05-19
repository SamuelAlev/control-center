import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// List agents tool.
class ListAgentsTool extends McpTool {
  /// Creates a new [List agents tool].
  ListAgentsTool({required AgentRepository repository})
    : _repository = repository;

  final AgentRepository _repository;

  @override
  String get name => 'list_agents';

  @override
  String get description =>
      'Lists all registered AI agents for a workspace.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace ID to list agents for.',
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of agents to return (default 100).',
        'default': 100,
      },
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id (expected string)');
    }
    final rawLimit = arguments['limit'];
    final workspaceId = rawWorkspaceId;
    final limit = rawLimit is int ? rawLimit : 100;
    final agents = await _repository.watchByWorkspace(workspaceId).first;

    final list = agents
        .take(limit)
        .map(
          (a) => {
            'id': a.id,
            'name': a.name,
            'title': a.title,
            'skills': a.skills.toList(),
            'persona': a.persona,
            'agent_md_path': a.agentMdPath,
            'reports_to': a.reportsTo,
          },
        )
        .toList();

    return CallResult.success(
      jsonEncode({'agents': list, 'count': list.length}),
    );
  }
}

