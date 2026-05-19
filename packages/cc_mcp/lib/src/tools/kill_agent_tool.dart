import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/agents/domain/usecases/kill_agent_processes.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// MCP tool that terminates all running processes for an agent.
class KillAgentTool extends McpTool {

  /// Creates a [KillAgentTool].
  KillAgentTool({
    required AgentRepository agentRepository,
    required KillAgentProcessesUseCase killAgentProcessesUseCase,
  }) : _agentRepository = agentRepository,
       _killAgentProcessesUseCase = killAgentProcessesUseCase;

  final AgentRepository _agentRepository;
  final KillAgentProcessesUseCase _killAgentProcessesUseCase;

  @override
  String get name => 'kill_agent';

  @override
  String get description =>
      'Terminates all running processes for an agent.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the agent belongs to.',
      },
      'agent_id': {
        'type': 'string',
        'description': 'The agent ID to terminate.',
      },
    },
    'required': ['workspace_id', 'agent_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final rawAgentId = arguments['agent_id'];
    if (rawAgentId is! String) {
      return CallResult.error('Missing or invalid argument: agent_id (expected string)');
    }
    final agentId = rawAgentId;

    final agent = await _agentRepository.getById(agentId);
    if (agent == null) {
      return CallResult.error('Agent not found: $agentId');
    }
    if (agent.workspaceId != rawWorkspaceId) {
      return CallResult.error('Agent belongs to a different workspace.');
    }

    await _killAgentProcessesUseCase.execute(agent);

    return CallResult.success(
      jsonEncode({
        'agent_id': agentId,
        'name': agent.name,
        'status': 'killed',
      }),
    );
  }
}
