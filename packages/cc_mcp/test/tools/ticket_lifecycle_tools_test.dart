import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/tools/ticket_lifecycle_tools.dart';
import 'package:test/test.dart';

void main() {
  late _FakeTickets tickets;
  late FailTicketTool tool;

  setUp(() {
    tickets = _FakeTickets();
    tool = FailTicketTool(
      service: TicketWorkflowService(
        repository: tickets,
        eventBus: DomainEventBus(),
      ),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({
      'ticket_id': 't1',
      'error_message': 'boom',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('fails an existing ticket', () async {
    tickets.store['t1'] = Ticket(
      id: 't1',
      workspaceId: 'ws-1',
      title: 'Fix login',
      status: TicketStatus.open,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'ticket_id': 't1',
      'error_message': 'boom',
    });
    expect(result.isError, isFalse);
    expect(tickets.store['t1']!.status, TicketStatus.failed);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['status'], 'failed');
  });
}

class _FakeTickets implements TicketRepository {
  final Map<String, Ticket> store = {};

  @override
  Future<void> insert(Ticket ticket) async => store[ticket.id] = ticket;

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async =>
      store[ticket.id] = ticket;

  @override
  Future<Ticket?> getById(String workspaceId, String id) async {
    final ticket = store[id];
    return ticket?.workspaceId == workspaceId ? ticket : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
