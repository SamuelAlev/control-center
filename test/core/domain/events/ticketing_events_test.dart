import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 18);

  group('TicketCreated',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = TicketCreated(ticketId: 't-1', occurredAt: now);

      expect(event.ticketId, 't-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = TicketCreated(ticketId: 't-1', occurredAt: now);
      expect(event, isA<DomainEvent>());
    });
  });

  group('TicketDelegated',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = TicketDelegated(
        ticketId: 't-2',
        parentTicketId: 't-1',
        occurredAt: now,
      );

      expect(event.ticketId, 't-2');
      expect(event.parentTicketId, 't-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = TicketDelegated(
        ticketId: 't-2',
        parentTicketId: 't-1',
        occurredAt: now,
      );
      expect(event, isA<DomainEvent>());
    });
  });

  group('TicketStarted',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = TicketStarted(ticketId: 't-1', occurredAt: now);

      expect(event.ticketId, 't-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = TicketStarted(ticketId: 't-1', occurredAt: now);
      expect(event, isA<DomainEvent>());
    });
  });

  group('TicketCompleted',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = TicketCompleted(ticketId: 't-1', occurredAt: now);

      expect(event.ticketId, 't-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = TicketCompleted(ticketId: 't-1', occurredAt: now);
      expect(event, isA<DomainEvent>());
    });
  });

  group('TicketFailed',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = TicketFailed(
        ticketId: 't-1',
        errorMessage: 'Agent crashed',
        occurredAt: now,
      );

      expect(event.ticketId, 't-1');
      expect(event.errorMessage, 'Agent crashed');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = TicketFailed(
        ticketId: 't-1',
        errorMessage: 'err',
        occurredAt: now,
      );
      expect(event, isA<DomainEvent>());
    });
  });

  group('TicketCancelled',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = TicketCancelled(ticketId: 't-1', occurredAt: now);

      expect(event.ticketId, 't-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = TicketCancelled(ticketId: 't-1', occurredAt: now);
      expect(event, isA<DomainEvent>());
    });
  });

  group('TicketStatusChanged',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = TicketStatusChanged(
        ticketId: 't-1',
        from: 'todo',
        to: 'in_progress',
        workspaceId: 'ws-1',
        occurredAt: now,
      );

      expect(event.ticketId, 't-1');
      expect(event.from, 'todo');
      expect(event.to, 'in_progress');
      expect(event.workspaceId, 'ws-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = TicketStatusChanged(
        ticketId: 't-1',
        from: 'a',
        to: 'b',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      expect(event, isA<DomainEvent>());
    });
  });

  group('TicketAssigned',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Fix bug',
        ticketBody: 'Description here',
        ticketUrl: 'https://example.com/t/1',
        assignedAgentId: 'agent-1',
        assignedTeamId: null,
        workspaceId: 'ws-1',
        occurredAt: now,
      );

      expect(event.ticketId, 't-1');
      expect(event.ticketTitle, 'Fix bug');
      expect(event.ticketBody, 'Description here');
      expect(event.ticketUrl, 'https://example.com/t/1');
      expect(event.assignedAgentId, 'agent-1');
      expect(event.assignedTeamId, isNull);
      expect(event.workspaceId, 'ws-1');
      expect(event.occurredAt, now);
    });

    test('supports all nullable fields', timeout: const Timeout.factor(2), () {
      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Title',
        ticketBody: null,
        ticketUrl: null,
        assignedAgentId: null,
        assignedTeamId: null,
        workspaceId: null,
        occurredAt: now,
      );

      expect(event.ticketBody, isNull);
      expect(event.ticketUrl, isNull);
      expect(event.assignedAgentId, isNull);
      expect(event.assignedTeamId, isNull);
      expect(event.workspaceId, isNull);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'T',
        occurredAt: now,
      );
      expect(event, isA<DomainEvent>());
    });
  });

  group('TicketReassigned',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = TicketReassigned(
        ticketId: 't-1',
        fromAgentId: 'agent-1',
        toAgentId: 'agent-2',
        occurredAt: now,
      );

      expect(event.ticketId, 't-1');
      expect(event.fromAgentId, 'agent-1');
      expect(event.toAgentId, 'agent-2');
      expect(event.occurredAt, now);
    });

    test('supports nullable agent fields', timeout: const Timeout.factor(2), () {
      final event = TicketReassigned(
        ticketId: 't-1',
        fromAgentId: null,
        toAgentId: null,
        occurredAt: now,
      );

      expect(event.fromAgentId, isNull);
      expect(event.toAgentId, isNull);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = TicketReassigned(
        ticketId: 't-1',
        fromAgentId: null,
        toAgentId: null,
        occurredAt: now,
      );
      expect(event, isA<DomainEvent>());
    });
  });

  group('TicketCollaboratorAdded',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = TicketCollaboratorAdded(
        ticketId: 't-1',
        agentId: 'agent-1',
        role: 'reviewer',
        occurredAt: now,
      );

      expect(event.ticketId, 't-1');
      expect(event.agentId, 'agent-1');
      expect(event.role, 'reviewer');
      expect(event.occurredAt, now);
    });

    test('user as collaborator uses literal string', timeout: const Timeout.factor(2), () {
      final event = TicketCollaboratorAdded(
        ticketId: 't-1',
        agentId: 'user',
        role: 'owner',
        occurredAt: now,
      );

      expect(event.agentId, 'user');
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = TicketCollaboratorAdded(
        ticketId: 't-1',
        agentId: 'a',
        role: 'r',
        occurredAt: now,
      );
      expect(event, isA<DomainEvent>());
    });
  });

  group('TicketDetailsUpdated',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = TicketDetailsUpdated(ticketId: 't-1', occurredAt: now);

      expect(event.ticketId, 't-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = TicketDetailsUpdated(ticketId: 't-1', occurredAt: now);
      expect(event, isA<DomainEvent>());
    });
  });

  group('Ticketing events on bus',() {
    test('terminal events filter independently', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final completed = <TicketCompleted>[];
      final failed = <TicketFailed>[];
      final cancelled = <TicketCancelled>[];

      bus.on<TicketCompleted>().listen(completed.add);
      bus.on<TicketFailed>().listen(failed.add);
      bus.on<TicketCancelled>().listen(cancelled.add);

      bus.publish(TicketCompleted(ticketId: 't-1', occurredAt: now));
      bus.publish(
        TicketFailed(ticketId: 't-2', errorMessage: 'err', occurredAt: now),
      );
      bus.publish(TicketCancelled(ticketId: 't-3', occurredAt: now));

      await Future.delayed(const Duration(milliseconds: 10));
      expect(completed, hasLength(1));
      expect(failed, hasLength(1));
      expect(cancelled, hasLength(1));
    });

    test('TicketCreated does not appear on TicketCompleted stream', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final completed = <TicketCompleted>[];
      bus.on<TicketCompleted>().listen(completed.add);

      bus.publish(TicketCreated(ticketId: 't-1', occurredAt: now));

      await Future.delayed(const Duration(milliseconds: 10));
      expect(completed, isEmpty);
    });

    test('TicketAssigned carries all payload fields through bus', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final received = <TicketAssigned>[];
      bus.on<TicketAssigned>().listen(received.add);

      bus.publish(
        TicketAssigned(
          ticketId: 't-1',
          ticketTitle: 'Implement X',
          ticketBody: 'Full description',
          ticketUrl: 'https://linear.app/issue/1',
          assignedAgentId: 'agent-1',
          assignedTeamId: 'team-a',
          workspaceId: 'ws-1',
          occurredAt: now,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));
      expect(received.first.ticketTitle, 'Implement X');
      expect(received.first.assignedAgentId, 'agent-1');
      expect(received.first.workspaceId, 'ws-1');
    });

    test('TicketStatusChanged tracks before/after', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final received = <TicketStatusChanged>[];
      bus.on<TicketStatusChanged>().listen(received.add);

      bus.publish(
        TicketStatusChanged(
          ticketId: 't-1',
          from: 'in_progress',
          to: 'done',
          workspaceId: 'ws-1',
          occurredAt: now,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));
      expect(received.first.from, 'in_progress');
      expect(received.first.to, 'done');
    });
  });
}
