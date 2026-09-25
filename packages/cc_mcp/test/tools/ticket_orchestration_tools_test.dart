import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/tools/ticket_orchestration_tools.dart';
import 'package:test/test.dart';

void main() {
  late _FakeTickets tickets;
  late AssignTicketTool tool;

  setUp(() {
    tickets = _FakeTickets();
    tool = AssignTicketTool(
      service: TicketWorkflowService(
        repository: tickets,
        eventBus: DomainEventBus(),
      ),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'ticket_id': 't1', 'agent_id': 'agent-a'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('assigns an existing ticket', () async {
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
      'agent_id': 'agent-a',
    });
    expect(result.isError, isFalse);
    expect(tickets.store['t1']!.assignedAgentId, 'agent-a');
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['status'], 'assigned');
  });
  test('all ticket mutations reject missing and foreign ids', () async {
    tickets.store['foreign'] = Ticket(
      id: 'foreign',
      workspaceId: 'ws-other',
      title: 'Untouched',
      status: TicketStatus.open,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final service = TicketWorkflowService(
      repository: tickets,
      eventBus: DomainEventBus(),
    );
    final cases = <(McpTool, Map<String, dynamic>)>[
      (AssignTicketTool(service: service), {'agent_id': 'agent-a'}),
      (ReassignTicketTool(service: service), {'agent_id': 'agent-b'}),
      (AddTicketCollaboratorTool(service: service), {'agent_id': 'agent-c'}),
      (TicketPrLinkTool(service: service), {'pr_external_id': 'pr-1'}),
      (
        TicketPrLinkTool(service: service),
        {'pr_external_id': 'pr-1', 'action': 'unlink'},
      ),
      (CloseTicketTool(service: service), {}),
    ];
    for (final (mutation, args) in cases) {
      for (final ticketId in ['missing', 'foreign']) {
        final result = await mutation.run({
          'workspace_id': 'ws-1',
          'ticket_id': ticketId,
          ...args,
        });
        expect(result.isError, isTrue, reason: '${mutation.name} $ticketId');
        expect(result.content.first.text, contains('not found'));
      }
    }
    expect(tickets.store['foreign']!.title, 'Untouched');
    expect(tickets.store['foreign']!.status, TicketStatus.open);
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
