import 'dart:convert';

import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

/// Get agent run logs tool.
class GetAgentRunLogsTool extends McpTool {
  /// Creates a new [Get agent run logs tool].
  GetAgentRunLogsTool({required AgentRunLogRepository repository})
    : _repository = repository;

  final AgentRunLogRepository _repository;

  @override
  String get name => 'get_agent_run_logs';

  @override
  String get description =>
      'Query run logs for an agent, showing execution history and status.';

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
        'description': 'The agent ID to query run logs for.',
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of log entries to return (default 50).',
        'default': 50,
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
    final rawLimit = arguments['limit'];
    final agentId = rawAgentId;
    final limit = rawLimit is int ? rawLimit : 50;

    // Scope to the caller's workspace: an agent id alone must not surface run
    // logs that belong to another workspace.
    final logs = (await _repository.watchByAgent(agentId).first)
        .where((l) => l.workspaceId == rawWorkspaceId)
        .toList();

    final list = logs
        .take(limit)
        .map(
          (log) => {
            'id': log.id,
            'status': log.status.name,
            'adapter': log.adapter,
            'summary': log.summary,
            'started_at': log.startedAt.toIso8601String(),
            'completed_at': log.completedAt?.toIso8601String(),
          },
        )
        .toList();

    return CallResult.success(
      jsonEncode({'run_logs': list, 'count': list.length}),
    );
  }
}
