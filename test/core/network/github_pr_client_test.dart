import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:cc_infra/src/network/models/github_check_run.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhttp/rhttp.dart';

void main() {
  late TestHttpClient fake;
  late GitHubPrClient client;

  setUp(() {
    fake = TestHttpClient(
      handler: (_) => throw StateError('no handler configured'),
    );
    // The redirectless hop only matters for `getJobLogs`; a `TestHttpClient`
    // never follows redirects, and passing it here keeps every request on the
    // fake so no native client is ever constructed.
    client = GitHubPrClient(fake, redirectlessHttpClient: fake);
  });

  /// Answers every request with [body] JSON-encoded (a String verbatim).
  void respond(
    Object? body, {
    int statusCode = 200,
    Map<String, String> headers = const {},
  }) {
    fake.handler = (request) => httpTextResponse(
      request,
      body,
      statusCode: statusCode,
      headers: headers,
    );
  }

  /// The JSON body of the single request captured so far.
  Map<String, dynamic> requestJsonBody() =>
      (fake.requests.single.body! as HttpBodyJson).json as Map<String, dynamic>;

  group('listOpenPullRequests', () {
    test('returns list of open PRs', () async {
      respond([
        {'number': 1, 'html_url': 'u'},
        {'number': 2, 'html_url': 'u'},
      ]);

      final result = await client.listOpenPullRequestsPage('owner', 'repo');
      expect(result.items.length, 2);
      expect(result.items[0].number, 1);
    });

    test('returns empty list for null data', () async {
      respond(null);

      final result = await client.listOpenPullRequestsPage('owner', 'repo');
      expect(result.items, isEmpty);
    });

    test('returns empty list for non-list data', () async {
      respond(42);

      final result = await client.listOpenPullRequestsPage('owner', 'repo');
      expect(result.items, isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listOpenPullRequestsPage('', 'repo'),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for empty repo', () {
      expect(
        () => client.listOpenPullRequestsPage('owner', ''),
        throwsArgumentError,
      );
    });

    test('propagates cancel token', () async {
      respond([]);
      final ct = CancelToken();
      await client.listOpenPullRequestsPage('owner', 'repo', cancelToken: ct);
      expect(fake.requests.single.cancelToken, same(ct));
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.listOpenPullRequestsPage('owner', 'repo'),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other transport errors', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, 'timeout');
      await expectLater(
        client.listOpenPullRequestsPage('owner', 'repo'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('calls correct URL with query parameters', () async {
      respond([]);
      await client.listOpenPullRequestsPage('owner', 'repo');
      expect(fake.requests.single.url, '/repos/owner/repo/pulls');
      expect(fake.requests.single.query, containsPair('state', 'open'));
    });
  });

  group('listRequestedReviews', () {
    test('returns PRs from search items', () async {
      respond({
        'items': [
          {'number': 10, 'html_url': 'u'},
        ],
      });
      final result = await client.listRequestedReviews('owner', 'repo');
      expect(result.length, 1);
      expect(result[0].number, 10);
    });

    test('returns empty list when items is null', () async {
      respond(<String, dynamic>{});
      expect(await client.listRequestedReviews('owner', 'repo'), isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listRequestedReviews('', 'repo'),
        throwsArgumentError,
      );
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.listRequestedReviews('owner', 'repo'),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other transport errors', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, 'not found');
      await expectLater(
        client.listRequestedReviews('owner', 'repo'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getPullRequest', () {
    test('returns a PR when data is map', () async {
      respond({'number': 42, 'html_url': 'u'});
      final result = await client.getPullRequest('owner', 'repo', 42);
      expect(result!.number, 42);
    });

    test('returns null when data is not a map', () async {
      respond([1, 2]);
      expect(await client.getPullRequest('owner', 'repo', 42), isNull);
    });

    test('returns null for null data', () async {
      respond(null);
      expect(await client.getPullRequest('owner', 'repo', 42), isNull);
    });

    test('throws ArgumentError for empty owner', () {
      expect(() => client.getPullRequest('', 'repo', 42), throwsArgumentError);
    });

    test('propagates cancel token', () async {
      respond({'number': 1});
      final ct = CancelToken();
      await client.getPullRequest('owner', 'repo', 1, cancelToken: ct);
      expect(fake.requests.single.cancelToken, same(ct));
    });

    test('wraps transport errors', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, 'error');
      await expectLater(
        client.getPullRequest('owner', 'repo', 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getPullRequestDiff', () {
    test('returns diff text', () async {
      respond('diff --git');
      expect(
        await client.getPullRequestDiff('owner', 'repo', 42),
        'diff --git',
      );
    });

    test('returns empty string for empty body', () async {
      respond('');
      expect(await client.getPullRequestDiff('owner', 'repo', 42), '');
    });

    test('sends Accept diff header', () async {
      respond('diff');
      await client.getPullRequestDiff('owner', 'repo', 1);
      expect(
        fake.requests.single.headers?[HttpHeaderName.accept],
        'application/vnd.github.diff',
      );
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.getPullRequestDiff('', 'repo', 1),
        throwsArgumentError,
      );
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.getPullRequestDiff('owner', 'repo', 1),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other transport errors', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, 'timeout');
      await expectLater(
        client.getPullRequestDiff('owner', 'repo', 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('listPullRequestFiles', () {
    test('returns list of files', () async {
      respond([
        {
          'filename': 'lib/main.dart',
          'status': 'modified',
          'additions': 5,
          'deletions': 2,
          'changes': 7,
        },
        {
          'filename': 'lib/foo.dart',
          'status': 'added',
          'additions': 10,
          'deletions': 0,
          'changes': 10,
        },
      ]);
      final result = await client.listPullRequestFiles('owner', 'repo', 42);
      expect(result.length, 2);
      expect(result[0].filename, 'lib/main.dart');
    });

    test('returns empty list for null data', () async {
      respond(null);
      expect(await client.listPullRequestFiles('owner', 'repo', 42), isEmpty);
    });

    test('sends per_page query parameter', () async {
      respond([]);
      await client.listPullRequestFiles('owner', 'repo', 1);
      expect(fake.requests.single.query, containsPair('per_page', '100'));
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listPullRequestFiles('', 'repo', 1),
        throwsArgumentError,
      );
    });

    test('propagates cancel token', () async {
      respond([]);
      final ct = CancelToken();
      await client.listPullRequestFiles('owner', 'repo', 1, cancelToken: ct);
      expect(fake.requests.single.cancelToken, same(ct));
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.listPullRequestFiles('owner', 'repo', 1),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other transport errors', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, '404');
      await expectLater(
        client.listPullRequestFiles('owner', 'repo', 1),
        throwsA(isA<NetworkException>()),
      );
    });

    test('filters out non-map items', () async {
      respond([
        {
          'filename': 'a.dart',
          'status': 'modified',
          'additions': 1,
          'deletions': 0,
          'changes': 1,
        },
        'not a map',
        42,
      ]);
      final result = await client.listPullRequestFiles('owner', 'repo', 1);
      expect(result.length, 1);
      expect(result[0].filename, 'a.dart');
    });
  });

  group('listPullRequestCommits', () {
    test('returns list of commits', () async {
      respond([
        {
          'sha': 'abc123',
          'commit': {
            'message': 'fix bug',
            'author': {
              'name': 'dev',
              'email': 'dev@test.com',
              'date': '2024-01-01T00:00:00Z',
            },
          },
        },
      ]);
      final result = await client.listPullRequestCommits('owner', 'repo', 42);
      expect(result.length, 1);
      expect(result[0].sha, 'abc123');
    });

    test('returns empty list for null data', () async {
      respond(null);
      expect(await client.listPullRequestCommits('owner', 'repo', 42), isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listPullRequestCommits('', 'repo', 1),
        throwsArgumentError,
      );
    });

    test('wraps transport errors', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, 'timeout');
      await expectLater(
        client.listPullRequestCommits('owner', 'repo', 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getCommitFiles', () {
    test('returns files from commit', () async {
      respond({
        'files': [
          {
            'filename': 'src/app.ts',
            'status': 'modified',
            'additions': 3,
            'deletions': 1,
            'changes': 4,
          },
        ],
      });
      final result = await client.getCommitFiles('owner', 'repo', 'abc123');
      expect(result.length, 1);
      expect(result[0].filename, 'src/app.ts');
    });

    test('returns empty list for empty sha', () async {
      expect(await client.getCommitFiles('owner', 'repo', ''), isEmpty);
    });

    test('returns empty list when data is not map', () async {
      respond([1, 2]);
      expect(await client.getCommitFiles('owner', 'repo', 'abc123'), isEmpty);
    });

    test('returns empty list when files is null', () async {
      respond({});
      expect(await client.getCommitFiles('owner', 'repo', 'abc123'), isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.getCommitFiles('', 'repo', 'abc123'),
        throwsArgumentError,
      );
    });

    test('propagates cancel token', () async {
      respond({'files': []});
      final ct = CancelToken();
      await client.getCommitFiles('owner', 'repo', 'sha', cancelToken: ct);
      expect(fake.requests.single.cancelToken, same(ct));
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.getCommitFiles('owner', 'repo', 'sha'),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other transport errors', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, '404');
      await expectLater(
        client.getCommitFiles('owner', 'repo', 'sha'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('listPullRequestReviews', () {
    test('returns list of reviews', () async {
      respond([
        {'id': 1, 'state': 'APPROVED', 'body': 'LGTM'},
        {'id': 2, 'state': 'CHANGES_REQUESTED', 'body': 'Needs work'},
      ]);
      final result = await client.listPullRequestReviews('owner', 'repo', 42);
      expect(result.length, 2);
      expect(result[0].state, GitHubReviewState.approved);
    });

    test('returns empty list for null data', () async {
      respond(null);
      expect(await client.listPullRequestReviews('owner', 'repo', 42), isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listPullRequestReviews('', 'repo', 1),
        throwsArgumentError,
      );
    });

    test('wraps transport errors', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, 'reset');
      await expectLater(
        client.listPullRequestReviews('owner', 'repo', 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('listPullRequestReviewComments', () {
    test('returns list of review comments', () async {
      respond([
        {
          'id': 1,
          'body': 'Please fix',
          'path': 'src/main.dart',
          'diff_hunk': '@@...',
        },
      ]);
      final result = await client.listPullRequestReviewComments(
        'owner',
        'repo',
        42,
      );
      expect(result.length, 1);
      expect(result[0].id, 1);
    });

    test('returns empty list for null data', () async {
      respond(null);
      expect(
        await client.listPullRequestReviewComments('owner', 'repo', 42),
        isEmpty,
      );
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listPullRequestReviewComments('', 'repo', 1),
        throwsArgumentError,
      );
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.listPullRequestReviewComments('owner', 'repo', 1),
        throwsA(isA<RhttpCancelException>()),
      );
    });
  });

  group('listIssueComments', () {
    test('returns list of issue comments', () async {
      respond([
        {'id': 1, 'body': 'Working'},
        {'id': 2, 'body': 'Done'},
      ]);
      final result = await client.listIssueComments('owner', 'repo', 42);
      expect(result.length, 2);
      expect(result[0].id, 1);
    });

    test('returns empty list for null data', () async {
      respond(null);
      expect(await client.listIssueComments('owner', 'repo', 42), isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listIssueComments('', 'repo', 1),
        throwsArgumentError,
      );
    });

    test('wraps transport errors', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, 'timeout');
      await expectLater(
        client.listIssueComments('owner', 'repo', 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('listCheckRuns', () {
    test('returns check runs', () async {
      respond({
        'check_runs': [
          {
            'id': 1,
            'name': 'build',
            'status': 'completed',
            'conclusion': 'success',
            'app': {'name': 'GitHub Actions'},
            'html_url': 'https://e.com',
          },
        ],
      });
      final result = await client.listCheckRuns('owner', 'repo', 'abc123');
      expect(result.length, 1);
      expect(result[0].name, 'build');
      expect(result[0].status, GitHubCheckStatus.completed);
    });

    test('returns empty list for empty ref', () async {
      expect(await client.listCheckRuns('owner', 'repo', ''), isEmpty);
    });

    test('returns empty list when data is not map', () async {
      respond([1, 2]);
      expect(await client.listCheckRuns('owner', 'repo', 'abc123'), isEmpty);
    });

    test('returns empty list when check_runs is null', () async {
      respond({});
      expect(await client.listCheckRuns('owner', 'repo', 'abc123'), isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listCheckRuns('', 'repo', 'ref'),
        throwsArgumentError,
      );
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.listCheckRuns('owner', 'repo', 'ref'),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other transport errors', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, '404');
      await expectLater(
        client.listCheckRuns('owner', 'repo', 'ref'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('createPullRequest', () {
    test('returns created PR data', () async {
      respond({'number': 99});
      final result = await client.createPullRequest(
        'owner',
        'repo',
        title: 'New',
        body: 'Desc',
        head: 'f',
        base: 'm',
      );
      expect(result['number'], 99);
    });

    test('returns empty map for non-map response', () async {
      respond([1, 2]);
      final result = await client.createPullRequest(
        'owner',
        'repo',
        title: 'New',
        body: 'Desc',
        head: 'f',
        base: 'm',
      );
      expect(result, isEmpty);
    });

    test('sends correct POST body', () async {
      respond({});
      await client.createPullRequest(
        'owner',
        'repo',
        title: 'Title',
        body: 'Body',
        head: 'head',
        base: 'base',
      );
      expect(fake.requests.single.method.value, 'POST');
      expect(fake.requests.single.url, '/repos/owner/repo/pulls');
      expect(requestJsonBody(), {
        'title': 'Title',
        'body': 'Body',
        'head': 'head',
        'base': 'base',
        'draft': false,
      });
    });

    test('throws ArgumentError for empty owner', () async {
      await expectLater(
        client.createPullRequest(
          '',
          'repo',
          title: 't',
          body: 'b',
          head: 'h',
          base: 'b',
        ),
        throwsArgumentError,
      );
    });

    test('propagates cancel token', () async {
      respond({});
      final ct = CancelToken();
      await client.createPullRequest(
        'owner',
        'repo',
        title: 't',
        body: 'b',
        head: 'h',
        base: 'b',
        cancelToken: ct,
      );
      expect(fake.requests.single.cancelToken, same(ct));
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.createPullRequest(
          'owner',
          'repo',
          title: 't',
          body: 'b',
          head: 'h',
          base: 'b',
        ),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other transport errors', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, '422');
      await expectLater(
        client.createPullRequest(
          'owner',
          'repo',
          title: 't',
          body: 'b',
          head: 'h',
          base: 'b',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('fromJson round-trip', () {
    test('PR includes externalId and headRef', () async {
      respond({
        'number': 1,
        'external_id': 'PR_nodeId',
        'head': {'sha': 'abc', 'ref': 'feature/x'},
        'user': {'login': 'dev', 'avatar_url': 'a'},
      });
      final result = await client.getPullRequest('owner', 'repo', 1);
      expect(result!.externalId, 'PR_nodeId');
      expect(result.headRef, 'feature/x');
    });

    test('PR file includes previousFilename for renames', () async {
      respond([
        {
          'filename': 'new.dart',
          'status': 'renamed',
          'additions': 0,
          'deletions': 0,
          'changes': 0,
          'previous_filename': 'old.dart',
        },
      ]);
      final result = await client.listPullRequestFiles('owner', 'repo', 1);
      expect(result[0].previousFilename, 'old.dart');
    });

    test('review comment includes line and diffHunk', () async {
      respond([
        {
          'id': 5,
          'body': 'N',
          'path': 'f.dart',
          'diff_hunk': '@@',
          'line': 42,
          'original_line': 40,
          'start_line': 38,
        },
      ]);
      final result = await client.listPullRequestReviewComments(
        'owner',
        'repo',
        1,
      );
      expect(result[0].line, 42);
      expect(result[0].originalLine, 40);
    });

    test('commit includes author and committedAt', () async {
      respond([
        {
          'sha': 'def456',
          'commit': {
            'message': 'feat',
            'author': {
              'name': 'Alice',
              'email': 'a@t.com',
              'date': '2024-06-15T12:00:00Z',
            },
          },
          'author': {'login': 'alice', 'avatar_url': 'a'},
        },
      ]);
      final result = await client.listPullRequestCommits('owner', 'repo', 1);
      expect(result[0].authorName, 'Alice');
      expect(result[0].committedAt, DateTime.utc(2024, 6, 15, 12, 0, 0));
    });
  });

  group('postReviewComment', () {
    test('returns created review comment', () async {
      respond({
        'id': 777,
        'body': 'New comment',
        'path': 'lib/main.dart',
        'diff_hunk': '@@...',
      });
      final result = await client.postReviewComment(
        'owner',
        'repo',
        prNumber: 42,
        commitSha: 'abc123',
        path: 'lib/main.dart',
        line: 10,
        side: 'RIGHT',
        body: 'New comment',
      );
      expect(result.id, 777);
      expect(result.body, 'New comment');
    });

    test('includes startLine and startSide for multi-line comments', () async {
      respond({'id': 1, 'body': 'm'});
      await client.postReviewComment(
        'owner',
        'repo',
        prNumber: 1,
        commitSha: 'sha',
        path: 'f.dart',
        line: 20,
        side: 'RIGHT',
        body: 'Multi-line',
        startLine: 15,
        startSide: 'RIGHT',
      );
      final body = requestJsonBody();
      expect(body['start_line'], 15);
      expect(body['start_side'], 'RIGHT');
    });

    test('omits startLine when equal to line', () async {
      respond({'id': 1, 'body': 'm'});
      await client.postReviewComment(
        'owner',
        'repo',
        prNumber: 1,
        commitSha: 'sha',
        path: 'f.dart',
        line: 10,
        side: 'RIGHT',
        body: 'Single line',
        startLine: 10,
      );
      expect(requestJsonBody().containsKey('start_line'), isFalse);
    });

    test('posts to correct URL', () async {
      respond({'id': 1, 'body': 'm'});
      await client.postReviewComment(
        'owner',
        'repo',
        prNumber: 42,
        commitSha: 'sha',
        path: 'f.dart',
        line: 1,
        side: 'RIGHT',
        body: 'Test',
      );
      expect(fake.requests.single.method.value, 'POST');
      expect(fake.requests.single.url, '/repos/owner/repo/pulls/42/comments');
    });

    test('throws for non-map response', () async {
      respond([1, 2]);
      await expectLater(
        client.postReviewComment(
          'owner',
          'repo',
          prNumber: 1,
          commitSha: 'sha',
          path: 'f.dart',
          line: 1,
          side: 'RIGHT',
          body: 'Test',
        ),
        throwsFormatException,
      );
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.postReviewComment(
          '',
          'repo',
          prNumber: 1,
          commitSha: 'sha',
          path: 'f.dart',
          line: 1,
          side: 'RIGHT',
          body: 'Test',
        ),
        throwsArgumentError,
      );
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.postReviewComment(
          'owner',
          'repo',
          prNumber: 1,
          commitSha: 'sha',
          path: 'f.dart',
          line: 1,
          side: 'RIGHT',
          body: 'Test',
        ),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other transport errors', () async {
      respond({'message': 'Unprocessable Entity'}, statusCode: 422);
      await expectLater(
        client.postReviewComment(
          'owner',
          'repo',
          prNumber: 1,
          commitSha: 'sha',
          path: 'f.dart',
          line: 1,
          side: 'RIGHT',
          body: 'Test',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('replyToReviewComment', () {
    test('returns comment from reply', () async {
      respond({
        'id': 888,
        'body': 'Good point',
        'path': 'lib/main.dart',
        'diff_hunk': '@@...',
      });
      final result = await client.replyToReviewComment(
        'owner',
        'repo',
        prNumber: 42,
        parentCommentId: 777,
        body: 'Good point',
      );
      expect(result.id, 888);
      expect(result.body, 'Good point');
    });

    test('posts to correct reply URL', () async {
      respond({'id': 1, 'body': 'm'});
      await client.replyToReviewComment(
        'owner',
        'repo',
        prNumber: 42,
        parentCommentId: 100,
        body: 'Reply',
      );
      expect(
        fake.requests.single.url,
        '/repos/owner/repo/pulls/42/comments/100/replies',
      );
    });

    test('throws for non-map response', () async {
      respond([1, 2]);
      await expectLater(
        client.replyToReviewComment(
          'owner',
          'repo',
          prNumber: 1,
          parentCommentId: 1,
          body: 'Reply',
        ),
        throwsFormatException,
      );
    });

    test('wraps transport errors', () async {
      respond({'message': 'Not Found'}, statusCode: 404);
      await expectLater(
        client.replyToReviewComment(
          'owner',
          'repo',
          prNumber: 1,
          parentCommentId: 1,
          body: 'Reply',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('deleteReviewComment', () {
    test('completes without error', () async {
      respond({});
      await expectLater(
        client.deleteReviewComment('owner', 'repo', commentId: 777),
        completes,
      );
    });

    test('calls DELETE on correct URL', () async {
      respond({});
      await client.deleteReviewComment('owner', 'repo', commentId: 42);
      expect(fake.requests.single.method.value, 'DELETE');
      expect(fake.requests.single.url, '/repos/owner/repo/pulls/comments/42');
    });

    test('propagates cancel token', () async {
      respond({});
      final ct = CancelToken();
      await client.deleteReviewComment(
        'owner',
        'repo',
        commentId: 1,
        cancelToken: ct,
      );
      expect(fake.requests.single.cancelToken, same(ct));
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.deleteReviewComment('owner', 'repo', commentId: 1),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other transport errors', () async {
      respond({'message': 'Forbidden'}, statusCode: 403);
      await expectLater(
        client.deleteReviewComment('owner', 'repo', commentId: 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('editReviewComment', () {
    test('returns edited review comment', () async {
      respond({
        'id': 999,
        'body': 'Updated comment',
        'path': 'lib/main.dart',
        'diff_hunk': '@@...',
      });
      final result = await client.editReviewComment(
        'owner',
        'repo',
        commentId: 999,
        body: 'Updated comment',
      );
      expect(result.id, 999);
      expect(result.body, 'Updated comment');
    });

    test('sends PATCH to correct URL with body', () async {
      respond({'id': 1, 'body': 'm'});
      await client.editReviewComment(
        'owner',
        'repo',
        commentId: 42,
        body: 'Edited',
      );
      expect(fake.requests.single.method.value, 'PATCH');
      expect(fake.requests.single.url, '/repos/owner/repo/pulls/comments/42');
      expect(requestJsonBody(), {'body': 'Edited'});
    });

    test('throws for non-map response', () async {
      respond([1, 2]);
      await expectLater(
        client.editReviewComment('owner', 'repo', commentId: 1, body: 'Edited'),
        throwsFormatException,
      );
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.editReviewComment('', 'repo', commentId: 1, body: 'Edit'),
        throwsArgumentError,
      );
    });

    test('propagates cancel token', () async {
      respond({'id': 1, 'body': 'm'});
      final ct = CancelToken();
      await client.editReviewComment(
        'owner',
        'repo',
        commentId: 1,
        body: 'Edited',
        cancelToken: ct,
      );
      expect(fake.requests.single.cancelToken, same(ct));
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.editReviewComment('owner', 'repo', commentId: 1, body: 'Edited'),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other transport errors', () async {
      respond({'message': 'Forbidden'}, statusCode: 403);
      await expectLater(
        client.editReviewComment('owner', 'repo', commentId: 1, body: 'Edited'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
