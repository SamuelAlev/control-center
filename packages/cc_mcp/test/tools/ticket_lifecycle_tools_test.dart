import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/tools/ticket_lifecycle_tools.dart';
import 'package:cc_mcp/src/tools/pending_delegation_hops.dart';
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
    final result = await tool.run({'ticket_id': 't1', 'error_message': 'boom'});
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
  test('missing and foreign tickets cannot be failed', () async {
    tickets.store['foreign'] = Ticket(
      id: 'foreign',
      workspaceId: 'ws-other',
      title: 'Other workspace',
      createdAt: DateTime(2026),
      status: TicketStatus.open,
      updatedAt: DateTime(2026),
    );
    for (final ticketId in ['missing', 'foreign']) {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'ticket_id': ticketId,
        'error_message': 'boom',
      });
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('not found'));
    }
    expect(tickets.store['foreign']!.status, isNot(TicketStatus.failed));
  });

  test(
    'delegate_ticket rejects dangling parents, cycles and depth overflow',
    () async {
      final delegate = DelegateTicketTool(
        service: TicketWorkflowService(
          repository: tickets,
          eventBus: DomainEventBus(),
        ),
        pendingHops: PendingDelegationHops(),
      );
      final missing = await delegate.run({
        'workspace_id': 'ws-1',
        'title': 'Child',
        'assigned_agent_id': 'agent-b',
        'delegated_by_agent_id': 'agent-a',
        'parent_ticket_id': 'missing',
      });
      expect(missing.isError, isTrue);
      expect(missing.content.first.text, contains('does not exist'));
      tickets.store['parent'] = Ticket(
        id: 'parent',
        workspaceId: 'ws-1',
        title: 'Parent',
        assignedAgentId: 'agent-a',
        status: TicketStatus.open,
        delegationDepth: 3,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final depth = await delegate.run({
        'workspace_id': 'ws-1',
        'title': 'Child',
        'assigned_agent_id': 'agent-b',
        'delegated_by_agent_id': 'agent-a',
        'parent_ticket_id': 'parent',
      });
      expect(depth.isError, isTrue);
      expect(depth.content.first.text, contains('depth'));
      tickets.store['parent'] = tickets.store['parent']!.copyWith(
        delegationDepth: 1,
      );
      final cycle = await delegate.run({
        'workspace_id': 'ws-1',
        'title': 'Child',
        'assigned_agent_id': 'agent-a',
        'delegated_by_agent_id': 'agent-a',
        'parent_ticket_id': 'parent',
      });
      expect(cycle.isError, isTrue);
      expect(cycle.content.first.text, contains('cycle'));
      expect(tickets.store, hasLength(1));
    },
  );
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
