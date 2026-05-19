import 'package:control_center/core/network/models/github_check_run.dart';
import 'package:control_center/core/network/models/github_commit.dart';
import 'package:control_center/core/network/models/github_issue_comment.dart';
import 'package:control_center/core/network/models/github_pull_request.dart';
import 'package:control_center/core/network/models/github_pull_request_file.dart';
import 'package:control_center/core/network/models/github_review.dart';
import 'package:control_center/core/network/models/github_review_comment.dart';
import 'package:control_center/core/network/models/github_user.dart';
import 'package:control_center/features/pr_review/data/mappers/pr_review_mapper.dart';
import 'package:control_center/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pullRequestFromGitHub', () {
    test('maps GitHub PR to domain PullRequest', () {
      final ghPr = GitHubPullRequest(
        number: 42,
        title: 'Add new feature',
        body: 'This PR adds a new feature',
        state: 'open',
        isDraft: false,
        userLogin: 'devuser',
        htmlUrl: 'https://github.com/acme/repo/pull/42',
        nodeId: 'node_123',
        headSha: 'abc123',
        baseRef: 'main',
        headRef: 'feature/new',
        author: const GitHubUser(
          login: 'devuser',
          avatarUrl: 'https://avatar.url/me.png',
        ),
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 15),
        mergedAt: null,
        requestedReviewers: [
          const GitHubUser(
            login: 'reviewer1',
            avatarUrl: 'https://avatar.url/r1.png',
          ),
        ],
        assignees: [
          const GitHubUser(
            login: 'devuser',
            avatarUrl: 'https://avatar.url/me.png',
          ),
        ],
      );

      final pr = pullRequestFromGitHub(ghPr, repoFullName: 'acme/repo');

      expect(pr.id, 42);
      expect(pr.number, 42);
      expect(pr.title, 'Add new feature');
      expect(pr.body, 'This PR adds a new feature');
      expect(pr.state, PrState.open);
      expect(pr.isDraft, isFalse);
      expect(pr.author?.login, 'devuser');
      expect(pr.createdAt, DateTime(2026, 5, 1));
      expect(pr.updatedAt, DateTime(2026, 5, 15));
      expect(pr.repoFullName, 'acme/repo');
      expect(pr.htmlUrl, 'https://github.com/acme/repo/pull/42');
      expect(pr.nodeId, 'node_123');
      expect(pr.headSha, 'abc123');
      expect(pr.baseRef, 'main');
      expect(pr.headRef, 'feature/new');
      expect(pr.mergedAt, isNull);
      expect(pr.isOpen, isTrue);
    });

    test('maps reviewers and assignees', () {
      const ghPr = GitHubPullRequest(
        number: 1,
        title: 'Test PR',
        body: '',
        state: 'open',
        isDraft: false,
        userLogin: 'author',
        htmlUrl: 'https://github.com/acme/repo/pull/1',
        nodeId: '',
        requestedReviewers: [
          GitHubUser(login: 'r1', avatarUrl: 'a1'),
          GitHubUser(login: 'r2', avatarUrl: 'a2'),
        ],
        assignees: [GitHubUser(login: 'a1', avatarUrl: 'a3')],
      );

      final pr = pullRequestFromGitHub(ghPr, repoFullName: 'acme/repo');

      expect(pr.requestedReviewers.length, 2);
      expect(pr.requestedReviewers[0].login, 'r1');
      expect(pr.requestedReviewers[1].login, 'r2');
      expect(pr.assignees.length, 1);
      expect(pr.assignees[0].login, 'a1');
      expect(pr.isPriority, isTrue);
    });

    test('maps closed PR state', () {
      const ghPr = GitHubPullRequest(
        number: 2,
        title: 'Closed PR',
        body: '',
        state: 'closed',
        isDraft: false,
        userLogin: 'user',
        htmlUrl: '',
        nodeId: '',
      );

      final pr = pullRequestFromGitHub(ghPr, repoFullName: 'acme/repo');

      expect(pr.state, PrState.closed);
      expect(pr.isClosed, isTrue);
      expect(pr.isOpen, isFalse);
      expect(pr.canMerge, isFalse);
    });

    test('maps merged PR state', () {
      const ghPr = GitHubPullRequest(
        number: 3,
        title: 'Merged PR',
        body: '',
        state: 'merged',
        isDraft: false,
        userLogin: 'user',
        htmlUrl: '',
        nodeId: '',
      );

      final pr = pullRequestFromGitHub(ghPr, repoFullName: 'acme/repo');

      expect(pr.state, PrState.merged);
      expect(pr.isMerged, isTrue);
    });

    test('maps draft PR', () {
      const ghPr = GitHubPullRequest(
        number: 4,
        title: 'Draft PR',
        body: '',
        state: 'open',
        isDraft: true,
        userLogin: 'user',
        htmlUrl: '',
        nodeId: '',
      );

      final pr = pullRequestFromGitHub(ghPr, repoFullName: 'acme/repo');

      expect(pr.isDraft, isTrue);
      expect(pr.canMerge, isFalse);
    });

    test('maps null author gracefully', () {
      const ghPr = GitHubPullRequest(
        number: 5,
        title: 'No Author',
        body: '',
        state: 'open',
        isDraft: false,
        userLogin: '',
        htmlUrl: '',
        nodeId: '',
        author: null,
      );

      final pr = pullRequestFromGitHub(ghPr, repoFullName: 'acme/repo');

      expect(pr.author, isNotNull);
      expect(pr.author!.login, '');
      expect(pr.author!.avatarUrl, '');
    });

    test('maps mergedAt timestamp', () {
      final mergedDate = DateTime(2026, 5, 10);
      final ghPr = GitHubPullRequest(
        number: 6,
        title: 'Merged',
        body: '',
        state: 'merged',
        isDraft: false,
        userLogin: 'user',
        htmlUrl: '',
        nodeId: '',
        mergedAt: mergedDate,
      );

      final pr = pullRequestFromGitHub(ghPr, repoFullName: 'acme/repo');

      expect(pr.mergedAt, mergedDate);
    });
  });

  group('prFileFromGitHub', () {
    test('maps basic file correctly', () {
      const ghFile = GitHubPullRequestFile(
        filename: 'lib/main.dart',
        status: 'modified',
        additions: 10,
        deletions: 3,
        changes: 13,
        patch: '@@ -1,3 +1,10 @@',
      );

      final file = prFileFromGitHub(ghFile);

      expect(file.filename, 'lib/main.dart');
      expect(file.status, PrFileStatus.modified);
      expect(file.additions, 10);
      expect(file.deletions, 3);
      expect(file.patch, '@@ -1,3 +1,10 @@');
      expect(file.previousFilename, isNull);
    });

    test('maps added file', () {
      const ghFile = GitHubPullRequestFile(
        filename: 'lib/new.dart',
        status: 'added',
        additions: 50,
        deletions: 0,
        changes: 50,
        patch: '@@ ...',
      );

      final file = prFileFromGitHub(ghFile);

      expect(file.status, PrFileStatus.added);
      expect(file.additions, 50);
      expect(file.deletions, 0);
    });

    test('maps removed file', () {
      const ghFile = GitHubPullRequestFile(
        filename: 'lib/old.dart',
        status: 'removed',
        additions: 0,
        deletions: 20,
        changes: 20,
        patch: '@@ ...',
      );

      final file = prFileFromGitHub(ghFile);

      expect(file.status, PrFileStatus.removed);
      expect(file.deletions, 20);
    });

    test('maps renamed file with previousFilename', () {
      const ghFile = GitHubPullRequestFile(
        filename: 'lib/renamed.dart',
        status: 'renamed',
        additions: 0,
        deletions: 0,
        changes: 0,
        patch: '',
        previousFilename: 'lib/original.dart',
      );

      final file = prFileFromGitHub(ghFile);

      expect(file.status, PrFileStatus.renamed);
      expect(file.previousFilename, 'lib/original.dart');
    });

    test('maps unchanged file', () {
      const ghFile = GitHubPullRequestFile(
        filename: 'lib/unchanged.dart',
        status: 'unchanged',
        additions: 0,
        deletions: 0,
        changes: 0,
        patch: '',
      );

      final file = prFileFromGitHub(ghFile);

      expect(file.status, PrFileStatus.unchanged);
    });
  });

  group('prCommitFromGitHub', () {
    test('maps commit correctly', () {
      final ghCommit = GitHubCommit(
        sha: 'abc123def456789',
        message: 'Fix: resolve login bug\n\nDetails about the fix.',
        authorName: 'Developer',
        authorEmail: 'dev@test.com',
        author: const GitHubUser(
          login: 'devuser',
          avatarUrl: 'https://avatar.url/dev.png',
        ),
        committedAt: DateTime(2026, 5, 15, 10, 30),
      );

      final commit = prCommitFromGitHub(ghCommit);

      expect(commit.sha, 'abc123def456789');
      expect(
        commit.message,
        'Fix: resolve login bug\n\nDetails about the fix.',
      );
      expect(commit.author?.login, 'devuser');
      expect(commit.author!.avatarUrl, 'https://avatar.url/dev.png');
      expect(commit.date, DateTime(2026, 5, 15, 10, 30));
      expect(commit.shortSha, 'abc123d');
      expect(commit.title, 'Fix: resolve login bug');
    });

    test('maps commit with null author', () {
      const ghCommit = GitHubCommit(
        sha: 'def456',
        message: 'Cleanup',
        authorName: 'Bot',
        authorEmail: 'bot@test.com',
        author: null,
        committedAt: null,
      );

      final commit = prCommitFromGitHub(ghCommit);

      expect(commit.author!.login, '');
      expect(commit.author!.avatarUrl, '');
      expect(commit.date, isNull);
    });
  });

  group('prCodeReviewCommentFromGitHub', () {
    test('maps review comment correctly', () {
      final ghComment = GitHubReviewComment(
        id: 101,
        body: 'Consider using a constant here.',
        path: 'lib/main.dart',
        diffHunk: '@@ -5,6 +5,8 @@',
        line: 10,
        originalLine: 9,
        startLine: 8,
        side: 'RIGHT',
        inReplyToId: 50,
        user: const GitHubUser(
          login: 'reviewer',
          avatarUrl: 'https://avatar.url/reviewer.png',
        ),
        createdAt: DateTime(2026, 5, 16),
      );

      final comment = prCodeReviewCommentFromGitHub(ghComment);

      expect(comment.id, 101);
      expect(comment.body, 'Consider using a constant here.');
      expect(comment.user?.login, 'reviewer');
      expect(comment.path, 'lib/main.dart');
      expect(comment.line, 10);
      expect(comment.originalLine, 9);
      expect(comment.startLine, 8);
      expect(comment.side, 'RIGHT');
      expect(comment.inReplyToId, 50);
      expect(comment.createdAt, DateTime(2026, 5, 16));
      expect(comment.diffHunk, '@@ -5,6 +5,8 @@');
    });

    test('falls back to originalLine when line is null', () {
      const ghComment = GitHubReviewComment(
        id: 102,
        body: 'Consider this change.',
        path: 'lib/foo.dart',
        diffHunk: '@@ ...',
        line: null,
        originalLine: 15,
        side: 'RIGHT',
      );

      final comment = prCodeReviewCommentFromGitHub(ghComment);

      expect(comment.position, 15);
      expect(comment.anchorLine, 15);
    });

    test('both line and originalLine can be null', () {
      const ghComment = GitHubReviewComment(
        id: 103,
        body: 'General comment.',
        path: 'lib/foo.dart',
        diffHunk: '',
        line: null,
        originalLine: null,
      );

      final comment = prCodeReviewCommentFromGitHub(ghComment);

      expect(comment.position, isNull);
      expect(comment.anchorLine, isNull);
    });
  });

  group('checkRunFromGitHub', () {
    test('maps completed successful check run', () {
      final ghCheckRun = GitHubCheckRun(
        id: 1,
        name: 'build-and-test',
        status: GitHubCheckStatus.completed,
        conclusion: GitHubCheckConclusion.success,
        appName: 'GitHub Actions',
        htmlUrl: 'https://github.com/owner/repo/runs/1',
        completedAt: DateTime(2026, 5, 16, 12, 0),
        output: 'All tests passed.',
      );

      final checkRun = checkRunFromGitHub(ghCheckRun);

      expect(checkRun.name, 'build-and-test');
      expect(checkRun.status, CheckRunStatus.completed);
      expect(checkRun.conclusion, CheckRunConclusion.success);
      expect(checkRun.htmlUrl, 'https://github.com/owner/repo/runs/1');
      expect(checkRun.isComplete, isTrue);
      expect(checkRun.isSuccess, isTrue);
      expect(checkRun.isFailing, isFalse);
    });

    test('maps queued check run', () {
      const ghCheckRun = GitHubCheckRun(
        id: 2,
        name: 'lint',
        status: GitHubCheckStatus.queued,
        conclusion: GitHubCheckConclusion.none,
        appName: 'GitHub Actions',
        htmlUrl: 'https://github.com/owner/repo/runs/2',
      );

      final checkRun = checkRunFromGitHub(ghCheckRun);

      expect(checkRun.status, CheckRunStatus.queued);
      expect(checkRun.conclusion, isNull);
    });

    test('maps in_progress check run', () {
      const ghCheckRun = GitHubCheckRun(
        id: 3,
        name: 'deploy',
        status: GitHubCheckStatus.inProgress,
        conclusion: GitHubCheckConclusion.none,
        appName: 'GitHub Actions',
        htmlUrl: 'https://github.com/owner/repo/runs/3',
      );

      final checkRun = checkRunFromGitHub(ghCheckRun);

      expect(checkRun.status, CheckRunStatus.inProgress);
    });

    test('maps failed check run', () {
      const ghCheckRun = GitHubCheckRun(
        id: 4,
        name: 'security-scan',
        status: GitHubCheckStatus.completed,
        conclusion: GitHubCheckConclusion.failure,
        appName: 'GitHub Actions',
        htmlUrl: 'https://github.com/owner/repo/runs/4',
      );

      final checkRun = checkRunFromGitHub(ghCheckRun);

      expect(checkRun.conclusion, CheckRunConclusion.failure);
      expect(checkRun.isFailing, isTrue);
      expect(checkRun.isSuccess, isFalse);
    });

    test('maps timed_out check run as failing', () {
      const ghCheckRun = GitHubCheckRun(
        id: 5,
        name: 'slow-test',
        status: GitHubCheckStatus.completed,
        conclusion: GitHubCheckConclusion.timedOut,
        appName: 'GitHub Actions',
        htmlUrl: 'https://github.com/owner/repo/runs/5',
      );

      final checkRun = checkRunFromGitHub(ghCheckRun);

      expect(checkRun.conclusion, CheckRunConclusion.timedOut);
      expect(checkRun.isFailing, isTrue);
    });

    test('maps action_required check run as failing', () {
      const ghCheckRun = GitHubCheckRun(
        id: 6,
        name: 'approval',
        status: GitHubCheckStatus.completed,
        conclusion: GitHubCheckConclusion.actionRequired,
        appName: 'GitHub Actions',
        htmlUrl: 'https://github.com/owner/repo/runs/6',
      );

      final checkRun = checkRunFromGitHub(ghCheckRun);

      expect(checkRun.conclusion, CheckRunConclusion.actionRequired);
      expect(checkRun.isFailing, isTrue);
    });
  });

  group('prReviewSubmissionFromGitHub', () {
    test('maps approved review', () {
      final ghReview = GitHubReview(
        id: 1,
        state: GitHubReviewState.approved,
        body: 'LGTM!',
        submittedAt: DateTime(2026, 5, 16),
        user: const GitHubUser(
          login: 'reviewer',
          avatarUrl: 'https://avatar.url/r.png',
        ),
      );

      final review = prReviewSubmissionFromGitHub(ghReview);

      expect(review.state, PrReviewSubmissionState.approved);
      expect(review.body, 'LGTM!');
      expect(review.author!.login, 'reviewer');
    });

    test('maps changes requested review', () {
      final ghReview = GitHubReview(
        id: 2,
        state: GitHubReviewState.changesRequested,
        body: 'Please fix the null safety issues.',
        submittedAt: DateTime(2026, 5, 16),
        user: const GitHubUser(login: 'r1', avatarUrl: ''),
      );

      final review = prReviewSubmissionFromGitHub(ghReview);

      expect(review.state, PrReviewSubmissionState.changesRequested);
      expect(review.body, 'Please fix the null safety issues.');
    });

    test('maps commented review', () {
      final ghReview = GitHubReview(
        id: 3,
        state: GitHubReviewState.commented,
        body: 'Left some comments.',
        submittedAt: DateTime(2026, 5, 16),
      );

      final review = prReviewSubmissionFromGitHub(ghReview);

      expect(review.state, PrReviewSubmissionState.commented);
    });

    test('maps dismissed review as commented', () {
      final ghReview = GitHubReview(
        id: 4,
        state: GitHubReviewState.dismissed,
        body: 'Old review.',
        submittedAt: DateTime(2026, 5, 16),
      );

      final review = prReviewSubmissionFromGitHub(ghReview);

      expect(review.state, PrReviewSubmissionState.commented);
    });

    test('maps pending review as commented', () {
      final ghReview = GitHubReview(
        id: 5,
        state: GitHubReviewState.pending,
        body: '',
        submittedAt: DateTime(2026, 5, 16),
      );

      final review = prReviewSubmissionFromGitHub(ghReview);

      expect(review.state, PrReviewSubmissionState.commented);
    });

    test('maps unknown review state as commented', () {
      final ghReview = GitHubReview(
        id: 6,
        state: GitHubReviewState.unknown,
        body: '',
        submittedAt: DateTime(2026, 5, 16),
      );

      final review = prReviewSubmissionFromGitHub(ghReview);

      expect(review.state, PrReviewSubmissionState.commented);
    });
  });

  group('issueCommentFromGitHub', () {
    test('maps issue comment correctly', () {
      final ghComment = GitHubIssueComment(
        id: 201,
        body: 'Looks good to me.',
        user: const GitHubUser(
          login: 'commenter',
          avatarUrl: 'https://avatar.url/c.png',
        ),
        createdAt: DateTime(2026, 5, 17, 9, 30),
      );

      final comment = issueCommentFromGitHub(ghComment);

      expect(comment.id, 201);
      expect(comment.body, 'Looks good to me.');
      expect(comment.user!.login, 'commenter');
      expect(comment.createdAt, DateTime(2026, 5, 17, 9, 30));
    });

    test('maps issue comment with null user', () {
      const ghComment = GitHubIssueComment(
        id: 202,
        body: 'Automated message',
        user: null,
        createdAt: null,
      );

      final comment = issueCommentFromGitHub(ghComment);

      expect(comment.user!.login, '');
      expect(comment.user!.avatarUrl, '');
      expect(comment.createdAt, isNull);
    });
  });

  group('prChecksStatusFromRollup', () {
    test('maps GraphQL StatusState to PrChecksStatus', () {
      expect(prChecksStatusFromRollup('SUCCESS'), PrChecksStatus.passing);
      expect(prChecksStatusFromRollup('FAILURE'), PrChecksStatus.failing);
      expect(prChecksStatusFromRollup('ERROR'), PrChecksStatus.failing);
      expect(prChecksStatusFromRollup('PENDING'), PrChecksStatus.pending);
      expect(prChecksStatusFromRollup('EXPECTED'), PrChecksStatus.pending);
      expect(prChecksStatusFromRollup(null), PrChecksStatus.none);
      expect(prChecksStatusFromRollup('WAT'), PrChecksStatus.none);
    });
  });

  group('priorityReviewFromSearchNode', () {
    Map<String, dynamic> node({String repo = 'octo/app'}) => {
      'number': 7,
      'title': 'Fix the thing',
      'isDraft': false,
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-02T00:00:00Z',
      'url': 'https://github.com/octo/app/pull/7',
      'headRefName': 'feat/thing',
      'additions': 120,
      'deletions': 4,
      'comments': {'totalCount': 5},
      'repository': {'nameWithOwner': repo},
    };

    test('maps a search PR node to a PullRequest plus its repo full name', () {
      final result = priorityReviewFromSearchNode(node());

      expect(result, isNotNull);
      expect(result!.repoFullName, 'octo/app');
      final pr = result.pr;
      expect(pr.number, 7);
      expect(pr.title, 'Fix the thing');
      expect(pr.headRef, 'feat/thing');
      expect(pr.htmlUrl, 'https://github.com/octo/app/pull/7');
      expect(pr.additions, 120);
      expect(pr.deletions, 4);
      expect(pr.commentsCount, 5);
      expect(pr.repoFullName, 'octo/app');
      expect(pr.updatedAt, DateTime.utc(2026, 1, 2));
    });

    test('leaves fields the lean query omits at their defaults', () {
      final pr = priorityReviewFromSearchNode(node())!.pr;

      // These are deliberately not requested by the search query — the mapper
      // must not fabricate them.
      expect(pr.author, isNull);
      expect(pr.nodeId, '');
      expect(pr.headSha, '');
      expect(pr.baseRef, '');
      expect(pr.requestedReviewers, isEmpty);
      expect(pr.checksStatus, PrChecksStatus.none);
    });

    test('returns null for an empty (non-PR) node', () {
      expect(priorityReviewFromSearchNode(const {}), isNull);
    });

    test('returns null when the repository is missing', () {
      final n = node()..remove('repository');
      expect(priorityReviewFromSearchNode(n), isNull);
    });
  });
}
