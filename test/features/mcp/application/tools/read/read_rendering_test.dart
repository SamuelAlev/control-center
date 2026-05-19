import 'package:cc_infra/src/network/models/github_check_run.dart';
import 'package:cc_infra/src/network/models/github_issue_comment.dart';
import 'package:cc_infra/src/network/models/github_pull_request.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:cc_infra/src/network/models/github_review_comment.dart';
import 'package:cc_infra/src/network/models/github_user.dart';
import 'package:cc_mcp/src/tools/read/rendering/diff_segmenter.dart';
import 'package:cc_mcp/src/tools/read/rendering/pr_markdown_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

GitHubPullRequest _makePr({
  int number = 42,
  String title = 'Test PR',
  String body = 'PR body',
  String state = 'open',
  String userLogin = 'testuser',
  String headSha = 'abc123',
  String baseRef = 'main',
  String headRef = 'feature/test',
}) =>
    GitHubPullRequest(
      number: number,
      title: title,
      body: body,
      state: state,
      isDraft: false,
      userLogin: userLogin,
      headSha: headSha,
      baseRef: baseRef,
      headRef: headRef,
      htmlUrl: 'https://github.com/owner/repo/pull/$number',
      nodeId: 'node_$number',
    );

GitHubCheckRun _makeCheckRun({
  int id = 1,
  String name = 'build',
  String appName = 'GitHub Actions',
  GitHubCheckStatus status = GitHubCheckStatus.completed,
  GitHubCheckConclusion conclusion = GitHubCheckConclusion.success,
}) =>
    GitHubCheckRun(
      id: id,
      name: name,
      status: status,
      conclusion: conclusion,
      appName: appName,
      htmlUrl: 'https://github.com/owner/repo/runs/$id',
    );

GitHubReview _makeReview({
  int id = 1,
  GitHubReviewState state = GitHubReviewState.approved,
  String body = 'LGTM',
  String login = 'reviewer1',
}) =>
    GitHubReview(
      id: id,
      state: state,
      body: body,
      submittedAt: DateTime(2025),
      user: GitHubUser(login: login, avatarUrl: ''),
    );

GitHubReviewComment _makeReviewComment({
  int id = 1,
  String body = 'inline note',
  String path = 'src/main.dart',
  int line = 42,
  String login = 'commenter',
}) =>
    GitHubReviewComment(
      id: id,
      body: body,
      path: path,
      diffHunk: '@@ -1 +1 @@',
      line: line,
      user: GitHubUser(login: login, avatarUrl: ''),
      createdAt: DateTime(2025),
    );

GitHubIssueComment _makeIssueComment({
  int id = 1,
  String body = 'Nice work',
  String login = 'commenter',
}) =>
    GitHubIssueComment(
      id: id,
      body: body,
      user: GitHubUser(login: login, avatarUrl: ''),
      createdAt: DateTime(2025),
    );

void main() {
  // ── DiffSegmenter ─────────────────────────────────────
  group('DiffSegmenter', () {
    const segmenter = DiffSegmenter();

    test('empty diff returns empty list', () {
      expect(segmenter.segments(''), isEmpty);
    });

    test('single file returns one segment', () {
      const diff = 'diff --git a/src/main.dart b/src/main.dart\n'
          '@@ -1,1 +1,1 @@\n'
          '-old\n'
          '+new\n';
      final segs = segmenter.segments(diff);
      expect(segs.length, 1);
      expect(segs[0].path, 'src/main.dart');
      expect(segs[0].text, contains('diff --git'));
      expect(segs[0].text, contains('-old'));
      expect(segs[0].text, contains('+new'));
    });

    test('multiple files returns correct count and paths', () {
      const diff = 'diff --git a/a.dart b/a.dart\n'
          '@@ -1 +1 @@\n'
          '-a\n'
          '+b\n'
          'diff --git a/b.dart b/b.dart\n'
          '@@ -1 +1 @@\n'
          '-c\n'
          '+d\n'
          'diff --git a/c.dart b/c.dart\n'
          '@@ -1 +1 @@\n'
          '-e\n'
          '+f\n';
      final segs = segmenter.segments(diff);
      expect(segs.length, 3);
      expect(segs[0].path, 'a.dart');
      expect(segs[1].path, 'b.dart');
      expect(segs[2].path, 'c.dart');
    });

    test('fileList returns paths only', () {
      const diff = 'diff --git a/src/main.dart b/src/main.dart\n@@ -1 +1 @@\n-x\n+y\n'
          'diff --git a/test/main_test.dart b/test/main_test.dart\n@@ -1 +1 @@\n-a\n+b\n';
      final files = segmenter.fileList(diff);
      expect(files, ['src/main.dart', 'test/main_test.dart']);
    });

    test('handles diff with no files gracefully', () {
      // Just header lines, no diff --git
      const diff = 'This is not a diff\n';
      // The segmenter splits on 'diff --git ' — since there's none, no segments
      final segs = segmenter.segments(diff);
      expect(segs, isEmpty);
    });
  });

  // ── PrMarkdownRenderer ────────────────────────────────
  group('PrMarkdownRenderer', () {
    const renderer = PrMarkdownRenderer();

    test('full render with all fields', () {
      final markdown = renderer.render(
        pr: _makePr(),
        checkRuns: [_makeCheckRun(name: 'build'), _makeCheckRun(name: 'lint')],
        reviews: [_makeReview()],
        reviewComments: [_makeReviewComment()],
        issueComments: [_makeIssueComment()],
      );

      expect(markdown, contains('# 42: Test PR'));
      expect(markdown, contains('State: open'));
      expect(markdown, contains('## Description'));
      expect(markdown, contains('PR body'));
      expect(markdown, contains('## Check runs (2)'));
      expect(markdown, contains('build'));
      expect(markdown, contains('lint'));
      expect(markdown, contains('## Reviews (1)'));
      expect(markdown, contains('reviewer1'));
      expect(markdown, contains('## Inline comments (1)'));
      expect(markdown, contains('src/main.dart'));
      expect(markdown, contains('## Comments (1)'));
      expect(markdown, contains('Nice work'));
    });

    test('render with empty reviews/comments/check runs excludes sections', () {
      final markdown = renderer.render(
        pr: _makePr(),
        checkRuns: const [],
        reviews: const [],
        reviewComments: const [],
        issueComments: const [],
      );

      expect(markdown, contains('# 42: Test PR'));
      expect(markdown, isNot(contains('## Check runs')));
      expect(markdown, isNot(contains('## Reviews')));
      expect(markdown, isNot(contains('## Inline comments')));
      expect(markdown, isNot(contains('## Comments')));
      // Description still present
      expect(markdown, contains('## Description'));
    });

    test('PR with empty body excludes description section', () {
      final markdown = renderer.render(
        pr: _makePr(body: ''),
        checkRuns: const [],
        reviews: const [],
        reviewComments: const [],
        issueComments: const [],
      );

      expect(markdown, contains('# 42: Test PR'));
      expect(markdown, isNot(contains('## Description')));
    });

    test('check run names and statuses are rendered', () {
      final markdown = renderer.render(
        pr: _makePr(),
        checkRuns: [
          _makeCheckRun(
            id: 1,
            name: 'build',
            status: GitHubCheckStatus.completed,
            conclusion: GitHubCheckConclusion.failure,
            appName: 'CircleCI',
          ),
        ],
        reviews: const [],
        reviewComments: const [],
        issueComments: const [],
      );

      expect(markdown, contains('## Check runs (1)'));
      expect(markdown, contains('build'));
      // Should mention status and conclusion
      expect(markdown, contains('completed'));
      expect(markdown, contains('failure'));
    });

    test('review state names are rendered', () {
      final markdown = renderer.render(
        pr: _makePr(),
        checkRuns: const [],
        reviews: [
          _makeReview(
            state: GitHubReviewState.changesRequested,
            body: 'Please fix X',
            login: 'strict-reviewer',
          ),
        ],
        reviewComments: const [],
        issueComments: const [],
      );

      expect(markdown, contains('## Reviews (1)'));
      expect(markdown, contains('strict-reviewer'));
      expect(markdown, contains('changesRequested'));
      expect(markdown, contains('Please fix X'));
    });
  });
}
