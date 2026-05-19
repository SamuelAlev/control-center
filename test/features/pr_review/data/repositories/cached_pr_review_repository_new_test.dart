import 'dart:async';

import 'package:control_center/core/database/daos/cache_dao.dart';
import 'package:control_center/core/database/daos/review_dao.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/pr_events.dart';
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
import 'package:control_center/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/features/pr_review/domain/entities/issue_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

// ===========================================================================
// Fake CacheDao — extends the real class with in-memory storage.
// The test database is only used to satisfy the type system; all methods
// are overridden so the real database is never touched.
// ===========================================================================
class FakeCacheDao extends CacheDao {
  FakeCacheDao() : super(createTestDatabase());

  final Map<String, String> _store = {};

  String _makeKey(String workspaceId, String kind, String key) =>
      '$workspaceId|$kind|$key';

  @override
  Future<String?> read(String workspaceId, String kind, String key) async =>
      _store[_makeKey(workspaceId, kind, key)];

  @override
  Future<void> put(
    String workspaceId,
    String kind,
    String key,
    String payload,
  ) async {
    _store[_makeKey(workspaceId, kind, key)] = payload;
  }

  @override
  Future<void> deleteEntry(
    String workspaceId,
    String kind,
    String key,
  ) async {
    _store.remove(_makeKey(workspaceId, kind, key));
  }

  @override
  Future<void> deleteKind(String workspaceId, String kind) async {
    final prefix = '$workspaceId|$kind|';
    _store.removeWhere((k, _) => k.startsWith(prefix));
  }

  @override
  Future<void> deleteKindWithPrefix(
    String workspaceId,
    String kind,
    String keyPrefix,
  ) async {
    final prefix = '$workspaceId|$kind|$keyPrefix';
    _store.removeWhere((k, _) => k.startsWith(prefix));
  }
}

// ===========================================================================
// Fake ReviewDao — same pattern
// ===========================================================================
class FakeReviewDao extends ReviewDao {
  FakeReviewDao() : super(createTestDatabase());

  final Map<String, String> _drafts = {};

  @override
  Future<void> upsertDraft(
    String owner,
    String repo,
    int prNumber,
    String commentText,
  ) async {
    _drafts['$owner/$repo/$prNumber'] = commentText;
  }

  @override
  Future<String?> getDraft(String owner, String repo, int prNumber) async =>
      _drafts['$owner/$repo/$prNumber'];

  @override
  Future<void> clearDraft(String owner, String repo, int prNumber) async {
    _drafts.remove('$owner/$repo/$prNumber');
  }
}

// ===========================================================================
// FakeGitHubPrClient — in-memory PR client
// ===========================================================================
class FakeGitHubPrClient extends GitHubPrClient {
  FakeGitHubPrClient() : super(_fakeDio);

  static final _fakeDio = _NullDio();

  final Map<String, GitHubPullRequest> pullRequests = {};
  final Map<String, String> diffs = {};
  final Map<String, List<GitHubPullRequestFile>> files = {};
  final Map<String, List<GitHubCommit>> commits = {};
  final Map<String, List<GitHubPullRequestFile>> commitFiles = {};
  final Map<String, List<GitHubReview>> reviews = {};
  final Map<String, List<GitHubReviewComment>> reviewComments = {};
  final Map<String, List<GitHubIssueComment>> issueComments = {};
  final Map<String, List<GitHubCheckRun>> checkRuns = {};

  /// Set to cause [getPullRequest] to throw.
  Object? getPullRequestError;
  Object? diffError;
  @override
  Future<GitHubPullRequest?> getPullRequest(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    if (getPullRequestError != null) {
      throw getPullRequestError!;
    }
    return pullRequests['$owner/$repo/$number'];
  }

  @override
  Future<String> getPullRequestDiff(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    if (diffError != null) {
      throw diffError!;
    }
    return diffs['$owner/$repo/$number'] ?? '';
  }

  @override
  Future<List<GitHubPullRequestFile>> listPullRequestFiles(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async =>
      files['$owner/$repo/$number'] ?? const [];

  @override
  Future<List<GitHubCommit>> listAllPullRequestCommits(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async =>
      commits['$owner/$repo/$number'] ?? const [];

  @override
  Future<List<GitHubPullRequestFile>> getCommitFiles(
    String owner,
    String repo,
    String sha, {
    CancelToken? cancelToken,
  }) async =>
      commitFiles['$owner/$repo/$sha'] ?? const [];

  /// Records each submitted review event so tests can assert what was sent.
  final List<String> submittedReviewEvents = [];

  @override
  Future<GitHubReview> submitReview(
    String owner,
    String repo, {
    required int prNumber,
    required String event,
    String? body,
    String? commitId,
    List<Map<String, dynamic>>? comments,
    CancelToken? cancelToken,
  }) async {
    submittedReviewEvents.add(event);
    return GitHubReview(
      id: 0,
      state: GitHubReviewState.approved,
      body: body ?? '',
      submittedAt: DateTime(2025),
    );
  }

  @override
  Future<List<GitHubReview>> listPullRequestReviews(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async =>
      reviews['$owner/$repo/$number'] ?? const [];

  @override
  Future<List<GitHubReviewComment>> listPullRequestReviewComments(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async =>
      reviewComments['$owner/$repo/$number'] ?? const [];

  @override
  Future<List<GitHubIssueComment>> listIssueComments(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async =>
      issueComments['$owner/$repo/$number'] ?? const [];

  @override
  Future<List<GitHubCheckRun>> listCheckRuns(
    String owner,
    String repo,
    String ref, {
    CancelToken? cancelToken,
  }) async =>
      checkRuns['$owner/$repo/$ref'] ?? const [];
}

// ===========================================================================
// FakeGitHubContentClient — minimal implementation
// ===========================================================================
class FakeGitHubContentClient extends GitHubContentClient {
  FakeGitHubContentClient() : super(_fakeDio);

  static final _fakeDio = _NullDio();

  final Map<String, String> fileContents = {};

  @override
  Future<String> getFileContent(
    String owner,
    String repo,
    String path,
    String ref, {
    CancelToken? cancelToken,
  }) async =>
      fileContents['$owner/$repo/$path|$ref'] ?? '';
}

// ===========================================================================
// FakeGitHubApiClient — facade wrapping the fake sub-clients
// ===========================================================================
class FakeGitHubApiClient implements GitHubApiClient {
  FakeGitHubApiClient({required this.pr, required this.content});

  @override
  final FakeGitHubPrClient pr;

  @override
  final FakeGitHubContentClient content;

  @override
  GitHubGraphQLClient get graphql => throw UnimplementedError();
}

// ===========================================================================
// FakePrDiffSource — stub diff source
// ===========================================================================
class FakePrDiffSource implements PrDiffSource {
  FakePrDiffSource({this.files, this.error});

  final List<PrFile>? files;
  final Object? error;

  @override
  Stream<PrFilesLoad> watchFiles(PrSourceRequest req) async* {
    if (error != null) {
      throw error!;
    }
    if (files != null) {
      yield PrFilesLoad(files: files!, isComplete: true);
    } else {
      yield const PrFilesLoad(files: []);
    }
  }

  @override
  Stream<List<PrCommit>> watchCommits(PrSourceRequest req) async* {
    yield const [];
  }

  @override
  Stream<List<PrFile>> watchCommitFiles(PrSourceRequest req, String sha) async* {
    yield const [];
  }
}

// ===========================================================================
// FakePrReviewRepository — simple in-memory implementation of the full
// PrReviewRepository interface, suitable as a test double.
// ===========================================================================
class FakePrReviewRepository implements PrReviewRepository {
  final Map<int, PullRequest> _prs = {};
  final Map<int, String> _diffs = {};
  final Map<int, List<PrFile>> _files = {};
  final Map<String, String> _fileContents = {};
  final Map<int, List<PrCommit>> _commits = {};
  final Map<String, List<PrFile>> _commitFiles = {};
  final Map<int, List<PrReviewSubmission>> _reviews = {};
  final Map<int, List<PrCodeReviewComment>> _reviewComments = {};
  final Map<int, List<IssueComment>> _issueComments = {};
  final Map<int, List<CheckRun>> _checkRuns = {};
  final Map<int, String> _drafts = {};

  int fetchCount = 0;
  int invalidateCount = 0;

  // -- PullRequest -------------------------------------------------------
  @override
  Stream<PullRequest?> watchPullRequest(int prNumber) async* {
    fetchCount++;
    if (_prs.containsKey(prNumber)) {
      yield _prs[prNumber];
    }
  }

  void setPullRequest(int prNumber, PullRequest pr) {
    _prs[prNumber] = pr;
  }

  // -- Diff --------------------------------------------------------------
  @override
  Stream<String> watchDiff(int prNumber) async* {
    if (_diffs.containsKey(prNumber)) {
      yield _diffs[prNumber]!;
    }
  }

  void setDiff(int prNumber, String diff) => _diffs[prNumber] = diff;

  // -- Files --------------------------------------------------------------
  @override
  Stream<List<PrFile>> watchFiles(int prNumber) async* {
    if (_files.containsKey(prNumber)) {
      yield _files[prNumber]!;
    }
  }

  void setFiles(int prNumber, List<PrFile> files) => _files[prNumber] = files;

  // -- File content ------------------------------------------------------
  @override
  Stream<String> watchFileContent(String path, String ref) async* {
    final key = '$path|$ref';
    if (_fileContents.containsKey(key)) {
      yield _fileContents[key]!;
    }
  }

  void setFileContent(String path, String ref, String content) =>
      _fileContents['$path|$ref'] = content;

  // -- Commits -----------------------------------------------------------
  @override
  Stream<List<PrCommit>> watchCommits(int prNumber) async* {
    if (_commits.containsKey(prNumber)) {
      yield _commits[prNumber]!;
    }
  }

  void setCommits(int prNumber, List<PrCommit> commits) =>
      _commits[prNumber] = commits;

  // -- Commit files ------------------------------------------------------
  @override
  Stream<List<PrFile>> watchCommitFiles(String sha) async* {
    if (_commitFiles.containsKey(sha)) {
      yield _commitFiles[sha]!;
    }
  }

  void setCommitFiles(String sha, List<PrFile> files) =>
      _commitFiles[sha] = files;

  // -- Reviews -----------------------------------------------------------
  @override
  Stream<List<PrReviewSubmission>> watchReviews(int prNumber) async* {
    if (_reviews.containsKey(prNumber)) {
      yield _reviews[prNumber]!;
    }
  }

  void setReviews(int prNumber, List<PrReviewSubmission> reviews) =>
      _reviews[prNumber] = reviews;

  // -- Review comments ---------------------------------------------------
  @override
  Stream<List<PrCodeReviewComment>> watchReviewComments(int prNumber) async* {
    if (_reviewComments.containsKey(prNumber)) {
      yield _reviewComments[prNumber]!;
    }
  }

  void setReviewComments(
    int prNumber,
    List<PrCodeReviewComment> comments,
  ) => _reviewComments[prNumber] = comments;

  // -- Issue comments ----------------------------------------------------
  @override
  Stream<List<IssueComment>> watchIssueComments(int prNumber) async* {
    if (_issueComments.containsKey(prNumber)) {
      yield _issueComments[prNumber]!;
    }
  }

  void setIssueComments(int prNumber, List<IssueComment> comments) =>
      _issueComments[prNumber] = comments;

  // -- Check runs --------------------------------------------------------
  @override
  Stream<List<CheckRun>> watchCheckRuns(int prNumber) async* {
    if (_checkRuns.containsKey(prNumber)) {
      yield _checkRuns[prNumber]!;
    }
  }

  void setCheckRuns(int prNumber, List<CheckRun> runs) =>
      _checkRuns[prNumber] = runs;

  // -- Invalidation ------------------------------------------------------
  @override
  Future<void> invalidatePullRequest(int prNumber) async {
    invalidateCount++;
    _prs.remove(prNumber);
    _diffs.remove(prNumber);
    _files.remove(prNumber);
    _commits.remove(prNumber);
    _reviews.remove(prNumber);
    _reviewComments.remove(prNumber);
    _issueComments.remove(prNumber);
    _checkRuns.remove(prNumber);
  }

  @override
  Future<void> invalidateDiff(int prNumber) async {
    _diffs.remove(prNumber);
    _files.remove(prNumber);
  }

  // -- Drafts ------------------------------------------------------------
  @override
  Future<void> upsertDraft(int prNumber, String text) async =>
      _drafts[prNumber] = text;

  @override
  Future<String?> getDraft(int prNumber) async => _drafts[prNumber];

  @override
  Future<void> clearDraft(int prNumber) async => _drafts.remove(prNumber);

  // -- Write stubs -------------------------------------------------------

  @override
  Future<void> markFileAsViewed({
    required int prNumber,
    required String nodeId,
    required String path,
    required bool viewed,
  }) async {}

  @override
  Future<Map<String, dynamic>> postReviewComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
  }) async =>
      <String, dynamic>{};

  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) async {}

  @override
  Future<String> uploadContent(
    String path,
    String base64Content,
    String message,
  ) async =>
      'https://example.com/$path';

  @override
  Future<void> toggleReviewCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) async {}

  @override
  Future<void> toggleIssueCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) async {}

  @override
  Future<void> togglePullRequestReaction({
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) async {}

  @override
  Future<void> submitReview({
    required int prNumber,
    required String event,
    String? body,
  }) async {}

  @override
  Future<Map<String, dynamic>> mergePullRequest({
    required int prNumber,
    required String mergeMethod,
    String? commitTitle,
    String? commitMessage,
  }) async =>
      <String, dynamic>{};

  @override
  Future<void> closePullRequest({required int prNumber}) async {}

  @override
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
  }) async {}

  @override
  Future<void> addAssignees({
    required int prNumber,
    required List<String> logins,
  }) async {}

  @override
  Future<void> removeAssignees({
    required int prNumber,
    required List<String> logins,
  }) async {}

  @override
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
  }) async {}

  @override
  Future<void> removeRequestedReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
  }) async {}

  @override
  Stream<List<PrReviewer>> watchReviewers(int prNumber) async* {
    yield const [];
  }

  @override
  Future<List<PrUser>> listAssignableUsers() async => [];

  @override
  Future<List<PrReviewerCandidate>> listRequestableReviewers() async => [];
}

// ===========================================================================
// _NullDio — Dio that never gets called; all methods are overridden
// ===========================================================================
class _NullDio implements Dio {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ===========================================================================
// Helpers
// ===========================================================================
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
  baseSha: 'base123',
  headRef: 'feature/test',
  requestedReviewers: const [],
  assignees: const [],
);

PullRequest _domainPR({
  required int id,
  required int number,
  required String title,
  String body = '',
  PrState state = PrState.open,
  bool isDraft = false,
  String login = 'u',
  String headSha = 's',
  String baseRef = 'm',
  String headRef = 'f',
}) =>
    PullRequest(
      id: id,
      number: number,
      title: title,
      body: body,
      state: state,
      isDraft: isDraft,
      author: PrUser(login: login, avatarUrl: ''),
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      repoFullName: 'o/r',
      htmlUrl: '',
      nodeId: 'n',
      headSha: headSha,
      baseRef: baseRef,
      headRef: headRef,
    );

CachedPrReviewRepository _makeRepo({
  required FakeCacheDao cacheDao,
  required FakeReviewDao draftDao,
  required FakeGitHubApiClient apiClient,
  String workspaceId = 'ws1',
  PrDiffSource? apiDiffSource,
  PrDiffSource? localDiffSource,
  DomainEventBus? eventBus,
}) =>
    CachedPrReviewRepository(
      cacheDao: cacheDao,
      draftDao: draftDao,
      gitHubClient: apiClient,
      workspaceId: workspaceId,
      owner: 'o',
      repo: 'r',
      apiDiffSource: apiDiffSource ?? FakePrDiffSource(),
      localDiffSource: localDiffSource ?? FakePrDiffSource(),
      eventBus: eventBus,
    );

// ===========================================================================
// Tests
// ===========================================================================
void main() {
  late FakeCacheDao cacheDao;
  late FakeReviewDao draftDao;
  late FakeGitHubPrClient mockPr;
  late FakeGitHubContentClient mockContent;
  late FakeGitHubApiClient apiClient;

  setUp(() {
    cacheDao = FakeCacheDao();
    draftDao = FakeReviewDao();
    mockPr = FakeGitHubPrClient();
    mockContent = FakeGitHubContentClient();
    apiClient = FakeGitHubApiClient(pr: mockPr, content: mockContent);
  });

  // -- submitReview emits approval status -----------------------------------

  group('submitReview approval event', () {
    test('APPROVE publishes PullRequestStatusChanged(approved)', () async {
      final bus = DomainEventBus();
      final events = <PullRequestStatusChanged>[];
      final sub = bus.on<PullRequestStatusChanged>().listen(events.add);
      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
        eventBus: bus,
      );

      await repo.submitReview(prNumber: 7, event: 'APPROVE');
      await Future<void>.delayed(Duration.zero);

      expect(mockPr.submittedReviewEvents, ['APPROVE']);
      expect(events, hasLength(1));
      expect(events.single.status, 'approved');
      expect(events.single.repoFullName, 'o/r');
      expect(events.single.prNumber, 7);
      expect(events.single.workspaceId, 'ws1');

      await sub.cancel();
      bus.dispose();
    });

    test('non-approving reviews do not publish a status change', () async {
      for (final event in ['COMMENT', 'REQUEST_CHANGES']) {
        final bus = DomainEventBus();
        final events = <PullRequestStatusChanged>[];
        final sub = bus.on<PullRequestStatusChanged>().listen(events.add);
        final repo = _makeRepo(
          cacheDao: cacheDao,
          draftDao: draftDao,
          apiClient: apiClient,
          eventBus: bus,
        );

        await repo.submitReview(prNumber: 7, event: event);
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty, reason: '$event must not emit');

        await sub.cancel();
        bus.dispose();
      }
    });
  });

  // -- FakePrReviewRepository tests -----------------------------------------

  group('FakePrReviewRepository', () {
    late FakePrReviewRepository repo;

    setUp(() {
      repo = FakePrReviewRepository();
    });

    test('watchPullRequest emits cached value then closes', () async {
      final pr = _domainPR(id: 1, number: 1, title: 'Cached');
      repo.setPullRequest(1, pr);

      final results = await repo.watchPullRequest(1).toList();
      expect(results, [pr]);
    });

    test('watchPullRequest emits empty when not cached', () async {
      final results = await repo.watchPullRequest(99).toList();
      expect(results, isEmpty);
    });

    test('invalidatePullRequest clears stored PR', () async {
      repo.setPullRequest(42, _domainPR(id: 42, number: 42, title: 'X'));
      expect(repo.invalidateCount, 0);

      await repo.invalidatePullRequest(42);
      expect(repo.invalidateCount, 1);

      final results = await repo.watchPullRequest(42).toList();
      expect(results, isEmpty);
    });

    test('draft get/set/clear round-trip', () async {
      expect(await repo.getDraft(1), isNull);
      await repo.upsertDraft(1, 'hello');
      expect(await repo.getDraft(1), 'hello');
      await repo.clearDraft(1);
      expect(await repo.getDraft(1), isNull);
    });
  });

  // -- Cache hit/miss -------------------------------------------------------

  group('CachedPrReviewRepository - cache hit/miss', () {
    test('cache hit emits stale then fresh for watchPullRequest', () async {
      mockPr.pullRequests['o/r/42'] = _testPR(42);
      await cacheDao.put(
        'ws1',
        'prDetail',
        '42',
        '{"number":42,"title":"Cached PR","body":"","state":"open","draft":false,'
        '"user":{"login":"cached","avatar_url":""},"html_url":"","node_id":"n",'
        '"head":{"sha":"aaa","ref":"f"},"base":{"ref":"m","sha":"old-base"},'
        '"requested_reviewers":[],"assignees":[]}',
      );

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchPullRequest(42).toList();
      expect(results.length, 2);
      expect(results[0]!.title, 'Cached PR');
      expect(results[1]!.title, 'Test PR 42');
    });

    test('cache miss emits only fresh data', () async {
      mockPr.pullRequests['o/r/1'] = _testPR(1);

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchPullRequest(1).toList();
      expect(results.length, 1);
      expect(results[0]!.number, 1);
    });

    test('swallows network error when cache exists', () async {
      await cacheDao.put(
        'ws1',
        'prDetail',
        '1',
        '{"number":1,"title":"Cached","body":"","state":"open","draft":false,'
        '"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n",'
        '"head":{"sha":"a","ref":"f"},"base":{"ref":"m","sha":"old"},'
        '"requested_reviewers":[],"assignees":[]}',
      );
      // Throw an error to simulate network failure.
      mockPr.getPullRequestError = Exception('Network error');

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchPullRequest(1).toList();
      expect(results.length, 1);
      expect(results[0]!.title, 'Cached');
    });

    test('corrupt cache falls through to fetch', () async {
      mockPr.pullRequests['o/r/99'] = _testPR(99);
      await cacheDao.put('ws1', 'prDetail', '99', '{invalid json');

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchPullRequest(99).toList();
      expect(results.length, 1);
      expect(results[0]!.number, 99);
    });

    test('cache hit for watchDiff emits stale then fresh', () async {
      mockPr.diffs['o/r/42'] = 'fresh diff';
      await cacheDao.put('ws1', 'prDiff', '42', 'cached diff');

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchDiff(42).toList();
      expect(results, ['cached diff', 'fresh diff']);
    });

    test('cache hit for watchFiles emits cached files', () async {
      await cacheDao.put(
        'ws1',
        'prFiles',
        '1',
        '[{"filename":"cached.dart","status":"added","additions":5,'
        '"deletions":0,"changes":5,"patch":""}]',
      );

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchFiles(1).toList();
      expect(results.length, 1);
      expect(results[0][0].filename, 'cached.dart');
    });

    test('cache hit for watchCommits', () async {
      await cacheDao.put(
        'ws1',
        'prCommits',
        '1',
        '[{"sha":"cached","commit":{"message":"old","author":'
        '{"name":"C","email":"c@t.com"}},"author":null}]',
      );
      mockPr.commits['o/r/1'] = [
        const GitHubCommit(
          sha: 'abc',
          message: 'fix: thing',
          authorName: 'Dev',
          authorEmail: 'dev@test.com',
        ),
      ];

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchCommits(1).toList();
      expect(results.length, 2);
      expect(results[0][0].sha, 'cached');
      expect(results[1][0].sha, 'abc');
    });

    test('cache hit for watchReviews', () async {
      await cacheDao.put(
        'ws1',
        'prReviews',
        '1',
        '[{"id":3,"state":"COMMENTED","body":"ok"}]',
      );
      mockPr.reviews['o/r/1'] = [
        const GitHubReview(
          id: 5,
          state: GitHubReviewState.approved,
          body: 'LGTM',
          submittedAt: null,
        ),
      ];

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchReviews(1).toList();
      expect(results.length, 2);
      expect(results[0][0].body, 'ok');
      expect(results[1][0].body, 'LGTM');
    });

    test('cache hit for watchReviewComments', () async {
      await cacheDao.put(
        'ws1',
        'prReviewComments',
        '1',
        '[{"id":8,"body":"cached comment","path":"f.dart","diff_hunk":"@@"}]',
      );
      mockPr.reviewComments['o/r/1'] = [
        const GitHubReviewComment(
          id: 10,
          body: 'nit',
          path: 'f.dart',
          diffHunk: '@@',
        ),
      ];

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchReviewComments(1).toList();
      expect(results.length, 2);
      expect(results[0][0].id, 8);
      expect(results[1][0].id, 10);
    });

    test('cache hit for watchIssueComments', () async {
      await cacheDao.put(
        'ws1',
        'prIssueComments',
        '1',
        '[{"id":15,"body":"cached issue comment"}]',
      );
      mockPr.issueComments['o/r/1'] = [
        const GitHubIssueComment(id: 20, body: 'looks good'),
      ];

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchIssueComments(1).toList();
      expect(results.length, 2);
      expect(results[0][0].id, 15);
      expect(results[1][0].id, 20);
    });

    test('watchFileContent caches and returns stale then fresh', () async {
      mockContent.fileContents['o/r/src/a.dart|main'] = 'fresh content';
      await cacheDao.put('ws1', 'prFileContent', 'src/a.dart|main', 'cached');

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo
          .watchFileContent('src/a.dart', 'main')
          .toList();
      expect(results, ['cached', 'fresh content']);
    });
  });

  // -- Invalidation on mutations -------------------------------------------

  group('CachedPrReviewRepository - invalidation on mutations', () {
    test('invalidatePullRequest removes all PR-scoped cache entries',
        () async {
      await cacheDao.put('ws1', 'prDetail', '42', '{}');
      await cacheDao.put('ws1', 'prDiff', '42', 'diff');
      await cacheDao.put('ws1', 'prFiles', '42', '[]');
      await cacheDao.put('ws1', 'prCommits', '42', '[]');
      await cacheDao.put('ws1', 'prReviews', '42', '[]');
      await cacheDao.put('ws1', 'prReviewComments', '42', '[]');
      await cacheDao.put('ws1', 'prIssueComments', '42', '[]');
      await cacheDao.put('ws1', 'prCheckRuns', '42', '[]');
      await cacheDao.put('ws1', 'prReviewerState', '42', '[]');
      await cacheDao.put('ws1', 'assignableUsers', 'o/r', '[]');

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      await repo.invalidatePullRequest(42);

      expect(await cacheDao.read('ws1', 'prDetail', '42'), isNull);
      expect(await cacheDao.read('ws1', 'prDiff', '42'), isNull);
      expect(await cacheDao.read('ws1', 'prFiles', '42'), isNull);
      expect(await cacheDao.read('ws1', 'prCommits', '42'), isNull);
      expect(await cacheDao.read('ws1', 'prReviews', '42'), isNull);
      expect(await cacheDao.read('ws1', 'prReviewComments', '42'), isNull);
      expect(await cacheDao.read('ws1', 'prIssueComments', '42'), isNull);
      expect(await cacheDao.read('ws1', 'prCheckRuns', '42'), isNull);
      expect(await cacheDao.read('ws1', 'prReviewerState', '42'), isNull);
      expect(await cacheDao.read('ws1', 'assignableUsers', 'o/r'), '[]');
    });

    test('invalidateDiff removes only diff and files entries', () async {
      await cacheDao.put('ws1', 'prDiff', '42', 'diff');
      await cacheDao.put('ws1', 'prFiles', '42', '[]');
      await cacheDao.put('ws1', 'prDetail', '42', '{}');

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      await repo.invalidateDiff(42);

      expect(await cacheDao.read('ws1', 'prDiff', '42'), isNull);
      expect(await cacheDao.read('ws1', 'prFiles', '42'), isNull);
      expect(await cacheDao.read('ws1', 'prDetail', '42'), '{}');
    });

    test('invalidatePullRequest does not affect unrelated PR', () async {
      await cacheDao.put('ws1', 'prDetail', '42', 'data42');
      await cacheDao.put('ws1', 'prDetail', '99', 'data99');

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      await repo.invalidatePullRequest(42);

      expect(await cacheDao.read('ws1', 'prDetail', '42'), isNull);
      expect(await cacheDao.read('ws1', 'prDetail', '99'), 'data99');
    });
  });

  // -- Workspace scoping ---------------------------------------------------

  group('CachedPrReviewRepository - workspace scoping', () {
    test('different workspace IDs are isolated', () async {
      await cacheDao.put(
        'ws1',
        'prDetail',
        '1',
        '{"number":1,"title":"ws1-data","body":"","state":"open","draft":false,'
        '"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n",'
        '"head":{"sha":"s","ref":"f"},"base":{"ref":"m","sha":"old"},'
        '"requested_reviewers":[],"assignees":[]}',
      );
      await cacheDao.put(
        'ws2',
        'prDetail',
        '1',
        '{"number":1,"title":"ws2-data","body":"","state":"open","draft":false,'
        '"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n",'
        '"head":{"sha":"s","ref":"f"},"base":{"ref":"m","sha":"old"},'
        '"requested_reviewers":[],"assignees":[]}',
      );

      mockPr.pullRequests['o/r/1'] = _testPR(1);

      final repo1 = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
        workspaceId: 'ws1',
      );
      final results1 = await repo1.watchPullRequest(1).toList();
      expect(results1.length, 2);
      expect(results1[0]!.title, 'ws1-data');

      final repo2 = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
        workspaceId: 'ws2',
      );
      final results2 = await repo2.watchPullRequest(1).toList();
      expect(results2.length, 2);
      expect(results2[0]!.title, 'ws2-data');
    });

    test('invalidation is scoped to workspace', () async {
      await cacheDao.put('ws1', 'prDetail', '1', 'ws1');
      await cacheDao.put('ws2', 'prDetail', '1', 'ws2');

      final repo1 = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
        workspaceId: 'ws1',
      );
      await repo1.invalidatePullRequest(1);

      expect(await cacheDao.read('ws1', 'prDetail', '1'), isNull);
      expect(await cacheDao.read('ws2', 'prDetail', '1'), 'ws2');
    });

    test('same workspace id shares cache', () async {
      await cacheDao.put(
        'ws1',
        'prDetail',
        '42',
        '{"number":42,"title":"shared","body":"","state":"open","draft":false,'
        '"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n",'
        '"head":{"sha":"aaa","ref":"f"},"base":{"ref":"m","sha":"old-base"},'
        '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.pullRequests['o/r/42'] = _testPR(42);

      final repoA = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
        workspaceId: 'ws1',
      );
      final resultsA = await repoA.watchPullRequest(42).toList();
      expect(resultsA[0]!.title, 'shared');

      final repoB = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
        workspaceId: 'ws1',
      );
      final resultsB = await repoB.watchPullRequest(42).toList();
      // repoA's fetch updated the cache, so repoB sees the fresh value.
      expect(resultsB.length, 1);
      expect(resultsB[0]!.title, 'Test PR 42');
    });
  });

  // -- Draft methods --------------------------------------------------------

  group('CachedPrReviewRepository - draft methods', () {
    test('upsertDraft delegates to draftDao', () async {
      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      await repo.upsertDraft(1, 'my draft');
      expect(await draftDao.getDraft('o', 'r', 1), 'my draft');
    });

    test('getDraft delegates to draftDao', () async {
      await draftDao.upsertDraft('o', 'r', 1, 'saved draft');
      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      expect(await repo.getDraft(1), 'saved draft');
    });

    test('clearDraft delegates to draftDao', () async {
      await draftDao.upsertDraft('o', 'r', 1, 'temp');
      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      await repo.clearDraft(1);
      expect(await draftDao.getDraft('o', 'r', 1), isNull);
    });
  });

  // -- Diff freshness: head/base sha change ----------------------------------

  group('CachedPrReviewRepository - diff freshness', () {
    test('reuses cache when head and base sha unchanged', () async {
      await cacheDao.put('ws1', 'prDiff', '42', 'cached diff');
      await cacheDao.put(
        'ws1',
        'prDetail',
        '42',
        '{"number":42,"title":"PR","body":"","state":"open","draft":false,'
        '"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n",'
        '"head":{"sha":"abc123","ref":"f"},"base":{"ref":"m","sha":"base123"},'
        '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.pullRequests['o/r/42'] = _testPR(42); // same sha

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchDiff(42).toList();
      expect(results, ['cached diff']);
    });

    test('fetches fresh diff when head sha changed', () async {
      await cacheDao.put('ws1', 'prDiff', '42', 'old diff');
      await cacheDao.put(
        'ws1',
        'prDetail',
        '42',
        '{"number":42,"title":"PR","body":"","state":"open","draft":false,'
        '"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n",'
        '"head":{"sha":"old-sha","ref":"f"},"base":{"ref":"m","sha":"base123"},'
        '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.diffs['o/r/42'] = 'fresh diff';
      mockPr.pullRequests['o/r/42'] = const GitHubPullRequest(
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
        baseSha: 'base123',
        headRef: 'f',
        requestedReviewers: [],
        assignees: [],
      );

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchDiff(42).toList();
      expect(results, ['old diff', 'fresh diff']);
    });

    test('fetches fresh diff when base sha changed', () async {
      await cacheDao.put('ws1', 'prDiff', '42', 'stale diff');
      await cacheDao.put(
        'ws1',
        'prDetail',
        '42',
        '{"number":42,"title":"PR","body":"","state":"open","draft":false,'
        '"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n",'
        '"head":{"sha":"abc123","ref":"f"},"base":{"ref":"m","sha":"old-base"},'
        '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.diffs['o/r/42'] = 'fresh diff';
      mockPr.pullRequests['o/r/42'] = const GitHubPullRequest(
        number: 42,
        title: 'PR',
        body: '',
        state: 'open',
        isDraft: false,
        userLogin: 'u',
        htmlUrl: '',
        nodeId: 'n',
        headSha: 'abc123',
        baseRef: 'm',
        baseSha: 'new-base',
        headRef: 'f',
        requestedReviewers: [],
        assignees: [],
      );

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchDiff(42).toList();
      expect(results, ['stale diff', 'fresh diff']);
    });
  });

  // -- watchPullRequest edge cases ------------------------------------------

  group('CachedPrReviewRepository - watchPullRequest edge cases', () {
    test('rethrows network error when no cache exists', () async {
      mockPr.getPullRequestError = Exception('Boom');
      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );

      await expectLater(
        repo.watchPullRequest(1).toList(),
        throwsA(isA<Exception>()),
      );
    });

    test('yields null when API returns null', () async {
      // Not inserting an entry into pullRequests — getPullRequest returns null.

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchPullRequest(42).toList();
      expect(results, [null]);
    });
  });

  // -- watchCommitFiles -----------------------------------------------------

  group('CachedPrReviewRepository - watchCommitFiles', () {
    test('returns empty list for empty sha', () async {
      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchCommitFiles('').toList();
      expect(results, [isEmpty]);
    });

    test('cache hit emits stale then fresh', () async {
      await cacheDao.put(
        'ws1',
        'prCommitFiles',
        'abc123',
        '[{"filename":"cached_f.dart","status":"modified","additions":1,'
        '"deletions":0,"changes":1,"patch":""}]',
      );
      mockPr.commitFiles['o/r/abc123'] = [
        const GitHubPullRequestFile(
          filename: 'fresh_f.dart',
          status: 'added',
          additions: 2,
          deletions: 0,
          changes: 2,
          patch: '',
        ),
      ];

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchCommitFiles('abc123').toList();
      expect(results.length, 2);
      expect(results[0][0].filename, 'cached_f.dart');
      expect(results[1][0].filename, 'fresh_f.dart');
    });
  });

  // -- watchFiles edge cases ------------------------------------------------

  group('CachedPrReviewRepository - watchFiles edge cases', () {
    test('cache miss fetches from API source', () async {
      mockPr.pullRequests['o/r/42'] = const GitHubPullRequest(
        number: 42,
        title: 'PR',
        body: '',
        state: 'open',
        isDraft: false,
        userLogin: 'u',
        htmlUrl: '',
        nodeId: 'n',
        headSha: 'abc123',
        baseRef: 'main',
        baseSha: 'base123',
        headRef: 'feature/x',
        requestedReviewers: [],
        assignees: [],
        changedFiles: 5,
      );
      final apiSource = FakePrDiffSource(files: [
        PrFile(
          filename: 'src/api.dart',
          status: PrFileStatus.added,
          additions: 10,
          deletions: 0,
          patch: '',
        ),
      ]);

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
        apiDiffSource: apiSource,
      );
      final results = await repo.watchFiles(42).toList();
      expect(results.length, 1);
      expect(results[0][0].filename, 'src/api.dart');
    });

    test('cache stale yields cached then fresh', () async {
      await cacheDao.put(
        'ws1',
        'prFiles',
        '42',
        '[{"filename":"old.dart","status":"modified","additions":1,'
        '"deletions":0,"changes":1,"patch":""}]',
      );
      await cacheDao.put(
        'ws1',
        'prDetail',
        '42',
        '{"number":42,"title":"PR","body":"","state":"open","draft":false,'
        '"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n",'
        '"head":{"sha":"old-sha","ref":"f"},"base":{"ref":"m","sha":"base123"},'
        '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.pullRequests['o/r/42'] = const GitHubPullRequest(
        number: 42,
        title: 'PR',
        body: '',
        state: 'open',
        isDraft: false,
        userLogin: 'u',
        htmlUrl: '',
        nodeId: 'n',
        headSha: 'new-sha',
        baseRef: 'main',
        baseSha: 'base123',
        headRef: 'feature/x',
        requestedReviewers: [],
        assignees: [],
        changedFiles: 5,
      );
      final apiSource = FakePrDiffSource(files: [
        PrFile(
          filename: 'new.dart',
          status: PrFileStatus.added,
          additions: 1,
          deletions: 0,
          patch: '',
        ),
      ]);

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
        apiDiffSource: apiSource,
      );
      final results = await repo.watchFiles(42).toList();
      expect(results.length, 2);
      expect(results[0][0].filename, 'old.dart');
      expect(results[1][0].filename, 'new.dart');
    });

    test('cache current skips re-fetch when sha unchanged', () async {
      await cacheDao.put(
        'ws1',
        'prFiles',
        '42',
        '[{"filename":"fresh.dart","status":"added","additions":2,'
        '"deletions":0,"changes":2,"patch":""}]',
      );
      await cacheDao.put(
        'ws1',
        'prDetail',
        '42',
        '{"number":42,"title":"PR","body":"","state":"open","draft":false,'
        '"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n",'
        '"head":{"sha":"abc123","ref":"f"},"base":{"ref":"m","sha":"base123"},'
        '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.pullRequests['o/r/42'] = const GitHubPullRequest(
        number: 42,
        title: 'PR',
        body: '',
        state: 'open',
        isDraft: false,
        userLogin: 'u',
        htmlUrl: '',
        nodeId: 'n',
        headSha: 'abc123',
        baseRef: 'main',
        baseSha: 'base123',
        headRef: 'feature/x',
        requestedReviewers: [],
        assignees: [],
        changedFiles: 5,
      );

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchFiles(42).toList();
      // Cache is current — only one emission.
      expect(results.length, 1);
      expect(results[0][0].filename, 'fresh.dart');
    });

    test('fetch error with no cache yields error', () async {
      mockPr.pullRequests['o/r/42'] = const GitHubPullRequest(
        number: 42,
        title: 'PR',
        body: '',
        state: 'open',
        isDraft: false,
        userLogin: 'u',
        htmlUrl: '',
        nodeId: 'n',
        headSha: 'abc123',
        baseRef: 'main',
        baseSha: 'base123',
        headRef: 'feature/x',
        requestedReviewers: [],
        assignees: [],
        changedFiles: 5,
      );
      final errorSource = FakePrDiffSource(error: Exception('Files failed'));

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
        apiDiffSource: errorSource,
      );
      final results = await repo.watchFilesLoad(42).toList();
      expect(results.length, 1);
      expect(results[0].error, isA<Exception>());
      expect(results[0].isComplete, isTrue);
    });

    test('fetch error with cache swallows and uses cache', () async {
      await cacheDao.put(
        'ws1',
        'prFiles',
        '42',
        '[{"filename":"cached.dart","status":"modified","additions":1,'
        '"deletions":0,"changes":1,"patch":""}]',
      );
      mockPr.pullRequests['o/r/42'] = const GitHubPullRequest(
        number: 42,
        title: 'PR',
        body: '',
        state: 'open',
        isDraft: false,
        userLogin: 'u',
        htmlUrl: '',
        nodeId: 'n',
        headSha: 'abc123',
        baseRef: 'main',
        baseSha: 'base123',
        headRef: 'feature/x',
        requestedReviewers: [],
        assignees: [],
        changedFiles: 5,
      );
      final errorSource = FakePrDiffSource(error: Exception('Files failed'));

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
        apiDiffSource: errorSource,
      );
      // watchFiles filters empty loads, watchFilesLoad shows everything.
      final results = await repo.watchFilesLoad(42).toList();
      // Only the cached emission; error is swallowed.
      expect(results.length, 1);
      expect(results[0].error, isNull);
      expect(results[0].files[0].filename, 'cached.dart');
    });
  });

  // -- watchDiff freshness: empty/null sha ----------------------------------

  group('CachedPrReviewRepository - watchDiff freshness null sha', () {
    test('revalidates when cached head sha is missing', () async {
      await cacheDao.put('ws1', 'prDiff', '42', 'old diff');
      // Cached PR detail without head.sha.
      await cacheDao.put(
        'ws1',
        'prDetail',
        '42',
        '{"number":42,"title":"PR","body":"","state":"open","draft":false,'
        '"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n",'
        '"head":{"ref":"f"},"base":{"ref":"m","sha":"base123"},'
        '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.diffs['o/r/42'] = 'fresh diff';
      mockPr.pullRequests['o/r/42'] = _testPR(42);

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchDiff(42).toList();
      expect(results, ['old diff', 'fresh diff']);
    });

    test('revalidates when cached base sha is missing', () async {
      await cacheDao.put('ws1', 'prDiff', '42', 'stale diff');
      // Cached PR detail without base.sha.
      await cacheDao.put(
        'ws1',
        'prDetail',
        '42',
        '{"number":42,"title":"PR","body":"","state":"open","draft":false,'
        '"user":{"login":"u","avatar_url":""},"html_url":"","node_id":"n",'
        '"head":{"sha":"abc123","ref":"f"},"base":{"ref":"m"},'
        '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.diffs['o/r/42'] = 'fresh diff';
      mockPr.pullRequests['o/r/42'] = _testPR(42);

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      final results = await repo.watchDiff(42).toList();
      expect(results, ['stale diff', 'fresh diff']);
    });
  });

  // -- Mutation no-ops (early returns before API call) -----------------------

  group('CachedPrReviewRepository - mutation no-ops', () {
    test('updatePullRequest with both null returns immediately', () async {
      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      // Should not throw — early return before API call.
      await repo.updatePullRequest(prNumber: 1);
    });

    test('addAssignees with empty list returns immediately', () async {
      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      await repo.addAssignees(prNumber: 1, logins: const []);
    });

    test('removeAssignees with empty list returns immediately', () async {
      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      await repo.removeAssignees(prNumber: 1, logins: const []);
    });

    test('requestReviewers with empty userLogins and teamSlugs returns immediately',
        () async {
      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      await repo.requestReviewers(prNumber: 1);
    });

    test('removeRequestedReviewers with empty lists returns immediately',
        () async {
      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      await repo.removeRequestedReviewers(prNumber: 1);
    });
  });

  // -- Invalidation edge cases ----------------------------------------------

  group('CachedPrReviewRepository - invalidation edge cases', () {
    test('invalidatePullRequest does not remove prCodeOwnerIds', () async {
      await cacheDao.put('ws1', 'prCodeOwnerIds', '42',
          '{"ids":["alice","bob"]}');
      await cacheDao.put('ws1', 'prDetail', '42', 'data');

      final repo = _makeRepo(
        cacheDao: cacheDao,
        draftDao: draftDao,
        apiClient: apiClient,
      );
      await repo.invalidatePullRequest(42);

      expect(await cacheDao.read('ws1', 'prDetail', '42'), isNull);
      expect(
        await cacheDao.read('ws1', 'prCodeOwnerIds', '42'),
        '{"ids":["alice","bob"]}',
      );
    });
  });
}
