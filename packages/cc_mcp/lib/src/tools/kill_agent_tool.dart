import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/agents/domain/usecases/kill_agent_processes.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_harness/tools.dart';

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
  Set<ActionClass> get actionClasses => const {ActionClass.processSpawn};

  @override
  String get description => 'Terminates all running processes for an agent.';

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
      return CallResult.error(
        'Missing or invalid argument: agent_id (expected string)',
      );
    }
    final agentId = rawAgentId;

    final agent = await _agentRepository.getById(rawWorkspaceId, agentId);
    if (agent == null) {
      return CallResult.error('Agent not found: $agentId');
    }
    if (agent.workspaceId != rawWorkspaceId) {
      // Not a foreign agent — a foreign id cannot resolve here at all, because
      // the read above opens this workspace's own database. This fires only when
      // a row's `workspace_id` column disagrees with the file holding it, i.e. a
      // mis-stamped write. Refuse rather than act on a row whose ownership is
      // self-contradictory.
      return CallResult.error(
        'Agent $agentId is stored in workspace $rawWorkspaceId but stamped '
        '${agent.workspaceId}; refusing to act on a mis-stamped row.',
      );
    }

    await _killAgentProcessesUseCase.execute(agent);

    return CallResult.success(
      jsonEncode({'agent_id': agentId, 'name': agent.name, 'status': 'killed'}),
    );
  }
}
