import 'dart:convert';

import 'package:cc_domain/features/teams/domain/entities/team_activity.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_activity_repository.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_mcp/src/tools/record_team_activity_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakeTickets tickets;
  late _FakeActivity activity;
  late RecordTeamActivityTool tool;

  setUp(() {
    tickets = _FakeTickets();
    activity = _FakeActivity();
    tool = RecordTeamActivityTool(
      ticketRepository: tickets,
      activityRepository: activity,
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({
      'ticket_id': 't1',
      'outcome': 'no_action',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('refuses a ticket with no team assignment', () async {
    tickets.stored = _ticket(assignedTeamId: null);
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'ticket_id': 't1',
      'outcome': 'no_action',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('not assigned to a team'));
  });

  test('records a no_action evaluation', () async {
    tickets.stored = _ticket(assignedTeamId: 'team-1');
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'ticket_id': 't1',
      'outcome': 'no_action',
      'summary': 'already shipped',
    });
    expect(result.isError, isFalse);
    expect(activity.recorded, isNotNull);
    expect(activity.recorded!.kind, TeamActivityKind.noAction);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['status'], 'recorded');
    expect(body['team_id'], 'team-1');
  });
}

Ticket _ticket({String? assignedTeamId}) => Ticket(
  id: 't1',
  workspaceId: 'ws-1',
  title: 'Ship it',
  status: TicketStatus.open,
  assignedTeamId: assignedTeamId,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _FakeTickets implements TicketRepository {
  Ticket? stored;

  @override
  Future<Ticket?> getById(String workspaceId, String id) async => stored;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeActivity implements TeamActivityRepository {
  TeamActivity? recorded;

  @override
  Future<void> record(TeamActivity activity) async {
    recorded = activity;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
