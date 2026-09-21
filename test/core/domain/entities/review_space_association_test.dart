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

  group('ReviewSpaceAssociation', () {
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

      test('does not mutate original', () {
        final assoc = createAssoc();
        assoc.copyWith(status: ReviewSpaceStatus.completed);
        expect(assoc.status, ReviewSpaceStatus.requested);
      });
    });
  });
}
