import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_link.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_link_service.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';

/// The relation strings accepted by the link tools, from the subject ticket's
/// point of view, mapped to a [TicketRelationKind].
const _relationByName = <String, TicketRelationKind>{
  'blocked_by': TicketRelationKind.blockedBy,
  'blocking': TicketRelationKind.blocking,
  'related_to': TicketRelationKind.relatedTo,
  'duplicate_of': TicketRelationKind.duplicateOf,
  'duplicated_by': TicketRelationKind.duplicatedBy,
  'sub_issue_of': TicketRelationKind.subIssueOf,
  'parent_of': TicketRelationKind.parentOf,
};

String _relationName(TicketRelationKind kind) =>
    _relationByName.entries.firstWhere((e) => e.value == kind).key;

/// MCP tool to add a dependency relation between two tickets, expressed from
/// the subject ticket's point of view. Sub-issue / parent relations are stored
/// on the ticket; the rest are dependency links.
class LinkTicketsTool extends McpTool {
  /// Creates a [LinkTicketsTool].
  LinkTicketsTool({
    required TicketLinkService linkService,
    required TicketWorkflowService workflow,
  })  : _linkService = linkService,
        _workflow = workflow;

  final TicketLinkService _linkService;
  final TicketWorkflowService _workflow;

  @override
  bool get requiresApproval => true;

  @override
  String get name => 'link_tickets';

  @override
  String get description =>
      'Adds a relation from ticket_id to related_ticket_id. The relation is '
      'one of: blocked_by, blocking, related_to, duplicate_of, duplicated_by, '
      'sub_issue_of (sets ticket_id\'s parent), parent_of (makes ticket_id the '
      'parent of related_ticket_id). Reading "ticket_id <relation> '
      'related_ticket_id".';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'ticket_id': {
            'type': 'string',
            'description': 'The subject ticket ID.',
          },
          'related_ticket_id': {
            'type': 'string',
            'description': 'The other ticket ID.',
          },
          'relation': {
            'type': 'string',
            'description':
                'blocked_by | blocking | related_to | duplicate_of | '
                    'duplicated_by | sub_issue_of | parent_of',
          },
        },
        'required': ['workspace_id', 'ticket_id', 'related_ticket_id', 'relation'],
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
    final otherId = arguments['related_ticket_id'];
    if (otherId is! String) {
      return CallResult.error('Missing or invalid argument: related_ticket_id');
    }
    final kind = _relationByName[arguments['relation']];
    if (kind == null) {
      return CallResult.error(
        'Invalid relation. Expected one of: ${_relationByName.keys.join(', ')}.',
      );
    }
    try {
      switch (kind) {
        case TicketRelationKind.subIssueOf:
          await _workflow.setParent(ticketId, otherId, workspaceId: workspaceId);
        case TicketRelationKind.parentOf:
          await _workflow.setParent(otherId, ticketId, workspaceId: workspaceId);
        default:
          await _linkService.addRelation(
            workspaceId: workspaceId,
            subjectTicketId: ticketId,
            otherTicketId: otherId,
            kind: kind,
          );
      }
    } on ArgumentError catch (e) {
      return CallResult.error('${e.message}');
    }
    return CallResult.success(jsonEncode({
      'ticket_id': ticketId,
      'relation': _relationName(kind),
      'related_ticket_id': otherId,
    }));
  }
}

/// MCP tool to remove a dependency relation between two tickets.
class UnlinkTicketsTool extends McpTool {
  /// Creates an [UnlinkTicketsTool].
  UnlinkTicketsTool({
    required TicketLinkService linkService,
    required TicketWorkflowService workflow,
  })  : _linkService = linkService,
        _workflow = workflow;

  final TicketLinkService _linkService;
  final TicketWorkflowService _workflow;

  @override
  bool get requiresApproval => true;

  @override
  String get name => 'unlink_tickets';

  @override
  String get description =>
      'Removes a relation between ticket_id and related_ticket_id (see '
      'link_tickets for the relation vocabulary).';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
          'ticket_id': {'type': 'string', 'description': 'The subject ticket ID.'},
          'related_ticket_id': {
            'type': 'string',
            'description': 'The other ticket ID.',
          },
          'relation': {
            'type': 'string',
            'description':
                'blocked_by | blocking | related_to | duplicate_of | '
                    'duplicated_by | sub_issue_of | parent_of',
          },
        },
        'required': ['workspace_id', 'ticket_id', 'related_ticket_id', 'relation'],
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
    final otherId = arguments['related_ticket_id'];
    if (otherId is! String) {
      return CallResult.error('Missing or invalid argument: related_ticket_id');
    }
    final kind = _relationByName[arguments['relation']];
    if (kind == null) {
      return CallResult.error(
        'Invalid relation. Expected one of: ${_relationByName.keys.join(', ')}.',
      );
    }
    switch (kind) {
      case TicketRelationKind.subIssueOf:
        await _workflow.clearParent(ticketId, workspaceId: workspaceId);
      case TicketRelationKind.parentOf:
        await _workflow.clearParent(otherId, workspaceId: workspaceId);
      default:
        await _linkService.removeRelation(
          workspaceId: workspaceId,
          subjectTicketId: ticketId,
          otherTicketId: otherId,
          kind: kind,
        );
    }
    return CallResult.success(jsonEncode({
      'ticket_id': ticketId,
      'relation': _relationName(kind),
      'related_ticket_id': otherId,
      'removed': true,
    }));
  }
}

/// MCP tool to list every relation touching a ticket (parent, sub-issues, and
/// dependency links), from that ticket's point of view.
class ListTicketRelationsTool extends McpTool {
  /// Creates a [ListTicketRelationsTool].
  ListTicketRelationsTool({
    required TicketLinkRepository linkRepository,
    required TicketRepository ticketRepository,
  })  : _linkRepository = linkRepository,
        _ticketRepository = ticketRepository;

  final TicketLinkRepository _linkRepository;
  final TicketRepository _ticketRepository;

  @override
  String get name => 'list_ticket_relations';

  @override
  String get description =>
      'Lists all relations of a ticket: its parent and sub-issues, plus its '
      'blocked_by / blocking / related_to / duplicate links.';

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
    final ticket = await _ticketRepository.getById(ticketId);
    if (ticket == null || ticket.workspaceId != workspaceId) {
      return CallResult.error('Ticket $ticketId not found in this workspace.');
    }
    final relations = <Map<String, dynamic>>[];
    if (ticket.parentTicketId != null) {
      relations.add({
        'relation': _relationName(TicketRelationKind.subIssueOf),
        'related_ticket_id': ticket.parentTicketId,
      });
    }
    final children =
        await _ticketRepository.childrenOf(workspaceId, ticketId);
    for (final child in children) {
      relations.add({
        'relation': _relationName(TicketRelationKind.parentOf),
        'related_ticket_id': child.id,
      });
    }
    final links = await _linkRepository.getForTicket(workspaceId, ticketId);
    for (final link in links) {
      final view = link.relationFor(ticketId);
      if (view == null) {
        continue;
      }
      relations.add({
        'relation': _relationName(view.kind),
        'related_ticket_id': view.otherTicketId,
      });
    }
    return CallResult.success(
      jsonEncode({'ticket_id': ticketId, 'relations': relations}),
    );
  }
}
