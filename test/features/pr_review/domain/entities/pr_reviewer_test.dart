import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = PrUser(login: 'Alice', avatarUrl: 'https://a.vatar');

  group('PrUserReviewer', () {
    test('creates with all fields', timeout: const Timeout.factor(2), () {
      const reviewer = PrUserReviewer(
        user: user,
        isCodeOwner: true,
        state: PrReviewSubmissionState.approved,
      );
      expect(reviewer.user, user);
      expect(reviewer.isCodeOwner, true);
      expect(reviewer.state, PrReviewSubmissionState.approved);
    });

    test('identity is lowercased user login', timeout: const Timeout.factor(2), () {
      const reviewer = PrUserReviewer(
        user: PrUser(login: 'Bob', avatarUrl: ''),
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
      );
      expect(reviewer.identity, 'user:bob');
    });

    test('equal when all fields match', timeout: const Timeout.factor(2), () {
      const a = PrUserReviewer(
        user: user,
        isCodeOwner: false,
        state: PrReviewSubmissionState.commented,
      );
      const b = PrUserReviewer(
        user: user,
        isCodeOwner: false,
        state: PrReviewSubmissionState.commented,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when user differs', timeout: const Timeout.factor(2), () {
      const a = PrUserReviewer(
        user: PrUser(login: 'a', avatarUrl: ''),
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
      );
      const b = PrUserReviewer(
        user: PrUser(login: 'b', avatarUrl: ''),
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when isCodeOwner differs', timeout: const Timeout.factor(2), () {
      const a = PrUserReviewer(
        user: user,
        isCodeOwner: true,
        state: PrReviewSubmissionState.pending,
      );
      const b = PrUserReviewer(
        user: user,
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when state differs', timeout: const Timeout.factor(2), () {
      const a = PrUserReviewer(
        user: user,
        isCodeOwner: false,
        state: PrReviewSubmissionState.approved,
      );
      const b = PrUserReviewer(
        user: user,
        isCodeOwner: false,
        state: PrReviewSubmissionState.changesRequested,
      );
      expect(a, isNot(equals(b)));
    });

    test('self equality', timeout: const Timeout.factor(2), () {
      const reviewer = PrUserReviewer(
        user: user,
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
      );
      expect(reviewer, equals(reviewer));
    });
  });

  group('PrTeamReviewer', () {
    test('creates with all fields', timeout: const Timeout.factor(2), () {
      const reviewer = PrTeamReviewer(
        name: 'Frontend',
        slug: 'frontend-team',
        isCodeOwner: true,
        state: PrReviewSubmissionState.approved,
        reviewedBy: user,
      );
      expect(reviewer.name, 'Frontend');
      expect(reviewer.slug, 'frontend-team');
      expect(reviewer.isCodeOwner, true);
      expect(reviewer.state, PrReviewSubmissionState.approved);
      expect(reviewer.reviewedBy, user);
    });

    test('identity is lowercased team slug', timeout: const Timeout.factor(2), () {
      const reviewer = PrTeamReviewer(
        name: 'Backend',
        slug: 'Backend-Core',
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
      );
      expect(reviewer.identity, 'team:backend-core');
    });

    test('reviewedBy defaults to null', timeout: const Timeout.factor(2), () {
      const reviewer = PrTeamReviewer(
        name: 'DevOps',
        slug: 'devops',
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
      );
      expect(reviewer.reviewedBy, isNull);
    });

    test('equal when all fields match', timeout: const Timeout.factor(2), () {
      const a = PrTeamReviewer(
        name: 'Team',
        slug: 'team',
        isCodeOwner: false,
        state: PrReviewSubmissionState.approved,
        reviewedBy: user,
      );
      const b = PrTeamReviewer(
        name: 'Team',
        slug: 'team',
        isCodeOwner: false,
        state: PrReviewSubmissionState.approved,
        reviewedBy: user,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when slug differs', timeout: const Timeout.factor(2), () {
      const a = PrTeamReviewer(
        name: 'Team',
        slug: 'a',
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
      );
      const b = PrTeamReviewer(
        name: 'Team',
        slug: 'b',
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when name differs', timeout: const Timeout.factor(2), () {
      const a = PrTeamReviewer(
        name: 'A',
        slug: 'team',
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
      );
      const b = PrTeamReviewer(
        name: 'B',
        slug: 'team',
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when reviewedBy differs', timeout: const Timeout.factor(2), () {
      const a = PrTeamReviewer(
        name: 'Team',
        slug: 'team',
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
        reviewedBy: PrUser(login: 'alice', avatarUrl: ''),
      );
      const b = PrTeamReviewer(
        name: 'Team',
        slug: 'team',
        isCodeOwner: false,
        state: PrReviewSubmissionState.pending,
        reviewedBy: PrUser(login: 'bob', avatarUrl: ''),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('ReviewerKind', () {
    test('has user and team values', timeout: const Timeout.factor(2), () {
      expect(ReviewerKind.values, containsAll([ReviewerKind.user, ReviewerKind.team]));
    });
  });

  group('PrReviewerCandidate', () {
    test('user factory creates user candidate', timeout: const Timeout.factor(2), () {
      final candidate = PrReviewerCandidate.user(user);
      expect(candidate.kind, ReviewerKind.user);
      expect(candidate.key, 'Alice');
      expect(candidate.label, 'Alice');
      expect(candidate.avatarUrl, 'https://a.vatar');
    });

    test('selectionKey for user', timeout: const Timeout.factor(2), () {
      const candidate = PrReviewerCandidate(
        kind: ReviewerKind.user,
        key: 'Alice',
        label: 'Alice',
      );
      expect(candidate.selectionKey, 'user:alice');
    });

    test('selectionKey for team', timeout: const Timeout.factor(2), () {
      const candidate = PrReviewerCandidate(
        kind: ReviewerKind.team,
        key: 'Frontend-Core',
        label: 'Frontend Core',
      );
      expect(candidate.selectionKey, 'team:frontend-core');
    });

    test('equal when kind and key match (case-insensitive)',
        timeout: const Timeout.factor(2), () {
      const a = PrReviewerCandidate(
        kind: ReviewerKind.user,
        key: 'Alice',
        label: 'Alice Smith',
      );
      const b = PrReviewerCandidate(
        kind: ReviewerKind.user,
        key: 'alice',
        label: 'Different label',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when kind differs', timeout: const Timeout.factor(2), () {
      const a = PrReviewerCandidate(
        kind: ReviewerKind.user,
        key: 'frontend',
        label: 'Frontend',
      );
      const b = PrReviewerCandidate(
        kind: ReviewerKind.team,
        key: 'frontend',
        label: 'Frontend',
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when key differs', timeout: const Timeout.factor(2), () {
      const a = PrReviewerCandidate(
        kind: ReviewerKind.user,
        key: 'alice',
        label: 'A',
      );
      const b = PrReviewerCandidate(
        kind: ReviewerKind.user,
        key: 'bob',
        label: 'B',
      );
      expect(a, isNot(equals(b)));
    });

    test('avatarUrl defaults to null for teams', timeout: const Timeout.factor(2), () {
      const candidate = PrReviewerCandidate(
        kind: ReviewerKind.team,
        key: 'team',
        label: 'Team',
      );
      expect(candidate.avatarUrl, isNull);
    });
  });
}
