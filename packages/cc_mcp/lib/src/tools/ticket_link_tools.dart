import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_link_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_harness/tools.dart';

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

/// MCP tool to add or remove a relation between two tickets, expressed from the
/// subject ticket's point of view. Sub-issue / parent relations are stored on
/// the ticket; the rest are dependency links.
///
/// One tool rather than the `link_tickets` / `unlink_tickets` pair it replaces:
/// they took identical arguments and differed only in direction, so a search
/// for "link tickets" returned both and a model had to disambiguate two nearly
/// identical descriptions. Near-duplicate tools are the measured cause of
/// tool-misselection, not the token count — an `action` argument is a choice
/// the model makes with the full context of the call, where picking between two
/// look-alike tools is a choice it makes from descriptions alone.
class TicketRelationTool extends McpTool {
  /// Creates a [TicketRelationTool].
  TicketRelationTool({
    required TicketLinkService linkService,
    required TicketWorkflowService workflow,
  }) : _linkService = linkService,
       _workflow = workflow;

  final TicketLinkService _linkService;
  final TicketWorkflowService _workflow;

  @override
  bool get requiresApproval => true;

  @override
  String get name => 'ticket_relation';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.vendorSyncWrite};

  @override
  String get description =>
      'Adds or removes a relation between two tickets — link, unlink, block, '
      'unblock, mark a duplicate, or set/clear a parent (sub-issue). Reads as '
      '"ticket_id <relation> related_ticket_id": `sub_issue_of` sets '
      "ticket_id's parent, `parent_of` makes ticket_id the parent of "
      'related_ticket_id. Use `action` to choose direction: `add` creates the '
      'relation, `remove` deletes it.';

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
        'enum': [..._relationByName.keys],
        'description': 'The relation, from ticket_id to related_ticket_id.',
      },
      'action': {
        'type': 'string',
        'enum': ['add', 'remove'],
        'description': 'Create the relation or delete it. Default: add.',
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
    final rawAction = arguments['action'];
    if (rawAction != null && rawAction != 'add' && rawAction != 'remove') {
      return CallResult.error("Invalid action. Expected 'add' or 'remove'.");
    }
    final removing = rawAction == 'remove';
    try {
      switch ((kind, removing)) {
        case (TicketRelationKind.subIssueOf, false):
          await _workflow.setParent(
            ticketId,
            otherId,
            workspaceId: workspaceId,
          );
        case (TicketRelationKind.parentOf, false):
          await _workflow.setParent(
            otherId,
            ticketId,
            workspaceId: workspaceId,
          );
        case (TicketRelationKind.subIssueOf, true):
          await _workflow.clearParent(ticketId, workspaceId: workspaceId);
        case (TicketRelationKind.parentOf, true):
          await _workflow.clearParent(otherId, workspaceId: workspaceId);
        case (_, true):
          await _linkService.removeRelation(
            workspaceId: workspaceId,
            subjectTicketId: ticketId,
            otherTicketId: otherId,
            kind: kind,
          );
        case (_, false):
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
    return CallResult.success(
      jsonEncode({
        'ticket_id': ticketId,
        'relation': _relationName(kind),
        'related_ticket_id': otherId,
        if (removing) 'removed': true,
      }),
    );
  }
}

/// MCP tool to list every relation touching a ticket (parent, sub-issues and
/// dependency links), from that ticket's point of view.
class ListTicketRelationsTool extends McpTool {
  /// Creates a [ListTicketRelationsTool].
  ListTicketRelationsTool({
    required TicketLinkRepository linkRepository,
    required TicketRepository ticketRepository,
  }) : _linkRepository = linkRepository,
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
    final ticket = await _ticketRepository.getById(workspaceId, ticketId);
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
    final children = await _ticketRepository.childrenOf(workspaceId, ticketId);
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
