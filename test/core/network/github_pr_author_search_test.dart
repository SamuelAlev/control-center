import 'package:cc_infra/src/network/github_graphql_client.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubGraphQLClient.prCountsByAuthor', () {
    test('reads the four aliased issueCounts from one request', () async {
      final fake = TestHttpClient(
        handler: (request) => httpTextResponse(request, {
          'data': {
            'open': {'issueCount': 3},
            'draft': {'issueCount': 1},
            'merged': {'issueCount': 42},
            'closed': {'issueCount': 7},
          },
        }),
      );

      final counts = await GitHubGraphQLClient(fake).prCountsByAuthor(
        login: 'octocat',
        repos: const [(owner: 'o', name: 'r')],
      );

      expect(counts, (open: 3, draft: 1, merged: 42, closed: 7));
      expect(fake.requests, hasLength(1));
    });

    test(
      'sums issueCounts across repo chunks (>5 repos => 2 requests)',
      () async {
        var call = 0;
        final fake = TestHttpClient(
          handler: (request) {
            final i = call++;
            return httpTextResponse(request, {
              'data': {
                'open': {'issueCount': i == 0 ? 10 : 5},
                'draft': {'issueCount': 0},
                'merged': {'issueCount': i == 0 ? 40 : 2},
                'closed': {'issueCount': 1},
              },
            });
          },
        );
        final repos = [for (var n = 0; n < 6; n++) (owner: 'o', name: 'r$n')];

        final counts = await GitHubGraphQLClient(
          fake,
        ).prCountsByAuthor(login: 'octocat', repos: repos);

        expect(
          fake.requests,
          hasLength(2),
          reason: 'chunk size 5 over 6 repos => 2 calls',
        );
        expect(counts, (open: 15, draft: 0, merged: 42, closed: 2));
      },
    );

    test('returns zeros without a request when repos are empty', () async {
      final fake = TestHttpClient(
        handler: (request) => httpTextResponse(request, const {'data': {}}),
      );

      final counts = await GitHubGraphQLClient(
        fake,
      ).prCountsByAuthor(login: 'octocat', repos: const []);

      expect(counts, (open: 0, draft: 0, merged: 0, closed: 0));
      expect(fake.requests, isEmpty);
    });
  });

  group('GitHubPrClient.searchClosedPullRequestsByAuthor', () {
    test('decodes items and reports hasMore from the Link header', () async {
      final fake = TestHttpClient(
        handler: (request) => httpTextResponse(
          request,
          {
            'total_count': 250,
            'items': [
              {
                'number': 1,
                'title': 'merged one',
                'state': 'closed',
                // `/search/issues` nests the merge timestamp under
                // `pull_request`; the model recovers it so this reads as merged.
                'pull_request': {'merged_at': '2024-01-01T00:00:00Z'},
              },
              {'number': 2, 'title': 'closed one', 'state': 'closed'},
            ],
          },
          headers: {'link': '<https://api.github.com/x?page=2>; rel="next"'},
        ),
      );

      final page = await GitHubPrClient(
        fake,
        redirectlessHttpClient: fake,
      ).searchClosedPullRequestsByAuthor('o', 'r', 'octocat');

      expect(page.items.length, 2);
      expect(page.hasMore, isTrue);
      expect(page.items.first.mergedAt, isNotNull, reason: 'merged hit');
      expect(page.items[1].mergedAt, isNull, reason: 'plain closed hit');
    });

    test('hasMore is false on the last page (no Link header)', () async {
      final fake = TestHttpClient(
        handler: (request) => httpTextResponse(request, const {
          'total_count': 1,
          'items': <dynamic>[],
        }),
      );

      final page = await GitHubPrClient(
        fake,
        redirectlessHttpClient: fake,
      ).searchClosedPullRequestsByAuthor('o', 'r', 'octocat', page: 3);

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });
}
