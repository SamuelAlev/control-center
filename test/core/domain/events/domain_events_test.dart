import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainEventBus', () {
    late DomainEventBus bus;

    setUp(() {
      bus = DomainEventBus();
    });

    test('publishes and receives events of correct type', () async {
      final future = bus.on<WorkspaceCreated>().first;
      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime(2026, 1, 1)),
      );

      final event = await future;
      expect(event.workspaceId, 'ws-1');
    });

    test('filters events by type', () async {
      final workspaceFuture = bus.on<WorkspaceCreated>().first;

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-2', occurredAt: DateTime(2026, 1, 2)),
      );

      final wsEvent = await workspaceFuture;

      expect(wsEvent.workspaceId, 'ws-2');
    });

    test('broadcast delivers events to multiple listeners', () async {
      final future1 = bus.on<WorkspaceCreated>().first;
      final future2 = bus.on<WorkspaceCreated>().first;

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
      );

      final event1 = await future1;
      final event2 = await future2;

      expect(event1.workspaceId, event2.workspaceId);
    });

    test('non-matching listeners do not receive events', () async {
      final received = <String>[];
      bus.on<WorkspaceCreated>().listen((e) => received.add('workspace'));
      bus.on<AgentRunCompleted>().listen((e) => received.add('agent'));

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, ['workspace']);
    });

    test('dispose stops future event delivery', () {
      bus.dispose();
      expect(
        () => bus.publish(
          WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
        ),
        throwsA(anything),
      );
    });
  });

  group('DomainEventBus — edge cases', () {
    test('on returns empty stream for no events published', () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final events = <WorkspaceCreated>[];
      bus.on<WorkspaceCreated>().listen(events.add);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(events, isEmpty);
    });

    test('publishes to all listeners of matching type', () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      var count = 0;
      bus.on<WorkspaceCreated>().listen((_) => count++);
      bus.on<WorkspaceCreated>().listen((_) => count++);
      bus.on<WorkspaceCreated>().listen((_) => count++);

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(count, 3);
    });
  });
}
