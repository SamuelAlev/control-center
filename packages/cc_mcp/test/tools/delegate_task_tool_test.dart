import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_infra/cc_infra.dart' show TicketSettledWakes;
import 'package:cc_mcp/src/tools/delegate_task_tool.dart';
import 'package:test/test.dart';

import 'peer_tool_kit.dart';

void main() {
  late _FakeTickets tickets;
  late DelegateTaskTool tool;
  late PeerKit kit;

  setUp(() {
    tickets = _FakeTickets();
    kit = PeerKit();
    tool = DelegateTaskTool(
      service: TicketWorkflowService(
        repository: tickets,
        eventBus: DomainEventBus(),
        resolveEffectiveAutonomy:
            ({required workspaceId, required agentId, spaceId}) async =>
                AutonomyLevel.actWithApproval,
        resolveRemainingBudgetMicros:
            ({required workspaceId, required agentId}) async => null,
      ),
      peerAsks: kit.service,
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
  test('an unconfigured guard policy refuses instead of passing', () async {
    final bare = DelegateTaskTool(
      service: TicketWorkflowService(
        repository: tickets,
        eventBus: DomainEventBus(),
      ),
      peerAsks: kit.service,
    );
    final result = await bare.run({
      'workspace_id': 'ws-1',
      'title': 'Look at this',
      'to_agent_id': 'agent-b',
      'from_agent_id': 'agent-a',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('not configured'));
    expect(tickets.store, isEmpty);
  });

  test('records the conversation and run it was delegated from', () async {
    kit.conversation('c-sp-a', spaceId: 'sp-a');
    final result = await tool.callForRun(
      {
        'workspace_id': 'ws-1',
        'title': 'Look at this',
        'to_agent_id': 'agent-b',
        'from_agent_id': 'agent-a',
      },
      runScope(agentId: 'agent-a', runId: 'run-a', conversationId: 'c-sp-a'),
    );
    expect(result.isError, isFalse, reason: result.content.first.text);
    final ticket = tickets.store.values.single;
    expect(ticket.delegatedFromConversationId, 'c-sp-a');
    expect(ticket.delegatedByAgentId, 'agent-a');
    expect(ticket.metadata[TicketSettledWakes.delegatingRunKey], 'run-a');
  });

  test('cannot delegate to the caller of an active ask', () async {
    // agent-a asked agent-b and waits on it.
    await kit.asks.insert(
      PeerAsk(
        id: 'ask-1',
        workspaceId: 'ws-1',
        askerAgentId: 'agent-a',
        askerConversationId: 'c-a',
        askerSpaceId: 'sp-a',
        recipientAgentId: 'agent-b',
        questionHash: 'h',
        createdAt: kit.now,
        expiresAt: kit.now.add(const Duration(hours: 24)),
      ),
    );
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'title': 'Loop back',
      'from_agent_id': 'agent-b',
      'to_agent_id': 'agent-a',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('cycle'));
    expect(refusalField(result, 'kind'), PeerAskRefusals.cycle);
    expect(tickets.store, isEmpty);
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
