import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';

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
        detail: 'Assign ticket ${arguments['ticket_id']} to '
            '${arguments['agent_id'] ?? arguments['team_id'] ?? 'nobody'}.',
      );

  @override
  String get name => 'assign_ticket';

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
      agentId: arguments['agent_id'] as String?,
      teamId: arguments['team_id'] as String?,
    );
    return CallResult.success(
        jsonEncode({'ticket_id': ticketId, 'status': 'assigned'}));
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
        detail: 'Reassign ticket ${arguments['ticket_id']} to '
            '${arguments['agent_id']}.',
      );

  @override
  String get name => 'reassign_ticket';

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
    await _service.reassign(ticketId, workspaceId: workspaceId, toAgentId: agentId);
    return CallResult.success(
        jsonEncode({'ticket_id': ticketId, 'status': 'reassigned'}));
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
      'Invite an agent to collaborate on a ticket (added to its channel).';

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
      agentId: agentId,
      role: TicketCollaboratorRole.fromStorage(arguments['role'] as String?),
    );
    return CallResult.success(
        jsonEncode({'ticket_id': ticketId, 'status': 'collaborator_added'}));
  }
}

/// MCP tool to post a comment into a ticket's discussion channel. @mentions in
/// the content dispatch the mentioned agent.
class CommentOnTicketTool extends McpTool {
  /// Creates a [CommentOnTicketTool].
  CommentOnTicketTool({
    required TicketRepository repository,
    required MessagingPort messagingPort,
  })  : _repository = repository,
        _messagingPort = messagingPort;

  final TicketRepository _repository;
  final MessagingPort _messagingPort;

  @override
  String get name => 'comment_on_ticket';

  @override
  String get description =>
      "Post a comment into a ticket's discussion channel. @mentions dispatch "
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
    final ticket = await _repository.getById(ticketId);
    if (ticket == null) {
      return CallResult.error('Ticket not found.');
    }
    if (ticket.workspaceId != workspaceId) {
      return CallResult.error('Ticket belongs to a different workspace.');
    }
    final channelId = ticket.channelId;
    if (channelId == null) {
      return CallResult.error(
        'Ticket has no discussion channel yet — assign it to an agent first.',
      );
    }
    await _messagingPort.sendAndDispatch(
      channelId,
      content,
      workspaceId: ticket.workspaceId,
    );
    return CallResult.success(
        jsonEncode({'ticket_id': ticketId, 'channel_id': channelId, 'status': 'commented'}));
  }
}

/// MCP tool to link a ticket to a pull request.
class LinkTicketToPrTool extends McpTool {
  /// Creates a [LinkTicketToPrTool].
  LinkTicketToPrTool({required TicketWorkflowService service})
      : _service = service;
  final TicketWorkflowService _service;

  @override
  String get name => 'link_ticket_to_pr';

  @override
  String get description => 'Link a ticket to a pull request (by PR node ID).';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'ticket_id': {'type': 'string', 'description': 'The ticket ID.'},
          'pr_node_id': {'type': 'string', 'description': 'The PR node ID.'},
        },
        'required': ['workspace_id', 'ticket_id', 'pr_node_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final ticketId = arguments['ticket_id'];
    final prNodeId = arguments['pr_node_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (ticketId is! String || prNodeId is! String) {
      return CallResult.error('Missing ticket_id or pr_node_id.');
    }
    await _service.linkPullRequest(ticketId, prNodeId, workspaceId: workspaceId);
    return CallResult.success(
        jsonEncode({'ticket_id': ticketId, 'pr_node_id': prNodeId, 'status': 'linked'}));
  }
}

/// MCP tool to unlink a ticket from a pull request.
class UnlinkTicketFromPrTool extends McpTool {
  /// Creates an [UnlinkTicketFromPrTool].
  UnlinkTicketFromPrTool({required TicketWorkflowService service})
      : _service = service;
  final TicketWorkflowService _service;

  @override
  String get name => 'unlink_ticket_from_pr';

  @override
  String get description =>
      'Unlink a ticket from a pull request (by PR node ID).';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'ticket_id': {'type': 'string', 'description': 'The ticket ID.'},
          'pr_node_id': {'type': 'string', 'description': 'The PR node ID.'},
        },
        'required': ['workspace_id', 'ticket_id', 'pr_node_id'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final ticketId = arguments['ticket_id'];
    final prNodeId = arguments['pr_node_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (ticketId is! String || prNodeId is! String) {
      return CallResult.error('Missing ticket_id or pr_node_id.');
    }
    await _service.unlinkPullRequest(ticketId, prNodeId,
        workspaceId: workspaceId);
    return CallResult.success(jsonEncode(
        {'ticket_id': ticketId, 'pr_node_id': prNodeId, 'status': 'unlinked'}));
  }
}

/// MCP tool to close (complete) a ticket.
class CloseTicketTool extends McpTool {
  /// Creates a [CloseTicketTool].
  CloseTicketTool({required TicketWorkflowService service}) : _service = service;
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
  String get description => 'Close a ticket (marks it done) with optional output.';

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
    await _service.completeTicket(
      ticketId,
      workspaceId: workspaceId,
      output: arguments['output'] as Map<String, dynamic>?,
    );
    return CallResult.success(
        jsonEncode({'ticket_id': ticketId, 'status': 'done'}));
  }
}
