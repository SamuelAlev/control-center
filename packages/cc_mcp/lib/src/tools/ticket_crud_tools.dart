import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_harness/tools.dart';

Map<String, dynamic> _ticketJson(Ticket t) => {
  'ticket_id': t.id,
  'key': t.displayKey,
  'title': t.title,
  'status': t.status.toStorageString(),
  'priority': t.priority.name,
  if (t.assignedAgentId != null) 'assignee': t.assignedAgentId,
  if (t.labels.isNotEmpty) 'labels': t.labels,
  'provider': t.provider.toStorageString(),
  if (t.url != null) 'url': t.url,
};

/// MCP tool to create a ticket on the active provider (vendor-agnostic).
class CreateTicketTool extends McpTool {
  /// Creates a [CreateTicketTool].
  CreateTicketTool({
    required TicketWorkflowService service,
    required TicketProvider provider,
  }) : _service = service,
       _provider = provider;

  final TicketWorkflowService _service;
  final TicketProvider _provider;

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) {
    return ApprovalPayload(
      title: 'Create ticket',
      detail:
          'About to create a ticket: "${arguments['title'] ?? '(untitled)'}".',
    );
  }

  @override
  String get name => 'create_ticket';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.vendorSyncWrite};

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
        'description': 'Remote provider team id, if the provider requires one.',
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
      priority: TicketPriority.fromStorage(
        rawPriority is int ? rawPriority : 0,
      ),
      assignedAgentId: arguments['assignee'] as String?,
      providerExtras: {
        if (teamId is String && teamId.isNotEmpty) 'teamId': teamId,
      },
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
    final ticket = await _repository.getById(workspaceId, ticketId);
    if (ticket == null) {
      return CallResult.error('Ticket not found.');
    }
    if (ticket.workspaceId != workspaceId) {
      return CallResult.error('Ticket belongs to a different workspace.');
    }
    final json = _ticketJson(ticket)
      ..['description'] = ticket.description ?? ''
      ..['collaborators'] = ticket.collaborators
          .map((c) => c.principalId)
          .toList();
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
            'Filter by status. Accepts the canonical tokens and common '
            'aliases: ${TicketStatus.acceptedTokensHint}.',
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
    final limit = McpTool.clampLimit(arguments, 50);
    final statusArg = arguments['status'];
    final assigneeArg = arguments['assignee'];

    var tickets = await _repository.watchForWorkspace(workspaceId).first;
    if (statusArg is String) {
      final status = TicketStatus.tryParseLoose(statusArg);
      if (status == null) {
        return CallResult.error(
          'Invalid status "$statusArg". Accepted values: '
          '${TicketStatus.acceptedTokensHint}.',
        );
      }
      tickets = tickets.where((t) => t.status == status).toList();
    }
    if (assigneeArg is String) {
      tickets = tickets.where((t) => t.assignedAgentId == assigneeArg).toList();
    }
    final list = tickets.take(limit).map(_ticketJson).toList();
    return CallResult.success(
      jsonEncode({'tickets': list, 'count': list.length}),
    );
  }
}

/// MCP tool to update a ticket's status, editable fields and labels.
///
/// This is the single typed surface for editing a ticket in place — it replaces
/// the `status set`, `priority set/clear` and `label add/remove/set` verbs of
/// the retired `ticket_cli`. Every field is optional; supply only what changes.
class UpdateTicketTool extends McpTool {
  /// Creates an [UpdateTicketTool].
  UpdateTicketTool({
    required TicketWorkflowService service,
    required TicketRepository repository,
  }) : _service = service,
       _repository = repository;
  final TicketWorkflowService _service;
  final TicketRepository _repository;

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
  Set<ActionClass> get actionClasses => const {ActionClass.vendorSyncWrite};

  @override
  String get description =>
      "Updates a ticket's status, title, description, priority, or labels. "
      'All fields are optional — pass only what you want to change.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'ticket_id': {'type': 'string', 'description': 'The ticket ID.'},
      'status': {
        'type': 'string',
        'description':
            'Target status. Accepts canonical tokens and aliases: '
            '${TicketStatus.acceptedTokensHint}.',
      },
      'title': {'type': 'string', 'description': 'New title.'},
      'description': {'type': 'string', 'description': 'New description.'},
      'priority': {
        'type': 'integer',
        'description': 'Priority: 0=None, 1=Urgent, 2=High, 3=Medium, 4=Low.',
      },
      'labels': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': "Replace the ticket's labels with exactly this set.",
      },
      'add_labels': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Labels to add (kept alongside existing labels).',
      },
      'remove_labels': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Labels to remove.',
      },
    },
    'required': ['workspace_id', 'ticket_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error(_missingWorkspaceId);
    }
    final ticketId = arguments['ticket_id'];
    if (ticketId is! String) {
      return CallResult.error('Missing or invalid argument: ticket_id.');
    }

    // Parse status first so a bad token fails before any mutation lands.
    final statusArg = arguments['status'];
    TicketStatus? status;
    if (statusArg is String) {
      status = TicketStatus.tryParseLoose(statusArg);
      if (status == null) {
        return CallResult.error(
          'Invalid status "$statusArg". Accepted values: '
          '${TicketStatus.acceptedTokensHint}.',
        );
      }
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
        priority: rawPriority is int
            ? TicketPriority.fromStorage(rawPriority)
            : null,
      );
    }

    // Labels: full replace via `labels`, or incremental via add/remove.
    final replace = _stringList(arguments['labels']);
    final add = _stringList(arguments['add_labels']);
    final remove = _stringList(arguments['remove_labels']);
    if (replace != null || add != null || remove != null) {
      List<String> base;
      if (replace != null) {
        base = replace;
      } else {
        final ticket = await _repository.getById(workspaceId, ticketId);
        if (ticket == null) {
          return CallResult.error('Ticket not found.');
        }
        if (ticket.workspaceId != workspaceId) {
          return CallResult.error('Ticket belongs to a different workspace.');
        }
        base = ticket.labels;
      }
      final next = {...base};
      if (remove != null) {
        next.removeAll(remove);
      }
      if (add != null) {
        next.addAll(add);
      }
      await _service.setLabels(
        ticketId,
        next.toList(),
        workspaceId: workspaceId,
      );
    }

    if (status != null) {
      await _service.transitionStatus(
        ticketId,
        status,
        workspaceId: workspaceId,
      );
    }
    return CallResult.success(
      jsonEncode({'ticket_id': ticketId, 'status': 'updated'}),
    );
  }

  /// Coerces a JSON array of strings; returns null when the key is absent so
  /// "not supplied" is distinguishable from "explicitly empty".
  static List<String>? _stringList(Object? raw) {
    if (raw is! List) {
      return null;
    }
    return raw.map((e) => '$e').where((s) => s.isNotEmpty).toList();
  }
}

/// Shared, self-explaining message for a missing `workspace_id`. For a
/// dispatched agent this argument is injected automatically from the session
/// scope, so seeing this means the call arrived without a workspace scope.
const String _missingWorkspaceId =
    'Missing or invalid argument: workspace_id. For a dispatched agent this '
    'is injected automatically from your session — you normally do not pass '
    'it. If you are calling this tool outside a dispatched session, pass your '
    'workspace_id.';
