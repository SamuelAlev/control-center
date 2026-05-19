import 'dart:convert';

import 'package:control_center/core/domain/entities/agent_working_memory.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:uuid/uuid.dart';

class RecordObservationTool extends McpTool {
  RecordObservationTool({required AgentWorkingMemoryRepository repository})
      : _repository = repository;

  final AgentWorkingMemoryRepository _repository;

  @override
  String get name => 'record_observation';

  @override
  String get description =>
      'Records an observation into the agent\'s private working memory.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
      'agent_id': {'type': 'string', 'description': 'The agent ID.'},
      'observation': {'type': 'string', 'description': 'The observation to record.'},
    },
    'required': ['workspace_id', 'agent_id', 'observation'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final agentId = arguments['agent_id'];
    final observation = arguments['observation'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }
    if (agentId is! String) {
      return CallResult.error('Missing agent_id');
    }
    if (observation is! String) {
      return CallResult.error('Missing observation');
    }

    final existing = await _repository.getByAgent(workspaceId, agentId);
    final now = DateTime.now();
    final updatedContent = existing != null
        ? '${existing.content}\n- $observation'
        : '- $observation';

    final memory = AgentWorkingMemory(
      id: existing?.id ?? const Uuid().v4(),
      workspaceId: workspaceId,
      agentId: agentId,
      content: updatedContent,
      updatedAt: now,
    );

    await _repository.upsert(memory);

    return CallResult.success(jsonEncode({
      'status': 'recorded',
      'agent_id': agentId,
      'observation_length': observation.length,
    }));
  }
}
