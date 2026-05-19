import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_search_query.dart';
import 'package:cc_infra/src/git/github_pr_search_adapter.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, {int status = 200}) => ResponseBody.fromString(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Repo _repo({String id = 'r1', String owner = 'acme', String name = 'widget'}) =>
    Repo(
      id: id,
      name: name,
      path: '/tmp/$name',
      githubOwner: owner,
      githubRepoName: name,
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
    );

Map<String, dynamic> _node({
  required int number,
  required String title,
  required String repoFullName,
  String updatedAt = '2025-01-02T00:00:00Z',
}) => {
  'number': number,
  'title': title,
  'updatedAt': updatedAt,
  'repository': {'nameWithOwner': repoFullName},
  'author': {'login': 'octocat'},
};

Map<String, dynamic> _envelope(List<Map<String, dynamic>> nodes) => {
  'data': {
    'search': {'nodes': nodes},
  },
};

GitHubApiClient _client(Object? Function() body) {
  final fake = _FakeAdapter((_) => _json(body()));
  final dio = Dio()..httpClientAdapter = fake;
  return GitHubApiClient(dio);
}

void main() {
  group('GitHubPrSearchAdapter.search', () {
    test('returns empty when query is inactive', () async {
      final client = _client(() => {'unexpected': true});
      final adapter = GitHubPrSearchAdapter(client);

      final result = await adapter.search(
        query: const PrSearchQuery(),
        repos: [_repo()],
      );

      expect(result, isEmpty);
    });

    test('returns empty when repos list is empty', () async {
      final client = _client(() => {'unexpected': true});
      final adapter = GitHubPrSearchAdapter(client);

      final result = await adapter.search(
        query: PrSearchQuery.parse('feature'),
        repos: const [],
      );

      expect(result, isEmpty);
    });

    test('maps matching nodes back to their repos', () async {
      final client = _client(
        () => _envelope([
          _node(number: 7, title: 'Feature', repoFullName: 'acme/widget'),
          _node(number: 8, title: 'Fix', repoFullName: 'acme/widget'),
        ]),
      );
      final adapter = GitHubPrSearchAdapter(client);

      final result = await adapter.search(
        query: PrSearchQuery.parse('feature'),
        repos: [_repo()],
      );

      expect(result, hasLength(1));
      expect(result.single.repo.id, 'r1');
      expect(result.single.prs.map((p) => p.number), [7, 8]);
    });

    test('drops nodes without a number or title', () async {
      final client = _client(
        () => _envelope([
          _node(number: 0, title: 'Zero', repoFullName: 'acme/widget'),
          _node(number: 5, title: '', repoFullName: 'acme/widget'),
          _node(number: 9, title: 'Ok', repoFullName: 'acme/widget'),
        ]),
      );
      final adapter = GitHubPrSearchAdapter(client);

      final result = await adapter.search(
        query: PrSearchQuery.parse('x'),
        repos: [_repo()],
      );

      expect(result.single.prs, hasLength(1));
      expect(result.single.prs.single.number, 9);
    });

    test('drops nodes whose repository is not in the input repos', () async {
      final client = _client(
        () => _envelope([
          _node(number: 1, title: 'A', repoFullName: 'acme/widget'),
          _node(number: 2, title: 'B', repoFullName: 'other/repo'),
        ]),
      );
      final adapter = GitHubPrSearchAdapter(client);

      final result = await adapter.search(
        query: PrSearchQuery.parse('x'),
        repos: [_repo()],
      );

      expect(result.single.prs.single.number, 1);
    });

    test('groups results across multiple repos', () async {
      final client = _client(
        () => _envelope([
          _node(number: 1, title: 'A', repoFullName: 'acme/widget'),
          _node(number: 2, title: 'B', repoFullName: 'acme/gadget'),
        ]),
      );
      final adapter = GitHubPrSearchAdapter(client);

      final result = await adapter.search(
        query: PrSearchQuery.parse('x'),
        repos: [
          _repo(id: 'r1', owner: 'acme', name: 'widget'),
          _repo(id: 'r2', owner: 'acme', name: 'gadget'),
        ],
      );

      expect(result, hasLength(2));
      final byRepo = {for (final r in result) r.repo.id: r.prs.single.number};
      expect(byRepo['r1'], 1);
      expect(byRepo['r2'], 2);
    });

    test('omits repos with no matching PRs', () async {
      final client = _client(
        () => _envelope([
          _node(number: 1, title: 'A', repoFullName: 'acme/widget'),
        ]),
      );
      final adapter = GitHubPrSearchAdapter(client);

      final result = await adapter.search(
        query: PrSearchQuery.parse('x'),
        repos: [
          _repo(id: 'r1', owner: 'acme', name: 'widget'),
          _repo(id: 'r2', owner: 'acme', name: 'gadget'),
        ],
      );

      expect(result, hasLength(1));
      expect(result.single.repo.id, 'r1');
    });

    test('sorts PRs within a repo by updatedAt descending', () async {
      final client = _client(
        () => _envelope([
          _node(
            number: 1,
            title: 'Older',
            repoFullName: 'acme/widget',
            updatedAt: '2025-01-01T00:00:00Z',
          ),
          _node(
            number: 2,
            title: 'Newer',
            repoFullName: 'acme/widget',
            updatedAt: '2025-02-01T00:00:00Z',
          ),
        ]),
      );
      final adapter = GitHubPrSearchAdapter(client);

      final result = await adapter.search(
        query: PrSearchQuery.parse('x'),
        repos: [_repo()],
      );

      expect(result.single.prs.map((p) => p.number).toList(), [2, 1]);
    });

    test('sorts repos by their top PR updatedAt descending', () async {
      final client = _client(
        () => _envelope([
          _node(
            number: 1,
            title: 'A',
            repoFullName: 'acme/widget',
            updatedAt: '2025-01-01T00:00:00Z',
          ),
          _node(
            number: 2,
            title: 'B',
            repoFullName: 'acme/gadget',
            updatedAt: '2025-02-01T00:00:00Z',
          ),
        ]),
      );
      final adapter = GitHubPrSearchAdapter(client);

      final result = await adapter.search(
        query: PrSearchQuery.parse('x'),
        repos: [
          _repo(id: 'r1', owner: 'acme', name: 'widget'),
          _repo(id: 'r2', owner: 'acme', name: 'gadget'),
        ],
      );

      // gadget has the newer top PR, so it sorts first.
      expect(result.first.repo.id, 'r2');
      expect(result.last.repo.id, 'r1');
    });

    test('repo name match is case-insensitive', () async {
      final client = _client(
        () => _envelope([
          _node(number: 1, title: 'A', repoFullName: 'ACME/Widget'),
        ]),
      );
      final adapter = GitHubPrSearchAdapter(client);

      final result = await adapter.search(
        query: PrSearchQuery.parse('x'),
        repos: [_repo(owner: 'acme', name: 'widget')],
      );

      expect(result.single.prs.single.number, 1);
    });

    test('handles missing search nodes gracefully (returns empty)', () async {
      final client = _client(() => {'data': {}});
      final adapter = GitHubPrSearchAdapter(client);

      final result = await adapter.search(
        query: PrSearchQuery.parse('x'),
        repos: [_repo()],
      );

      expect(result, isEmpty);
    });

    test('pull request carries the repo fullName', () async {
      final client = _client(
        () => _envelope([
          _node(number: 3, title: 'T', repoFullName: 'acme/widget'),
        ]),
      );
      final adapter = GitHubPrSearchAdapter(client);

      final result = await adapter.search(
        query: PrSearchQuery.parse('x'),
        repos: [_repo()],
      );

      expect(result.single.prs.single.repoFullName, 'acme/widget');
      expect(result.single.prs.single.title, 'T');
      expect(result.single.prs.single.state, PrState.open);
    });

    test(
      'passes author qualifiers and repo scope to the GraphQL client',
      () async {
        late RequestOptions captured;
        final fake = _FakeAdapter((options) {
          captured = options;
          return _json(_envelope([]));
        });
        final dio = Dio()..httpClientAdapter = fake;
        final client = GitHubApiClient(dio);
        final adapter = GitHubPrSearchAdapter(client);

        await adapter.search(
          query: PrSearchQuery.parse('author:octocat foo'),
          repos: [_repo()],
        );

        // Confirm the request hit the GraphQL endpoint with a query body.
        expect(captured.path, contains('/graphql'));
        final body = captured.data as Map;
        final variables = body['variables'] as Map;
        final q = variables['q'] as String;
        expect(q, contains('repo:acme/widget'));
        expect(q, contains('author:octocat'));
        expect(q, contains('foo'));
      },
    );
  });
}
