import 'package:control_center/features/pr_review/domain/entities/review_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 1, 15, 10, 30);

  ReviewSession createSession({
    ReviewSessionStatus status = ReviewSessionStatus.inProgress,
  }) {
    return ReviewSession(
      id: 'session-1',
      prNumber: 42,
      workspaceId: 'ws-1',
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('ReviewSession constructor', () {
    test('creates with all fields', timeout: const Timeout.factor(2), () {
      final session = createSession();
      expect(session.id, 'session-1');
      expect(session.prNumber, 42);
      expect(session.workspaceId, 'ws-1');
      expect(session.status, ReviewSessionStatus.inProgress);
      expect(session.createdAt, now);
      expect(session.updatedAt, now);
    });
  });

  group('ReviewSession status getters', () {
    test('isInProgress is true when inProgress', timeout: const Timeout.factor(2), () {
      final session = createSession(status: ReviewSessionStatus.inProgress);
      expect(session.isInProgress, true);
      expect(session.isCompleted, false);
      expect(session.isAbandoned, false);
    });

    test('isCompleted is true when completed', timeout: const Timeout.factor(2), () {
      final session = createSession(status: ReviewSessionStatus.completed);
      expect(session.isInProgress, false);
      expect(session.isCompleted, true);
      expect(session.isAbandoned, false);
    });

    test('isAbandoned is true when abandoned', timeout: const Timeout.factor(2), () {
      final session = createSession(status: ReviewSessionStatus.abandoned);
      expect(session.isInProgress, false);
      expect(session.isCompleted, false);
      expect(session.isAbandoned, true);
    });
  });

  group('ReviewSession == and hashCode', () {
    test('equal when id matches', timeout: const Timeout.factor(2), () {
      final a = createSession();
      final b = ReviewSession(
        id: 'session-1',
        prNumber: 99,
        workspaceId: 'other',
        status: ReviewSessionStatus.completed,
        createdAt: DateTime(2020),
        updatedAt: DateTime(2020),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when id differs', timeout: const Timeout.factor(2), () {
      final a = createSession();
      final b = ReviewSession(
        id: 'session-2',
        prNumber: 42,
        workspaceId: 'ws-1',
        status: ReviewSessionStatus.inProgress,
        createdAt: now,
        updatedAt: now,
      );
      expect(a, isNot(equals(b)));
    });

    test('self equality', timeout: const Timeout.factor(2), () {
      final session = createSession();
      expect(session, equals(session));
    });
  });

  group('ReviewSessionStatus.tryParse', () {
    test('parses in_progress', timeout: const Timeout.factor(2), () {
      expect(ReviewSessionStatus.tryParse('in_progress'), ReviewSessionStatus.inProgress);
    });

    test('parses completed', timeout: const Timeout.factor(2), () {
      expect(ReviewSessionStatus.tryParse('completed'), ReviewSessionStatus.completed);
    });

    test('parses abandoned', timeout: const Timeout.factor(2), () {
      expect(ReviewSessionStatus.tryParse('abandoned'), ReviewSessionStatus.abandoned);
    });

    test('defaults to inProgress for unknown values', timeout: const Timeout.factor(2), () {
      expect(ReviewSessionStatus.tryParse('unknown'), ReviewSessionStatus.inProgress);
      expect(ReviewSessionStatus.tryParse(''), ReviewSessionStatus.inProgress);
    });
  });

  group('ReviewSessionStatus.serializedName', () {
    test('returns correct serialized names', timeout: const Timeout.factor(2), () {
      expect(ReviewSessionStatus.inProgress.serializedName, 'in_progress');
      expect(ReviewSessionStatus.completed.serializedName, 'completed');
      expect(ReviewSessionStatus.abandoned.serializedName, 'abandoned');
    });

    test('round-trips through serialization', timeout: const Timeout.factor(2), () {
      for (final status in ReviewSessionStatus.values) {
        expect(ReviewSessionStatus.tryParse(status.serializedName), status);
      }
    });
  });
}
