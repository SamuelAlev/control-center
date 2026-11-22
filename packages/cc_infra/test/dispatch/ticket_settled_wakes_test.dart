import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/value_objects/delegation_brief.dart';
import 'package:cc_infra/src/dispatch/ticket_settled_wakes.dart';
import 'package:test/test.dart';

import 'peer_test_kit.dart';

class _Tickets implements TicketRepository {
  final Map<String, Ticket> byId = {};

  @override
  Future<Ticket?> getById(String workspaceId, String id) async {
    final t = byId[id];
    return t?.workspaceId == workspaceId ? t : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A delegated ticket that completes, fails or is cancelled wakes its
/// delegator once, in the conversation it was delegated from, for whoever
/// the delegating run acted for (plan section 10, defect 18).
void main() {
  late PeerKit kit;
  late _Tickets tickets;
  late TicketSettledWakes wakes;

  Ticket ticket({
    String id = 'T-42',
    String workspaceId = PeerKit.ws,
    String? from = 'c-a',
    String delegatingRun = 'run-a',
    String? error,
  }) => tickets.byId[id] = Ticket(
    id: id,
    workspaceId: workspaceId,
    title: 'Index audit',
    status: TicketStatus.inProgress,
    assignedAgentId: 'agent-b',
    delegatedByAgentId: 'agent-a',
    delegatedFromConversationId: from,
    errorMessage: error,
    linkedPrIds: const ['pr-7'],
    metadata: {
      TicketSettledWakes.delegatingRunKey: delegatingRun,
      DelegationBrief.metadataKey: DelegationBrief(
        doneMeans: const ['the audit lists every unused index'],
      ).toMetadata(),
    },
    createdAt: kit.now,
    updatedAt: kit.now,
  );

  setUp(() async {
    kit = PeerKit()
      ..agent('agent-a', 'Ada')
      ..agent('agent-b', 'Bo')
      ..conversation('c-a', spaceId: 'sp-a')
      ..conversation('c-b', spaceId: 'sp-b')
      ..run(
        'run-a',
        agentId: 'agent-a',
        conversationId: 'c-a',
        requester: 'user-1',
      );
    kit.runs['run-b'] = AgentRunLog(
      id: 'run-b',
      agentId: 'agent-b',
      workspaceId: PeerKit.ws,
      spaceId: 'sp-b',
      conversationId: 'c-b',
      startedAt: kit.now,
      completedAt: kit.now,
      status: RunStatus.completed,
      ticketId: 'T-42',
      summary: 'Three unused indexes.',
    );
    kit.messages['run-b'] = Message(
      id: 'run-b',
      spaceId: 'sp-b',
      conversationId: 'c-b',
      senderId: 'agent-b',
      senderType: SenderType.agent,
      content: 'Three unused indexes: a, b, c.',
      messageType: MessageType.text,
      createdAt: kit.now,
    );
    tickets = _Tickets();
    wakes = TicketSettledWakes(
      tickets: tickets,
      agents: kit.agentRepository,
      conversations: kit.conversationRepository,
      facts: CompletionFacts(
        messages: kit.messageRepository,
        runLogs: kit.runLogRepository,
      ),
      clock: () => kit.now,
    )..sink = kit.queue.enqueue;
    wakes.start(kit.bus);
    await kit.start();
  });

  tearDown(() => wakes.stop());

  List<Wake> childWakes() => [
    for (final w in kit.wakes.all(PeerKit.ws))
      if (w.reason == WakeReason.childCompleted) w,
  ];

  for (final (status, event) in [
    (
      'completed',
      (DateTime at) => TicketCompleted(
        ticketId: 'T-42',
        workspaceId: PeerKit.ws,
        occurredAt: at,
      ),
    ),
    (
      'failed',
      (DateTime at) => TicketFailed(
        ticketId: 'T-42',
        workspaceId: PeerKit.ws,
        errorMessage: 'the database was locked',
        occurredAt: at,
      ),
    ),
    (
      'cancelled',
      (DateTime at) => TicketCancelled(
        ticketId: 'T-42',
        workspaceId: PeerKit.ws,
        occurredAt: at,
      ),
    ),
  ]) {
    test('a $status ticket wakes the delegator once, in the conversation '
        'it was delegated from', () async {
      ticket(error: status == 'failed' ? 'the database was locked' : null);
      kit.bus
        ..publish(event(kit.now))
        ..publish(event(kit.now));
      await kit.pump();
      await kit.deliver();
      final wake = childWakes().single;
      expect(wake.agentId, 'agent-a');
      expect(wake.conversationId, 'c-a');
      expect(wake.spaceId, 'sp-a');
      expect(wake.dedupKey, 'ticket:T-42:settled');
      expect(wake.requestedByUserId, 'user-1');
      expect(wake.detail.status, status);
      expect(wake.detail.ticketId, 'T-42');
      expect(wake.detail.sourceAgentId, 'agent-b');
      expect(wake.detail.sourceRunId, 'run-b');
      expect(wake.detail.fields[WakeFields.sourceAgentName], 'Bo');
      expect(wake.detail.fields[WakeFields.artifacts], {
        'pullRequests': ['pr-7'],
      });
      expect(wake.detail.fields[WakeFields.doneMeans], [
        'the audit lists every unused index',
      ]);
      expect(
        wake.payload,
        status == 'failed'
            ? 'the database was locked'
            : 'Three unused indexes: a, b, c.',
      );
      final run = kit.dispatched.single;
      expect(run.agentId, 'agent-a');
      expect(run.conversationId, 'c-a');
      expect(run.requestedByUserId, 'user-1');
      expect(run.wakeContext.wakeReason, WakeReason.childCompleted);
    });
  }

  test('a ticket nobody delegated from a conversation wakes nobody', () async {
    ticket(from: null);
    expect(
      await wakes.onTicketSettled(PeerKit.ws, 'T-42', 'completed'),
      isFalse,
    );
    expect(childWakes(), isEmpty);
  });

  test("another workspace's ticket of the same id wakes nobody", () async {
    ticket(workspaceId: PeerKit.other);
    kit.bus.publish(
      TicketCompleted(
        ticketId: 'T-42',
        workspaceId: PeerKit.ws,
        occurredAt: kit.now,
      ),
    );
    await kit.pump();
    expect(childWakes(), isEmpty);
    expect(kit.wakes.all(PeerKit.other), isEmpty);
  });

  test(
    'a delegating run of another agent lends no person: a bot wake',
    () async {
      kit.run(
        'run-c',
        agentId: 'agent-b',
        conversationId: 'c-b',
        requester: 'user-2',
      );
      ticket(delegatingRun: 'run-c');
      await wakes.onTicketSettled(PeerKit.ws, 'T-42', 'completed');
      expect(childWakes().single.requestedByUserId, isNull);
    },
  );
}
