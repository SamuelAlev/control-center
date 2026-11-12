import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/tools/peer_delegation_gate.dart';
import 'package:cc_mcp/src/tools/pending_delegation_hops.dart';
import 'package:test/test.dart';

const _ws = 'ws-1';

void main() {
  late PendingDelegationHops hops;
  late AutonomyLevel delegatorAutonomy;
  late AutonomyLevel recipientAutonomy;
  int? remainingBudget;

  PeerDelegationGate gate({bool configured = true}) => PeerDelegationGate(
    service: TicketWorkflowService(
      repository: _NoTickets(),
      eventBus: DomainEventBus(),
      resolveEffectiveAutonomy: configured
          ? ({required workspaceId, required agentId, spaceId}) async =>
                agentId == 'agent-a' ? delegatorAutonomy : recipientAutonomy
          : null,
      resolveRemainingBudgetMicros: configured
          ? ({required workspaceId, required agentId}) async => remainingBudget
          : null,
    ),
    pendingHops: hops,
  );

  setUp(() {
    hops = PendingDelegationHops();
    delegatorAutonomy = AutonomyLevel.actWithApproval;
    recipientAutonomy = AutonomyLevel.actWithApproval;
    remainingBudget = null;
  });

  test('allows a hop every guard passes', () async {
    final refusal = await gate().refusal(
      workspaceId: _ws,
      fromAgentId: 'agent-a',
      recipientId: 'agent-b',
    );
    expect(refusal, isNull);
  });

  test(
    'an unconfigured policy refuses rather than reading as allowed',
    () async {
      final refusal = await gate(configured: false).refusal(
        workspaceId: _ws,
        fromAgentId: 'agent-a',
        recipientId: 'agent-b',
      );
      expect(refusal, contains('not configured'));
    },
  );

  test('refuses a delegate above the delegator autonomy ceiling', () async {
    recipientAutonomy = AutonomyLevel.actFreely;
    final refusal = await gate().refusal(
      workspaceId: _ws,
      fromAgentId: 'agent-a',
      recipientId: 'agent-b',
    );
    expect(refusal, contains('ceiling'));
  });

  test('refuses on an exhausted budget envelope', () async {
    remainingBudget = 0;
    final refusal = await gate().refusal(
      workspaceId: _ws,
      fromAgentId: 'agent-a',
      recipientId: 'agent-b',
    );
    expect(refusal, contains('budget'));
  });

  test('refuses a parent ticket outside the workspace', () async {
    final refusal = await gate().refusal(
      workspaceId: _ws,
      fromAgentId: 'agent-a',
      recipientId: 'agent-b',
      parentTicketId: 'missing',
    );
    expect(refusal, contains('does not exist in this workspace'));
  });

  test('a ticket hand-off does not need the parent assigned to the caller, '
      'and its depth is the ticket depth alone', () async {
    final tickets = _OneTicket(
      Ticket(
        id: 'parent',
        workspaceId: _ws,
        title: 'Parent',
        assignedAgentId: 'agent-c',
        status: TicketStatus.open,
        delegationDepth: 2,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    final service = TicketWorkflowService(
      repository: tickets,
      eventBus: DomainEventBus(),
      resolveEffectiveAutonomy:
          ({required workspaceId, required agentId, spaceId}) async =>
              AutonomyLevel.actWithApproval,
      resolveRemainingBudgetMicros:
          ({required workspaceId, required agentId}) async => null,
    );
    // One in-flight ask above agent-a: an ask counts it, a ticket does not.
    hops.enter(_ws, 'agent-x', 'agent-a');
    final gate = PeerDelegationGate(service: service, pendingHops: hops);
    expect(
      await gate.refusal(
        workspaceId: _ws,
        fromAgentId: 'agent-a',
        recipientId: 'agent-b',
        handOff: PeerHandOff.ticket,
        parentTicketId: 'parent',
      ),
      isNull,
    );
    expect(
      await gate.refusal(
        workspaceId: _ws,
        fromAgentId: 'agent-a',
        recipientId: 'agent-b',
        parentTicketId: 'parent',
      ),
      contains('not assigned to the asker'),
    );
  });

  test(
    'refuses a hop back to an agent already waiting on the sender',
    () async {
      hops.enter(_ws, 'agent-b', 'agent-a');
      final refusal = await gate().refusal(
        workspaceId: _ws,
        fromAgentId: 'agent-a',
        recipientId: 'agent-b',
      );
      expect(refusal, contains('cycle'));
      expect(
        PeerDelegationGate.cycleRefusalIn(
          hops,
          workspaceId: _ws,
          fromAgentId: 'agent-a',
          recipientId: 'agent-b',
        ),
        contains('agent-b'),
      );
      // Another workspace's hops never block this one.
      expect(
        PeerDelegationGate.cycleRefusalIn(
          hops,
          workspaceId: 'ws-2',
          fromAgentId: 'agent-a',
          recipientId: 'agent-b',
        ),
        isNull,
      );
    },
  );
}

class _OneTicket implements TicketRepository {
  _OneTicket(this.ticket);
  final Ticket ticket;

  @override
  Future<Ticket?> getById(String workspaceId, String id) async =>
      id == ticket.id && workspaceId == ticket.workspaceId ? ticket : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoTickets implements TicketRepository {
  @override
  Future<Ticket?> getById(String workspaceId, String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
