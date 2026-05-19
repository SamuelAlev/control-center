import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/repo_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepoAdded',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 5, 18);
      final event = RepoAdded(
        repoId: 'repo-1',
        path: '/home/user/repos/project',
        workspaceId: 'ws-1',
        occurredAt: now,
      );

      expect(event.repoId, 'repo-1');
      expect(event.path, '/home/user/repos/project');
      expect(event.workspaceId, 'ws-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = RepoAdded(
        repoId: 'repo-1',
        path: '/tmp/repo',
        workspaceId: 'ws-1',
        occurredAt: DateTime.now(),
      );

      expect(event, isA<DomainEvent>());
    });

    test('different repos have different repoIds', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 1, 1);
      final a = RepoAdded(
        repoId: 'repo-1',
        path: '/a',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      final b = RepoAdded(
        repoId: 'repo-2',
        path: '/b',
        workspaceId: 'ws-1',
        occurredAt: now,
      );

      expect(a.repoId, isNot(equals(b.repoId)));
    });

    test('type filtering on bus', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final received = <RepoAdded>[];
      bus.on<RepoAdded>().listen(received.add);

      bus.publish(
        RepoAdded(
          repoId: 'repo-1',
          path: '/tmp/r',
          workspaceId: 'ws-1',
          occurredAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));
      expect(received.first.repoId, 'repo-1');
    });
  });
}
