import 'package:cc_infra/src/network/models/github_check_run.dart';
import 'package:cc_infra/src/network/models/github_commit.dart';
import 'package:cc_infra/src/network/models/github_pull_request.dart';
import 'package:cc_infra/src/network/models/github_pull_request_file.dart';
import 'package:cc_infra/src/network/models/github_reaction.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:cc_infra/src/network/models/github_review_comment.dart';
import 'package:test/test.dart';

/// Exercises the GitHub network model DTOs — each is a pure `fromJson` factory
/// that must tolerate missing/null fields and parse nested objects. These pin
/// the wire shape so a GitHub API change doesn't silently break parsing.
void main() {
  group('GitHubPullRequest.fromJson', () {
    test('parses a full PR payload', () {
      final pr = GitHubPullRequest.fromJson({
        'number': 42,
        'title': 'Fix bug',
        'body': 'the body',
        'state': 'open',
        'draft': false,
        'user': {
          'login': 'sam',
          'html_url': 'u',
          'avatar_url': 'a',
          'type': 'User',
        },
        'html_url': 'https://github.com/o/r/pull/42',
        'node_id': 'PR_node',
        'created_at': '2026-01-01T00:00:00Z',
        'head': {'sha': 'abc', 'ref': 'feature'},
        'base': {'sha': 'def', 'ref': 'main'},
        'merged_at': '2026-01-02T00:00:00Z',
        'changed_files': 3,
        'commits': 2,
        'mergeable_state': 'clean',
      });
      expect(pr.number, 42);
      expect(pr.title, 'Fix bug');
      expect(pr.userLogin, 'sam');
      expect(pr.headSha, 'abc');
      expect(pr.baseRef, 'main');
      expect(pr.mergedAt, isNotNull);
      expect(pr.changedFiles, 3);
      expect(pr.commitsCount, 2);
    });

    test(
      'falls back to nested pull_request.merged_at (search/issues shape)',
      () {
        final pr = GitHubPullRequest.fromJson({
          'number': 1,
          'title': 't',
          'body': 'b',
          'state': 'closed',
          'draft': false,
          'user': {'login': 'sam'},
          'html_url': 'u',
          'node_id': 'n',
          'pull_request': {'merged_at': '2026-01-03T00:00:00Z'},
        });
        expect(pr.mergedAt, isNotNull);
      },
    );

    test('tolerates null/missing fields', () {
      final pr = GitHubPullRequest.fromJson({
        'number': 1,
        'title': 't',
        'body': '',
        'state': 'open',
        'draft': false,
        'html_url': 'u',
        'node_id': 'n',
      });
      expect(pr.userLogin, '');
      expect(pr.headSha, '');
      expect(pr.requestedReviewers, isEmpty);
    });
  });

  group('GitHubCheckRun.fromJson', () {
    test('parses a completed successful check', () {
      final cr = GitHubCheckRun.fromJson({
        'name': 'CI',
        'status': 'completed',
        'conclusion': 'success',
        'html_url': 'u',
        'started_at': '2026-01-01T00:00:00Z',
        'completed_at': '2026-01-01T00:05:00Z',
      });
      expect(cr.name, 'CI');
      expect(cr.status, GitHubCheckStatus.completed);
      expect(cr.conclusion, GitHubCheckConclusion.success);
    });

    test('parses an in-progress check', () {
      final cr = GitHubCheckRun.fromJson({
        'name': 'build',
        'status': 'in_progress',
      });
      expect(cr.status, GitHubCheckStatus.inProgress);
      expect(cr.conclusion, GitHubCheckConclusion.none);
    });

    test('unknown status/conclusion map to unknown/none', () {
      final cr = GitHubCheckRun.fromJson({
        'name': 'x',
        'status': 'weird',
        'conclusion': 'bogus',
      });
      expect(cr.status, GitHubCheckStatus.unknown);
      expect(cr.conclusion, GitHubCheckConclusion.none);
    });
  });

  group('GitHubReviewComment.fromJson', () {
    test('parses a comment', () {
      final c = GitHubReviewComment.fromJson({
        'id': 1,
        'body': 'nit',
        'path': 'lib/x.dart',
        'line': 10,
        'user': {'login': 'reviewer'},
        'html_url': 'u',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(c.body, 'nit');
      expect(c.path, 'lib/x.dart');
      expect(c.user?.login, 'reviewer');
    });

    test('tolerates missing fields', () {
      final c = GitHubReviewComment.fromJson({});
      expect(c.body, '');
      expect(c.user, isNull);
    });

    test('parses line/original_line/start_line/side/in_reply_to_id', () {
      final c = GitHubReviewComment.fromJson({
        'id': 1,
        'line': 12,
        'original_line': 11,
        'start_line': 5,
        'side': 'LEFT',
        'in_reply_to_id': 9,
      });
      expect(c.line, 12);
      expect(c.originalLine, 11);
      expect(c.startLine, 5);
      expect(c.side, 'LEFT');
      expect(c.inReplyToId, 9);
    });

    test('parses reactions and body_html', () {
      final c = GitHubReviewComment.fromJson({
        'id': 1,
        'reactions': {'total_count': 2, '+1': 1},
        'body_html': '<p>hi</p>',
      });
      expect(c.reactions?.totalCount, 2);
      expect(c.bodyHtml, '<p>hi</p>');
    });

    test('anchorLine prefers line over original_line', () {
      final c = GitHubReviewComment.fromJson({'line': 20, 'original_line': 15});
      expect(c.anchorLine, 20);
    });

    test('anchorLine falls back to original_line when line missing', () {
      final c = GitHubReviewComment.fromJson({'original_line': 15});
      expect(c.anchorLine, 15);
    });

    test('anchorLine is null when both missing', () {
      final c = GitHubReviewComment.fromJson({});
      expect(c.anchorLine, isNull);
    });

    test('toJson round-trips the GitHub shape', () {
      final c = GitHubReviewComment.fromJson({
        'id': 1,
        'body': 'b',
        'path': 'p',
        'diff_hunk': '@@',
        'line': 5,
        'user': {'login': 'sam'},
        'created_at': '2026-01-01T00:00:00Z',
        'reactions': {'total_count': 1, '+1': 1},
        'body_html': '<p>x</p>',
      });
      final json = c.toJson();
      expect(json['id'], 1);
      expect(json['body'], 'b');
      expect(json['path'], 'p');
      expect(json['diff_hunk'], '@@');
      expect(json['line'], 5);
      expect((json['user'] as Map)['login'], 'sam');
      expect(json['reactions'], isA<Map>());
      expect(json['body_html'], '<p>x</p>');
    });

    test('toJson omits reactions/body_html when absent', () {
      final c = GitHubReviewComment.fromJson({'id': 1});
      final json = c.toJson();
      expect(json.containsKey('reactions'), isFalse);
      expect(json.containsKey('body_html'), isFalse);
    });
  });

  group('GitHubCommit.fromJson', () {
    test('parses a commit', () {
      final c = GitHubCommit.fromJson({
        'sha': 'abc123',
        'commit': {
          'message': 'fix',
          'author': {
            'name': 'Sam',
            'email': 's@x.com',
            'date': '2026-01-01T00:00:00Z',
          },
        },
        'html_url': 'u',
        'author': {'login': 'sam'},
      });
      expect(c.sha, 'abc123');
      expect(c.message, 'fix');
      expect(c.author?.login, 'sam');
    });

    test('tolerates missing commit object', () {
      final c = GitHubCommit.fromJson({'sha': 'x'});
      expect(c.sha, 'x');
      expect(c.message, '');
    });

    test('parses author name/email/date from commit.author', () {
      final c = GitHubCommit.fromJson({
        'sha': 's',
        'commit': {
          'message': 'm',
          'author': {
            'name': 'N',
            'email': 'e@x',
            'date': '2026-02-03T04:05:06Z',
          },
        },
      });
      expect(c.authorName, 'N');
      expect(c.authorEmail, 'e@x');
      expect(c.committedAt, DateTime.utc(2026, 2, 3, 4, 5, 6));
      expect(c.author, isNull);
    });

    test('shortSha returns first 7 characters', () {
      final c = GitHubCommit.fromJson({'sha': '0123456789abcdef'});
      expect(c.shortSha, '0123456');
    });

    test('shortSha returns whole sha when shorter than 7', () {
      final c = GitHubCommit.fromJson({'sha': 'abc'});
      expect(c.shortSha, 'abc');
    });

    test('title returns the first line of the message', () {
      final c = GitHubCommit.fromJson({
        'sha': 's',
        'commit': {'message': 'First line\nBody line'},
      });
      expect(c.title, 'First line');
    });

    test('title returns whole message when no newline', () {
      final c = GitHubCommit.fromJson({
        'sha': 's',
        'commit': {'message': 'only line'},
      });
      expect(c.title, 'only line');
    });

    test('bodyText returns the trimmed remainder', () {
      final c = GitHubCommit.fromJson({
        'sha': 's',
        'commit': {'message': 'First\n  indented body  \nmore'},
      });
      // .trim() strips leading/trailing whitespace of the whole body; internal
      // trailing spaces on the first line are preserved.
      expect(c.bodyText, 'indented body  \nmore');
    });

    test('bodyText is empty when no newline', () {
      final c = GitHubCommit.fromJson({
        'sha': 's',
        'commit': {'message': 'only'},
      });
      expect(c.bodyText, '');
    });

    test('toJson round-trips the GitHub shape', () {
      final original = GitHubCommit.fromJson({
        'sha': 's',
        'commit': {
          'message': 'm',
          'author': {
            'name': 'N',
            'email': 'e@x',
            'date': '2026-01-01T00:00:00.000Z',
          },
        },
        'author': {'login': 'sam'},
      });
      final json = original.toJson();
      expect(json['sha'], 's');
      final commit = json['commit'] as Map<String, dynamic>;
      expect(commit['message'], 'm');
      final author = commit['author'] as Map<String, dynamic>;
      expect(author['name'], 'N');
      expect(author['email'], 'e@x');
      expect(author['date'], contains('2026-01-01'));
      expect((json['author'] as Map)['login'], 'sam');
    });

    test('toJson emits null author when absent', () {
      final c = GitHubCommit.fromJson({'sha': 's'});
      expect(c.toJson()['author'], isNull);
    });
  });

  group('GitHubReview.fromJson', () {
    test('parses an approved review', () {
      final r = GitHubReview.fromJson({
        'id': 1,
        'state': 'APPROVED',
        'body': 'lgtm',
        'user': {'login': 'reviewer'},
        'html_url': 'u',
        'submitted_at': '2026-01-01T00:00:00Z',
      });
      expect(r.state, GitHubReviewState.approved);
      expect(r.body, 'lgtm');
      expect(r.user?.login, 'reviewer');
    });

    test('parses a changes_requested review', () {
      final r = GitHubReview.fromJson({'state': 'CHANGES_REQUESTED'});
      expect(r.state, GitHubReviewState.changesRequested);
    });

    test('unknown state maps to commented', () {
      final r = GitHubReview.fromJson({'state': 'bogus'});
      expect(r.state, GitHubReviewState.unknown);
    });

    test('parses a dismissed review with a dismissal note', () {
      final r = GitHubReview.fromJson({
        'state': 'DISMISSED',
        'dismissal': {'message': 'stale'},
      });
      expect(r.state, GitHubReviewState.dismissed);
    });

    test('parses a pending review', () {
      final r = GitHubReview.fromJson({'state': 'PENDING'});
      expect(r.state, GitHubReviewState.pending);
    });

    test('toJson round-trips the GitHub shape', () {
      final r = GitHubReview.fromJson({
        'id': 7,
        'state': 'APPROVED',
        'body': 'lgtm',
        'user': {'login': 'sam'},
        'html_url': 'u',
        'submitted_at': '2026-01-01T00:00:00Z',
      });
      final json = r.toJson();
      expect(json['id'], 7);
      expect(json['state'], 'APPROVED');
      expect(json['body'], 'lgtm');
      expect((json['user'] as Map)['login'], 'sam');
      expect(json['submitted_at'], isNotNull);
    });

    test('toJson emits null user when absent', () {
      final r = GitHubReview.fromJson({});
      expect(r.toJson()['user'], isNull);
    });
  });

  group('GitHubReactionSummary.fromJson', () {
    test('parses reaction counts', () {
      final r = GitHubReactionSummary.fromJson({
        'total_count': 5,
        '+1': 3,
        '-1': 1,
        'laugh': 1,
        'hooray': 0,
        'confused': 0,
        'heart': 0,
        'rocket': 0,
        'eyes': 0,
        'url': 'u',
      });
      expect(r.totalCount, 5);
      expect(r.plusOne, 3);
      expect(r.minusOne, 1);
      expect(r.laugh, 1);
    });

    test('defaults to zero when missing', () {
      final r = GitHubReactionSummary.fromJson({});
      expect(r.totalCount, 0);
      expect(r.plusOne, 0);
    });
  });

  group('GitHubPullRequestFile.fromJson', () {
    test('parses a file diff', () {
      final f = GitHubPullRequestFile.fromJson({
        'sha': 'abc',
        'filename': 'lib/x.dart',
        'status': 'modified',
        'additions': 10,
        'deletions': 2,
        'changes': 12,
        'patch': '@@ -1,1 +1,1 @@',
        'blob_url': 'u',
      });
      expect(f.filename, 'lib/x.dart');
      expect(f.status, 'modified');
      expect(f.additions, 10);
      expect(f.deletions, 2);
      expect(f.patch, '@@ -1,1 +1,1 @@');
    });

    test('tolerates missing fields', () {
      final f = GitHubPullRequestFile.fromJson({});
      expect(f.filename, '');
      expect(f.additions, 0);
    });

    test('extension returns the lowercase suffix', () {
      final f = GitHubPullRequestFile.fromJson({'filename': 'a/b.dart'});
      expect(f.extension, 'dart');
    });

    test('extension lowercases mixed-case suffixes', () {
      final f = GitHubPullRequestFile.fromJson({'filename': 'X.TS'});
      expect(f.extension, 'ts');
    });

    test('extension is empty when there is no dot', () {
      final f = GitHubPullRequestFile.fromJson({'filename': 'Makefile'});
      expect(f.extension, '');
    });

    test('extension is empty when filename ends with a dot', () {
      final f = GitHubPullRequestFile.fromJson({'filename': 'odd.'});
      expect(f.extension, '');
    });

    test('parses previous_filename', () {
      final f = GitHubPullRequestFile.fromJson({
        'filename': 'new.dart',
        'previous_filename': 'old.dart',
      });
      expect(f.previousFilename, 'old.dart');
    });

    test('toJson round-trips the GitHub shape', () {
      final f = GitHubPullRequestFile.fromJson({
        'sha': 'abc',
        'filename': 'lib/x.dart',
        'status': 'modified',
        'additions': 1,
        'deletions': 2,
        'changes': 3,
        'patch': '@@',
        'blob_url': 'u',
        'previous_filename': 'old.dart',
      });
      final json = f.toJson();
      expect(json['sha'], 'abc');
      expect(json['filename'], 'lib/x.dart');
      expect(json['status'], 'modified');
      expect(json['additions'], 1);
      expect(json['deletions'], 2);
      expect(json['changes'], 3);
      expect(json['patch'], '@@');
      expect(json['blob_url'], 'u');
      expect(json['previous_filename'], 'old.dart');
    });
  });
}
