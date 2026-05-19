import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Exercises the GitHub REST PR client's request building (URLs, query params,
/// payloads, headers), pagination (Link-header probing), decode tolerance and
/// error mapping — using a stubbed [HttpClientAdapter] so no live network is
/// needed. Mirrors the pattern in `github_app_token_minter_test.dart`.

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(
  Object? body, {
  int status = 200,
  Map<String, List<String>> headers = const {},
}) {
  return ResponseBody.fromString(
    body == null ? '' : jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...headers,
    },
  );
}

ResponseBody _text(String body, {int status = 200}) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: ['text/plain'],
  },
);

typedef Handler = ResponseBody Function(RequestOptions o);

({GitHubPrClient client, _FakeAdapter fake}) build(Handler handler) {
  final fake = _FakeAdapter(handler);
  final dio = Dio()..httpClientAdapter = fake;
  return (client: GitHubPrClient(dio), fake: fake);
}

void main() {
  const owner = 'octo';
  const repo = 'cats';

  group('GitHubPrClient.listOpenPullRequestsPage', () {
    test(
      'GETs the pulls page and reports hasMore from the Link header',
      () async {
        final b = build(
          (o) => _json(
            [
              {'number': 1, 'title': 'A', 'state': 'open'},
              {'number': 2, 'title': 'B', 'state': 'open'},
            ],
            headers: {
              'link': [
                '<https://api.github.com/repos/o/c/pulls?page=2>; rel="next"',
              ],
            },
          ),
        );
        final page = await b.client.listOpenPullRequestsPage(owner, repo);
        expect(page.items.map((p) => p.number), [1, 2]);
        expect(page.hasMore, isTrue);
        final req = b.fake.requests.single;
        expect(req.method, 'GET');
        expect(req.path, '/repos/$owner/$repo/pulls');
        expect(req.queryParameters['state'], 'open');
        expect(req.queryParameters['per_page'], 100);
        expect(req.queryParameters['page'], 1);
      },
    );

    test('hasMore is false when no rel="next" link is present', () async {
      final b = build((_) => _json(<Object>[]));
      final page = await b.client.listOpenPullRequestsPage(owner, repo);
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('throws ArgumentError when owner or repo is empty', () {
      final b = build((_) => _json(<Object>[]));
      expect(
        () => b.client.listOpenPullRequestsPage('', repo),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => b.client.listOpenPullRequestsPage(owner, ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('maps a non-cancel DioException via mapDioException', () async {
      final b = build((_) => _json({'message': 'nope'}, status: 404));
      await expectLater(
        b.client.listOpenPullRequestsPage(owner, repo),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('GitHubPrClient.listRequestedReviews / listReviewedByMePrNumbers', () {
    test(
      'search/issues query for requested reviews decodes PR nodes',
      () async {
        final b = build(
          (o) => _json({
            'items': [
              {'number': 7, 'title': 'review me', 'state': 'open'},
              {'number': 8, 'title': 'and me', 'state': 'open'},
            ],
          }),
        );
        final prs = await b.client.listRequestedReviews(owner, repo);
        expect(prs.map((p) => p.number), [7, 8]);
        expect(
          b.fake.requests.single.queryParameters['q'],
          'type:pr state:open review-requested:@me repo:$owner/$repo',
        );
      },
    );

    test('reviewed-by-me returns the set of PR numbers > 0', () async {
      final b = build(
        (_) => _json({
          'items': [
            {'number': 11},
            {'number': 0}, // filtered out
            {'number': 13},
          ],
        }),
      );
      final nums = await b.client.listReviewedByMePrNumbers(owner, repo);
      expect(nums, {11, 13});
    });

    test('reviewed-by-me tolerates a missing items array', () async {
      final b = build((_) => _json({'items': null}));
      final nums = await b.client.listReviewedByMePrNumbers(owner, repo);
      expect(nums, isEmpty);
    });
  });

  group('GitHubPrClient.searchClosedPullRequestsByAuthor', () {
    test('encodes the author query and forwards hasMore', () async {
      final b = build(
        (o) => _json(
          {
            'items': [
              {'number': 5, 'title': 'old', 'state': 'closed'},
            ],
          },
          headers: {
            'link': ['<x>; rel="next"'],
          },
        ),
      );
      final page = await b.client.searchClosedPullRequestsByAuthor(
        owner,
        repo,
        'alice',
        page: 2,
      );
      expect(page.items.single.number, 5);
      expect(page.hasMore, isTrue);
      final qp = b.fake.requests.single.queryParameters;
      expect(qp['q'], 'type:pr state:closed author:alice repo:$owner/$repo');
      expect(qp['sort'], 'updated');
      expect(qp['order'], 'desc');
      expect(qp['page'], 2);
    });
  });

  group('GitHubPrClient.getPullRequest / getIssueReactionSummary', () {
    test('getPullRequest returns the mapped PR', () async {
      final b = build(
        (_) => _json({'number': 42, 'title': 'hi', 'state': 'open'}),
      );
      final pr = await b.client.getPullRequest(owner, repo, 42);
      expect(pr?.number, 42);
      expect(
        b.fake.requests.single.headers['Accept'],
        'application/vnd.github.full+json',
      );
    });

    test('getPullRequest returns null on non-map data', () async {
      final b = build((_) => _json(<Object>[1, 2, 3]));
      final pr = await b.client.getPullRequest(owner, repo, 1);
      expect(pr, isNull);
    });

    test('getIssueReactionSummary decodes the reactions sub-map', () async {
      final b = build(
        (_) => _json({
          'reactions': {'total_count': 4, '+1': 3, 'heart': 1},
        }),
      );
      final summary = await b.client.getIssueReactionSummary(owner, repo, 9);
      expect(summary?.totalCount, 4);
      expect(summary?.plusOne, 3);
      expect(
        b.fake.requests.single.headers['Accept'],
        'application/vnd.github.squirrel-girl-preview+json',
      );
    });

    test(
      'getIssueReactionSummary returns null when reactions missing',
      () async {
        final b = build((_) => _json({'number': 9}));
        final summary = await b.client.getIssueReactionSummary(owner, repo, 9);
        expect(summary, isNull);
      },
    );
  });

  group('GitHubPrClient.getPullRequestDiff', () {
    test('requests the diff media type and returns plain text', () async {
      final b = build((_) => _text('diff --git a/x b/x'));
      final diff = await b.client.getPullRequestDiff(owner, repo, 3);
      expect(diff, 'diff --git a/x b/x');
      final req = b.fake.requests.single;
      expect(req.headers['Accept'], 'application/vnd.github.diff');
      expect(req.responseType, ResponseType.plain);
    });

    test('returns empty string when response data is null', () async {
      final b = build((_) => ResponseBody.fromString('', 200));
      final diff = await b.client.getPullRequestDiff(owner, repo, 3);
      expect(diff, '');
    });
  });

  group('GitHubPrClient.streamPullRequestFiles / listPullRequestFiles', () {
    test('streams pages and stops early when a page is short', () async {
      // Page 1: full page (100). Page 2: 2 entries -> stop.
      var page = 0;
      final b = build((_) {
        page++;
        if (page == 1) {
          return _json([
            for (var i = 0; i < 100; i++)
              {
                'filename': 'f$i.dart',
                'patch': 'p',
                'additions': 1,
                'deletions': 0,
              },
          ]);
        }
        return _json([
          {
            'filename': 'last1.dart',
            'patch': 'p',
            'additions': 0,
            'deletions': 1,
          },
          {
            'filename': 'last2.dart',
            'patch': 'p',
            'additions': 0,
            'deletions': 1,
          },
        ]);
      });
      final all = await b.client.listPullRequestFiles(owner, repo, 1);
      expect(all.length, 102);
      expect(all.last.filename, 'last2.dart');
    });

    test('yields only non-empty pages', () async {
      final b = build((_) => _json(<Object>[]));
      final all = await b.client.listPullRequestFiles(owner, repo, 1);
      expect(all, isEmpty);
    });
  });

  group(
    'GitHubPrClient.listPullRequestCommits / listAllPullRequestCommits',
    () {
      test('single-page commits use per_page=100', () async {
        final b = build(
          (_) => _json([
            {
              'sha': 'abc',
              'commit': {
                'message': 'm',
                'author': {'name': 'n'},
              },
            },
          ]),
        );
        final commits = await b.client.listPullRequestCommits(owner, repo, 1);
        expect(commits.single.sha, 'abc');
        expect(b.fake.requests.single.queryParameters['per_page'], 100);
      });

      test(
        'listAllPullRequestCommits paginates while hasMore + full pages',
        () async {
          var page = 0;
          final b = build((_) {
            page++;
            final hasNext = page == 1;
            return _json(
              [
                for (var i = 0; i < 100; i++)
                  {
                    'sha': 's$page$i',
                    'commit': {
                      'message': 'm',
                      'author': {'name': 'n'},
                    },
                  },
              ],
              headers: {
                if (hasNext) 'link': ['<x>; rel="next"'],
              },
            );
          });
          final all = await b.client.listAllPullRequestCommits(owner, repo, 1);
          expect(all.length, 200); // stops after page 2 (short on Link)
        },
      );
    },
  );

  group('GitHubPrClient.getCommit / getCommitFiles', () {
    test('getCommit returns null for empty sha', () async {
      final b = build((_) => _json({}));
      expect(await b.client.getCommit(owner, repo, ''), isNull);
      expect(b.fake.requests, isEmpty);
    });

    test('getCommit maps the commit envelope', () async {
      final b = build(
        (_) => _json({
          'sha': 'deadbeef',
          'commit': {
            'message': 'hello',
            'author': {'name': 'Sam'},
          },
        }),
      );
      final c = await b.client.getCommit(owner, repo, 'deadbeef');
      expect(c?.sha, 'deadbeef');
      expect(c?.message, 'hello');
    });

    test('getCommitFiles returns empty for empty sha', () async {
      final b = build((_) => _json({}));
      expect(await b.client.getCommitFiles(owner, repo, ''), isEmpty);
    });

    test('getCommitFiles decodes the files array', () async {
      final b = build(
        (_) => _json({
          'files': [
            {'filename': 'a.dart', 'patch': 'p'},
          ],
        }),
      );
      final files = await b.client.getCommitFiles(owner, repo, 'sha');
      expect(files.single.filename, 'a.dart');
    });
  });

  group('GitHubPrClient review / comment listings', () {
    test('listPullRequestReviews decodes', () async {
      final b = build(
        (_) => _json([
          {
            'id': 1,
            'state': 'APPROVED',
            'user': {'login': 'x'},
          },
        ]),
      );
      final reviews = await b.client.listPullRequestReviews(owner, repo, 1);
      expect(reviews.single.state, GitHubReviewState.approved);
    });

    test('listPullRequestReviewComments sends full+json header', () async {
      final b = build(
        (_) => _json([
          {
            'id': 9,
            'body': 'nit',
            'user': {'login': 'y'},
          },
        ]),
      );
      await b.client.listPullRequestReviewComments(owner, repo, 1);
      expect(
        b.fake.requests.single.headers['Accept'],
        'application/vnd.github.full+json',
      );
    });

    test('listIssueComments decodes issue comments', () async {
      final b = build(
        (_) => _json([
          {
            'id': 1,
            'body': 'b',
            'user': {'login': 'y'},
          },
        ]),
      );
      final comments = await b.client.listIssueComments(owner, repo, 1);
      expect(comments.single.body, 'b');
    });
  });

  group('GitHubPrClient check runs / workflow runs', () {
    test('listCheckRuns returns empty for empty ref', () async {
      final b = build((_) => _json({}));
      expect(await b.client.listCheckRuns(owner, repo, ''), isEmpty);
      expect(b.fake.requests, isEmpty);
    });

    test('listCheckRuns decodes the check_runs envelope', () async {
      final b = build(
        (_) => _json({
          'check_runs': [
            {
              'id': 1,
              'name': 'ci',
              'status': 'completed',
              'conclusion': 'success',
            },
          ],
        }),
      );
      final runs = await b.client.listCheckRuns(owner, repo, 'sha');
      expect(runs.single.name, 'ci');
    });

    test('listWorkflowRuns returns empty for empty headSha', () async {
      final b = build((_) => _json({}));
      expect(await b.client.listWorkflowRuns(owner, repo, ''), isEmpty);
    });

    test('listWorkflowRuns decodes the workflow_runs envelope', () async {
      final b = build(
        (_) => _json({
          'workflow_runs': [
            {
              'id': 7,
              'name': 'build',
              'head_sha': 'abc',
              'status': 'completed',
            },
          ],
        }),
      );
      final runs = await b.client.listWorkflowRuns(owner, repo, 'abc');
      expect(runs.single.id, 7);
    });
  });

  group('GitHubPrClient write endpoints', () {
    test('postReviewComment builds the single-line payload', () async {
      final b = build(
        (_) => _json({
          'id': 1,
          'body': 'b',
          'user': {'login': 'me'},
        }),
      );
      await b.client.postReviewComment(
        owner,
        repo,
        prNumber: 5,
        commitSha: 'abc',
        path: 'a.dart',
        line: 9,
        side: 'RIGHT',
        body: 'nit',
      );
      final body = b.fake.requests.single.data as Map<String, dynamic>;
      expect(body['commit_id'], 'abc');
      expect(body['line'], 9);
      expect(body['side'], 'RIGHT');
      expect(body, isNot(contains('start_line')));
    });

    test(
      'postReviewComment includes start_line/side for multi-line anchors',
      () async {
        final b = build((_) => _json({'id': 1}));
        await b.client.postReviewComment(
          owner,
          repo,
          prNumber: 5,
          commitSha: 'abc',
          path: 'a.dart',
          line: 12,
          side: 'RIGHT',
          body: 'b',
          startLine: 9,
          startSide: 'RIGHT',
        );
        final body = b.fake.requests.single.data as Map<String, dynamic>;
        expect(body['start_line'], 9);
        expect(body['start_side'], 'RIGHT');
      },
    );

    test('postReviewComment throws when the POST returns a non-map', () async {
      final b = build((_) => _json(<Object>[1, 2]));
      await expectLater(
        b.client.postReviewComment(
          owner,
          repo,
          prNumber: 5,
          commitSha: 'abc',
          path: 'a.dart',
          line: 1,
          side: 'RIGHT',
          body: 'b',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('replyToReviewComment POSTs to the replies sub-path', () async {
      final b = build((_) => _json({'id': 1}));
      await b.client.replyToReviewComment(
        owner,
        repo,
        prNumber: 5,
        parentCommentId: 42,
        body: 'reply',
      );
      final req = b.fake.requests.single;
      expect(req.method, 'POST');
      expect(
        req.path,
        '/repos/$owner/$repo/pulls/5/comments/42/replies',
      );
      expect((req.data as Map)['body'], 'reply');
    });

    test('deleteReviewComment DELETEs the comment', () async {
      final b = build((_) => _json({}, status: 204));
      await b.client.deleteReviewComment(owner, repo, commentId: 88);
      final req = b.fake.requests.single;
      expect(req.method, 'DELETE');
      expect(req.path, contains('/comments/88'));
    });

    test('editReviewComment PATCHes the body', () async {
      final b = build((_) => _json({'id': 88}));
      final c = await b.client.editReviewComment(
        owner,
        repo,
        commentId: 88,
        body: 'edited',
      );
      final req = b.fake.requests.single;
      expect(req.method, 'PATCH');
      expect((req.data as Map)['body'], 'edited');
      expect(c.id, 88);
    });

    test(
      'submitReview includes body/commitId/comments only when provided',
      () async {
        final b = build((_) => _json({'id': 1, 'state': 'APPROVED'}));
        await b.client.submitReview(
          owner,
          repo,
          prNumber: 3,
          event: 'APPROVE',
          body: 'lgtm',
          commitId: 'sha1',
          comments: [
            {'path': 'a.dart', 'line': 1, 'side': 'RIGHT', 'body': 'x'},
          ],
        );
        final body = b.fake.requests.single.data as Map<String, dynamic>;
        expect(body['event'], 'APPROVE');
        expect(body['body'], 'lgtm');
        expect(body['commit_id'], 'sha1');
        expect(body['comments'], hasLength(1));
      },
    );

    test('submitReview omits empty optional fields', () async {
      final b = build((_) => _json({'id': 1}));
      await b.client.submitReview(owner, repo, prNumber: 3, event: 'COMMENT');
      final body = b.fake.requests.single.data as Map<String, dynamic>;
      expect(body, {'event': 'COMMENT'});
    });

    test('createPullRequest returns the raw map', () async {
      final b = build((_) => _json({'number': 99}));
      final pr = await b.client.createPullRequest(
        owner,
        repo,
        title: 't',
        body: 'b',
        head: 'feature',
        base: 'main',
        draft: true,
      );
      expect(pr['number'], 99);
      expect((b.fake.requests.single.data as Map)['draft'], true);
    });

    test(
      'mergePullRequest only includes non-empty commit title/message',
      () async {
        final b = build((_) => _json({'merged': true, 'sha': 'abc'}));
        final res = await b.client.mergePullRequest(
          owner,
          repo,
          prNumber: 1,
          mergeMethod: 'squash',
          commitTitle: 't',
        );
        expect(res['merged'], true);
        final body = b.fake.requests.single.data as Map<String, dynamic>;
        expect(body['merge_method'], 'squash');
        expect(body['commit_title'], 't');
        expect(body, isNot(contains('commit_message')));
      },
    );

    test('closePullRequest PATCHes state=closed', () async {
      final b = build((_) => _json({}, status: 200));
      await b.client.closePullRequest(owner, repo, prNumber: 4);
      final req = b.fake.requests.single;
      expect(req.method, 'PATCH');
      expect((req.data as Map)['state'], 'closed');
    });

    test('updatePullRequest only sends non-null fields', () async {
      final b = build(
        (_) => _json({'number': 4, 'title': 'x', 'state': 'open'}),
      );
      await b.client.updatePullRequest(
        owner,
        repo,
        prNumber: 4,
        title: 'new title',
      );
      final body = b.fake.requests.single.data as Map<String, dynamic>;
      expect(body['title'], 'new title');
      expect(body, isNot(contains('body')));
    });
  });

  group('GitHubPrClient assignees / reviewers', () {
    test('addAssignees is a no-op for an empty logins list', () async {
      final b = build((_) => _json({}));
      await b.client.addAssignees(owner, repo, prNumber: 1, logins: const []);
      expect(b.fake.requests, isEmpty);
    });

    test('addAssignees POSTs the logins', () async {
      final b = build((_) => _json({}, status: 201));
      await b.client.addAssignees(
        owner,
        repo,
        prNumber: 1,
        logins: const ['a', 'b'],
      );
      final req = b.fake.requests.single;
      expect(req.method, 'POST');
      expect((req.data as Map)['assignees'], ['a', 'b']);
    });

    test('removeAssignees DELETEs the logins', () async {
      final b = build((_) => _json({}, status: 200));
      await b.client.removeAssignees(
        owner,
        repo,
        prNumber: 1,
        logins: const ['a'],
      );
      final req = b.fake.requests.single;
      expect(req.method, 'DELETE');
      expect((req.data as Map)['assignees'], ['a']);
    });

    test('requestReviewers is a no-op when both lists are empty', () async {
      final b = build((_) => _json({}));
      await b.client.requestReviewers(owner, repo, prNumber: 1);
      expect(b.fake.requests, isEmpty);
    });

    test('requestReviewers POSTs reviewers + team_reviewers', () async {
      final b = build((_) => _json({}, status: 201));
      await b.client.requestReviewers(
        owner,
        repo,
        prNumber: 1,
        reviewers: const ['me'],
        teamReviewers: const ['eng'],
      );
      final body = b.fake.requests.single.data as Map<String, dynamic>;
      expect(body['reviewers'], ['me']);
      expect(body['team_reviewers'], ['eng']);
    });

    test('removeRequestedReviewers DELETEs reviewers', () async {
      final b = build((_) => _json({}, status: 200));
      await b.client.removeRequestedReviewers(
        owner,
        repo,
        prNumber: 1,
        reviewers: const ['me'],
      );
      final req = b.fake.requests.single;
      expect(req.method, 'DELETE');
      expect((req.data as Map)['team_reviewers'], isEmpty);
    });
  });

  group('GitHubPrClient reactions', () {
    test('createReviewCommentReaction maps the reaction', () async {
      final b = build(
        (_) => _json({
          'id': 1,
          'user': {'login': 'x'},
          'content': '+1',
        }),
      );
      final r = await b.client.createReviewCommentReaction(
        owner,
        repo,
        commentId: 5,
        content: '+1',
      );
      expect(r.content, '+1');
    });

    test('createReviewCommentReaction throws on non-map', () async {
      final b = build((_) => _json(<Object>[]));
      await expectLater(
        b.client.createReviewCommentReaction(
          owner,
          repo,
          commentId: 5,
          content: '+1',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('deleteReviewCommentReaction DELETEs', () async {
      final b = build((_) => _json({}, status: 204));
      await b.client.deleteReviewCommentReaction(
        owner,
        repo,
        commentId: 5,
        reactionId: 9,
      );
      expect(b.fake.requests.single.method, 'DELETE');
    });

    test('listReviewCommentReactions decodes', () async {
      final b = build(
        (_) => _json([
          {
            'id': 1,
            'user': {'login': 'x'},
            'content': 'heart',
          },
        ]),
      );
      final rs = await b.client.listReviewCommentReactions(
        owner,
        repo,
        commentId: 5,
      );
      expect(rs.single.content, 'heart');
    });

    test('createIssueCommentReaction / listIssueCommentReactions', () async {
      final b = build(
        (_) => _json([
          {
            'id': 1,
            'user': {'login': 'x'},
            'content': 'rocket',
          },
        ]),
      );
      expect(
        (await b.client.listIssueCommentReactions(
          owner,
          repo,
          commentId: 1,
        )).single.content,
        'rocket',
      );
    });

    test('deleteIssueCommentReaction DELETEs', () async {
      final b = build((_) => _json({}, status: 204));
      await b.client.deleteIssueCommentReaction(
        owner,
        repo,
        commentId: 5,
        reactionId: 9,
      );
      expect(
        b.fake.requests.single.path,
        contains('/issues/comments/5/reactions/9'),
      );
    });

    test(
      'createIssueReaction / listIssueReactions / deleteIssueReaction',
      () async {
        var n = 0;
        final b = build((o) {
          n++;
          switch (n) {
            case 1:
              return _json({
                'id': 1,
                'user': {'login': 'x'},
                'content': '+1',
              });
            case 2:
              return _json([
                {
                  'id': 1,
                  'user': {'login': 'x'},
                  'content': '+1',
                },
              ]);
            default:
              return _json({}, status: 204);
          }
        });
        final created = await b.client.createIssueReaction(
          owner,
          repo,
          issueNumber: 7,
          content: '+1',
        );
        expect(created.content, '+1');
        expect(
          (await b.client.listIssueReactions(
            owner,
            repo,
            issueNumber: 7,
          )).single.content,
          '+1',
        );
        await b.client.deleteIssueReaction(
          owner,
          repo,
          issueNumber: 7,
          reactionId: 9,
        );
        expect(b.fake.requests.last.method, 'DELETE');
      },
    );
  });

  group('GitHubPrClient pagination loops', () {
    test('listAssignableUsers paginates while rel="next" present', () async {
      var page = 0;
      final b = build((_) {
        page++;
        return _json(
          [
            {'login': 'u$page', 'avatar_url': 'a'},
          ],
          headers: {
            if (page == 1) 'link': ['<x>; rel="next"'],
          },
        );
      });
      final users = await b.client.listAssignableUsers(owner, repo);
      expect(users.map((u) => u.login), ['u1', 'u2']);
    });

    test('listRequestableTeams returns [] on 404', () async {
      final b = build((_) => _json({'message': 'not found'}, status: 404));
      final teams = await b.client.listRequestableTeams(owner, repo);
      expect(teams, isEmpty);
    });

    test('listRequestableTeams maps team nodes', () async {
      final b = build(
        (_) => _json([
          {'id': 1, 'name': 'Eng', 'slug': 'eng'},
        ]),
      );
      final teams = await b.client.listRequestableTeams(owner, repo);
      expect(teams.single.slug, 'eng');
      expect(
        teams.single.avatarUrl,
        'https://avatars.githubusercontent.com/t/1',
      );
    });

    test('listBranches paginates and skips empty names', () async {
      var page = 0;
      final b = build((_) {
        page++;
        return _json(
          [
            {'name': 'main'},
            if (page == 1) {'name': ''}, // skipped
          ],
          headers: {
            if (page == 1) 'link': ['<x>; rel="next"'],
          },
        );
      });
      final branches = await b.client.listBranches(owner, repo);
      expect(branches, ['main', 'main']); // one per page, '' skipped
    });

    test('getDefaultBranch returns the default_branch field', () async {
      final b = build((_) => _json({'default_branch': 'develop'}));
      expect(await b.client.getDefaultBranch(owner, repo), 'develop');
    });

    test('getDefaultBranch returns empty string for non-map data', () async {
      final b = build((_) => _json(<Object>[1]));
      expect(await b.client.getDefaultBranch(owner, repo), '');
    });
  });

  group('GitHubPrClient.compareBranches', () {
    test('sums additions/deletions across files and counts commits', () async {
      final b = build(
        (_) => _json({
          'total_commits': 3,
          'files': [
            {
              'filename': 'a.dart',
              'patch': 'p',
              'additions': 4,
              'deletions': 1,
            },
            {
              'filename': 'b.dart',
              'patch': 'p',
              'additions': 2,
              'deletions': 0,
            },
          ],
          'commits': [
            {
              'sha': 's1',
              'commit': {
                'message': 'm',
                'author': {'name': 'n'},
              },
            },
          ],
        }),
      );
      final cmp = await b.client.compareBranches(
        owner,
        repo,
        base: 'main',
        head: 'feature',
      );
      expect(cmp.totalCommits, 3);
      expect(cmp.additions, 6);
      expect(cmp.deletions, 1);
      expect(cmp.commits.single.sha, 's1');
    });

    test('tolerates a non-map response', () async {
      final b = build((_) => _json(<Object>[1]));
      final cmp = await b.client.compareBranches(
        owner,
        repo,
        base: 'main',
        head: 'feature',
      );
      expect(cmp.totalCommits, 0);
      expect(cmp.files, isEmpty);
    });
  });

  group('GitHubPrClient.searchIssues', () {
    test('returns (number,title) hits for the query', () async {
      final b = build(
        (_) => _json({
          'items': [
            {'number': 11, 'title': 'first'},
            {'number': 22, 'title': 'second'},
          ],
        }),
      );
      final hits = await b.client.searchIssues(owner, repo, 'fix');
      expect(hits.map((h) => h.number), [11, 22]);
      expect(hits.last.title, 'second');
      expect(
        b.fake.requests.single.queryParameters['q'],
        'repo:$owner/$repo fix',
      );
    });

    test('falls back to state:open when the query is blank', () async {
      final b = build((_) => _json({'items': []}));
      await b.client.searchIssues(owner, repo, '   ');
      expect(
        b.fake.requests.single.queryParameters['q'],
        'repo:$owner/$repo state:open',
      );
    });

    test(
      'returns [] on a non-cancel DioException (autocomplete never throws)',
      () async {
        final b = build((_) => _json({'message': 'boom'}, status: 500));
        expect(await b.client.searchIssues(owner, repo, 'x'), isEmpty);
      },
    );
  });
  group('GitHubPrClient workflow run jobs / job detail', () {
    test('listWorkflowRunJobs decodes the jobs envelope incl. steps', () async {
      final b = build(
        (_) => _json({
          'jobs': [
            {
              'id': 101,
              'run_id': 7,
              'name': 'Unit test (1)',
              'status': 'completed',
              'conclusion': 'success',
              'html_url': 'https://github.com/o/c/actions/runs/7/job/101',
              'check_run_url':
                  '/repos/o/c/check-runs/555',
              'started_at': '2025-01-01T10:00:00Z',
              'completed_at': '2025-01-01T10:05:00Z',
              'steps': [
                {
                  'number': 1,
                  'name': 'Set up job',
                  'status': 'completed',
                  'conclusion': 'success',
                  'started_at': '2025-01-01T10:00:00Z',
                  'completed_at': '2025-01-01T10:00:10Z',
                },
                {'number': 2, 'name': 'Run tests', 'status': 'in_progress'},
              ],
            },
          ],
        }),
      );
      final jobs = await b.client.listWorkflowRunJobs(owner, repo, 7);
      final job = jobs.single;
      expect(job.id, 101);
      expect(job.runId, 7);
      expect(job.checkRunUrl, endsWith('/check-runs/555'));
      expect(job.steps, hasLength(2));
      expect(job.steps.first.number, 1);
      expect(job.steps.first.conclusion, 'success');
      expect(job.steps.last.status, 'in_progress');
      final req = b.fake.requests.single;
      expect(
        req.path,
        '/repos/$owner/$repo/actions/runs/7/jobs',
      );
      expect(req.queryParameters['per_page'], 100);
    });

    test('getJobRun decodes one job', () async {
      final b = build(
        (_) => _json({
          'id': 101,
          'run_id': 7,
          'name': 'build',
          'status': 'in_progress',
          'steps': [
            {'number': 1, 'name': 'Set up job', 'status': 'completed'},
          ],
        }),
      );
      final job = await b.client.getJobRun(owner, repo, 101);
      expect(job, isNotNull);
      expect(job!.id, 101);
      expect(job.status, 'in_progress');
      expect(job.steps.single.name, 'Set up job');
      expect(
        b.fake.requests.single.path,
        '/repos/$owner/$repo/actions/jobs/101',
      );
    });

    test('getJobRun returns null on 404', () async {
      final b = build((_) => _json({'message': 'not found'}, status: 404));
      expect(await b.client.getJobRun(owner, repo, 999), isNull);
    });

    test('getWorkflowRun decodes path + head_sha', () async {
      final b = build(
        (_) => _json({
          'id': 7,
          'name': 'CI',
          'check_suite_id': 42,
          'head_sha': 'abc123',
          'path': '.github/workflows/ci.yaml',
          'status': 'completed',
          'conclusion': 'success',
        }),
      );
      final run = await b.client.getWorkflowRun(owner, repo, 7);
      expect(run, isNotNull);
      expect(run!.path, '.github/workflows/ci.yaml');
      expect(run.headSha, 'abc123');
      expect(run.checkSuiteId, 42);
      expect(
        b.fake.requests.single.path,
        '/repos/$owner/$repo/actions/runs/7',
      );
    });

    test('getWorkflowRun returns null on 404', () async {
      final b = build((_) => _json({'message': 'not found'}, status: 404));
      expect(await b.client.getWorkflowRun(owner, repo, 999), isNull);
    });
  });

  group('GitHubPrClient.getJobLogs', () {
    GitHubPrClient clientWith(_FakeAdapter authed, _FakeAdapter download) {
      final authedDio = Dio()..httpClientAdapter = authed;
      final downloadDio = Dio()..httpClientAdapter = download;
      return GitHubPrClient(authedDio, downloadDio: downloadDio);
    }

    test(
      'follows the 302 to the signed URL on the PLAIN download client',
      () async {
        const logText = 'line one\nline two\n';
        final authed = _FakeAdapter(
          (_) => _json(
            {'message': 'Found'},
            status: 302,
            headers: {
              'location': ['https://signed.example/log.zip'],
            },
          ),
        );
        final download = _FakeAdapter((_) => _text(logText));
        final client = clientWith(authed, download);

        final result = await client.getJobLogs(owner, repo, 101);
        expect(result, isNotNull);
        expect(result!.text, logText.replaceAll('\r\n', '\n'));
        expect(result.truncated, isFalse);
        // The redirect target was hit on the download client — never on the
        // authed one (the Authorization header must not leak to Azure).
        expect(authed.requests, hasLength(1));
        expect(authed.requests.single.followRedirects, isFalse);
        expect(download.requests.single.path, 'https://signed.example/log.zip');
      },
    );

    test('returns null on 404 (job running / logs expired)', () async {
      final authed = _FakeAdapter(
        (_) => _json({'message': 'not found'}, status: 404),
      );
      final download = _FakeAdapter((_) => _text(''));
      final client = clientWith(authed, download);
      expect(await client.getJobLogs(owner, repo, 101), isNull);
      expect(download.requests, isEmpty);
    });

    test('keeps only the tail past maxBytes and reports truncation', () async {
      final big = List.generate(2000, (i) => 'log line $i').join('\n');
      final authed = _FakeAdapter(
        (_) => _json(
          {'message': 'Found'},
          status: 302,
          headers: {
            'location': ['https://signed.example/log.zip'],
          },
        ),
      );
      final download = _FakeAdapter((_) => _text(big));
      final client = clientWith(authed, download);

      final result = await client.getJobLogs(owner, repo, 101, maxBytes: 1024);
      expect(result, isNotNull);
      expect(result!.truncated, isTrue);
      expect(result.text.length, lessThanOrEqualTo(1024));
      expect(result.text, endsWith('log line 1999'));
    });

    test(
      'returns null when the head response has no redirect location',
      () async {
        final authed = _FakeAdapter((_) => _json({'ok': true}, status: 200));
        final download = _FakeAdapter((_) => _text(''));
        final client = clientWith(authed, download);
        expect(await client.getJobLogs(owner, repo, 101), isNull);
        expect(download.requests, isEmpty);
      },
    );
  });

  group('GitHubPrClient stacks', () {
    const stackJson = <String, dynamic>{
      'id': 7,
      'number': 3,
      'external_id': 'S_1',
      'url': '/repos/o/c/stacks/3',
      'base': {'ref': 'main'},
      'open': true,
      'created_at': '2026-01-01T00:00:00Z',
      'pull_requests': [
        {
          'number': 101,
          'state': 'open',
          'draft': false,
          'merged_at': null,
          'head': {'ref': 'feat-a', 'sha': 'sha1'},
        },
        {
          'number': 102,
          'state': 'closed',
          'draft': false,
          'merged_at': '2026-01-02T00:00:00Z',
          'head': {'ref': 'feat-b', 'sha': 'sha2'},
        },
      ],
    };

    test('listStacks GETs the endpoint with the API-version header', () async {
      final b = build((_) => _json([stackJson]));
      final page = await b.client.listStacks(owner, repo, pullRequest: 101);
      expect(page.items.single.number, 3);
      expect(page.items.single.baseRef, 'main');
      expect(page.items.single.pullRequests, hasLength(2));
      expect(page.items.single.pullRequests.last.mergedAt, isNotNull);
      expect(page.hasMore, isFalse);
      final req = b.fake.requests.single;
      expect(req.method, 'GET');
      expect(req.path, '/repos/$owner/$repo/stacks');
      expect(req.queryParameters['pull_request'], 101);
      expect(req.headers['X-GitHub-Api-Version'], '2026-03-10');
    });

    test('getStack returns null on a 404', () async {
      final b = build((_) => _json({'message': 'Not Found'}, status: 404));
      expect(await b.client.getStack(owner, repo, 3), isNull);
    });

    test('createStack POSTs the ordered PR numbers', () async {
      final b = build((_) => _json(stackJson, status: 201));
      final stack = await b.client.createStack(owner, repo, const [101, 102]);
      expect(stack.number, 3);
      final req = b.fake.requests.single;
      expect(req.method, 'POST');
      expect(req.path, '/repos/$owner/$repo/stacks');
      expect((req.data as Map)['pull_requests'], [101, 102]);
    });

    test('addToStack POSTs to the add sub-endpoint', () async {
      final b = build((_) => _json(stackJson));
      await b.client.addToStack(owner, repo, 3, const [103]);
      final req = b.fake.requests.single;
      expect(req.method, 'POST');
      expect(
        req.path,
        '/repos/$owner/$repo/stacks/3/add',
      );
    });

    test('unstack maps a 204 (dissolved stack) to null', () async {
      final b = build((_) => _json(null, status: 204));
      expect(await b.client.unstack(owner, repo, 3), isNull);
      final req = b.fake.requests.single;
      expect(
        req.path,
        '/repos/$owner/$repo/stacks/3/unstack',
      );
    });
  });
}
