import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/github_graphql_client.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhttp/rhttp.dart';

void main() {
  late TestHttpClient fake;
  late GitHubGraphQLClient client;

  setUp(() {
    fake = TestHttpClient(handler: (_) => throw StateError('handler not set'));
    client = GitHubGraphQLClient(fake);
  });

  group('markFileAsViewed', () {
    test('sends correct GraphQL mutation', () async {
      fake.handler = (request) => httpTextResponse(request, {});

      await client.markFileAsViewed(
        pullRequestId: 'PR_1',
        path: 'lib/main.dart',
      );

      final request = fake.requests.single;
      expect(request.url, '/graphql');
      expect(request.method.value, 'POST');
      final body = (request.body as HttpBodyJson).json as Map<String, dynamic>;
      expect(body['query'] as String, contains('markFileAsViewed'));
      expect(body['variables'], {
        'pullRequestId': 'PR_1',
        'path': 'lib/main.dart',
      });
    });

    test('completes without error', () async {
      fake.handler = (request) => httpTextResponse(request, {});

      await expectLater(
        client.markFileAsViewed(pullRequestId: 'PR_1', path: 'src/foo.dart'),
        completes,
      );
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fake.handler = (request) {
        received = request.cancelToken;
        return httpTextResponse(request, {});
      };
      final ct = CancelToken();
      await client.markFileAsViewed(
        pullRequestId: 'PR_1',
        path: 'lib/main.dart',
        cancelToken: ct,
      );
      expect(received, same(ct));
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);

      await expectLater(
        client.markFileAsViewed(pullRequestId: 'PR_1', path: 'lib/main.dart'),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other exceptions', () async {
      fake.handler = (request) =>
          httpTextResponse(request, 'not found', statusCode: 404);

      await expectLater(
        client.markFileAsViewed(pullRequestId: 'PR_1', path: 'lib/main.dart'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('wraps connection error exceptions', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, 'No connection');

      await expectLater(
        client.markFileAsViewed(pullRequestId: 'PR_1', path: 'lib/main.dart'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('unmarkFileAsViewed', () {
    test('sends correct GraphQL mutation', () async {
      fake.handler = (request) => httpTextResponse(request, {});

      await client.unmarkFileAsViewed(
        pullRequestId: 'PR_2',
        path: 'test/foo_test.dart',
      );

      final request = fake.requests.single;
      expect(request.url, '/graphql');
      expect(request.method.value, 'POST');
      final body = (request.body as HttpBodyJson).json as Map<String, dynamic>;
      expect(body['query'] as String, contains('unmarkFileAsViewed'));
      expect(body['variables'], {
        'pullRequestId': 'PR_2',
        'path': 'test/foo_test.dart',
      });
    });

    test('completes without error', () async {
      fake.handler = (request) => httpTextResponse(request, {});

      await expectLater(
        client.unmarkFileAsViewed(pullRequestId: 'PR_1', path: 'src/bar.dart'),
        completes,
      );
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fake.handler = (request) {
        received = request.cancelToken;
        return httpTextResponse(request, {});
      };
      final ct = CancelToken();
      await client.unmarkFileAsViewed(
        pullRequestId: 'PR_1',
        path: 'lib/main.dart',
        cancelToken: ct,
      );
      expect(received, same(ct));
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);

      await expectLater(
        client.unmarkFileAsViewed(pullRequestId: 'PR_1', path: 'lib/main.dart'),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other exceptions', () async {
      fake.handler = (request) =>
          httpTextResponse(request, 'server error', statusCode: 500);

      await expectLater(
        client.unmarkFileAsViewed(pullRequestId: 'PR_1', path: 'lib/main.dart'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('wraps timeout exceptions', () async {
      fake.handler = (request) => throw RhttpTimeoutException(request);

      await expectLater(
        client.unmarkFileAsViewed(pullRequestId: 'PR_1', path: 'lib/main.dart'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('searchReviewRequestedPullRequests', () {
    void respondWithNodes(Object nodes) {
      fake.handler = (request) => httpTextResponse(request, {
        'data': {
          'search': {'nodes': nodes},
        },
      });
    }

    test('builds a review-requested search scoped to the repos', () async {
      respondWithNodes([
        {
          'number': 7,
          'title': 'Fix the thing',
          'url': 'https://github.com/o/r/pull/7',
          'repository': {'nameWithOwner': 'o/r'},
        },
      ]);

      final nodes = await client.searchReviewRequestedPullRequests(
        reviewerLogin: 'octocat',
        repos: [(owner: 'o', name: 'r')],
      );

      expect(fake.requests, hasLength(1));
      final request = fake.requests.single;
      final body = (request.body as HttpBodyJson).json as Map<String, dynamic>;
      // The search string is a *variable*, not interpolated into the query.
      expect(body['query'] as String, contains(r'search(query: $q'));
      final q = (body['variables'] as Map)['q'] as String;
      expect(q, contains('is:pr is:open draft:false review-requested:octocat'));
      expect(q, contains('repo:o/r'));
      expect(nodes, hasLength(1));
      expect(nodes.first['number'], 7);
    });

    test('chunks repos into separate requests (5 per query)', () async {
      respondWithNodes(const []);

      await client.searchReviewRequestedPullRequests(
        reviewerLogin: 'me',
        repos: List.generate(6, (i) => (owner: 'o', name: 'r$i')),
      );

      expect(fake.requests, hasLength(2));
    });

    test('returns empty without a request when there are no repos', () async {
      respondWithNodes(const []);

      final nodes = await client.searchReviewRequestedPullRequests(
        reviewerLogin: 'me',
        repos: const [],
      );

      expect(nodes, isEmpty);
      expect(fake.requests, isEmpty);
    });

    test('swallows cancellation and returns empty', () async {
      fake.handler = (request) => throw RhttpCancelException(request);

      final nodes = await client.searchReviewRequestedPullRequests(
        reviewerLogin: 'me',
        repos: [(owner: 'o', name: 'r')],
      );

      expect(nodes, isEmpty);
    });
  });

  group('searchReviewedByPullRequests', () {
    test(
      'builds a reviewed-by search and returns (repo, number) pairs',
      () async {
        fake.handler = (request) => httpTextResponse(request, {
          'data': {
            'search': {
              'nodes': [
                {
                  'number': 7,
                  'repository': {'nameWithOwner': 'o/r'},
                },
                // A non-PR hit deserializes empty — must be skipped.
                <String, dynamic>{},
              ],
            },
          },
        });

        final pairs = await client.searchReviewedByPullRequests(
          reviewerLogin: 'octocat',
          repos: [(owner: 'o', name: 'r')],
        );

        final request = fake.requests.single;
        final body = (request.body as HttpBodyJson).json as Map;
        final q = (body['variables'] as Map)['q'] as String;
        expect(q, contains('is:pr is:open reviewed-by:octocat'));
        expect(q, contains('repo:o/r'));
        expect(pairs, hasLength(1));
        expect(pairs.first.repoFullName, 'o/r');
        expect(pairs.first.number, 7);
      },
    );

    test('returns empty without a request when there are no repos', () async {
      fake.handler = (request) => httpTextResponse(request, {});

      final pairs = await client.searchReviewedByPullRequests(
        reviewerLogin: 'me',
        repos: const [],
      );

      expect(pairs, isEmpty);
      expect(fake.requests, isEmpty);
    });
  });
}
