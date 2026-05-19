import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_channel_service.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Hand-rolled test doubles.
// ---------------------------------------------------------------------------

class _FakeTicketRepository implements TicketRepository {
  Ticket? ticketToReturn;

  @override
  Future<Ticket?> getById(String id) async => ticketToReturn;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMessagingPort implements MessagingPort {
  @override
  Future<void> retryAgentTurn({
    required String channelId,
    required String failedMessageId,
  }) async {}

  final List<_AddCall> addCalls = [];

  @override
  Future<void> addAgentToChannel(String channelId, String agentId) async {
    addCalls.add(_AddCall(channelId, agentId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AddCall {

  const _AddCall(this.channelId, this.agentId);
  final String channelId;
  final String agentId;

  @override
  String toString() => '_AddCall($channelId, $agentId)';
}

class _ThrowingMessagingPort implements MessagingPort {
  @override
  Future<void> addAgentToChannel(String channelId, String agentId) async {
    throw Exception('messaging port failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Helpers.
// ---------------------------------------------------------------------------

Ticket _ticket({String? channelId = 'chan-1'}) {
  return Ticket(
    id: 'ticket-1',
    workspaceId: 'ws-1',
    title: 'Test ticket',
    status: TicketStatus.open,
    channelId: channelId,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

TicketCollaboratorAdded _event({
  String ticketId = 'ticket-1',
  String agentId = 'agent-42',
  String role = 'collaborator',
  DateTime? occurredAt,
}) {
  return TicketCollaboratorAdded(
    ticketId: ticketId,
    agentId: agentId,
    role: role,
    occurredAt: occurredAt ?? DateTime(2025, 1, 1),
  );
}

/// Flush the event loop so async listeners have a chance to run.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

// ---------------------------------------------------------------------------
// Tests.
// ---------------------------------------------------------------------------

void main() {
  group('TicketChannelService', () {
    late DomainEventBus bus;
    late _FakeTicketRepository repo;
    late _FakeMessagingPort messaging;

    setUp(() {
      bus = DomainEventBus();
      repo = _FakeTicketRepository();
      messaging = _FakeMessagingPort();
    });

    test('adds agent to channel when all conditions are met', () async {
      repo.ticketToReturn = _ticket(channelId: 'chan-1');
      final svc = TicketChannelService(
        eventBus: bus,
        ticketRepository: repo,
        messagingPort: messaging,
      );
      svc.start();

      bus.publish(_event(agentId: 'agent-99'));
      await _settle();

      expect(messaging.addCalls, hasLength(1));
      expect(messaging.addCalls[0].channelId, 'chan-1');
      expect(messaging.addCalls[0].agentId, 'agent-99');
    }, timeout: const Timeout.factor(2));

    test('skips user sentinel (agentId == "user")', () async {
      repo.ticketToReturn = _ticket(channelId: 'chan-1');
      final svc = TicketChannelService(
        eventBus: bus,
        ticketRepository: repo,
        messagingPort: messaging,
      );
      svc.start();

      bus.publish(_event(agentId: TicketCollaborator.userSentinel));
      await _settle();

      expect(messaging.addCalls, isEmpty);
    }, timeout: const Timeout.factor(2));

    test('skips when ticket not found (getById returns null)', () async {
      repo.ticketToReturn = null;
      final svc = TicketChannelService(
        eventBus: bus,
        ticketRepository: repo,
        messagingPort: messaging,
      );
      svc.start();

      bus.publish(_event(ticketId: 'nonexistent'));
      await _settle();

      expect(messaging.addCalls, isEmpty);
    }, timeout: const Timeout.factor(2));

    test('skips when ticket has no channelId', () async {
      repo.ticketToReturn = _ticket(channelId: null);
      final svc = TicketChannelService(
        eventBus: bus,
        ticketRepository: repo,
        messagingPort: messaging,
      );
      svc.start();

      bus.publish(_event());
      await _settle();

      expect(messaging.addCalls, isEmpty);
    }, timeout: const Timeout.factor(2));

    test('multiple events work independently', () async {
      repo.ticketToReturn = _ticket(channelId: 'chan-1');
      final svc = TicketChannelService(
        eventBus: bus,
        ticketRepository: repo,
        messagingPort: messaging,
      );
      svc.start();

      bus.publish(_event(agentId: 'agent-1'));
      bus.publish(_event(agentId: 'agent-2'));
      bus.publish(_event(agentId: 'agent-3'));
      await _settle();

      expect(messaging.addCalls, hasLength(3));
      expect(
        messaging.addCalls.map((c) => c.agentId),
        ['agent-1', 'agent-2', 'agent-3'],
      );
    }, timeout: const Timeout.factor(2));

    test('error in handler does not crash — caught by try/catch', () async {
      final throwingPort = _ThrowingMessagingPort();
      repo.ticketToReturn = _ticket(channelId: 'chan-1');
      final svc = TicketChannelService(
        eventBus: bus,
        ticketRepository: repo,
        messagingPort: throwingPort,
      );
      svc.start();

      // Should not throw.
      bus.publish(_event(agentId: 'agent-99'));
      await _settle();

      // Service should still be alive; subsequent events dispatched to the
      // regular messaging port should process normally.
      final secondMessaging = _FakeMessagingPort();
      final svc2 = TicketChannelService(
        eventBus: bus,
        ticketRepository: repo,
        messagingPort: secondMessaging,
      );
      svc2.start();

      bus.publish(_event(agentId: 'agent-42'));
      await _settle();

      expect(secondMessaging.addCalls, hasLength(1));
      expect(secondMessaging.addCalls[0].agentId, 'agent-42');
    }, timeout: const Timeout.factor(2));
  });
}
