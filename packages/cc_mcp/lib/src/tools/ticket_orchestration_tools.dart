import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_harness/tools.dart';

/// MCP tool to assign a ticket to an agent and/or team.
class AssignTicketTool extends McpTool {
  /// Creates an [AssignTicketTool].
  AssignTicketTool({required TicketWorkflowService service})
    : _service = service;
  final TicketWorkflowService _service;

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) =>
      ApprovalPayload(
        title: 'Assign ticket',
        detail:
            'Assign ticket ${arguments['ticket_id']} to '
            '${arguments['agent_id'] ?? arguments['team_id'] ?? 'nobody'}.',
      );

  @override
  String get name => 'assign_ticket';
  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.vendorSyncWrite,
    ActionClass.processSpawn,
  };

  @override
  String get description => 'Assign a ticket to an agent and/or team.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'ticket_id': {'type': 'string', 'description': 'The ticket ID.'},
      'agent_id': {'type': 'string', 'description': 'Agent to assign.'},
      'team_id': {'type': 'string', 'description': 'Team to assign.'},
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
    await _service.assign(
      ticketId,
      workspaceId: workspaceId,
      assigneeId: arguments['agent_id'] as String?,
      teamId: arguments['team_id'] as String?,
    );
    return CallResult.success(
      jsonEncode({'ticket_id': ticketId, 'status': 'assigned'}),
    );
  }
}

/// MCP tool to reassign a ticket to another agent.
class ReassignTicketTool extends McpTool {
  /// Creates a [ReassignTicketTool].
  ReassignTicketTool({required TicketWorkflowService service})
    : _service = service;
  final TicketWorkflowService _service;

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) =>
      ApprovalPayload(
        title: 'Reassign ticket',
        detail:
            'Reassign ticket ${arguments['ticket_id']} to '
            '${arguments['agent_id']}.',
      );

  @override
  String get name => 'reassign_ticket';
  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.vendorSyncWrite,
    ActionClass.processSpawn,
  };

  @override
  String get description => 'Reassign a ticket to a different agent.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'ticket_id': {'type': 'string', 'description': 'The ticket ID.'},
      'agent_id': {'type': 'string', 'description': 'New assignee.'},
    },
    'required': ['workspace_id', 'ticket_id', 'agent_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final ticketId = arguments['ticket_id'];
    final agentId = arguments['agent_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (ticketId is! String || agentId is! String) {
      return CallResult.error('Missing ticket_id or agent_id.');
    }
    await _service.reassign(
      ticketId,
      workspaceId: workspaceId,
      toAgentId: agentId,
    );
    return CallResult.success(
      jsonEncode({'ticket_id': ticketId, 'status': 'reassigned'}),
    );
  }
}

/// MCP tool to invite a collaborator onto a ticket.
class AddTicketCollaboratorTool extends McpTool {
  /// Creates an [AddTicketCollaboratorTool].
  AddTicketCollaboratorTool({required TicketWorkflowService service})
    : _service = service;
  final TicketWorkflowService _service;

  @override
  String get name => 'add_ticket_collaborator';

  @override
  String get description =>
      'Invite an agent to collaborate on a ticket (added to its space).';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'ticket_id': {'type': 'string', 'description': 'The ticket ID.'},
      'agent_id': {'type': 'string', 'description': 'Collaborator agent.'},
      'role': {
        'type': 'string',
        'description': 'collaborator (default) | reviewer | assignee.',
      },
    },
    'required': ['workspace_id', 'ticket_id', 'agent_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final ticketId = arguments['ticket_id'];
    final agentId = arguments['agent_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (ticketId is! String || agentId is! String) {
      return CallResult.error('Missing ticket_id or agent_id.');
    }
    await _service.addCollaborator(
      ticketId,
      workspaceId: workspaceId,
      principalId: agentId,
      role: TicketCollaboratorRole.fromStorage(arguments['role'] as String?),
    );
    return CallResult.success(
      jsonEncode({'ticket_id': ticketId, 'status': 'collaborator_added'}),
    );
  }
}

/// MCP tool to post a comment into a ticket's discussion space. @mentions in
/// the content dispatch the mentioned agent.
class CommentOnTicketTool extends McpTool {
  /// Creates a [CommentOnTicketTool].
  CommentOnTicketTool({
    required TicketRepository repository,
    required MessagingPort messagingPort,
  }) : _repository = repository,
       _messagingPort = messagingPort;

  final TicketRepository _repository;
  final MessagingPort _messagingPort;

  @override
  String get name => 'comment_on_ticket';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.processSpawn};

  @override
  String get description =>
      "Post a comment into a ticket's discussion space. @mentions dispatch "
      'the mentioned agent.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'ticket_id': {'type': 'string', 'description': 'The ticket ID.'},
      'content': {'type': 'string', 'description': 'The comment body.'},
    },
    'required': ['workspace_id', 'ticket_id', 'content'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final ticketId = arguments['ticket_id'];
    final content = arguments['content'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (ticketId is! String || content is! String) {
      return CallResult.error('Missing ticket_id or content.');
    }
    final ticket = await _repository.getById(workspaceId, ticketId);
    if (ticket == null) {
      return CallResult.error('Ticket not found.');
    }
    if (ticket.workspaceId != workspaceId) {
      return CallResult.error('Ticket belongs to a different workspace.');
    }
    final spaceId = ticket.spaceId;
    if (spaceId == null) {
      return CallResult.error(
        'Ticket has no discussion space yet — assign it to an agent first.',
      );
    }
    await _messagingPort.sendAndDispatch(
      ticket.workspaceId,
      spaceId,
      content,
    );
    return CallResult.success(
      jsonEncode({
        'ticket_id': ticketId,
        'space_id': spaceId,
        'status': 'commented',
      }),
    );
  }
}

/// MCP tool to link or unlink a ticket and a pull request.
///
/// One tool rather than the `link_ticket_to_pr` / `unlink_ticket_from_pr` pair
/// it replaces: identical arguments, opposite direction. Two tools that differ
/// only by a prefix are the shape a retriever cannot separate, and a model
/// choosing between two look-alike descriptions is exactly the case that
/// degrades tool-selection accuracy.
class TicketPrLinkTool extends McpTool {
  /// Creates a [TicketPrLinkTool].
  TicketPrLinkTool({required TicketWorkflowService service})
    : _service = service;
  final TicketWorkflowService _service;

  @override
  String get name => 'ticket_pr_link';

  @override
  String get description =>
      'Link a ticket to a pull request, or unlink them. Identify the PR by its '
      'node ID. Use `action` to choose: `link` (default) or `unlink`.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'ticket_id': {'type': 'string', 'description': 'The ticket ID.'},
      'pr_external_id': {'type': 'string', 'description': 'The PR node ID.'},
      'action': {
        'type': 'string',
        'enum': ['link', 'unlink'],
        'description': 'Attach or detach the PR. Default: link.',
      },
    },
    'required': ['workspace_id', 'ticket_id', 'pr_external_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final ticketId = arguments['ticket_id'];
    final prExternalId = arguments['pr_external_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (ticketId is! String || prExternalId is! String) {
      return CallResult.error('Missing ticket_id or pr_external_id.');
    }
    final rawAction = arguments['action'];
    if (rawAction != null && rawAction != 'link' && rawAction != 'unlink') {
      return CallResult.error("Invalid action. Expected 'link' or 'unlink'.");
    }
    final unlinking = rawAction == 'unlink';
    if (unlinking) {
      await _service.unlinkPullRequest(
        ticketId,
        prExternalId,
        workspaceId: workspaceId,
      );
    } else {
      await _service.linkPullRequest(
        ticketId,
        prExternalId,
        workspaceId: workspaceId,
      );
    }
    return CallResult.success(
      jsonEncode({
        'ticket_id': ticketId,
        'pr_external_id': prExternalId,
        'status': unlinking ? 'unlinked' : 'linked',
      }),
    );
  }
}

/// MCP tool to close (complete) a ticket.
class CloseTicketTool extends McpTool {
  /// Creates a [CloseTicketTool].
  CloseTicketTool({required TicketWorkflowService service})
    : _service = service;
  final TicketWorkflowService _service;

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) =>
      ApprovalPayload(
        title: 'Close ticket',
        detail: 'Mark ticket ${arguments['ticket_id']} as done.',
      );

  @override
  String get name => 'close_ticket';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.vendorSyncWrite};

  @override
  String get description =>
      'Close a ticket (marks it done) with optional output.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'ticket_id': {'type': 'string', 'description': 'The ticket ID.'},
      'output': {
        'type': 'object',
        'description': 'Optional closing summary payload.',
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
    await _service.completeTicket(ticketId, workspaceId: workspaceId);
    return CallResult.success(
      jsonEncode({'ticket_id': ticketId, 'status': 'done'}),
    );
  }
}
