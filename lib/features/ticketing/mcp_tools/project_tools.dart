import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:control_center/features/ticketing/domain/repositories/project_repository.dart';
import 'package:control_center/features/ticketing/domain/services/project_service.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';

Map<String, dynamic> _projectJson(Project p) => {
      'project_id': p.id,
      'name': p.name,
      if (p.description != null) 'description': p.description,
      'color': p.color.toStorageString(),
      'status': p.status.toStorageString(),
    };

/// MCP tool to create a project (a workspace-scoped grouping of tickets).
class CreateProjectTool extends McpTool {
  /// Creates a [CreateProjectTool].
  CreateProjectTool({required ProjectService service}) : _service = service;

  final ProjectService _service;

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) {
    return ApprovalPayload(
      title: 'Create project',
      detail: 'About to create a project: "${arguments['name'] ?? '(unnamed)'}".',
    );
  }

  @override
  String get name => 'create_project';

  @override
  String get description =>
      'Creates a project (a workspace-scoped grouping of tickets toward a '
      'shared goal). Projects are local to Control Center and are not synced '
      'to any remote ticket provider.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'name': {'type': 'string', 'description': 'The project name.'},
          'description': {
            'type': 'string',
            'description': 'Optional project description / goal.',
          },
          'color': {
            'type': 'string',
            'description':
                'Optional color: gray, blue, green, amber, red, purple, teal, pink.',
          },
        },
        'required': ['workspace_id', 'name'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final name = arguments['name'];
    if (name is! String || name.trim().isEmpty) {
      return CallResult.error('Missing or invalid argument: name');
    }
    final project = await _service.create(
      workspaceId: workspaceId,
      name: name,
      description: arguments['description'] as String?,
      color: ProjectColor.fromStorage(arguments['color'] as String?),
    );
    return CallResult.success(jsonEncode(_projectJson(project)));
  }
}

/// MCP tool to list a workspace's projects.
class ListProjectsTool extends McpTool {
  /// Creates a [ListProjectsTool].
  ListProjectsTool({required ProjectRepository repository})
      : _repository = repository;

  final ProjectRepository _repository;

  @override
  String get name => 'list_projects';

  @override
  String get description => 'Lists the projects in a workspace.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'include_archived': {
            'type': 'boolean',
            'description': 'Include archived projects (default false).',
          },
        },
        'required': ['workspace_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final includeArchived = arguments['include_archived'] == true;
    final projects = await _repository.getForWorkspace(workspaceId);
    final visible = includeArchived
        ? projects
        : projects.where((p) => p.status != ProjectStatus.archived).toList();
    return CallResult.success(
      jsonEncode({'projects': visible.map(_projectJson).toList()}),
    );
  }
}

/// MCP tool to update a project's editable fields.
class UpdateProjectTool extends McpTool {
  /// Creates an [UpdateProjectTool].
  UpdateProjectTool({required ProjectService service}) : _service = service;

  final ProjectService _service;

  @override
  bool get requiresApproval => true;

  @override
  String get name => 'update_project';

  @override
  String get description =>
      'Updates a project (name, description, color, or status). Status is one '
      'of: active, completed, archived.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'project_id': {'type': 'string', 'description': 'The project ID.'},
          'name': {'type': 'string', 'description': 'New name.'},
          'description': {
            'type': 'string',
            'description': 'New description (empty string clears it).',
          },
          'color': {'type': 'string', 'description': 'New color.'},
          'status': {
            'type': 'string',
            'description': 'New status: active, completed, archived.',
          },
        },
        'required': ['workspace_id', 'project_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final projectId = arguments['project_id'];
    if (projectId is! String) {
      return CallResult.error('Missing or invalid argument: project_id');
    }
    final rawColor = arguments['color'];
    final rawStatus = arguments['status'];
    final updated = await _service.update(
      projectId,
      workspaceId: workspaceId,
      name: arguments['name'] as String?,
      description: arguments['description'] as String?,
      color: rawColor is String ? ProjectColor.fromStorage(rawColor) : null,
      status: rawStatus is String ? ProjectStatus.fromStorage(rawStatus) : null,
    );
    if (updated == null) {
      return CallResult.error('Project $projectId not found.');
    }
    return CallResult.success(jsonEncode(_projectJson(updated)));
  }
}

/// MCP tool to delete a project (its tickets are orphaned, not deleted).
class DeleteProjectTool extends McpTool {
  /// Creates a [DeleteProjectTool].
  DeleteProjectTool({required ProjectService service}) : _service = service;

  final ProjectService _service;

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) {
    return const ApprovalPayload(
      title: 'Delete project',
      detail: 'About to delete a project. Its tickets are kept but unassigned '
          'from the project.',
    );
  }

  @override
  String get name => 'delete_project';

  @override
  String get description =>
      'Deletes a project. Tickets in the project are not deleted — they are '
      'simply removed from the project.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'project_id': {'type': 'string', 'description': 'The project ID.'},
        },
        'required': ['workspace_id', 'project_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final projectId = arguments['project_id'];
    if (projectId is! String) {
      return CallResult.error('Missing or invalid argument: project_id');
    }
    await _service.delete(projectId, workspaceId: workspaceId);
    return CallResult.success(jsonEncode({'deleted': projectId}));
  }
}

/// MCP tool to assign (or clear) a ticket's project. Validates that the
/// project belongs to the same workspace before assigning.
class SetTicketProjectTool extends McpTool {
  /// Creates a [SetTicketProjectTool].
  SetTicketProjectTool({
    required TicketWorkflowService service,
    required ProjectRepository projectRepository,
  })  : _service = service,
        _projectRepository = projectRepository;

  final TicketWorkflowService _service;
  final ProjectRepository _projectRepository;

  @override
  bool get requiresApproval => true;

  @override
  String get name => 'set_ticket_project';

  @override
  String get description =>
      'Assigns a ticket to a project, or removes it from its project when '
      'project_id is omitted or null.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'ticket_id': {'type': 'string', 'description': 'The ticket ID.'},
          'project_id': {
            'type': 'string',
            'description':
                'The project ID to assign, or null/omitted to clear the project.',
          },
        },
        'required': ['workspace_id', 'ticket_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final ticketId = arguments['ticket_id'];
    if (ticketId is! String) {
      return CallResult.error('Missing or invalid argument: ticket_id');
    }
    final projectId = arguments['project_id'];
    if (projectId != null && projectId is! String) {
      return CallResult.error('Invalid argument: project_id');
    }
    if (projectId is String) {
      final project = await _projectRepository.getById(projectId);
      if (project == null) {
        return CallResult.error('Project $projectId not found.');
      }
      if (project.workspaceId != workspaceId) {
        return CallResult.error('Project $projectId belongs to a different workspace.');
      }
    }
    await _service.setProject(
      ticketId,
      projectId as String?,
      workspaceId: workspaceId,
    );
    return CallResult.success(
      jsonEncode({'ticket_id': ticketId, 'project_id': projectId}),
    );
  }
}
