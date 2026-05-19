import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCreatedAt = DateTime(2024, 6, 1);
  final testUpdatedAt = DateTime(2024, 6, 2);

  ReviewSpaceAssociation createAssoc({
    String id = 'rca-1',
    String spaceId = 'ch-1',
    String workspaceId = 'ws-1',
    String prExternalId = 'PR_node1',
    int prNumber = 42,
    String repoFullName = 'acme/repo',
    ReviewSpaceStatus status = ReviewSpaceStatus.requested,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewSpaceAssociation(
      id: id,
      spaceId: spaceId,
      workspaceId: workspaceId,
      prExternalId: prExternalId,
      prNumber: prNumber,
      repoFullName: repoFullName,
      status: status,
      createdAt: createdAt ?? testCreatedAt,
      updatedAt: updatedAt ?? testUpdatedAt,
    );
  }

  group('ReviewSpaceStatus', () {
    test('has all expected values', () {
      expect(
        ReviewSpaceStatus.values,
        containsAll([
          ReviewSpaceStatus.requested,
          ReviewSpaceStatus.inProgress,
          ReviewSpaceStatus.awaitingApproval,
          ReviewSpaceStatus.completed,
        ]),
      );
    });
  });

  group('ReviewSpaceAssociation', () {
    group('constructor', () {
      test('creates with all required fields', () {
        final assoc = createAssoc();
        expect(assoc.id, 'rca-1');
        expect(assoc.spaceId, 'ch-1');
        expect(assoc.workspaceId, 'ws-1');
        expect(assoc.prExternalId, 'PR_node1');
        expect(assoc.prNumber, 42);
        expect(assoc.repoFullName, 'acme/repo');
        expect(assoc.status, ReviewSpaceStatus.requested);
        expect(assoc.createdAt, testCreatedAt);
        expect(assoc.updatedAt, testUpdatedAt);
      });
    });

    group('convenience getters', () {
      test('isRequested returns true for requested status', () {
        final assoc = createAssoc(status: ReviewSpaceStatus.requested);
        expect(assoc.isRequested, isTrue);
      });

      test('isRequested returns false for other status', () {
        final assoc = createAssoc(status: ReviewSpaceStatus.inProgress);
        expect(assoc.isRequested, isFalse);
      });

      test('isInProgress returns true for inProgress status', () {
        final assoc = createAssoc(status: ReviewSpaceStatus.inProgress);
        expect(assoc.isInProgress, isTrue);
      });

      test('isInProgress returns false for other status', () {
        final assoc = createAssoc(status: ReviewSpaceStatus.requested);
        expect(assoc.isInProgress, isFalse);
      });

      test('isAwaitingApproval returns true for awaitingApproval status', () {
        final assoc = createAssoc(status: ReviewSpaceStatus.awaitingApproval);
        expect(assoc.isAwaitingApproval, isTrue);
      });

      test('isAwaitingApproval returns false for other status', () {
        final assoc = createAssoc(status: ReviewSpaceStatus.completed);
        expect(assoc.isAwaitingApproval, isFalse);
      });

      test('isCompleted returns true for completed status', () {
        final assoc = createAssoc(status: ReviewSpaceStatus.completed);
        expect(assoc.isCompleted, isTrue);
      });

      test('isCompleted returns false for other status', () {
        final assoc = createAssoc(status: ReviewSpaceStatus.requested);
        expect(assoc.isCompleted, isFalse);
      });
    });

    group('status transition methods', () {
      test('markInProgress returns copy with inProgress status', () {
        final assoc = createAssoc(status: ReviewSpaceStatus.requested);
        final updated = assoc.markInProgress();
        expect(updated.status, ReviewSpaceStatus.inProgress);
        expect(updated.id, assoc.id);
        expect(updated.spaceId, assoc.spaceId);
        expect(updated.workspaceId, assoc.workspaceId);
        expect(updated.prExternalId, assoc.prExternalId);
        expect(updated.prNumber, assoc.prNumber);
        expect(updated.repoFullName, assoc.repoFullName);
      });

      test(
        'markAwaitingApproval returns copy with awaitingApproval status',
        () {
          final assoc = createAssoc(status: ReviewSpaceStatus.inProgress);
          final updated = assoc.markAwaitingApproval();
          expect(updated.status, ReviewSpaceStatus.awaitingApproval);
        },
      );

      test('markCompleted returns copy with completed status', () {
        final assoc = createAssoc(status: ReviewSpaceStatus.awaitingApproval);
        final updated = assoc.markCompleted();
        expect(updated.status, ReviewSpaceStatus.completed);
      });

      test('transition methods do not mutate original', () {
        final assoc = createAssoc(status: ReviewSpaceStatus.requested);
        assoc.markInProgress();
        expect(assoc.status, ReviewSpaceStatus.requested);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', () {
        final a = createAssoc();
        final b = createAssoc();
        expect(a, equals(b));
      });

      test('== returns true for same instance', () {
        final assoc = createAssoc();
        expect(assoc, equals(assoc));
      });

      test('== returns false for different id', () {
        final a = createAssoc(id: 'rca-1');
        final b = createAssoc(id: 'rca-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different spaceId', () {
        final a = createAssoc(spaceId: 'ch-1');
        final b = createAssoc(spaceId: 'ch-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different workspaceId', () {
        final a = createAssoc(workspaceId: 'ws-1');
        final b = createAssoc(workspaceId: 'ws-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different prExternalId', () {
        final a = createAssoc(prExternalId: 'PR_1');
        final b = createAssoc(prExternalId: 'PR_2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different prNumber', () {
        final a = createAssoc(prNumber: 1);
        final b = createAssoc(prNumber: 2);
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different repoFullName', () {
        final a = createAssoc(repoFullName: 'a/repo');
        final b = createAssoc(repoFullName: 'b/repo');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different status', () {
        final a = createAssoc(status: ReviewSpaceStatus.requested);
        final b = createAssoc(status: ReviewSpaceStatus.inProgress);
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different createdAt', () {
        final a = createAssoc(createdAt: DateTime(2024, 1, 1));
        final b = createAssoc(createdAt: DateTime(2024, 2, 1));
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different updatedAt', () {
        final a = createAssoc(updatedAt: DateTime(2024, 1, 1));
        final b = createAssoc(updatedAt: DateTime(2024, 2, 1));
        expect(a, isNot(equals(b)));
      });

      test('== returns false for non-ReviewSpaceAssociation', () {
        final assoc = createAssoc();
        expect(assoc, isNot(equals('not an assoc')));
      });

      test('hashCode matches for equal instances', () {
        final a = createAssoc();
        final b = createAssoc();
        expect(a.hashCode, equals(b.hashCode));
      });

      test('hashCode differs for different instances', () {
        final a = createAssoc(id: 'rca-1');
        final b = createAssoc(id: 'rca-2');
        expect(a.hashCode, isNot(equals(b.hashCode)));
      });
    });

    group('copyWith', () {
      test('returns identical copy with no arguments', () {
        final assoc = createAssoc();
        final copy = assoc.copyWith();
        expect(copy, equals(assoc));
        expect(copy.hashCode, equals(assoc.hashCode));
      });

      test('updates id', () {
        final assoc = createAssoc();
        final copy = assoc.copyWith(id: 'new-id');
        expect(copy.id, 'new-id');
        expect(copy.spaceId, assoc.spaceId);
      });

      test('updates spaceId', () {
        final assoc = createAssoc();
        final copy = assoc.copyWith(spaceId: 'new-ch');
        expect(copy.spaceId, 'new-ch');
      });

      test('updates workspaceId', () {
        final assoc = createAssoc();
        final copy = assoc.copyWith(workspaceId: 'new-ws');
        expect(copy.workspaceId, 'new-ws');
      });

      test('updates prExternalId', () {
        final assoc = createAssoc();
        final copy = assoc.copyWith(prExternalId: 'PR_new');
        expect(copy.prExternalId, 'PR_new');
      });

      test('updates prNumber', () {
        final assoc = createAssoc();
        final copy = assoc.copyWith(prNumber: 99);
        expect(copy.prNumber, 99);
      });

      test('updates repoFullName', () {
        final assoc = createAssoc();
        final copy = assoc.copyWith(repoFullName: 'org/new-repo');
        expect(copy.repoFullName, 'org/new-repo');
      });

      test('updates status', () {
        final assoc = createAssoc();
        final copy = assoc.copyWith(status: ReviewSpaceStatus.completed);
        expect(copy.status, ReviewSpaceStatus.completed);
      });

      test('updates createdAt', () {
        final assoc = createAssoc();
        final newDate = DateTime(2025, 1, 1);
        final copy = assoc.copyWith(createdAt: newDate);
        expect(copy.createdAt, newDate);
      });

      test('updates updatedAt', () {
        final assoc = createAssoc();
        final newDate = DateTime(2025, 6, 1);
        final copy = assoc.copyWith(updatedAt: newDate);
        expect(copy.updatedAt, newDate);
      });

      test('does not mutate original', () {
        final assoc = createAssoc();
        assoc.copyWith(status: ReviewSpaceStatus.completed);
        expect(assoc.status, ReviewSpaceStatus.requested);
      });

      test('chaining copyWith calls', () {
        final assoc = createAssoc();
        final copy = assoc
            .copyWith(status: ReviewSpaceStatus.inProgress)
            .copyWith(repoFullName: 'new/repo');
        expect(copy.status, ReviewSpaceStatus.inProgress);
        expect(copy.repoFullName, 'new/repo');
      });
    });
  });
}
