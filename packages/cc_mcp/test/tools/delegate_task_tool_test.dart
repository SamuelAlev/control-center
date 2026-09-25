import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/tools/delegate_task_tool.dart';
import 'package:cc_mcp/src/tools/pending_delegation_hops.dart';
import 'package:test/test.dart';

void main() {
  late _FakeTickets tickets;
  late DelegateTaskTool tool;
  late PendingDelegationHops pendingHops;

  setUp(() {
    tickets = _FakeTickets();
    pendingHops = PendingDelegationHops();
    tool = DelegateTaskTool(
      service: TicketWorkflowService(
        repository: tickets,
        eventBus: DomainEventBus(),
      ),
      pendingHops: pendingHops,
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({
      'title': 'Look at this',
      'to_agent_id': 'agent-b',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('creates a child ticket for the delegate', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'title': 'Look at this',
      'to_agent_id': 'agent-b',
      'from_agent_id': 'agent-a',
    });
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['assigned_agent_id'], 'agent-b');
    expect(body['delegation_depth'], 1);
    expect(tickets.store, hasLength(1));
  });

  test('unknown parent is a delegation refusal, not a hang', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'title': 'Child',
      'to_agent_id': 'agent-b',
      'parent_ticket_id': 'missing',
      'from_agent_id': 'agent-a',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('does not exist'));
  });
  test('cannot delegate to the caller of an active ask', () async {
    final release = pendingHops.enter('ws-1', 'agent-a', 'agent-b');
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'title': 'Loop back',
      'from_agent_id': 'agent-b',
      'to_agent_id': 'agent-a',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('cycle'));
    expect(tickets.store, isEmpty);
    release();
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
