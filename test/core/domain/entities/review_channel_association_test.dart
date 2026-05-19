import 'package:control_center/core/domain/entities/review_channel_association.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCreatedAt = DateTime(2024, 6, 1);
  final testUpdatedAt = DateTime(2024, 6, 2);

  ReviewChannelAssociation createAssoc({
    String id = 'rca-1',
    String channelId = 'ch-1',
    String workspaceId = 'ws-1',
    String prNodeId = 'PR_node1',
    int prNumber = 42,
    String repoFullName = 'acme/repo',
    ReviewChannelStatus status = ReviewChannelStatus.requested,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewChannelAssociation(
      id: id,
      channelId: channelId,
      workspaceId: workspaceId,
      prNodeId: prNodeId,
      prNumber: prNumber,
      repoFullName: repoFullName,
      status: status,
      createdAt: createdAt ?? testCreatedAt,
      updatedAt: updatedAt ?? testUpdatedAt,
    );
  }

  group('ReviewChannelStatus', () {
    test('has all expected values', () {
      expect(ReviewChannelStatus.values, containsAll([
        ReviewChannelStatus.requested,
        ReviewChannelStatus.inProgress,
        ReviewChannelStatus.awaitingApproval,
        ReviewChannelStatus.completed,
      ]));
    });
  });

  group('ReviewChannelAssociation', () {

    group('constructor', () {
      test('creates with all required fields', () {
        final assoc = createAssoc();
        expect(assoc.id, 'rca-1');
        expect(assoc.channelId, 'ch-1');
        expect(assoc.workspaceId, 'ws-1');
        expect(assoc.prNodeId, 'PR_node1');
        expect(assoc.prNumber, 42);
        expect(assoc.repoFullName, 'acme/repo');
        expect(assoc.status, ReviewChannelStatus.requested);
        expect(assoc.createdAt, testCreatedAt);
        expect(assoc.updatedAt, testUpdatedAt);
      });
    });

    group('convenience getters', () {
      test('isRequested returns true for requested status', () {
        final assoc = createAssoc(status: ReviewChannelStatus.requested);
        expect(assoc.isRequested, isTrue);
      });

      test('isRequested returns false for other status', () {
        final assoc = createAssoc(status: ReviewChannelStatus.inProgress);
        expect(assoc.isRequested, isFalse);
      });

      test('isInProgress returns true for inProgress status', () {
        final assoc = createAssoc(status: ReviewChannelStatus.inProgress);
        expect(assoc.isInProgress, isTrue);
      });

      test('isInProgress returns false for other status', () {
        final assoc = createAssoc(status: ReviewChannelStatus.requested);
        expect(assoc.isInProgress, isFalse);
      });

      test('isAwaitingApproval returns true for awaitingApproval status', () {
        final assoc = createAssoc(status: ReviewChannelStatus.awaitingApproval);
        expect(assoc.isAwaitingApproval, isTrue);
      });

      test('isAwaitingApproval returns false for other status', () {
        final assoc = createAssoc(status: ReviewChannelStatus.completed);
        expect(assoc.isAwaitingApproval, isFalse);
      });

      test('isCompleted returns true for completed status', () {
        final assoc = createAssoc(status: ReviewChannelStatus.completed);
        expect(assoc.isCompleted, isTrue);
      });

      test('isCompleted returns false for other status', () {
        final assoc = createAssoc(status: ReviewChannelStatus.requested);
        expect(assoc.isCompleted, isFalse);
      });
    });

    group('status transition methods', () {
      test('markInProgress returns copy with inProgress status', () {
        final assoc = createAssoc(status: ReviewChannelStatus.requested);
        final updated = assoc.markInProgress();
        expect(updated.status, ReviewChannelStatus.inProgress);
        expect(updated.id, assoc.id);
        expect(updated.channelId, assoc.channelId);
        expect(updated.workspaceId, assoc.workspaceId);
        expect(updated.prNodeId, assoc.prNodeId);
        expect(updated.prNumber, assoc.prNumber);
        expect(updated.repoFullName, assoc.repoFullName);
      });

      test('markAwaitingApproval returns copy with awaitingApproval status', () {
        final assoc = createAssoc(status: ReviewChannelStatus.inProgress);
        final updated = assoc.markAwaitingApproval();
        expect(updated.status, ReviewChannelStatus.awaitingApproval);
      });

      test('markCompleted returns copy with completed status', () {
        final assoc = createAssoc(status: ReviewChannelStatus.awaitingApproval);
        final updated = assoc.markCompleted();
        expect(updated.status, ReviewChannelStatus.completed);
      });

      test('transition methods do not mutate original', () {
        final assoc = createAssoc(status: ReviewChannelStatus.requested);
        assoc.markInProgress();
        expect(assoc.status, ReviewChannelStatus.requested);
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

      test('== returns false for different channelId', () {
        final a = createAssoc(channelId: 'ch-1');
        final b = createAssoc(channelId: 'ch-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different workspaceId', () {
        final a = createAssoc(workspaceId: 'ws-1');
        final b = createAssoc(workspaceId: 'ws-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different prNodeId', () {
        final a = createAssoc(prNodeId: 'PR_1');
        final b = createAssoc(prNodeId: 'PR_2');
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
        final a = createAssoc(status: ReviewChannelStatus.requested);
        final b = createAssoc(status: ReviewChannelStatus.inProgress);
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

      test('== returns false for non-ReviewChannelAssociation', () {
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
        expect(copy.channelId, assoc.channelId);
      });

      test('updates channelId', () {
        final assoc = createAssoc();
        final copy = assoc.copyWith(channelId: 'new-ch');
        expect(copy.channelId, 'new-ch');
      });

      test('updates workspaceId', () {
        final assoc = createAssoc();
        final copy = assoc.copyWith(workspaceId: 'new-ws');
        expect(copy.workspaceId, 'new-ws');
      });

      test('updates prNodeId', () {
        final assoc = createAssoc();
        final copy = assoc.copyWith(prNodeId: 'PR_new');
        expect(copy.prNodeId, 'PR_new');
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
        final copy = assoc.copyWith(status: ReviewChannelStatus.completed);
        expect(copy.status, ReviewChannelStatus.completed);
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
        assoc.copyWith(status: ReviewChannelStatus.completed);
        expect(assoc.status, ReviewChannelStatus.requested);
      });

      test('chaining copyWith calls', () {
        final assoc = createAssoc();
        final copy = assoc
            .copyWith(status: ReviewChannelStatus.inProgress)
            .copyWith(repoFullName: 'new/repo');
        expect(copy.status, ReviewChannelStatus.inProgress);
        expect(copy.repoFullName, 'new/repo');
      });
    });
  });
}
