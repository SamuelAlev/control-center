import 'package:control_center/core/network/models/github_pr_review_state.dart';
import 'package:control_center/features/pr_review/data/mappers/pr_review_mapper.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prReviewersFromReviewState', () {
    test('maps a pending code-owner user request', () {
      final result = prReviewersFromReviewState(
        const GitHubPrReviewState(
          pendingUsers: [
            GitHubPendingUserRequest(
              login: 'octocat',
              avatarUrl: 'a',
              asCodeOwner: true,
            ),
          ],
        ),
      );
      expect(result, hasLength(1));
      final r = result.single as PrUserReviewer;
      expect(r.user.login, 'octocat');
      expect(r.isCodeOwner, isTrue);
      expect(r.state, PrReviewSubmissionState.pending);
    });

    test('maps a pending code-owner team request', () {
      final result = prReviewersFromReviewState(
        const GitHubPrReviewState(
          pendingTeams: [
            GitHubPendingTeamRequest(
              name: 'Frontend platform',
              slug: 'frontend-platform',
              asCodeOwner: true,
            ),
          ],
        ),
      );
      final r = result.single as PrTeamReviewer;
      expect(r.slug, 'frontend-platform');
      expect(r.name, 'Frontend platform');
      expect(r.isCodeOwner, isTrue);
      expect(r.reviewedBy, isNull);
      expect(r.state, PrReviewSubmissionState.pending);
    });

    test('merges an on-behalf review into the team row', () {
      final result = prReviewersFromReviewState(
        const GitHubPrReviewState(
          completedReviews: [
            GitHubCompletedReview(
              authorLogin: 'kim',
              authorAvatarUrl: 'k',
              state: 'APPROVED',
              onBehalfOf: [
                GitHubReviewTeamRef(name: 'Platform', slug: 'platform'),
              ],
            ),
          ],
        ),
      );
      final r = result.single as PrTeamReviewer;
      expect(r.slug, 'platform');
      expect(r.reviewedBy?.login, 'kim');
      expect(r.state, PrReviewSubmissionState.approved);
    });

    test('individual review overrides a pending request for the same user', () {
      final result = prReviewersFromReviewState(
        const GitHubPrReviewState(
          pendingUsers: [
            GitHubPendingUserRequest(
              login: 'octocat',
              avatarUrl: 'a',
              asCodeOwner: false,
            ),
          ],
          completedReviews: [
            GitHubCompletedReview(
              authorLogin: 'octocat',
              authorAvatarUrl: 'a',
              state: 'CHANGES_REQUESTED',
            ),
          ],
        ),
      );
      expect(result, hasLength(1));
      final r = result.single as PrUserReviewer;
      expect(r.state, PrReviewSubmissionState.changesRequested);
    });

    test('maps a dismissed review to pending', () {
      final result = prReviewersFromReviewState(
        const GitHubPrReviewState(
          completedReviews: [
            GitHubCompletedReview(
              authorLogin: 'octocat',
              authorAvatarUrl: 'a',
              state: 'DISMISSED',
            ),
          ],
        ),
      );
      expect(
        (result.single as PrUserReviewer).state,
        PrReviewSubmissionState.pending,
      );
    });

    test('knownCodeOwnerIds marks a reviewer as code owner', () {
      final result = prReviewersFromReviewState(
        const GitHubPrReviewState(
          completedReviews: [
            GitHubCompletedReview(
              authorLogin: 'octocat',
              authorAvatarUrl: 'a',
              state: 'APPROVED',
            ),
          ],
        ),
        knownCodeOwnerIds: {'user:octocat'},
      );
      expect((result.single as PrUserReviewer).isCodeOwner, isTrue);
    });

    test('renders users before teams', () {
      final result = prReviewersFromReviewState(
        const GitHubPrReviewState(
          pendingUsers: [
            GitHubPendingUserRequest(login: 'u', avatarUrl: '', asCodeOwner: false),
          ],
          pendingTeams: [
            GitHubPendingTeamRequest(name: 't', slug: 't', asCodeOwner: false),
          ],
        ),
      );
      expect(result.first, isA<PrUserReviewer>());
      expect(result.last, isA<PrTeamReviewer>());
    });
  });

  group('codeOwnerIdentitiesFromReviewState', () {
    test('collects only the pending asCodeOwner identities', () {
      final ids = codeOwnerIdentitiesFromReviewState(
        const GitHubPrReviewState(
          pendingUsers: [
            GitHubPendingUserRequest(login: 'A', avatarUrl: '', asCodeOwner: true),
            GitHubPendingUserRequest(login: 'B', avatarUrl: '', asCodeOwner: false),
          ],
          pendingTeams: [
            GitHubPendingTeamRequest(name: 'T', slug: 'Team', asCodeOwner: true),
          ],
        ),
      );
      expect(ids, {'user:a', 'team:team'});
    });
  });
}
