import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_mention_avatar_scope.dart';
import 'package:control_center/shared/widgets/github_mention_avatar_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveGitHubMentionAvatar', () {
    const avatars = {
      'eng': 'https://t/eng',
      'acme/eng': 'https://t/eng',
      'octocat': 'https://u/octo',
    };

    test('matches a user login', () {
      expect(
        resolveGitHubMentionAvatar(avatars, login: 'Octocat', isTeam: false),
        'https://u/octo',
      );
    });

    test('matches a team by org/slug or slug', () {
      expect(
        resolveGitHubMentionAvatar(avatars, login: 'acme/eng', isTeam: true),
        'https://t/eng',
      );
      expect(
        resolveGitHubMentionAvatar(avatars, login: 'other/eng', isTeam: true),
        'https://t/eng',
      );
    });

    test('returns empty when unknown', () {
      expect(
        resolveGitHubMentionAvatar(avatars, login: 'ghost', isTeam: false),
        '',
      );
    });
  });

  group('githubMentionAvatars', () {
    test('indexes team slug, name and owner/slug', () {
      final map = githubMentionAvatars(
        owner: 'acme',
        reviewers: const [
          PrTeamReviewer(
            name: 'Eng',
            slug: 'eng',
            avatarUrl: 'https://t/eng',
            isCodeOwner: false,
            state: PrReviewSubmissionState.pending,
          ),
          PrUserReviewer(
            user: PrUser(login: 'octocat', avatarUrl: 'https://u/octo'),
            isCodeOwner: false,
            state: PrReviewSubmissionState.pending,
          ),
        ],
      );
      expect(map['eng'], 'https://t/eng');
      expect(map['acme/eng'], 'https://t/eng');
      expect(map['octocat'], 'https://u/octo');
    });

    test('indexes requestable team candidates', () {
      final map = githubMentionAvatars(
        owner: 'acme',
        candidates: const [
          PrReviewerCandidate(
            kind: ReviewerKind.team,
            key: 'platform',
            label: 'Platform',
            avatarUrl: 'https://t/p',
          ),
        ],
      );
      expect(map['platform'], 'https://t/p');
      expect(map['acme/platform'], 'https://t/p');
    });
  });
}
