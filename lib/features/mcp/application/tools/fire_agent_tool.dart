import 'dart:convert';

import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

/// Fire agent tool.
class FireAgentTool extends McpTool {
  /// Creates a new [Fire agent tool].
  FireAgentTool({required AgentRepository repository})
    : _repository = repository;

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) {
    final id = arguments['agent_id'];
    return ApprovalPayload(
      title: 'Fire agent',
      detail: 'About to remove agent ${id ?? 'unknown'} from the workspace.',
      isDestructive: true,
    );
  }

  final AgentRepository _repository;

  @override
  String get name => 'fire_agent';

  @override
  String get description =>
      'Removes an agent permanently.';

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
        'description': 'The agent ID to remove.',
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

    final existing = await _repository.getById(agentId);
    if (existing == null) {
      return CallResult.error('Agent not found: $agentId');
    }
    if (existing.workspaceId != rawWorkspaceId) {
      return CallResult.error('Agent belongs to a different workspace.');
    }

    await _repository.delete(agentId);

    return CallResult.success(
      jsonEncode({
        'agent_id': agentId,
        'name': existing.name,
        'status': 'removed',
      }),
    );
  }
}
