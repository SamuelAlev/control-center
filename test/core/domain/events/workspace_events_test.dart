import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceCreated',() {
    test('constructs with workspaceId and occurredAt', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 5, 18);
      final event = WorkspaceCreated(workspaceId: 'ws-123', occurredAt: now);

      expect(event.workspaceId, 'ws-123');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = WorkspaceCreated(
        workspaceId: 'ws-1',
        occurredAt: DateTime.now(),
      );

      expect(event, isA<DomainEvent>());
    });

    test('different workspaceIds produce different events', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 1, 1);
      final a = WorkspaceCreated(workspaceId: 'ws-1', occurredAt: now);
      final b = WorkspaceCreated(workspaceId: 'ws-2', occurredAt: now);

      expect(a.workspaceId, isNot(equals(b.workspaceId)));
    });

    test('type filtering on bus', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final received = <WorkspaceCreated>[];
      bus.on<WorkspaceCreated>().listen(received.add);

      bus.publish(
        WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));
      expect(received.first.workspaceId, 'ws-1');
    });
  });
}
