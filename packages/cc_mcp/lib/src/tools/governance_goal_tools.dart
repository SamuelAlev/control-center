import 'dart:convert';

import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/governance/domain/services/goal_progress_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_level.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

Map<String, dynamic> _goalJson(OrgGoal g) => {
  'id': g.id,
  'title': g.title,
  'level': g.level.name,
  'status': g.status.name,
  'progress': g.progress,
  'parent_goal_id': g.parentGoalId,
  'owner_agent_id': g.ownerAgentId,
  'team_id': g.teamId,
  'target_ticket_id': g.targetTicketId,
  'description': g.description,
};

/// Creates a goal in the company → team → agent → task hierarchy.
class CreateGoalTool extends McpTool {
  /// Creates a [CreateGoalTool].
  CreateGoalTool({required GoalProgressService service}) : _service = service;

  final GoalProgressService _service;

  @override
  String get name => 'create_goal';

  @override
  String get description =>
      'Creates an organizational goal (company, team, agent, or task level) '
      'so agents can see how their work serves the bigger picture. Link a goal '
      'to its parent via parent_goal_id; progress aggregates upward.';

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) =>
      ApprovalPayload(
        title: 'Create goal',
        detail:
            'About to create a goal: "${arguments['title'] ?? '(untitled)'}".',
      );

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'title': {'type': 'string', 'description': 'Goal title.'},
      'level': {
        'type': 'string',
        'enum': ['company', 'team', 'agent', 'task'],
        'description': 'Level in the hierarchy.',
      },
      'parent_goal_id': {
        'type': 'string',
        'description': 'Parent goal id (omit for the company mission).',
      },
      'description': {'type': 'string', 'description': 'Optional details.'},
      'owner_agent_id': {'type': 'string', 'description': 'Owning agent.'},
      'team_id': {'type': 'string', 'description': 'Owning team.'},
      'target_ticket_id': {
        'type': 'string',
        'description': 'Ticket that realizes a task-level goal.',
      },
      'progress': {
        'type': 'integer',
        'description': 'Initial progress percent (0-100).',
      },
    },
    'required': ['workspace_id', 'title', 'level'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final title = arguments['title'];
    if (title is! String) {
      return CallResult.error('Missing or invalid argument: title');
    }
    final rawLevel = arguments['level'];
    if (rawLevel is! String) {
      return CallResult.error('Missing or invalid argument: level');
    }
    final rawProgress = arguments['progress'];
    final goal = await _service.createGoal(
      workspaceId: workspaceId,
      title: title,
      level: OrgGoalLevel.fromStorage(rawLevel),
      parentGoalId: arguments['parent_goal_id'] as String?,
      description: arguments['description'] as String?,
      ownerAgentId: arguments['owner_agent_id'] as String?,
      teamId: arguments['team_id'] as String?,
      targetTicketId: arguments['target_ticket_id'] as String?,
      progress: rawProgress is int ? rawProgress : 0,
    );
    return CallResult.success(jsonEncode(_goalJson(goal)));
  }
}

/// Lists the goals in a workspace.
class ListGoalsTool extends McpTool {
  /// Creates a [ListGoalsTool].
  ListGoalsTool({required GoalRepository repository})
    : _repository = repository;

  final GoalRepository _repository;

  @override
  String get name => 'list_goals';

  @override
  String get description =>
      'Lists the organizational goals for a workspace with their level, '
      'status and aggregated progress.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final goals = await _repository.listByWorkspace(workspaceId);
    return CallResult.success(
      jsonEncode({
        'goals': goals.map(_goalJson).toList(),
        'count': goals.length,
      }),
    );
  }
}

/// Updates a goal's progress (and cascades it upward through the hierarchy).
class UpdateGoalProgressTool extends McpTool {
  /// Creates an [UpdateGoalProgressTool].
  UpdateGoalProgressTool({required GoalProgressService service})
    : _service = service;

  final GoalProgressService _service;

  @override
  String get name => 'update_goal_progress';

  @override
  String get description =>
      'Sets a goal\'s completion percentage (0-100); parent goals recompute '
      'their progress automatically from their children.';

  @override
  bool get requiresApproval => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'goal_id': {'type': 'string', 'description': 'Goal id.'},
      'progress': {
        'type': 'integer',
        'description': 'New progress percent (0-100).',
      },
    },
    'required': ['workspace_id', 'goal_id', 'progress'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final goalId = arguments['goal_id'];
    if (goalId is! String) {
      return CallResult.error('Missing or invalid argument: goal_id');
    }
    final progress = arguments['progress'];
    if (progress is! int) {
      return CallResult.error('Missing or invalid argument: progress');
    }
    await _service.setProgress(workspaceId, goalId, progress);
    return CallResult.success(
      jsonEncode({'goal_id': goalId, 'progress': progress}),
    );
  }
}
