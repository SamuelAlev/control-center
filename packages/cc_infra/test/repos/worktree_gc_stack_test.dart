import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/ports/pr_worktree_port.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_infra/src/repos/worktree_gc_listener.dart';
import 'package:test/test.dart';

void main() {
  test('merging a pull request does not release a topic space', () async {
    final bus = DomainEventBus();
    final provisioner = _Provisioner();
    final reviews = _Reviews([]);
    final listener = WorktreeGcListener(
      eventBus: bus,
      provisioner: provisioner,
      reviewSpaces: reviews,
      prWorktrees: _PrWorktrees(),
    );
    listener.start();

    bus.publish(
      PrMerged(
        prId: 'PR_layer',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        occurredAt: DateTime.utc(2026),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(provisioner.released, isEmpty);

    reviews.rows.add(
      ReviewSpaceAssociation(
        id: 'assoc-1',
        spaceId: 'review-room',
        workspaceId: 'ws-1',
        prExternalId: 'PR_layer',
        prNumber: 4,
        repoFullName: 'acme/app',
        status: ReviewSpaceStatus.completed,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    bus.publish(
      PrMerged(
        prId: 'PR_layer',
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        occurredAt: DateTime.utc(2026, 1, 2),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(provisioner.released, ['review-room']);
    listener.dispose();
  });
}

class _Provisioner implements RepoWorkspaceProvisionerPort {
  final List<String> released = [];

  @override
  Future<void> releaseSpace({
    required String workspaceId,
    required String spaceId,
  }) async {
    released.add(spaceId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reviews implements ReviewSpaceRepository {
  _Reviews(this.rows);

  final List<ReviewSpaceAssociation> rows;

  @override
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId) {
    return Stream.value([
      for (final row in rows)
        if (row.workspaceId == workspaceId) row,
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PrWorktrees implements PrWorktreePort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
