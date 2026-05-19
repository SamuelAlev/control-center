import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/task_lifecycle_events.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainEventBus', () {
    late DomainEventBus bus;

    setUp(() {
      bus = DomainEventBus();
    });

    tearDown(() {
      bus.dispose();
    });

    test(
      'publish dispatches to listeners',
      timeout: const Timeout.factor(2),
      () async {
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
      },
    );

    test(
      'subscribe returns subscription that can cancel',
      timeout: const Timeout.factor(2),
      () async {
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
      },
    );

    test(
      'multiple subscribers receive events',
      timeout: const Timeout.factor(2),
      () async {
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
      },
    );

    test(
      'cancelled subscription does not receive events',
      timeout: const Timeout.factor(2),
      () async {
        final received = <WorkspaceCreated>[];
        final subscription = bus.on<WorkspaceCreated>().listen(received.add);

        await subscription.cancel();

        bus.publish(
          WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
        );
        await Future.delayed(const Duration(milliseconds: 10));
        expect(received, isEmpty);
      },
    );

    test(
      'only matching types receive events',
      timeout: const Timeout.factor(2),
      () async {
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
      },
    );

    test(
      'on<DomainEvent> receives all event types',
      timeout: const Timeout.factor(2),
      () async {
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
      },
    );

    test(
      'one cancelled subscription does not affect others',
      timeout: const Timeout.factor(2),
      () async {
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
      },
    );

    test(
      'dispose closes the stream controller',
      timeout: const Timeout.factor(2),
      () {
        bus.dispose();
        expect(
          () => bus.publish(
            WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
          ),
          throwsA(anything),
        );
      },
    );

    test(
      'no events delivered when nothing is published',
      timeout: const Timeout.factor(2),
      () async {
        final received = <WorkspaceCreated>[];
        bus.on<WorkspaceCreated>().listen(received.add);

        await Future.delayed(const Duration(milliseconds: 10));
        expect(received, isEmpty);
      },
    );

    test(
      'multiple events delivered in order',
      timeout: const Timeout.factor(2),
      () async {
        final received = <String>[];
        bus.on<WorkspaceCreated>().listen((e) => received.add(e.workspaceId));

        for (var i = 0; i < 5; i++) {
          bus.publish(
            WorkspaceCreated(workspaceId: 'ws-$i', occurredAt: DateTime.now()),
          );
        }

        await Future.delayed(const Duration(milliseconds: 10));
        expect(received, ['ws-0', 'ws-1', 'ws-2', 'ws-3', 'ws-4']);
      },
    );

    // ── Type-keyed dispatch ──────────────────────────────────────────────
    //
    // Dispatch went from "one broadcast stream, filtered per subscriber" to
    // "one lane per subscribed type, with a cached route per concrete event
    // type". These pin the parts of the contract that rewrite could break —
    // subtype delivery, the route cache staying correct when a lane appears
    // after routing has already happened, and a shared lane not coupling its
    // listeners' lifetimes.

    test(
      'a supertype subscription receives every subtype',
      timeout: const Timeout.factor(2),
      () async {
        final received = <TaskLifecycleEvent>[];
        bus.on<TaskLifecycleEvent>().listen(received.add);

        bus.publish(
          TaskDispatched(
            taskId: 't1',
            seq: 1,
            workspaceId: 'ws-1',
            occurredAt: DateTime.now(),
          ),
        );
        bus.publish(
          TaskRunning(
            taskId: 't2',
            seq: 2,
            workspaceId: 'ws-1',
            occurredAt: DateTime.now(),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 10));
        expect(received, hasLength(2));
        expect(received[0], isA<TaskDispatched>());
        expect(received[1], isA<TaskRunning>());
      },
    );

    test(
      'one event reaches both its exact lane and its supertype lane',
      timeout: const Timeout.factor(2),
      () async {
        final exact = <TaskDispatched>[];
        final base = <TaskLifecycleEvent>[];
        final all = <DomainEvent>[];
        bus.on<TaskDispatched>().listen(exact.add);
        bus.on<TaskLifecycleEvent>().listen(base.add);
        bus.on<DomainEvent>().listen(all.add);

        bus.publish(
          TaskDispatched(
            taskId: 't1',
            seq: 1,
            workspaceId: 'ws-1',
            occurredAt: DateTime.now(),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 10));
        expect(exact, hasLength(1));
        expect(base, hasLength(1));
        expect(all, hasLength(1));
      },
    );

    test(
      'a lane added AFTER an event type was routed still receives it',
      timeout: const Timeout.factor(2),
      () async {
        // The route cache is keyed by concrete event type. Subscribing later
        // must invalidate it, or the new listener is silently dead — the one
        // way a cache like this goes wrong.
        final first = <WorkspaceCreated>[];
        bus.on<WorkspaceCreated>().listen(first.add);
        bus.publish(
          WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
        );
        await Future.delayed(const Duration(milliseconds: 10));

        final late = <DomainEvent>[];
        bus.on<DomainEvent>().listen(late.add);
        bus.publish(
          WorkspaceCreated(workspaceId: 'ws-2', occurredAt: DateTime.now()),
        );

        await Future.delayed(const Duration(milliseconds: 10));
        expect(first, hasLength(2));
        expect(late, hasLength(1));
        expect(late.first, isA<WorkspaceCreated>());
      },
    );

    test(
      'an event with no subscriber is dropped, and caches that answer',
      timeout: const Timeout.factor(2),
      () async {
        final received = <WorkspaceCreated>[];
        bus.on<WorkspaceCreated>().listen(received.add);

        // No lane wants this one. It must not throw and must not leak into
        // the WorkspaceCreated lane.
        for (var i = 0; i < 3; i++) {
          bus.publish(
            AgentRunCompleted(
              agentId: 'a1',
              workspaceId: null,
              conversationId: null,
              occurredAt: DateTime.now(),
            ),
          );
        }

        await Future.delayed(const Duration(milliseconds: 10));
        expect(received, isEmpty);
      },
    );

    test(
      'listeners on the shared lane are independent',
      timeout: const Timeout.factor(2),
      () async {
        // Same-type callers now share ONE controller. Cancelling one must not
        // close the lane for the others.
        final a = <WorkspaceCreated>[];
        final b = <WorkspaceCreated>[];
        final c = <WorkspaceCreated>[];
        final subA = bus.on<WorkspaceCreated>().listen(a.add);
        bus.on<WorkspaceCreated>().listen(b.add);
        final subC = bus.on<WorkspaceCreated>().listen(c.add);

        await subA.cancel();
        await subC.cancel();

        bus.publish(
          WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
        );
        await Future.delayed(const Duration(milliseconds: 10));

        expect(a, isEmpty);
        expect(c, isEmpty);
        expect(b, hasLength(1));
      },
    );

    test(
      'a listener attached after a same-type listener cancelled still works',
      timeout: const Timeout.factor(2),
      () async {
        // A broadcast controller with no listeners is NOT closed, so the lane
        // must survive going empty and be reusable.
        final first = <WorkspaceCreated>[];
        final sub = bus.on<WorkspaceCreated>().listen(first.add);
        await sub.cancel();

        final second = <WorkspaceCreated>[];
        bus.on<WorkspaceCreated>().listen(second.add);
        bus.publish(
          WorkspaceCreated(workspaceId: 'ws-1', occurredAt: DateTime.now()),
        );

        await Future.delayed(const Duration(milliseconds: 10));
        expect(first, isEmpty);
        expect(second, hasLength(1));
      },
    );
  });
}
