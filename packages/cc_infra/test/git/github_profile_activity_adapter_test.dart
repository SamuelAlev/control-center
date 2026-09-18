import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_infra/src/git/github_profile_activity_adapter.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = options.data as Map<String, dynamic>;
    final variables = body['variables'] as Map;
    if (variables.containsKey('open')) {
      return _json({
        'data': {
          'open': {'issueCount': 1},
          'draft': {'issueCount': 0},
          'merged': {'issueCount': 2},
          'closed': {'issueCount': 1},
        },
      });
    }
    return _json({
      'data': {
        'search': {
          'issueCount': 1001,
          'nodes': [
            _node(number: 1, state: 'OPEN', additions: 8, deletions: 2),
            _node(
              number: 2,
              state: 'MERGED',
              additions: 15,
              deletions: 5,
              mergedAt: '2026-01-01T04:00:00Z',
              reviewedAt: '2026-01-01T01:00:00Z',
            ),
            _node(
              number: 3,
              state: 'MERGED',
              additions: 60,
              deletions: 40,
              mergedAt: '2026-01-01T10:00:00Z',
            ),
          ],
          'pageInfo': {'hasNextPage': false},
        },
      },
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _node({
  required int number,
  required String state,
  required int additions,
  required int deletions,
  String? mergedAt,
  String? reviewedAt,
}) => {
  'number': number,
  'title': 'PR $number',
  'state': state,
  'isDraft': false,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': mergedAt ?? '2026-01-01T02:00:00Z',
  'mergedAt': mergedAt,
  'url': 'https://github.com/acme/app/pull/$number',
  'id': 'PR_$number',
  'baseRefName': 'main',
  'headRefName': 'change-$number',
  'headRefOid': 'sha-$number',
  'author': {'login': 'ada', 'avatarUrl': ''},
  'additions': additions,
  'deletions': deletions,
  'comments': {'totalCount': 0},
  'reviews': {
    'nodes': [
      if (reviewedAt != null)
        {
          'author': {'login': 'grace'},
          'submittedAt': reviewedAt,
        },
    ],
  },
  'repository': {'nameWithOwner': 'acme/app'},
};

ResponseBody _json(Object body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  test(
    'computes nearest-rank delivery percentiles from the detailed sample',
    () async {
      final fake = _FakeAdapter();
      final dio = Dio()..httpClientAdapter = fake;
      final adapter = GitHubProfileActivityAdapter(GitHubApiClient(dio));
      final repo = Repo(
        id: 'repo-1',
        name: 'acme/app',
        path: '/repos/acme/app',
        remoteOwner: 'acme',
        remoteName: 'app',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final activity = await adapter.fetch(repos: [repo], logins: ['ada']);

      expect(fake.requests, hasLength(2));
      expect(activity.metrics.total, 4);
      expect(activity.metrics.analyzedPullRequests, 3);
      expect(activity.metrics.resultsTruncated, isTrue);
      expect(activity.metrics.medianLinesChanged, 20);
      expect(activity.metrics.p90LinesChanged, 100);
      expect(activity.metrics.medianHoursToMerge, 4);
      expect(activity.metrics.p90HoursToMerge, 10);
      expect(activity.metrics.medianHoursToFirstReview, 1);
      expect(activity.metrics.reviewCoveragePercent, 50);
      expect(activity.metrics.mergeRatePercent, closeTo(66.67, 0.01));
      expect(activity.repos.single.repoId, 'repo-1');
      expect(activity.repos.single.prs.map((pr) => pr.number), [3, 2, 1]);
    },
  );
}
