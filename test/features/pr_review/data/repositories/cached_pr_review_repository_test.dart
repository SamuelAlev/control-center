import 'dart:async';

import 'package:control_center/core/network/github_api_client.dart';
import 'package:control_center/core/network/github_content_client.dart';
import 'package:control_center/core/network/github_graphql_client.dart';
import 'package:control_center/core/network/github_pr_client.dart';
import 'package:control_center/core/network/models/github_check_run.dart';
import 'package:control_center/core/network/models/github_commit.dart';
import 'package:control_center/core/network/models/github_issue_comment.dart';
import 'package:control_center/core/network/models/github_pull_request.dart';
import 'package:control_center/core/network/models/github_pull_request_file.dart';
import 'package:control_center/core/network/models/github_review.dart';
import 'package:control_center/core/network/models/github_review_comment.dart';
import 'package:control_center/features/pr_review/data/repositories/cached_pr_review_repository.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'mock_spec.mocks.dart';

class _FakeGitHubApiClient implements GitHubApiClient {
  _FakeGitHubApiClient({required this.pr, required this.content});
  @override
  final GitHubPrClient pr;
  @override
  final GitHubContentClient content;
  @override
  GitHubGraphQLClient get graphql => throw UnimplementedError();
}

class _StubDiffSource implements PrDiffSource {
  @override
  Stream<PrFilesLoad> watchFiles(PrSourceRequest req) =>
      Stream.value(const PrFilesLoad(files: [], isComplete: true));

  @override
  Stream<List<PrCommit>> watchCommits(PrSourceRequest req) =>
      Stream.value(const []);

  @override
  Stream<List<PrFile>> watchCommitFiles(PrSourceRequest req, String sha) =>
      Stream.value(const []);
}

GitHubPullRequest _testPR(int number) => GitHubPullRequest(
  number: number,
  title: 'Test PR $number',
  body: 'Test body',
  state: 'open',
  isDraft: false,
  userLogin: 'testuser',
  htmlUrl: 'https://github.com/o/r/pull/$number',
  nodeId: 'node_$number',
  headSha: 'abc123',
  baseRef: 'main',
  headRef: 'feature/test',
  requestedReviewers: const [],
  assignees: const [],
);

void main() {
  late MockCacheDao cacheDao;
  late MockReviewDao draftDao;
  late _FakeGitHubApiClient apiClient;
  late MockGitHubPrClient mockPr;
  late MockGitHubContentClient mockContent;

  setUp(() {
    cacheDao = MockCacheDao();
    draftDao = MockReviewDao();
    mockPr = MockGitHubPrClient();
    mockContent = MockGitHubContentClient();
    apiClient = _FakeGitHubApiClient(pr: mockPr, content: mockContent);
  });

  CachedPrReviewRepository makeRepo() => CachedPrReviewRepository(
    cacheDao: cacheDao,
    draftDao: draftDao,
    gitHubClient: apiClient,
    workspaceId: 'ws1',
    owner: 'o',
    repo: 'r',
    apiDiffSource: _StubDiffSource(),
    localDiffSource: _StubDiffSource(),
  );

  group('EmptyPrReviewRepository', () {
    late EmptyPrReviewRepository repo;

    setUp(() {
      repo = const EmptyPrReviewRepository();
    });

    test('watchPullRequest emits null', () async {
      expect(await repo.watchPullRequest(1).first, isNull);
    });

    test('watchDiff emits empty string', () async {
      expect(await repo.watchDiff(1).first, isEmpty);
    });

    test('watchFiles emits empty list', () async {
      expect(await repo.watchFiles(1).first, isEmpty);
    });

    test('watchFileContent emits empty string', () async {
      expect(await repo.watchFileContent('f', 'ref').first, isEmpty);
    });

    test('watchCommits emits empty list', () async {
      expect(await repo.watchCommits(1).first, isEmpty);
    });

    test('watchCommitFiles emits empty list', () async {
      expect(await repo.watchCommitFiles('sha').first, isEmpty);
    });

    test('watchReviews emits empty list', () async {
      expect(await repo.watchReviews(1).first, isEmpty);
    });

    test('watchReviewComments emits empty list', () async {
      expect(await repo.watchReviewComments(1).first, isEmpty);
    });

    test('watchIssueComments emits empty list', () async {
      expect(await repo.watchIssueComments(1).first, isEmpty);
    });

    test('watchCheckRuns emits empty list', () async {
      expect(await repo.watchCheckRuns(1).first, isEmpty);
    });

    test('invalidatePullRequest completes', () async {
      await repo.invalidatePullRequest(1);
    });
  });

  group('CachedPrReviewRepository - watchPullRequest', () {
    test('caches and returns stale then fresh data', () async {
      final testPR = _testPR(42);
      when(cacheDao.read('ws1', 'prDetail', '42')).thenAnswer(
        (_) async =>
            '{"number":42,"title":"Cached PR","body":"","state":"open","draft":false,"user":{"login":"cached","avatar_url":""},"html_url":"","node_id":"n","head":{"sha":"aaa","ref":"f"},"base":{"ref":"m"},"requested_reviewers":[],"assignees":[]}',
      );
      when(
        mockPr.getPullRequest(
          'o',
          'r',
          42,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => testPR);

      final results = await makeRepo().watchPullRequest(42).toList();
      expect(results.length, 2);
      expect(results[0]!.title, 'Cached PR');
      expect(results[1]!.title, 'Test PR 42');
    });

    test('emits only fresh data when no cache', () async {
      final testPR = _testPR(1);
      when(cacheDao.read('ws1', 'prDetail', '1')).thenAnswer((_) async => null);
      when(
        mockPr.getPullRequest(
          'o',
          'r',
          1,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => testPR);

      final results = await makeRepo().watchPullRequest(1).toList();
      expect(results.length, 1);
      expect(results[0]!.number, 1);
    });

    test('swallows network error when cache exists', () async {
      when(cacheDao.read('ws1', 'prDetail', '1')).thenAnswer(
        (_) async =>
            '{"number":1,"title":"Cached","body":"","state":"open","draft":false,"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n","head":{"sha":"a","ref":"f"},"base":{"ref":"m"},"requested_reviewers":[],"assignees":[]}',
      );
      when(
        mockPr.getPullRequest(
          'o',
          'r',
          1,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenThrow(Exception('Network error'));

      final results = await makeRepo().watchPullRequest(1).toList();
      expect(results.length, 1);
      expect(results[0]!.title, 'Cached');
    });

    test('corrupt cache falls through to fetch', () async {
      final testPR = _testPR(99);
      when(
        cacheDao.read('ws1', 'prDetail', '99'),
      ).thenAnswer((_) async => '{invalid json');
      when(
        mockPr.getPullRequest(
          'o',
          'r',
          99,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => testPR);

      final results = await makeRepo().watchPullRequest(99).toList();
      expect(results.length, 1);
      expect(results[0]!.number, 99);
    });
  });

  group('CachedPrReviewRepository - request cancellation', () {
    test('cancelling the subscription cancels the in-flight request', () async {
      // Simulates navigating away from a PR: the autoDispose provider tears
      // down and cancels its subscription, which must abort the in-flight GET.
      // The mock mirrors dio: cancelling the token completes the request with a
      // cancel error (a real CancelToken.whenCancel does exactly this).
      CancelToken? captured;
      // A cached value means the swallowed cancel error doesn't surface as a
      // stream error (matches _swr: errors are swallowed when a cache exists).
      when(cacheDao.read('ws1', 'prDetail', '7')).thenAnswer(
        (_) async =>
            '{"number":7,"title":"Cached","body":"","state":"open","draft":false,"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n","head":{"sha":"a","ref":"f"},"base":{"ref":"m"},"requested_reviewers":[],"assignees":[]}',
      );
      when(
        mockPr.getPullRequest('o', 'r', 7, cancelToken: anyNamed('cancelToken')),
      ).thenAnswer((inv) {
        final token = inv.namedArguments[#cancelToken] as CancelToken?;
        captured = token;
        final completer = Completer<GitHubPullRequest?>();
        token?.whenCancel.then((_) {
          if (!completer.isCompleted) {
            completer.completeError(
              DioException(
                requestOptions: RequestOptions(path: ''),
                type: DioExceptionType.cancel,
              ),
            );
          }
        });
        return completer.future; // request stays in flight until cancelled
      });

      final sub = makeRepo().watchPullRequest(7).listen((_) {});
      // Let the stream start, emit the cached value, and reach the live fetch.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(captured, isNotNull, reason: 'fetch should have started');
      expect(captured!.isCancelled, isFalse);

      await sub.cancel();
      expect(
        captured!.isCancelled,
        isTrue,
        reason: 'cancelling the subscription must cancel the request token',
      );
    });
  });

  group('CachedPrReviewRepository - watchDiff', () {
    test('caches and returns stale then fresh diff', () async {
      when(
        cacheDao.read('ws1', 'prDiff', '42'),
      ).thenAnswer((_) async => 'cached diff');
      when(
        mockPr.getPullRequestDiff(
          'o',
          'r',
          42,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => 'fresh diff');

      final results = await makeRepo().watchDiff(42).toList();
      expect(results, ['cached diff', 'fresh diff']);
    });
  });

  group('CachedPrReviewRepository - watchFiles', () {
    test('caches and returns stale then fresh files', () async {
      when(cacheDao.read('ws1', 'prFiles', '1')).thenAnswer(
        (_) async =>
            '[{"filename":"src/cached.dart","status":"added","additions":5,"deletions":0,"changes":5,"patch":""}]',
      );

      final results = await makeRepo().watchFiles(1).toList();
      expect(results.length, 1);
      expect(results[0][0].filename, 'src/cached.dart');
    });
  });

  group('CachedPrReviewRepository - watchCommits', () {
    test('caches and returns stale then fresh commits', () async {
      const freshCommit = GitHubCommit(
        sha: 'abc',
        message: 'fix: thing',
        authorName: 'Dev',
        authorEmail: 'dev@test.com',
      );
      when(cacheDao.read('ws1', 'prCommits', '1')).thenAnswer(
        (_) async =>
            '[{"sha":"cached","commit":{"message":"old","author":{"name":"C","email":"c@t.com"}},"author":null}]',
      );
      when(
        mockPr.listAllPullRequestCommits(
          'o',
          'r',
          1,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => [freshCommit]);

      final results = await makeRepo().watchCommits(1).toList();
      expect(results.length, 2);
      expect(results[0][0].sha, 'cached');
      expect(results[1][0].sha, 'abc');
    });
  });

  group('CachedPrReviewRepository - watchCommitFiles', () {
    test('returns empty list for empty sha', () async {
      final results = await makeRepo().watchCommitFiles('').toList();
      expect(results, [const <GitHubPullRequestFile>[]]);
    });
  });

  group('CachedPrReviewRepository - watchReviews', () {
    test('caches and returns stale then fresh reviews', () async {
      const freshReview = GitHubReview(
        id: 5,
        state: GitHubReviewState.approved,
        body: 'LGTM',
        submittedAt: null,
      );
      when(
        cacheDao.read('ws1', 'prReviews', '1'),
      ).thenAnswer((_) async => '[{"id":3,"state":"COMMENTED","body":"ok"}]');
      when(
        mockPr.listPullRequestReviews(
          'o',
          'r',
          1,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => [freshReview]);

      final results = await makeRepo().watchReviews(1).toList();
      expect(results.length, 2);
      expect(results[0][0].body, 'ok');
      expect(results[1][0].body, 'LGTM');
    });
  });

  group('CachedPrReviewRepository - watchReviewComments', () {
    test('caches and returns stale then fresh comments', () async {
      const freshComment = GitHubReviewComment(
        id: 10,
        body: 'nit',
        path: 'f.dart',
        diffHunk: '@@',
      );
      when(cacheDao.read('ws1', 'prReviewComments', '1')).thenAnswer(
        (_) async =>
            '[{"id":8,"body":"cached comment","path":"f.dart","diff_hunk":"@@"}]',
      );
      when(
        mockPr.listPullRequestReviewComments(
          'o',
          'r',
          1,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => [freshComment]);

      final results = await makeRepo().watchReviewComments(1).toList();
      expect(results.length, 2);
      expect(results[0][0].id, 8);
      expect(results[1][0].id, 10);
    });
  });

  group('CachedPrReviewRepository - watchIssueComments', () {
    test('caches and returns stale then fresh comments', () async {
      const freshComment = GitHubIssueComment(id: 20, body: 'looks good');
      when(
        cacheDao.read('ws1', 'prIssueComments', '1'),
      ).thenAnswer((_) async => '[{"id":15,"body":"cached issue comment"}]');
      when(
        mockPr.listIssueComments(
          'o',
          'r',
          1,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => [freshComment]);

      final results = await makeRepo().watchIssueComments(1).toList();
      expect(results.length, 2);
      expect(results[0][0].id, 15);
      expect(results[1][0].id, 20);
    });
  });

  group('CachedPrReviewRepository - watchCheckRuns', () {
    test('emits empty list when sha is null', () async {
      when(
        cacheDao.read('ws1', 'prDetail', '999'),
      ).thenAnswer((_) async => null);
      when(
        mockPr.getPullRequest(
          'o',
          'r',
          999,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => null);

      final results = await makeRepo().watchCheckRuns(999).toList();
      expect(results, [const <GitHubCheckRun>[]]);
    });
  });

  group('CachedPrReviewRepository - invalidatePullRequest', () {
    test('invalidates all PR-scoped entries', () async {
      await makeRepo().invalidatePullRequest(42);
      verify(cacheDao.deleteEntry('ws1', 'prDetail', '42')).called(1);
      verify(cacheDao.deleteEntry('ws1', 'prDiff', '42')).called(1);
      verify(cacheDao.deleteEntry('ws1', 'prFiles', '42')).called(1);
      verify(cacheDao.deleteEntry('ws1', 'prCommits', '42')).called(1);
      verify(cacheDao.deleteEntry('ws1', 'prReviews', '42')).called(1);
      verify(cacheDao.deleteEntry('ws1', 'prReviewComments', '42')).called(1);
      verify(cacheDao.deleteEntry('ws1', 'prIssueComments', '42')).called(1);
      verify(cacheDao.deleteEntry('ws1', 'prCheckRuns', '42')).called(1);
    });
  });

  group('CachedPrReviewRepository - watchCheckRuns with cached sha', () {
    test('uses cached PR head sha for check runs', () async {
      when(cacheDao.read('ws1', 'prDetail', '42')).thenAnswer(
        (_) async =>
            '{"number":42,"title":"PR","body":"","state":"open","draft":false,"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n","head":{"sha":"head-sha-123","ref":"f"},"base":{"ref":"m"},"requested_reviewers":[],"assignees":[]}',
      );
      when(
        cacheDao.read('ws1', 'prCheckRuns', 'head-sha-123'),
      ).thenAnswer((_) async => null);
      when(
        mockPr.listCheckRuns(
          'o',
          'r',
          'head-sha-123',
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => []);
      when(
        mockPr.getPullRequest(
          'o',
          'r',
          42,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => _testPR(42));

      final results = await makeRepo().watchCheckRuns(42).toList();
      expect(results, [const <GitHubCheckRun>[]]);
    });
  });

  group('CachedPrReviewRepository - watchDiff with skipRevalidate', () {
    test('reuses cache when head sha unchanged', () async {
      when(
        cacheDao.read('ws1', 'prDiff', '42'),
      ).thenAnswer((_) async => 'cached diff content');
      when(cacheDao.read('ws1', 'prDetail', '42')).thenAnswer(
        (_) async =>
            '{"number":42,"title":"PR","body":"","state":"open","draft":false,"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n","head":{"sha":"abc123","ref":"f"},"base":{"ref":"m"},"requested_reviewers":[],"assignees":[]}',
      );
      when(
        mockPr.getPullRequest(
          'o',
          'r',
          42,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => _testPR(42));

      final results = await makeRepo().watchDiff(42).toList();
      expect(results, ['cached diff content']);
    });

    test('fetches fresh diff when head sha changed', () async {
      when(
        cacheDao.read('ws1', 'prDiff', '42'),
      ).thenAnswer((_) async => 'old diff');
      when(cacheDao.read('ws1', 'prDetail', '42')).thenAnswer(
        (_) async =>
            '{"number":42,"title":"PR","body":"","state":"open","draft":false,"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n","head":{"sha":"old-sha","ref":"f"},"base":{"ref":"m"},"requested_reviewers":[],"assignees":[]}',
      );
      const changedPR = GitHubPullRequest(
        number: 42,
        title: 'PR',
        body: '',
        state: 'open',
        isDraft: false,
        userLogin: 'u',
        htmlUrl: '',
        nodeId: 'n',
        headSha: 'new-sha',
        baseRef: 'm',
        headRef: 'f',
        requestedReviewers: [],
        assignees: [],
      );
      when(
        mockPr.getPullRequest(
          'o',
          'r',
          42,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => changedPR);
      when(
        mockPr.getPullRequestDiff(
          'o',
          'r',
          42,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => 'fresh diff');

      final results = await makeRepo().watchDiff(42).toList();
      expect(results, ['old diff', 'fresh diff']);
    });
  });

  group('CachedPrReviewRepository - watchFiles with skipRevalidate', () {
    test('reuses cache when head sha unchanged', () async {
      when(cacheDao.read('ws1', 'prFiles', '42')).thenAnswer(
        (_) async =>
            '[{"filename":"cached.dart","status":"modified","additions":1,"deletions":0,"patch":""}]',
      );
      when(cacheDao.read('ws1', 'prDetail', '42')).thenAnswer(
        (_) async =>
            '{"number":42,"title":"PR","body":"","state":"open","draft":false,"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n","head":{"sha":"sha-match","ref":"f"},"base":{"ref":"m"},"requested_reviewers":[],"assignees":[]}',
      );
      const matchingPR = GitHubPullRequest(
        number: 42,
        title: 'PR',
        body: '',
        state: 'open',
        isDraft: false,
        userLogin: 'u',
        htmlUrl: '',
        nodeId: 'n',
        headSha: 'sha-match',
        baseRef: 'm',
        headRef: 'f',
        requestedReviewers: [],
        assignees: [],
      );
      when(
        mockPr.getPullRequest(
          'o',
          'r',
          42,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => matchingPR);

      final results = await makeRepo().watchFiles(42).toList();
      expect(results.length, 1);
      expect(results[0][0].filename, 'cached.dart');
    });
  });

  group('CachedPrReviewRepository - watchFileContent', () {
    test('caches and returns file content', () async {
      when(
        cacheDao.read('ws1', 'prFileContent', 'src/a.dart|main'),
      ).thenAnswer((_) async => 'cached content');
      when(
        mockContent.getFileContent(
          'o',
          'r',
          'src/a.dart',
          'main',
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => 'fresh content');

      final results = await makeRepo()
          .watchFileContent('src/a.dart', 'main')
          .toList();
      expect(results, ['cached content', 'fresh content']);
    });
  });

  group('CachedPrReviewRepository - watchCommitFiles', () {
    test('returns cached then fresh commit files', () async {
      when(cacheDao.read('ws1', 'prCommitFiles', 'abc')).thenAnswer(
        (_) async =>
            '[{"filename":"cached.dart","status":"added","additions":1,"deletions":0,"patch":""}]',
      );
      when(
        mockPr.getCommitFiles(
          'o',
          'r',
          'abc',
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => []);

      final results = await makeRepo().watchCommitFiles('abc').toList();
      expect(results.length, 2);
    });
  });

  group('CachedPrReviewRepository - draft methods', () {
    test('upsertDraft delegates to draftDao', () async {
      await makeRepo().upsertDraft(1, 'my draft');
      verify(draftDao.upsertDraft('o', 'r', 1, 'my draft')).called(1);
    });

    test('getDraft delegates to draftDao', () async {
      when(
        draftDao.getDraft('o', 'r', 1),
      ).thenAnswer((_) async => 'saved draft');
      final result = await makeRepo().getDraft(1);
      expect(result, 'saved draft');
    });

    test('getDraft returns null when no draft', () async {
      when(draftDao.getDraft('o', 'r', 1)).thenAnswer((_) async => null);
      final result = await makeRepo().getDraft(1);
      expect(result, isNull);
    });

    test('clearDraft delegates to draftDao', () async {
      await makeRepo().clearDraft(1);
      verify(draftDao.clearDraft('o', 'r', 1)).called(1);
    });
  });

  group('CachedPrReviewRepository - _decodeJsonList edge cases', () {
    test('watchPullRequest handles null json map', () async {
      when(
        cacheDao.read('ws1', 'prDetail', '999'),
      ).thenAnswer((_) async => 'not a json object');
      when(
        mockPr.getPullRequest(
          'o',
          'r',
          999,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => null);

      final results = await makeRepo().watchPullRequest(999).toList();
      expect(results, [isNull]);
    });

    test('watchFiles handles non-list json', () async {
      when(
        cacheDao.read('ws1', 'prFiles', '999'),
      ).thenAnswer((_) async => '{"not": "a list"}');
      when(
        mockPr.listPullRequestFiles(
          'o',
          'r',
          999,
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer((_) async => []);

      final stream = makeRepo().watchFiles(999);
      final results = await stream.toList();
      expect(results, const <List<GitHubPullRequestFile>>[]);
    });
  });
}
