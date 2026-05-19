import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_harness/tools.dart';

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
  Set<ActionClass> get actionClasses => const {ActionClass.workspaceMutation};

  @override
  String get description => 'Removes an agent permanently.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the agent belongs to.',
      },
      'agent_id': {'type': 'string', 'description': 'The agent ID to remove.'},
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

    final existing = await _repository.getById(rawWorkspaceId, agentId);
    if (existing == null) {
      return CallResult.error('Agent not found: $agentId');
    }
    if (existing.workspaceId != rawWorkspaceId) {
      // Not a foreign agent — a foreign id cannot resolve here at all, because
      // the read above opens this workspace's own database. This fires only when
      // a row's `workspace_id` column disagrees with the file holding it, i.e. a
      // mis-stamped write. Refuse rather than act on a row whose ownership is
      // self-contradictory.
      return CallResult.error(
        'Agent $agentId is stored in workspace $rawWorkspaceId but stamped '
        '${existing.workspaceId}; refusing to act on a mis-stamped row.',
      );
    }

    await _repository.delete(rawWorkspaceId, agentId);

    return CallResult.success(
      jsonEncode({
        'agent_id': agentId,
        'name': existing.name,
        'status': 'removed',
      }),
    );
  }
}
