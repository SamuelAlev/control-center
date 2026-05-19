
import 'package:control_center/core/domain/events/agent_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/workspace_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainEventBus',() {
    late DomainEventBus bus;

    setUp(() {
      bus = DomainEventBus();
    });

    tearDown(() {
      bus.dispose();
    });

    test('publish dispatches to listeners', timeout: const Timeout.factor(2), () async {
      final received = <WorkspaceCreated>[];
      bus.on<WorkspaceCreated>().listen(received.add);

      final event = WorkspaceCreated(
        workspaceId: 'ws-1',
        occurredAt: DateTime(2026, 1, 1),
      );
      bus.publish(event);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));
      expect(received.first.workspaceId, 'ws-1');
    });

    test('subscribe returns subscription that can cancel', timeout: const Timeout.factor(2), () async {
      final received = <WorkspaceCreated>[];
      final subscription = bus.on<WorkspaceCreated>().listen(received.add);

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));

      await subscription.cancel();

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-2', occurredAt: DateTime.now()),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      // Cancelled subscription should not receive new events.
      expect(received, hasLength(1));
      expect(received.first.workspaceId, 'ws-1');
    });

    test('multiple subscribers receive events', timeout: const Timeout.factor(2), () async {
      final received1 = <DomainEvent>[];
      final received2 = <DomainEvent>[];
      final received3 = <DomainEvent>[];

      bus.on<WorkspaceCreated>().listen(received1.add);
      bus.on<WorkspaceCreated>().listen(received2.add);
      bus.on<WorkspaceCreated>().listen(received3.add);

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received1, hasLength(1));
      expect(received2, hasLength(1));
      expect(received3, hasLength(1));
    });

    test('cancelled subscription does not receive events', timeout: const Timeout.factor(2), () async {
      final received = <WorkspaceCreated>[];
      final subscription = bus.on<WorkspaceCreated>().listen(received.add);

      await subscription.cancel();

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, isEmpty);
    });

    test('only matching types receive events', timeout: const Timeout.factor(2), () async {
      final workspaceReceived = <WorkspaceCreated>[];
      final agentReceived = <AgentRunCompleted>[];

      bus.on<WorkspaceCreated>().listen(workspaceReceived.add);
      bus.on<AgentRunCompleted>().listen(agentReceived.add);

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(workspaceReceived, hasLength(1));
      expect(agentReceived, isEmpty);
    });

    test('on<DomainEvent> receives all event types', timeout: const Timeout.factor(2), () async {
      final allReceived = <DomainEvent>[];
      bus.on<DomainEvent>().listen(allReceived.add);

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
      );
      bus.publish(
        AgentRunCompleted(
          agentId: 'a1',
          workspaceId: null,
          conversationId: null,
          occurredAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(allReceived, hasLength(2));
      expect(allReceived[0], isA<WorkspaceCreated>());
      expect(allReceived[1], isA<AgentRunCompleted>());
    });

    test('one cancelled subscription does not affect others', timeout: const Timeout.factor(2), () async {
      final received1 = <WorkspaceCreated>[];
      final received2 = <WorkspaceCreated>[];

      final sub1 = bus.on<WorkspaceCreated>().listen(received1.add);
      bus.on<WorkspaceCreated>().listen(received2.add);

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
      );
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received1, hasLength(1));
      expect(received2, hasLength(1));

      await sub1.cancel();

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-2', occurredAt: DateTime.now()),
      );
      await Future.delayed(const Duration(milliseconds: 10));

      expect(received1, hasLength(1)); // stopped after cancel
      expect(received2, hasLength(2)); // still active
    });

    test('dispose closes the stream controller', timeout: const Timeout.factor(2), () {
      bus.dispose();
      expect(
        () => bus.publish(
          WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
        ),
        throwsA(anything),
      );
    });

    test('no events delivered when nothing is published', timeout: const Timeout.factor(2), () async {
      final received = <WorkspaceCreated>[];
      bus.on<WorkspaceCreated>().listen(received.add);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, isEmpty);
    });

    test('multiple events delivered in order', timeout: const Timeout.factor(2), () async {
      final received = <String>[];
      bus.on<WorkspaceCreated>().listen((e) => received.add(e.workspaceId));

      for (var i = 0; i < 5; i++) {
        bus.publish(
          WorkspaceCreated(workspaceId: 'ws-$i', occurredAt: DateTime.now()),
        );
      }

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, ['ws-0', 'ws-1', 'ws-2', 'ws-3', 'ws-4']);
    });
  });
}
