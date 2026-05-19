import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';

Map<String, dynamic> _ticketJson(Ticket t) => {
      'ticket_id': t.id,
      'key': t.displayKey,
      'title': t.title,
      'status': t.status.toStorageString(),
      'priority': t.priority.name,
      if (t.assignedAgentId != null) 'assignee': t.assignedAgentId,
      'provider': t.provider.toStorageString(),
      if (t.url != null) 'url': t.url,
    };

/// MCP tool to create a ticket on the active provider (vendor-agnostic).
class CreateTicketTool extends McpTool {
  /// Creates a [CreateTicketTool].
  CreateTicketTool({
    required TicketWorkflowService service,
    required TicketProvider provider,
  })  : _service = service,
        _provider = provider;

  final TicketWorkflowService _service;
  final TicketProvider _provider;

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) {
    return ApprovalPayload(
      title: 'Create ticket',
      detail: 'About to create a ticket: "${arguments['title'] ?? '(untitled)'}".',
    );
  }

  @override
  String get name => 'create_ticket';

  @override
  String get description => 'Creates a new ticket on the configured provider.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'title': {'type': 'string', 'description': 'The ticket title.'},
          'description': {
            'type': 'string',
            'description': 'The ticket description (markdown).',
          },
          'priority': {
            'type': 'integer',
            'description': 'Priority: 0=None, 1=Urgent, 2=High, 3=Medium, 4=Low.',
          },
          'assignee': {
            'type': 'string',
            'description': 'Agent ID to assign (optional).',
          },
          'team_id': {
            'type': 'string',
            'description':
                'Remote provider team id, if the provider requires one.',
          },
        },
        'required': ['workspace_id', 'title'],
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
    final rawPriority = arguments['priority'];
    final teamId = arguments['team_id'];
    final ticket = await _service.createTicket(
      workspaceId: workspaceId,
      title: title,
      description: arguments['description'] as String?,
      provider: _provider,
      priority: TicketPriority.fromStorage(rawPriority is int ? rawPriority : 0),
      assignedAgentId: arguments['assignee'] as String?,
      providerExtras: {if (teamId is String && teamId.isNotEmpty) 'teamId': teamId},
    );
    return CallResult.success(jsonEncode(_ticketJson(ticket)));
  }
}

/// MCP tool to fetch a single ticket by id.
class GetTicketTool extends McpTool {
  /// Creates a [GetTicketTool].
  GetTicketTool({required TicketRepository repository})
      : _repository = repository;
  final TicketRepository _repository;

  @override
  String get name => 'get_ticket';

  @override
  String get description => 'Fetches a single ticket by its ID.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'ticket_id': {'type': 'string', 'description': 'The ticket ID.'},
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
    final ticket = await _repository.getById(ticketId);
    if (ticket == null) {
      return CallResult.error('Ticket not found.');
    }
    if (ticket.workspaceId != workspaceId) {
      return CallResult.error('Ticket belongs to a different workspace.');
    }
    final json = _ticketJson(ticket)
      ..['description'] = ticket.description ?? ''
      ..['collaborators'] =
          ticket.collaborators.map((c) => c.agentId).toList();
    return CallResult.success(jsonEncode(json));
  }
}

/// MCP tool to list tickets in a workspace, optionally filtered.
class ListTicketsTool extends McpTool {
  /// Creates a [ListTicketsTool].
  ListTicketsTool({required TicketRepository repository})
      : _repository = repository;
  final TicketRepository _repository;

  @override
  String get name => 'list_tickets';

  @override
  String get description =>
      'Lists tickets in a workspace, optionally filtered by status or assignee.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'status': {
            'type': 'string',
            'description':
                'Filter by status (backlog/open/inProgress/blocked/inReview/'
                'done/failed/cancelled).',
          },
          'assignee': {
            'type': 'string',
            'description': 'Filter by assigned agent ID.',
          },
          'limit': {
            'type': 'integer',
            'description': 'Maximum number of tickets to return (default 50).',
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
    final limit = arguments['limit'] is int ? arguments['limit'] as int : 50;
    final statusArg = arguments['status'];
    final assigneeArg = arguments['assignee'];

    var tickets = await _repository.watchForWorkspace(workspaceId).first;
    if (statusArg is String) {
      final status = TicketStatus.fromStorage(statusArg);
      tickets = tickets.where((t) => t.status == status).toList();
    }
    if (assigneeArg is String) {
      tickets = tickets.where((t) => t.assignedAgentId == assigneeArg).toList();
    }
    final list = tickets.take(limit).map(_ticketJson).toList();
    return CallResult.success(
        jsonEncode({'tickets': list, 'count': list.length}));
  }
}

/// MCP tool to update a ticket's status and/or editable fields.
class UpdateTicketTool extends McpTool {
  /// Creates an [UpdateTicketTool].
  UpdateTicketTool({required TicketWorkflowService service})
      : _service = service;
  final TicketWorkflowService _service;

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) {
    return ApprovalPayload(
      title: 'Update ticket',
      detail: 'About to update ticket ${arguments['ticket_id'] ?? 'unknown'}.',
    );
  }

  @override
  String get name => 'update_ticket';

  @override
  String get description =>
      "Updates a ticket's status, title, description, or priority.";

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'ticket_id': {'type': 'string', 'description': 'The ticket ID.'},
          'status': {
            'type': 'string',
            'description':
                'Target status (backlog/open/inProgress/blocked/inReview/'
                'done/failed/cancelled).',
          },
          'title': {'type': 'string', 'description': 'New title.'},
          'description': {'type': 'string', 'description': 'New description.'},
          'priority': {
            'type': 'integer',
            'description': 'Priority: 0=None, 1=Urgent, 2=High, 3=Medium, 4=Low.',
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
    final title = arguments['title'];
    final description = arguments['description'];
    final rawPriority = arguments['priority'];
    if (title is String || description is String || rawPriority is int) {
      await _service.updateDetails(
        ticketId,
        workspaceId: workspaceId,
        title: title is String ? title : null,
        description: description is String ? description : null,
        priority:
            rawPriority is int ? TicketPriority.fromStorage(rawPriority) : null,
      );
    }
    final statusArg = arguments['status'];
    if (statusArg is String) {
      await _service.transitionStatus(
          ticketId, TicketStatus.fromStorage(statusArg),
          workspaceId: workspaceId);
    }
    return CallResult.success(
        jsonEncode({'ticket_id': ticketId, 'status': 'updated'}));
  }
}
