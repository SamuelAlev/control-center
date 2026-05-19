
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
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

  group('WorkspaceCreated event', () {
    test('constructs with workspaceId and occurredAt', () {
      final now = DateTime(2026, 5, 18);
      final event = WorkspaceCreated(workspaceId: 'ws-123', occurredAt: now);

      expect(event.workspaceId, 'ws-123');
      expect(event.occurredAt, now);
    });
  });

  group('AgentRunCompleted event', () {
    test('constructs with required fields', () {
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

    test('supports nullable workspaceId and conversationId', () {
      final event = AgentRunCompleted(
        agentId: 'agent-1',
        workspaceId: null,
        conversationId: null,
        occurredAt: DateTime.now(),
      );

      expect(event.workspaceId, isNull);
      expect(event.conversationId, isNull);
    });
  });

  group('PullRequestPublished event', () {
    test('constructs with required fields', () {
      final now = DateTime(2026, 5, 18);
      final event = PullRequestPublished(
        prId: 'pr-1',
        workspaceId: 'ws-1',
        repoOwner: 'acme',
        repoName: 'project',
        occurredAt: now,
      );

      expect(event.prId, 'pr-1');
      expect(event.workspaceId, 'ws-1');
      expect(event.repoOwner, 'acme');
      expect(event.repoName, 'project');
      expect(event.occurredAt, now);
    });
  });

  group('DomainEvent interface', () {
    test('all event types implement DomainEvent', () {
      final workspaceEvent = WorkspaceCreated(
        workspaceId: 'ws-1',
        occurredAt: DateTime.now(),
      );
      final agentEvent = AgentRunCompleted(
        agentId: 'a1',
        workspaceId: 'ws-1',
        conversationId: 'c1',
        occurredAt: DateTime.now(),
      );
      final prEvent = PullRequestPublished(
        prId: 'pr-1',
        workspaceId: 'ws-1',
        repoOwner: 'acme',
        repoName: 'proj',
        occurredAt: DateTime.now(),
      );

      expect(workspaceEvent, isA<DomainEvent>());
      expect(agentEvent, isA<DomainEvent>());
      expect(prEvent, isA<DomainEvent>());
    });
  });

  group('PullRequestPublished equality', () {
    test('different prId means not equal', () {
      final now = DateTime(2026, 5, 18);
      final a = PullRequestPublished(
        prId: 'pr-1',
        workspaceId: 'ws-1',
        repoOwner: 'acme',
        repoName: 'proj',
        occurredAt: now,
      );
      final b = PullRequestPublished(
        prId: 'pr-2',
        workspaceId: 'ws-1',
        repoOwner: 'acme',
        repoName: 'proj',
        occurredAt: now,
      );
      expect(a.prId, isNot(equals(b.prId)));
      expect(a.workspaceId, equals(b.workspaceId));
    });

    test('prId and workspaceId are accessible', () {
      final event = PullRequestPublished(
        prId: 'pr-1',
        workspaceId: 'ws-1',
        repoOwner: 'acme',
        repoName: 'proj',
        occurredAt: DateTime(2026, 5, 18),
      );
      expect(event.prId, 'pr-1');
      expect(event.workspaceId, 'ws-1');
      expect(event.repoOwner, 'acme');
      expect(event.repoName, 'proj');
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
