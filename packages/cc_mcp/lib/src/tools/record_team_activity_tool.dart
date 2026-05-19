import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/teams/domain/entities/team_activity.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_activity_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:uuid/uuid.dart';

/// `record_team_activity` — the team leader's mandatory evaluation verb.
///
/// After delegating (or deciding not to), the leader records the outcome
/// against the ticket. A `no_action` outcome suppresses further leader
/// re-triggers for that ticket (the dedup guard that bounds the coordination
/// loop). The team is resolved from the ticket's assignment, so the leader only
/// supplies the ticket id + outcome.
class RecordTeamActivityTool extends McpTool {
  /// Creates a [RecordTeamActivityTool].
  RecordTeamActivityTool({
    required TicketRepository ticketRepository,
    required TeamActivityRepository activityRepository,
  }) : _tickets = ticketRepository,
       _activity = activityRepository;

  final TicketRepository _tickets;
  final TeamActivityRepository _activity;
  final Uuid _uuid = const Uuid();

  @override
  String get name => 'record_team_activity';

  @override
  String get description =>
      'Records a team leader\'s evaluation of a routed ticket. Outcome is one '
      'of action (delegated to a member), no_action (nothing more to do — stops '
      'further re-triggers for this ticket), or failed (the member could not '
      'complete it). The team is resolved from the ticket\'s assignment.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace the ticket belongs to.',
      },
      'ticket_id': {
        'type': 'string',
        'description': 'The routed ticket being evaluated.',
      },
      'outcome': {
        'type': 'string',
        'enum': ['action', 'no_action', 'failed'],
        'description': 'The evaluation outcome.',
      },
      'member_id': {
        'type': 'string',
        'description': 'Agent delegated to (for an action outcome).',
      },
      'summary': {
        'type': 'string',
        'description': 'Short note about the decision.',
      },
    },
    'required': ['workspace_id', 'ticket_id', 'outcome'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final ticketId = arguments['ticket_id'];
    final outcome = arguments['outcome'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (ticketId is! String) {
      return CallResult.error('Missing or invalid argument: ticket_id');
    }
    if (outcome is! String ||
        !const {'action', 'no_action', 'failed'}.contains(outcome)) {
      return CallResult.error(
        'Invalid argument: outcome must be action | no_action | failed',
      );
    }

    final ticket = await _tickets.getById(workspaceId, ticketId);
    if (ticket == null || ticket.workspaceId != workspaceId) {
      return CallResult.error(
        'Ticket $ticketId not found in this workspace, or it belongs to a '
        'different workspace.',
      );
    }
    final teamId = ticket.assignedTeamId;
    if (teamId == null || teamId.isEmpty) {
      return CallResult.error('Ticket $ticketId is not assigned to a team.');
    }

    final memberId = arguments['member_id'];
    final summary = arguments['summary'];
    await _activity.record(
      TeamActivity(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        teamId: teamId,
        ticketId: ticketId,
        kind: TeamActivityKind.fromString(outcome),
        memberId: memberId is String ? memberId : null,
        summary: summary is String ? summary : null,
        createdAt: DateTime.now(),
      ),
    );

    return CallResult.success(
      jsonEncode({
        'ticket_id': ticketId,
        'team_id': teamId,
        'outcome': outcome,
        'status': 'recorded',
      }),
    );
  }
}
