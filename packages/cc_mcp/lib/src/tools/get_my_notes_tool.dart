import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';

/// MCP tool that retrieves the agent's private working memory notes.
class GetMyNotesTool extends McpTool {

  /// Creates a [GetMyNotesTool].
  GetMyNotesTool({required AgentWorkingMemoryRepository repository})
      : _repository = repository;

  final AgentWorkingMemoryRepository _repository;

  @override
  String get name => 'get_my_notes';

  @override
  String get description =>
      'Retrieves the agent\'s private working memory notes.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
      'agent_id': {'type': 'string', 'description': 'The agent ID.'},
    },
    'required': ['workspace_id', 'agent_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final agentId = arguments['agent_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }
    if (agentId is! String) {
      return CallResult.error('Missing agent_id');
    }

    final memory = await _repository.getByAgent(workspaceId, agentId);

    if (memory == null) {
      return CallResult.success(jsonEncode({
        'workspace_id': workspaceId,
        'agent_id': agentId,
        'content': null,
        'message': 'No working memory found for this agent.',
      }));
    }

    return CallResult.success(jsonEncode({
      'workspace_id': workspaceId,
      'agent_id': agentId,
      'content': memory.content,
      'updated_at': memory.updatedAt.toIso8601String(),
    }));
  }
}
