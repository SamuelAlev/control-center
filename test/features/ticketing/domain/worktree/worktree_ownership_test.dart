import 'package:cc_domain/features/ticketing/domain/worktree/worktree_ownership.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const classifier = WorktreeOwnershipClassifier();

  test('tracked worktree is cc-managed', () {
    final o = classifier.classify(
      const WorktreeOwnershipSignals(path: '/work/ws/a', trackedByCc: true),
    );
    expect(o, WorktreeOwnership.ccManaged);
  });

  test('CC creation metadata is decisive even when untracked', () {
    final o = classifier.classify(
      WorktreeOwnershipSignals(
        path: '/somewhere/else',
        ccCreatedAt: DateTime.utc(2026),
      ),
    );
    expect(o, WorktreeOwnership.ccManaged);
    final o2 = classifier.classify(
      const WorktreeOwnershipSignals(path: '/x', createdWithAgent: true),
    );
    expect(o2, WorktreeOwnership.ccManaged);
  });

  test('untracked worktree inside the CC layout is unknown-legacy', () {
    final o = classifier.classify(
      const WorktreeOwnershipSignals(
        path: '/work/ws/legacy-wt',
        ccWorktreeRoots: ['/work/ws'],
      ),
    );
    expect(o, WorktreeOwnership.unknownLegacy);
  });

  test('untracked worktree outside any known layout is external', () {
    final o = classifier.classify(
      const WorktreeOwnershipSignals(
        path: '/home/dev/other-tool/checkout',
        ccWorktreeRoots: ['/work/ws'],
        legacyWorktreeRoots: ['/old/cc'],
      ),
    );
    expect(o, WorktreeOwnership.external);
  });

  group('visibility policy', () {
    test('default hides external, shows cc-managed and legacy', () {
      const policy = WorktreeVisibilityPolicy();
      expect(policy.isVisible(WorktreeOwnership.ccManaged), isTrue);
      expect(policy.isVisible(WorktreeOwnership.external), isFalse);
      expect(policy.isVisible(WorktreeOwnership.unknownLegacy), isTrue);
    });

    test('can be configured to show external', () {
      const policy = WorktreeVisibilityPolicy(showExternal: true);
      expect(policy.isVisible(WorktreeOwnership.external), isTrue);
    });
  });
}
