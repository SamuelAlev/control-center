import 'dart:convert';

import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_mcp/src/tools/ticket_crud_tools.dart';
import 'package:test/test.dart';

void main() {
  late _FakeTickets tickets;
  late GetTicketTool tool;

  setUp(() {
    tickets = _FakeTickets();
    tool = GetTicketTool(repository: tickets);
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'ticket_id': 't1'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('refuses a ticket from another workspace', () async {
    tickets.stored = _ticket(workspaceId: 'ws-other');
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'ticket_id': 't1',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('different workspace'));
  });

  test('returns a ticket in the caller workspace', () async {
    tickets.stored = _ticket(workspaceId: 'ws-1');
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'ticket_id': 't1',
    });
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['ticket_id'], 't1');
    expect(body['title'], 'Fix login');
  });
}

Ticket _ticket({required String workspaceId}) => Ticket(
  id: 't1',
  workspaceId: workspaceId,
  title: 'Fix login',
  status: TicketStatus.open,
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
