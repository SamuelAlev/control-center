import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityLogged',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 5, 18);
      final event = ActivityLogged(
        id: 'log-1',
        actorType: 'agent',
        actorId: 'agent-1',
        action: 'created',
        entityType: 'workspace',
        entityId: 'ws-1',
        details: 'Created workspace',
        occurredAt: now,
      );

      expect(event.id, 'log-1');
      expect(event.actorType, 'agent');
      expect(event.actorId, 'agent-1');
      expect(event.action, 'created');
      expect(event.entityType, 'workspace');
      expect(event.entityId, 'ws-1');
      expect(event.details, 'Created workspace');
      expect(event.occurredAt, now);
    });

    test('supports nullable optional fields', timeout: const Timeout.factor(2), () {
      final event = ActivityLogged(
        id: 'log-2',
        actorType: 'system',
        actorId: null,
        action: 'deleted',
        entityType: 'repo',
        entityId: null,
        details: null,
        occurredAt: DateTime.now(),
      );

      expect(event.actorId, isNull);
      expect(event.entityId, isNull);
      expect(event.details, isNull);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = ActivityLogged(
        id: 'log-1',
        actorType: 'user',
        action: 'read',
        entityType: 'ticket',
        occurredAt: DateTime.now(),
      );

      expect(event, isA<DomainEvent>());
    });

    test('type filtering on bus', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final received = <ActivityLogged>[];
      bus.on<ActivityLogged>().listen(received.add);

      bus.publish(
        ActivityLogged(
          id: 'log-1',
          actorType: 'agent',
          action: 'deployed',
          entityType: 'pipeline',
          occurredAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));
      expect(received.first.action, 'deployed');
    });
  });

  group('WorktreeMerged',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 5, 18);
      final event = WorktreeMerged(
        workspaceId: 'ws-1',
        sourceBranch: 'feature/x',
        targetBranch: 'main',
        mergedBy: 'agent-1',
        occurredAt: now,
      );

      expect(event.workspaceId, 'ws-1');
      expect(event.sourceBranch, 'feature/x');
      expect(event.targetBranch, 'main');
      expect(event.mergedBy, 'agent-1');
      expect(event.occurredAt, now);
    });

    test('supports nullable mergedBy', timeout: const Timeout.factor(2), () {
      final event = WorktreeMerged(
        workspaceId: 'ws-1',
        sourceBranch: 'fix/y',
        targetBranch: 'main',
        mergedBy: null,
        occurredAt: DateTime.now(),
      );

      expect(event.mergedBy, isNull);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = WorktreeMerged(
        workspaceId: 'ws-1',
        sourceBranch: 'a',
        targetBranch: 'b',
        occurredAt: DateTime.now(),
      );

      expect(event, isA<DomainEvent>());
    });

    test('type filtering on bus', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final received = <WorktreeMerged>[];
      bus.on<WorktreeMerged>().listen(received.add);

      bus.publish(
        WorktreeMerged(
          workspaceId: 'ws-1',
          sourceBranch: 'feature/z',
          targetBranch: 'main',
          occurredAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));
      expect(received.first.sourceBranch, 'feature/z');
    });
  });

  group('BudgetThresholdCrossed',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 5, 18);
      final event = BudgetThresholdCrossed(
        scopeType: 'workspace',
        scopeId: 'ws-1',
        spentCents: 5000,
        budgetCents: 10000,
        isHardStop: false,
        occurredAt: now,
      );

      expect(event.scopeType, 'workspace');
      expect(event.scopeId, 'ws-1');
      expect(event.spentCents, 5000);
      expect(event.budgetCents, 10000);
      expect(event.isHardStop, isFalse);
      expect(event.occurredAt, now);
    });

    test('isHardStop true for hard stops', timeout: const Timeout.factor(2), () {
      final event = BudgetThresholdCrossed(
        scopeType: 'user',
        scopeId: 'u-1',
        spentCents: 15000,
        budgetCents: 10000,
        isHardStop: true,
        occurredAt: DateTime.now(),
      );

      expect(event.isHardStop, isTrue);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = BudgetThresholdCrossed(
        scopeType: 'workspace',
        scopeId: 'ws-1',
        spentCents: 0,
        budgetCents: 1000,
        isHardStop: false,
        occurredAt: DateTime.now(),
      );

      expect(event, isA<DomainEvent>());
    });

    test('type filtering on bus', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final received = <BudgetThresholdCrossed>[];
      bus.on<BudgetThresholdCrossed>().listen(received.add);

      bus.publish(
        BudgetThresholdCrossed(
          scopeType: 'workspace',
          scopeId: 'ws-1',
          spentCents: 9000,
          budgetCents: 10000,
          isHardStop: false,
          occurredAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));
      expect(received.first.scopeType, 'workspace');
    });
  });

  group('Observability events isolation',() {
    test('ActivityLogged does not appear on WorktreeMerged stream', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final received = <WorktreeMerged>[];
      bus.on<WorktreeMerged>().listen(received.add);

      bus.publish(
        ActivityLogged(
          id: 'log-1',
          actorType: 'agent',
          action: 'read',
          entityType: 'workspace',
          occurredAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, isEmpty);
    });
  });
}
