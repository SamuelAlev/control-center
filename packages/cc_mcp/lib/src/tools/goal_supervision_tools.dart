import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/ports/goal_supervision_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// Declares the calling agent's durable goal achieved.
class CompleteGoalTool extends McpTool {
  /// Creates a [CompleteGoalTool].
  CompleteGoalTool({required GoalSupervisionPort supervisionPort})
    : _supervisionPort = supervisionPort;

  final GoalSupervisionPort _supervisionPort;

  @override
  String get name => 'complete_goal';

  @override
  String get description =>
      'Declares your active durable goal (started with /goal or /loop) '
      'achieved, with a final summary of what was accomplished. The '
      'supervisor keeps dispatching runs until you call this — a run ending, '
      'even on a turn ceiling, just triggers the next segment. Call only when '
      'the objective is truly met.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'agent_id': {
        'type': 'string',
        'description': 'Your own agent id (resolves the active goal).',
      },
      'summary': {
        'type': 'string',
        'description': 'Final report of what was achieved.',
      },
    },
    'required': ['workspace_id', 'agent_id', 'summary'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final agentId = arguments['agent_id'];
    if (agentId is! String || agentId.isEmpty) {
      return CallResult.error('Missing or invalid argument: agent_id');
    }
    final summary = arguments['summary'];
    if (summary is! String || summary.trim().isEmpty) {
      return CallResult.error('Missing or invalid argument: summary');
    }

    final goal = await _supervisionPort.activeGoalForAgent(
      workspaceId,
      agentId,
    );
    try {
      await _supervisionPort.completeGoal(
        workspaceId,
        agentId,
        summary: summary,
      );
    } on StateError catch (e) {
      return CallResult.error(e.message);
    }
    return CallResult.success(
      jsonEncode({
        'status': 'completed',
        'goal_id': goal?.id,
        'summary': summary,
      }),
    );
  }
}
