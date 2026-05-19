import 'package:cc_infra/src/network/models/github_pr_review_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubPrReviewState', () {
    test(
      'constructor holds all fields',
      timeout: const Timeout.factor(2),
      () {
        const state = GitHubPrReviewState(
          pendingUsers: [
            GitHubPendingUserRequest(
              login: 'alice',
              avatarUrl: 'https://a.com/alice.png',
              asCodeOwner: true,
            ),
          ],
          pendingTeams: [
            GitHubPendingTeamRequest(
              name: 'Frontend',
              slug: 'frontend',
              asCodeOwner: false,
            ),
          ],
          completedReviews: [
            GitHubCompletedReview(
              authorLogin: 'bob',
              authorAvatarUrl: 'https://a.com/bob.png',
              state: 'APPROVED',
              onBehalfOf: [
                GitHubReviewTeamRef(name: 'Backend', slug: 'backend'),
              ],
            ),
          ],
        );

        expect(state.pendingUsers.length, 1);
        expect(state.pendingUsers.first.login, 'alice');
        expect(state.pendingUsers.first.asCodeOwner, true);
        expect(state.pendingTeams.length, 1);
        expect(state.pendingTeams.first.slug, 'frontend');
        expect(state.completedReviews.length, 1);
        expect(state.completedReviews.first.state, 'APPROVED');
        expect(state.completedReviews.first.onBehalfOf.first.slug, 'backend');
      },
    );

    test(
      'defaults to empty lists',
      timeout: const Timeout.factor(2),
      () {
        const state = GitHubPrReviewState();
        expect(state.pendingUsers, isEmpty);
        expect(state.pendingTeams, isEmpty);
        expect(state.completedReviews, isEmpty);
      },
    );
  });

  group('GitHubPendingUserRequest', () {
    test(
      'holds all fields',
      timeout: const Timeout.factor(2),
      () {
        const req = GitHubPendingUserRequest(
          login: 'user1',
          avatarUrl: 'https://example.com/avatar.png',
          asCodeOwner: false,
        );
        expect(req.login, 'user1');
        expect(req.avatarUrl, 'https://example.com/avatar.png');
        expect(req.asCodeOwner, false);
      },
    );

    test(
      'asCodeOwner can be true',
      timeout: const Timeout.factor(2),
      () {
        const req = GitHubPendingUserRequest(
          login: 'user1',
          avatarUrl: 'https://example.com/avatar.png',
          asCodeOwner: true,
        );
        expect(req.asCodeOwner, true);
      },
    );
  });

  group('GitHubPendingTeamRequest', () {
    test(
      'holds all fields',
      timeout: const Timeout.factor(2),
      () {
        const req = GitHubPendingTeamRequest(
          name: 'Platform Team',
          slug: 'platform-team',
          asCodeOwner: true,
        );
        expect(req.name, 'Platform Team');
        expect(req.slug, 'platform-team');
        expect(req.asCodeOwner, true);
      },
    );

    test(
      'asCodeOwner defaults to false when not code owner',
      timeout: const Timeout.factor(2),
      () {
        const req = GitHubPendingTeamRequest(
          name: 'Ops',
          slug: 'ops',
          asCodeOwner: false,
        );
        expect(req.asCodeOwner, false);
      },
    );
  });

  group('GitHubCompletedReview', () {
    test(
      'holds all fields',
      timeout: const Timeout.factor(2),
      () {
        const review = GitHubCompletedReview(
          authorLogin: 'reviewer',
          authorAvatarUrl: 'https://example.com/r.png',
          state: 'CHANGES_REQUESTED',
          onBehalfOf: [
            GitHubReviewTeamRef(name: 'Core', slug: 'core'),
            GitHubReviewTeamRef(name: 'Infra', slug: 'infra'),
          ],
        );
        expect(review.authorLogin, 'reviewer');
        expect(review.authorAvatarUrl, 'https://example.com/r.png');
        expect(review.state, 'CHANGES_REQUESTED');
        expect(review.onBehalfOf.length, 2);
        expect(review.onBehalfOf[0].slug, 'core');
        expect(review.onBehalfOf[1].slug, 'infra');
      },
    );

    test(
      'onBehalfOf defaults to empty list',
      timeout: const Timeout.factor(2),
      () {
        const review = GitHubCompletedReview(
          authorLogin: 'reviewer',
          authorAvatarUrl: 'https://example.com/r.png',
          state: 'APPROVED',
        );
        expect(review.onBehalfOf, isEmpty);
      },
    );

    test(
      'state covers all possible GraphQL values',
      timeout: const Timeout.factor(2),
      () {
        const states = [
          'APPROVED',
          'CHANGES_REQUESTED',
          'COMMENTED',
          'DISMISSED',
          'PENDING',
        ];
        // Verify each state string can be assigned
        for (final s in states) {
          final review = GitHubCompletedReview(
            authorLogin: 'u',
            authorAvatarUrl: '',
            state: s,
          );
          expect(review.state, s);
        }
      },
    );
  });

  group('GitHubReviewTeamRef', () {
    test(
      'holds name and slug',
      timeout: const Timeout.factor(2),
      () {
        const ref = GitHubReviewTeamRef(name: 'Design', slug: 'design');
        expect(ref.name, 'Design');
        expect(ref.slug, 'design');
      },
    );

    test(
      'supports const construction',
      timeout: const Timeout.factor(2),
      () {
        const ref = GitHubReviewTeamRef(name: 'A', slug: 'a');
        expect(ref.name, 'A');
        expect(ref.slug, 'a');
      },
    );
  });
}
