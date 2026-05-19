import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentRunCompleted',() {
    test('constructs with all required fields', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 5, 18);
      final event = AgentRunCompleted(
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        occurredAt: now,
      );

      expect(event.agentId, 'agent-1');
      expect(event.workspaceId, 'ws-1');
      expect(event.conversationId, 'conv-1');
      expect(event.occurredAt, now);
    });

    test('supports nullable workspaceId', timeout: const Timeout.factor(2), () {
      final event = AgentRunCompleted(
        agentId: 'agent-1',
        workspaceId: null,
        conversationId: 'conv-1',
        occurredAt: DateTime.now(),
      );

      expect(event.workspaceId, isNull);
    });

    test('supports nullable conversationId', timeout: const Timeout.factor(2), () {
      final event = AgentRunCompleted(
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: null,
        occurredAt: DateTime.now(),
      );

      expect(event.conversationId, isNull);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = AgentRunCompleted(
        agentId: 'a1',
        workspaceId: null,
        conversationId: null,
        occurredAt: DateTime.now(),
      );

      expect(event, isA<DomainEvent>());
    });

    test('different instances with same values are not identical', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 1, 1);
      final a = AgentRunCompleted(
        agentId: 'a1',
        workspaceId: 'ws-1',
        conversationId: 'c1',
        occurredAt: now,
      );
      final b = AgentRunCompleted(
        agentId: 'a1',
        workspaceId: 'ws-1',
        conversationId: 'c1',
        occurredAt: now,
      );

      // These are plain data classes without value equality.
      expect(identical(a, b), isFalse);
    });

    test('hashCode differs for different instances', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 1, 1);
      final a = AgentRunCompleted(
        agentId: 'a1',
        workspaceId: 'ws-1',
        conversationId: 'c1',
        occurredAt: now,
      );
      final b = AgentRunCompleted(
        agentId: 'a2',
        workspaceId: 'ws-1',
        conversationId: 'c1',
        occurredAt: now,
      );

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('type filtering on bus', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final received = <AgentRunCompleted>[];
      bus.on<AgentRunCompleted>().listen(received.add);

      bus.publish(
        AgentRunCompleted(
          agentId: 'a1',
          workspaceId: 'ws-1',
          conversationId: 'c1',
          occurredAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));
      expect(received.first.agentId, 'a1');
    });
  });
}
