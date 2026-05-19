import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:uuid/uuid.dart';

/// MCP tool that updates the agent's private working memory notes.
class UpdateMyNotesTool extends McpTool {

  /// Creates a [UpdateMyNotesTool].
  UpdateMyNotesTool({required AgentWorkingMemoryRepository repository})
      : _repository = repository;

  final AgentWorkingMemoryRepository _repository;

  @override
  String get name => 'update_my_notes';

  @override
  String get description =>
      'Updates the agent\'s private working memory notes.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
      'agent_id': {'type': 'string', 'description': 'The agent ID.'},
      'content': {'type': 'string', 'description': 'New content for the notes (markdown).'},
    },
    'required': ['workspace_id', 'agent_id', 'content'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final agentId = arguments['agent_id'];
    final content = arguments['content'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }
    if (agentId is! String) {
      return CallResult.error('Missing agent_id');
    }
    if (content is! String) {
      return CallResult.error('Missing content');
    }

    final existing = await _repository.getByAgent(workspaceId, agentId);
    final now = DateTime.now();

    final memory = AgentWorkingMemory(
      id: existing?.id ?? const Uuid().v4(),
      workspaceId: workspaceId,
      agentId: agentId,
      content: content,
      updatedAt: now,
    );

    await _repository.upsert(memory);

    return CallResult.success(jsonEncode({
      'status': 'updated',
      'agent_id': agentId,
    }));
  }
}
