import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/pr_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 18);

  group('PullRequestPublished',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
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

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = PullRequestPublished(
        prId: 'pr-1',
        workspaceId: 'ws-1',
        repoOwner: 'acme',
        repoName: 'project',
        occurredAt: now,
      );

      expect(event, isA<DomainEvent>());
    });
  });

  group('PullRequestStatusChanged',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = PullRequestStatusChanged(
        status: 'merged',
        prId: 'pr-1',
        workspaceId: 'ws-1',
        repoFullName: 'acme/project',
        prNumber: 42,
        occurredAt: now,
      );

      expect(event.status, 'merged');
      expect(event.prId, 'pr-1');
      expect(event.workspaceId, 'ws-1');
      expect(event.repoFullName, 'acme/project');
      expect(event.prNumber, 42);
      expect(event.occurredAt, now);
    });

    test('supports nullable optional fields', timeout: const Timeout.factor(2), () {
      final event = PullRequestStatusChanged(
        status: 'closed',
        occurredAt: now,
      );

      expect(event.prId, isNull);
      expect(event.workspaceId, isNull);
      expect(event.repoFullName, isNull);
      expect(event.prNumber, isNull);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = PullRequestStatusChanged(
        status: 'opened',
        occurredAt: now,
      );

      expect(event, isA<DomainEvent>());
    });
  });

  group('PrMerged',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = PrMerged(
        prId: 'pr-1',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        occurredAt: now,
      );

      expect(event.prId, 'pr-1');
      expect(event.workspaceId, 'ws-1');
      expect(event.agentId, 'agent-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = PrMerged(
        prId: 'pr-1',
        workspaceId: 'ws-1',
        agentId: 'a1',
        occurredAt: now,
      );

      expect(event, isA<DomainEvent>());
    });
  });

  group('ExternalPrDetected',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = ExternalPrDetected(
        repoOwner: 'acme',
        repoName: 'project',
        prNumber: 99,
        prTitle: 'Fix bug',
        author: 'teammate',
        workspaceId: 'ws-1',
        occurredAt: now,
      );

      expect(event.repoOwner, 'acme');
      expect(event.repoName, 'project');
      expect(event.prNumber, 99);
      expect(event.prTitle, 'Fix bug');
      expect(event.author, 'teammate');
      expect(event.workspaceId, 'ws-1');
      expect(event.occurredAt, now);
    });

    test('supports nullable workspaceId', timeout: const Timeout.factor(2), () {
      final event = ExternalPrDetected(
        repoOwner: 'acme',
        repoName: 'project',
        prNumber: 1,
        prTitle: 'PR',
        author: 'user',
        workspaceId: null,
        occurredAt: now,
      );

      expect(event.workspaceId, isNull);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = ExternalPrDetected(
        repoOwner: 'a',
        repoName: 'b',
        prNumber: 1,
        prTitle: 't',
        author: 'u',
        workspaceId: null,
        occurredAt: now,
      );

      expect(event, isA<DomainEvent>());
    });
  });

  group('PR events on bus',() {
    test('each PR event type filters independently', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final published = <PullRequestPublished>[];
      final merged = <PrMerged>[];
      final external = <ExternalPrDetected>[];
      final statusChanged = <PullRequestStatusChanged>[];

      bus.on<PullRequestPublished>().listen(published.add);
      bus.on<PrMerged>().listen(merged.add);
      bus.on<ExternalPrDetected>().listen(external.add);
      bus.on<PullRequestStatusChanged>().listen(statusChanged.add);

      bus.publish(
        PullRequestPublished(
          prId: 'pr-1',
          workspaceId: 'ws-1',
          repoOwner: 'acme',
          repoName: 'proj',
          occurredAt: now,
        ),
      );
      bus.publish(
        PrMerged(
          prId: 'pr-1',
          workspaceId: 'ws-1',
          agentId: 'a1',
          occurredAt: now,
        ),
      );
      bus.publish(
        ExternalPrDetected(
          repoOwner: 'acme',
          repoName: 'proj',
          prNumber: 5,
          prTitle: 'Ext',
          author: 'bob',
          workspaceId: null,
          occurredAt: now,
        ),
      );
      bus.publish(
        PullRequestStatusChanged(status: 'opened', occurredAt: now),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(published, hasLength(1));
      expect(merged, hasLength(1));
      expect(external, hasLength(1));
      expect(statusChanged, hasLength(1));
    });

    test('PrMerged does not appear on PullRequestPublished stream', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final published = <PullRequestPublished>[];
      bus.on<PullRequestPublished>().listen(published.add);

      bus.publish(
        PrMerged(
          prId: 'pr-1',
          workspaceId: 'ws-1',
          agentId: 'a1',
          occurredAt: now,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(published, isEmpty);
    });
  });
}
