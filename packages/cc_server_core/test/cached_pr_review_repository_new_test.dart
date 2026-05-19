import 'dart:async';

import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/job_run_detail.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_stack.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pending_review_comment.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/cached_pr_review_repository.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

// ===========================================================================
// Fake CacheDao — extends the real class with in-memory storage.
// The test database is only used to satisfy the type system; all methods
// are overridden so the real database is never touched.
// ===========================================================================
// ===========================================================================
// Fake ReviewDao — same pattern
// ===========================================================================
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

  /// Set to intercept [getPullRequest] with custom (e.g. blocking) behaviour —
  /// used to hold a request in-flight while the consumer cancels, reproducing
  /// the navigate-away race. Receives the [CancelToken] so it can mirror dio
  /// and abort on cancellation. Takes precedence over the canned map and error.
  Future<GitHubPullRequest?> Function(CancelToken? cancelToken)?
  getPullRequestHook;
  Object? diffError;

  /// How many times the PR detail was actually asked of the forge. The detail
  /// is fetched by the detail stream AND probed by the diff and files routing
  /// passes, so this is what proves those collapse into one request.
  int getPullRequestCalls = 0;

  @override
  Future<GitHubPullRequest?> getPullRequest(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    getPullRequestCalls++;
    if (getPullRequestHook != null) {
      return getPullRequestHook!(cancelToken);
    }
    if (getPullRequestError != null) {
      throw getPullRequestError!;
    }
    return pullRequests['$owner/$repo/$number'];
  }

  /// How many times [getPullRequestDiff] was asked for a diff. Lets a test
  /// assert the raw-diff fetch stays off the common path.
  int diffCalls = 0;

  @override
  Future<String> getPullRequestDiff(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    diffCalls++;
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
  }) async => files['$owner/$repo/$number'] ?? const [];

  @override
  Future<List<GitHubCommit>> listAllPullRequestCommits(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async => commits['$owner/$repo/$number'] ?? const [];

  @override
  Future<List<GitHubPullRequestFile>> getCommitFiles(
    String owner,
    String repo,
    String sha, {
    CancelToken? cancelToken,
  }) async => commitFiles['$owner/$repo/$sha'] ?? const [];

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
  }) async => reviews['$owner/$repo/$number'] ?? const [];

  @override
  Future<List<GitHubReviewComment>> listPullRequestReviewComments(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async => reviewComments['$owner/$repo/$number'] ?? const [];

  @override
  Future<List<GitHubIssueComment>> listIssueComments(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async => issueComments['$owner/$repo/$number'] ?? const [];

  @override
  Future<List<GitHubCheckRun>> listCheckRuns(
    String owner,
    String repo,
    String ref, {
    CancelToken? cancelToken,
  }) async => checkRuns['$owner/$repo/$ref'] ?? const [];

  /// Jobs per workflow run id — feeds the check-run → job-id join.
  final Map<int, List<GitHubJobRun>> workflowRunJobs = {};

  @override
  Future<List<GitHubJobRun>> listWorkflowRunJobs(
    String owner,
    String repo,
    int runId, {
    CancelToken? cancelToken,
  }) async => workflowRunJobs[runId] ?? const [];

  /// Workflow runs per head SHA — feeds the check-suite → workflow join.
  final Map<String, List<GitHubWorkflowRun>> workflowRuns = {};

  @override
  Future<List<GitHubWorkflowRun>> listWorkflowRuns(
    String owner,
    String repo,
    String headSha, {
    CancelToken? cancelToken,
  }) async => workflowRuns['$owner/$repo/$headSha'] ?? const [];
}

// ===========================================================================
// FakeGitHubContentClient — minimal implementation
// ===========================================================================
class FakeGitHubContentClient extends GitHubContentClient {
  FakeGitHubContentClient() : super(_fakeDio);

  static final _fakeDio = _NullDio();

  final Map<String, String> fileContents = {};

  /// The user `getAuthenticatedUser` reports; null by default so the
  /// viewer-dependent enrichment paths take their "login unknown" branch.
  GitHubUser? authenticatedUser;

  @override
  Future<GitHubUser?> getAuthenticatedUser({CancelToken? cancelToken}) async =>
      authenticatedUser;

  @override
  Future<String> getFileContent(
    String owner,
    String repo,
    String path,
    String ref, {
    CancelToken? cancelToken,
  }) async => fileContents['$owner/$repo/$path|$ref'] ?? '';
}

/// GraphQL surface whose review-reaction listing is set per test. Everything
/// else is left to the real client (over a null Dio — reaching any other
/// method is a test bug).
class StubGraphqlClient extends GitHubGraphQLClient {
  StubGraphqlClient() : super(_nullDio());

  static Dio _nullDio() => _NullDio();

  List<GitHubReviewReactionSet> reviewReactions = const [];

  /// When set, the listing throws — the enrichment's failure branch.
  Object? listReviewReactionsError;

  /// Successive reviewer-state responses, one per read. The last entry is
  /// repeated once the script runs out, so a test only has to spell out the
  /// reads it cares about. Lets a test model GitHub's read-after-write lag:
  /// the reviewer rail is a GraphQL read while a review is a REST write, so
  /// the first read after a submit can still serve the pre-review state.
  List<GitHubPrReviewState> reviewStates = const [];

  /// Reviewer-state reads served so far.
  int reviewStateReads = 0;

  @override
  Future<GitHubPrReviewState> getPullRequestReviewState({
    required String owner,
    required String repo,
    required int number,
    CancelToken? cancelToken,
  }) async {
    if (reviewStates.isEmpty) {
      return const GitHubPrReviewState();
    }
    final index = reviewStateReads.clamp(0, reviewStates.length - 1);
    reviewStateReads++;
    return reviewStates[index];
  }

  @override
  Future<List<GitHubReviewReactionSet>> listReviewReactions({
    required String owner,
    required String repo,
    required int number,
    CancelToken? cancelToken,
  }) async {
    final error = listReviewReactionsError;
    if (error != null) {
      throw error;
    }
    return reviewReactions;
  }
}

// ===========================================================================
// FakeGitHubApiClient — facade wrapping the fake sub-clients
// ===========================================================================
class FakeGitHubApiClient implements GitHubApiClient {
  FakeGitHubApiClient({required this.pr, required this.content})
    : _graphql = StubGraphqlClient();

  @override
  final FakeGitHubPrClient pr;

  @override
  final FakeGitHubContentClient content;

  final StubGraphqlClient _graphql;

  /// The stubbed GraphQL surface, settable per test.
  StubGraphqlClient get graphqlStub => _graphql;

  @override
  GitHubGraphQLClient get graphql => _graphql;
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
  Stream<List<PrFile>> watchCommitFiles(
    PrSourceRequest req,
    String sha,
  ) async* {
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

  void setReviewComments(int prNumber, List<PrCodeReviewComment> comments) =>
      _reviewComments[prNumber] = comments;

  // -- Issue comments ----------------------------------------------------
  @override
  Stream<List<IssueComment>> watchIssueComments(int prNumber) async* {
    if (_issueComments.containsKey(prNumber)) {
      yield _issueComments[prNumber]!;
    }
  }

  @override
  Stream<List<PrTimelineEvent>> watchTimelineEvents(int prNumber) async* {
    yield const [];
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

  @override
  Future<JobRunDetail?> getJobRunDetail(int jobId) async => null;

  @override
  Future<WorkflowGraph?> getWorkflowGraph(int workflowRunId) async => null;

  // -- Commit statuses ---------------------------------------------------
  final Map<int, List<CommitStatus>> _commitStatuses = {};

  @override
  Stream<List<CommitStatus>> watchCommitStatuses(int prNumber) async* {
    if (_commitStatuses.containsKey(prNumber)) {
      yield _commitStatuses[prNumber]!;
    }
  }

  void setCommitStatuses(int prNumber, List<CommitStatus> statuses) =>
      _commitStatuses[prNumber] = statuses;

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
    required String externalId,
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
  }) async => <String, dynamic>{};

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
  ) async => 'https://example.com/$path';

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
  Future<void> toggleReviewReaction({
    required int reviewId,
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
    List<PendingReviewComment> comments = const [],
  }) async {}

  @override
  Future<void> setReviewThreadResolved({
    required int prNumber,
    required String threadId,
    required bool resolved,
  }) async {}

  @override
  Future<Map<String, dynamic>> mergePullRequest({
    String? idempotencyKey,
    required int prNumber,
    required String mergeMethod,
    String? commitTitle,
    String? commitMessage,
  }) async => <String, dynamic>{};

  @override
  Future<void> closePullRequest({required int prNumber}) async {}

  @override
  Future<void> setPullRequestDraft({
    required int prNumber,
    required bool draft,
  }) async {}

  @override
  Future<List<PrStack>> listStacks({int? prNumber}) async => const <PrStack>[];

  @override
  Future<PrStack> createStack({required List<int> prNumbers}) =>
      throw UnsupportedError('stacks not wired');

  @override
  Future<PrStack?> addToStack({
    required int stackNumber,
    required List<int> prNumbers,
  }) async => null;

  @override
  Future<PrStack?> unstack({required int stackNumber}) async => null;

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

  @override
  Future<List<PrUser>> listSuggestedReviewers(int prNumber) async => [];
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
  externalId: 'node_$number',
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
}) => PullRequest(
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
  externalId: 'n',
  headSha: headSha,
  baseRef: baseRef,
  headRef: headRef,
);

/// A wire-shaped PR for the routing/SWR calls `watchFiles` makes before it
/// touches a diff source.
GitHubPullRequest _ghPr({int changedFiles = 1, String headSha = 'abc123'}) =>
    GitHubPullRequest(
      number: 42,
      title: 'PR',
      body: '',
      state: 'open',
      isDraft: false,
      userLogin: 'u',
      htmlUrl: '',
      externalId: 'n',
      headSha: headSha,
      baseRef: 'main',
      baseSha: 'base123',
      headRef: 'feature/x',
      requestedReviewers: const [],
      assignees: const [],
      changedFiles: changedFiles,
    );

/// A two-file raw unified diff, in the shape GitHub's `.diff` media type
/// returns it — including the `index`/`---`/`+++` metadata the extractor has
/// to strip.
const _rawDiff = '''
diff --git a/small.dart b/small.dart
index 1111111..2222222 100644
--- a/small.dart
+++ b/small.dart
@@ -1,2 +1,2 @@
-old
+new
 keep
diff --git a/huge.json b/huge.json
index 3333333..4444444 100644
--- a/huge.json
+++ b/huge.json
@@ -1,3 +1,3 @@
 {
-  "a": 1
+  "a": 2
 }
''';

CachedPrReviewRepository _makeRepo({
  required WorkspaceDatabase db,
  required FakeGitHubApiClient apiClient,
  PrDiffSource? apiDiffSource,
  PrDiffSource? localDiffSource,
  DomainEventBus? eventBus,
  PrChangeSignals? changeSignals,
}) => CachedPrReviewRepository(
  db: db,
  // The repository is forge-agnostic now, so the fake HTTP surface is driven
  // through the real GitHub adapter — which means these tests also cover the
  // adapter's mapping rather than bypassing it.
  forgeClient: GitHubForgePrClient(client: apiClient, owner: 'o', repo: 'r'),
  owner: 'o',
  repo: 'r',
  apiDiffSource: apiDiffSource ?? FakePrDiffSource(),
  localDiffSource: localDiffSource ?? FakePrDiffSource(),
  eventBus: eventBus,
  changeSignals: changeSignals,
);

// ===========================================================================
// Tests
// ===========================================================================
void main() {
  late WorkspaceDatabase db;

  /// A SECOND workspace's database. Two workspaces are two files now, so a test
  /// that used to prove "the cache key carries a workspace id" proves something
  /// stronger here: the other workspace's rows are not reachable at all.
  late WorkspaceDatabase otherDb;
  late FakeGitHubPrClient mockPr;
  late FakeGitHubContentClient mockContent;
  late FakeGitHubApiClient apiClient;

  setUp(() {
    db = createTestDatabase(workspaceId: 'ws1');
    otherDb = createTestDatabase(workspaceId: 'ws2');
    mockPr = FakeGitHubPrClient();
    mockContent = FakeGitHubContentClient();
    apiClient = FakeGitHubApiClient(pr: mockPr, content: mockContent);
  });

  // -- request amplification on a PR open -----------------------------------
  //
  // Opening a PR mounts ~10 watch streams at once and each one revalidated
  // unconditionally, so a page that had been open ten seconds ago re-ran the
  // whole forge fan-out. Two separate causes, both pinned here: the SWR pass
  // asked again on every subscribe, and the diff/files routing probes called
  // `getPullRequest` directly — outside the cache and outside the single-flight
  // lane the detail stream uses.

  group('forge request amplification', () {
    test('streams opened together share one PR-detail fetch', () async {
      // What a PR open actually looks like: every watch mounts in the same
      // frame. The detail stream fetches the PR, and the files pass needs
      // `changedFiles` to choose its source while the diff pass needs the head
      // and base SHAs — all three used to issue their own `GET /pulls/{n}`
      // because the two probes called the client directly, outside the
      // single-flight lane.
      //
      // The probes deliberately do NOT read the freshness window (a freshness
      // check answered from the row it is checking is a self-comparison), so
      // the lane is what collapses them. Hold the first fetch open until every
      // stream has reached it.
      final gate = Completer<void>();
      mockPr.getPullRequestHook = (_) async {
        await gate.future;
        return _ghPr(changedFiles: 2);
      };
      mockPr.diffs['o/r/42'] = 'a diff';
      final repo = _makeRepo(db: db, apiClient: apiClient);

      final detail = repo.watchPullRequest(42).toList();
      final files = repo.watchFiles(42).toList();
      final diff = repo.watchDiff(42).toList();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      gate.complete();
      await Future.wait([detail, files, diff]);

      expect(mockPr.getPullRequestCalls, 1);
    });

    test(
      'a re-subscribe inside the freshness window serves the cache',
      () async {
        mockPr.pullRequests['o/r/42'] = _ghPr();
        final repo = _makeRepo(db: db, apiClient: apiClient);

        final first = await repo.watchPullRequest(42).toList();
        expect(first.single?.number, 42);
        expect(mockPr.getPullRequestCalls, 1);

        // Stepping into another tab and back, or any rebuild that re-subscribes.
        final second = await repo.watchPullRequest(42).toList();
        expect(
          second.single?.number,
          42,
          reason: 'the cached row is still served — only the ask is skipped',
        );
        expect(mockPr.getPullRequestCalls, 1);
      },
    );

    test('an explicit invalidation re-asks inside the window', () async {
      mockPr.pullRequests['o/r/42'] = _ghPr();
      final repo = _makeRepo(db: db, apiClient: apiClient);

      await repo.watchPullRequest(42).toList();
      expect(mockPr.getPullRequestCalls, 1);

      // The refresh button. It deletes the cache rows precisely because it
      // wants the network hit; a surviving freshness stamp would let the next
      // subscriber skip the fetch the operator just asked for.
      await repo.invalidatePullRequest(42);
      await repo.watchPullRequest(42).toList();
      expect(mockPr.getPullRequestCalls, 2);
    });

    test('a cold subscription still fetches', () async {
      // The window is a de-duplication window, not a TTL on the data: with
      // nothing cached there is nothing to serve and the fetch must happen.
      mockPr.pullRequests['o/r/42'] = _ghPr();
      final repo = _makeRepo(db: db, apiClient: apiClient);

      final emitted = await repo.watchPullRequest(42).toList();
      expect(emitted.single?.number, 42);
      expect(mockPr.getPullRequestCalls, 1);
    });

    test('a head move inside the window still refreshes the diff', () async {
      // The freshness window must never reach the routing probes. Both the
      // diff's SHA check and the files pass compare a LIVE PR against SHAs read
      // out of the cached detail row — so answering the probe from that same
      // row compares it with itself, reports "unchanged" forever, and strands
      // the diff at whatever commit it was built from.
      mockPr.pullRequests['o/r/42'] = _ghPr(headSha: 'sha-one');
      mockPr.diffs['o/r/42'] = 'diff-at-sha-one';
      final repo = _makeRepo(db: db, apiClient: apiClient);

      expect(await repo.watchDiff(42).toList(), ['diff-at-sha-one']);

      // A push lands moments later — inside every window in the table.
      mockPr.pullRequests['o/r/42'] = _ghPr(headSha: 'sha-two');
      mockPr.diffs['o/r/42'] = 'diff-at-sha-two';

      expect(
        await repo.watchDiff(42).toList(),
        contains('diff-at-sha-two'),
        reason:
            'the probe has to be told by something it did not already '
            'believe',
      );
    });

    test('a separate repository instance holds its own window', () async {
      // The stamps are per-instance and in-process. A second instance (another
      // acting user, or the server after a restart) must not inherit a
      // freshness claim it never verified.
      mockPr.pullRequests['o/r/42'] = _ghPr();
      await _makeRepo(
        db: db,
        apiClient: apiClient,
      ).watchPullRequest(42).toList();
      expect(mockPr.getPullRequestCalls, 1);

      await _makeRepo(
        db: db,
        apiClient: apiClient,
      ).watchPullRequest(42).toList();
      expect(mockPr.getPullRequestCalls, 2);
    });
  });

  // -- check runs: workflow-run join ----------------------------------------

  group('watchCheckRuns workflow-run join', () {
    test(
      'resolves workflowName, jobId and workflowRunId via the jobs join',
      () async {
        mockPr.pullRequests['o/r/7'] = _testPR(7);
        mockPr.checkRuns['o/r/abc123'] = [
          const GitHubCheckRun(
            id: 555,
            name: 'Unit test (1)',
            status: GitHubCheckStatus.completed,
            conclusion: GitHubCheckConclusion.success,
            appName: 'GitHub Actions',
            htmlUrl: 'https://github.com/o/r/runs/555',
            checkSuiteId: 42,
          ),
          const GitHubCheckRun(
            id: 556,
            name: 'external-check',
            status: GitHubCheckStatus.completed,
            conclusion: GitHubCheckConclusion.neutral,
            appName: 'Vercel',
            htmlUrl: 'https://vercel.com/x',
          ),
        ];
        mockPr.workflowRuns['o/r/abc123'] = [
          const GitHubWorkflowRun(
            id: 900,
            name: 'CI',
            checkSuiteId: 42,
            headSha: 'abc123',
            htmlUrl: 'https://github.com/o/r/actions/runs/900',
            path: '.github/workflows/ci.yaml',
            status: 'completed',
            conclusion: 'success',
          ),
        ];
        mockPr.workflowRunJobs[900] = [
          const GitHubJobRun(
            id: 101,
            runId: 900,
            name: 'Unit test (1)',
            status: 'completed',
            conclusion: 'success',
            checkRunUrl: 'https://api.github.com/repos/o/r/check-runs/555',
          ),
        ];
        final repo = _makeRepo(db: db, apiClient: apiClient);

        final results = await repo.watchCheckRuns(7).toList();
        final checks = results.last;
        expect(checks, hasLength(2));
        final actionsCheck = checks.firstWhere(
          (c) => c.name == 'Unit test (1)',
        );
        expect(actionsCheck.workflowName, 'CI');
        expect(actionsCheck.jobId, 101);
        expect(actionsCheck.workflowRunId, 900);
        // The external check has no check suite — it never joins.
        final external = checks.firstWhere((c) => c.name == 'external-check');
        expect(external.workflowName, isNull);
        expect(external.jobId, isNull);
        expect(external.workflowRunId, isNull);
      },
    );

    test(
      'a failing jobs call degrades to jobId == null, never fails',
      () async {
        mockPr.pullRequests['o/r/7'] = _testPR(7);
        mockPr.checkRuns['o/r/abc123'] = [
          const GitHubCheckRun(
            id: 555,
            name: 'Unit test (1)',
            status: GitHubCheckStatus.completed,
            conclusion: GitHubCheckConclusion.success,
            appName: 'GitHub Actions',
            htmlUrl: 'https://github.com/o/r/runs/555',
            checkSuiteId: 42,
          ),
        ];
        mockPr.workflowRuns['o/r/abc123'] = [
          const GitHubWorkflowRun(
            id: 900,
            name: 'CI',
            checkSuiteId: 42,
            headSha: 'abc123',
            htmlUrl: 'https://github.com/o/r/actions/runs/900',
            path: '.github/workflows/ci.yaml',
            status: 'completed',
          ),
        ];
        // No workflowRunJobs entry → the fake returns []. jobId stays null but
        // the workflow name still resolves.
        final repo = _makeRepo(db: db, apiClient: apiClient);

        final results = await repo.watchCheckRuns(7).toList();
        final check = results.last.single;
        expect(check.workflowName, 'CI');
        expect(check.jobId, isNull);
        expect(check.workflowRunId, 900);
      },
    );

    test('keeps only the latest run per workflow (push/pull_request twins, '
        're-runs)', () async {
      mockPr.pullRequests['o/r/7'] = _testPR(7);
      // Two runs of the SAME workflow file on the same head SHA — the
      // check-runs API returns the jobs of both.
      mockPr.checkRuns['o/r/abc123'] = [
        const GitHubCheckRun(
          id: 555,
          name: 'build',
          status: GitHubCheckStatus.completed,
          conclusion: GitHubCheckConclusion.failure,
          appName: 'GitHub Actions',
          htmlUrl: 'https://github.com/o/r/runs/555',
          checkSuiteId: 42,
        ),
        const GitHubCheckRun(
          id: 556,
          name: 'build',
          status: GitHubCheckStatus.completed,
          conclusion: GitHubCheckConclusion.success,
          appName: 'GitHub Actions',
          htmlUrl: 'https://github.com/o/r/runs/556',
          checkSuiteId: 43,
        ),
      ];
      mockPr.workflowRuns['o/r/abc123'] = [
        const GitHubWorkflowRun(
          id: 900,
          name: 'CI',
          checkSuiteId: 42,
          headSha: 'abc123',
          htmlUrl: 'https://github.com/o/r/actions/runs/900',
          path: '.github/workflows/ci.yaml',
          status: 'completed',
          conclusion: 'failure',
        ),
        const GitHubWorkflowRun(
          id: 901,
          name: 'CI',
          checkSuiteId: 43,
          headSha: 'abc123',
          htmlUrl: 'https://github.com/o/r/actions/runs/901',
          path: '.github/workflows/ci.yaml',
          status: 'completed',
          conclusion: 'success',
        ),
      ];
      final repo = _makeRepo(db: db, apiClient: apiClient);

      final results = await repo.watchCheckRuns(7).toList();
      // Only the newer run (id 901, suite 43) survives — the superseded
      // run's jobs must not render as a second card.
      final check = results.last.single;
      expect(check.name, 'build');
      expect(check.workflowRunId, 901);
      expect(check.conclusion, CheckRunConclusion.success);
    });

    test(
      'a different workflow file with the same name is not deduplicated',
      () async {
        mockPr.pullRequests['o/r/7'] = _testPR(7);
        mockPr.checkRuns['o/r/abc123'] = [
          const GitHubCheckRun(
            id: 555,
            name: 'build',
            status: GitHubCheckStatus.completed,
            conclusion: GitHubCheckConclusion.success,
            appName: 'GitHub Actions',
            htmlUrl: 'https://github.com/o/r/runs/555',
            checkSuiteId: 42,
          ),
          const GitHubCheckRun(
            id: 556,
            name: 'build',
            status: GitHubCheckStatus.completed,
            conclusion: GitHubCheckConclusion.success,
            appName: 'GitHub Actions',
            htmlUrl: 'https://github.com/o/r/runs/556',
            checkSuiteId: 43,
          ),
        ];
        mockPr.workflowRuns['o/r/abc123'] = [
          const GitHubWorkflowRun(
            id: 900,
            name: 'CI',
            checkSuiteId: 42,
            headSha: 'abc123',
            htmlUrl: 'https://github.com/o/r/actions/runs/900',
            path: '.github/workflows/ci.yaml',
            status: 'completed',
          ),
          const GitHubWorkflowRun(
            id: 901,
            name: 'CI',
            checkSuiteId: 43,
            headSha: 'abc123',
            htmlUrl: 'https://github.com/o/r/actions/runs/901',
            path: '.github/workflows/ci-nightly.yaml',
            status: 'completed',
          ),
        ];
        final repo = _makeRepo(db: db, apiClient: apiClient);

        final results = await repo.watchCheckRuns(7).toList();
        expect(results.last, hasLength(2));
      },
    );

    test(
      'collapses a check run re-created by a re-run-failed-jobs attempt',
      () async {
        mockPr.pullRequests['o/r/7'] = _testPR(7);
        // Same suite, same job name, two check-run ids: the re-run minted a
        // new check run for the job.
        mockPr.checkRuns['o/r/abc123'] = [
          const GitHubCheckRun(
            id: 555,
            name: 'build',
            status: GitHubCheckStatus.completed,
            conclusion: GitHubCheckConclusion.failure,
            appName: 'GitHub Actions',
            htmlUrl: 'https://github.com/o/r/runs/555',
            checkSuiteId: 42,
          ),
          const GitHubCheckRun(
            id: 560,
            name: 'build',
            status: GitHubCheckStatus.completed,
            conclusion: GitHubCheckConclusion.success,
            appName: 'GitHub Actions',
            htmlUrl: 'https://github.com/o/r/runs/560',
            checkSuiteId: 42,
          ),
        ];
        mockPr.workflowRuns['o/r/abc123'] = [
          const GitHubWorkflowRun(
            id: 900,
            name: 'CI',
            checkSuiteId: 42,
            headSha: 'abc123',
            htmlUrl: 'https://github.com/o/r/actions/runs/900',
            path: '.github/workflows/ci.yaml',
            status: 'completed',
          ),
        ];
        mockPr.workflowRunJobs[900] = [
          const GitHubJobRun(
            id: 102,
            runId: 900,
            name: 'build',
            status: 'completed',
            conclusion: 'success',
            checkRunUrl: 'https://api.github.com/repos/o/r/check-runs/560',
          ),
        ];
        final repo = _makeRepo(db: db, apiClient: apiClient);

        final results = await repo.watchCheckRuns(7).toList();
        final check = results.last.single;
        expect(check.conclusion, CheckRunConclusion.success);
        expect(check.jobId, 102);
      },
    );

    test('collapses an external app re-reporting the same check', () async {
      mockPr.pullRequests['o/r/7'] = _testPR(7);
      mockPr.checkRuns['o/r/abc123'] = [
        const GitHubCheckRun(
          id: 10,
          name: 'deploy',
          status: GitHubCheckStatus.completed,
          conclusion: GitHubCheckConclusion.failure,
          appName: 'Vercel',
          htmlUrl: 'https://vercel.com/old',
        ),
        const GitHubCheckRun(
          id: 11,
          name: 'deploy',
          status: GitHubCheckStatus.completed,
          conclusion: GitHubCheckConclusion.success,
          appName: 'Vercel',
          htmlUrl: 'https://vercel.com/new',
        ),
      ];
      final repo = _makeRepo(db: db, apiClient: apiClient);

      final results = await repo.watchCheckRuns(7).toList();
      final check = results.last.single;
      expect(check.conclusion, CheckRunConclusion.success);
      expect(check.htmlUrl, 'https://vercel.com/new');
    });
  });

  // -- submitReview emits approval status -----------------------------------

  group('submitReview approval event', () {
    test('APPROVE publishes PullRequestStatusChanged(approved)', () async {
      final bus = DomainEventBus();
      final events = <PullRequestStatusChanged>[];
      final sub = bus.on<PullRequestStatusChanged>().listen(events.add);
      final repo = _makeRepo(db: db, apiClient: apiClient, eventBus: bus);

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
        final repo = _makeRepo(db: db, apiClient: apiClient, eventBus: bus);

        await repo.submitReview(prNumber: 7, event: event);
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty, reason: '$event must not emit');

        await sub.cancel();
        bus.dispose();
      }
    });
  });

  // -- submitReview settles a lagging reviewer rail ---------------------------

  group('submitReview reviewer-rail settle', () {
    late PrChangeSignals signals;

    setUp(() => signals = PrChangeSignals());
    tearDown(() => signals.dispose());

    Future<void> pump() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('re-validates until the forge reports the submitted review', () async {
      const pending = GitHubPrReviewState(
        pendingUsers: [
          GitHubPendingUserRequest(
            login: 'reviewer1',
            avatarUrl: 'https://avatars/reviewer1',
            asCodeOwner: false,
          ),
        ],
      );
      const approved = GitHubPrReviewState(
        completedReviews: [
          GitHubCompletedReview(
            authorLogin: 'reviewer1',
            authorAvatarUrl: 'https://avatars/reviewer1',
            state: 'APPROVED',
          ),
        ],
      );
      // Read 1 is the initial load. Read 2 is the re-validation
      // `invalidatePullRequest` triggers the instant the review is POSTed —
      // GraphQL has not caught up with the REST write yet, so it still says
      // "pending". Only read 3 sees the approval.
      apiClient.graphqlStub.reviewStates = const [pending, pending, approved];

      final repo = _makeRepo(
        db: db,
        apiClient: apiClient,
        changeSignals: signals,
      );

      final emitted = <List<PrReviewSubmissionState>>[];
      final sub = repo
          .watchReviewers(7)
          .listen((rs) => emitted.add([for (final r in rs) r.state]));
      await pump();
      expect(emitted, [
        [PrReviewSubmissionState.pending],
      ]);

      await repo.submitReview(prNumber: 7, event: 'APPROVE');
      await pump();
      // The immediate re-validation came back with the payload the stream had
      // already sent, so the SWR fingerprint deduped it away. Nothing was
      // emitted — this is exactly the state the rail used to be stuck in
      // until the operator pressed refresh.
      expect(
        emitted,
        hasLength(1),
        reason: 'the stale re-validation must dedupe, not emit',
      );

      // The settle pass re-validates after its first backoff step.
      await Future<void>.delayed(const Duration(seconds: 1));
      await pump();
      expect(emitted, hasLength(2));
      expect(emitted.last, [PrReviewSubmissionState.approved]);
      expect(apiClient.graphqlStub.reviewStateReads, 3);

      await sub.cancel();
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('a forge that answers immediately is not re-read', () async {
      const pending = GitHubPrReviewState(
        pendingUsers: [
          GitHubPendingUserRequest(
            login: 'reviewer1',
            avatarUrl: 'https://avatars/reviewer1',
            asCodeOwner: false,
          ),
        ],
      );
      const approved = GitHubPrReviewState(
        completedReviews: [
          GitHubCompletedReview(
            authorLogin: 'reviewer1',
            authorAvatarUrl: 'https://avatars/reviewer1',
            state: 'APPROVED',
          ),
        ],
      );
      apiClient.graphqlStub.reviewStates = const [pending, approved];

      final repo = _makeRepo(
        db: db,
        apiClient: apiClient,
        changeSignals: signals,
      );

      final emitted = <List<PrReviewSubmissionState>>[];
      final sub = repo
          .watchReviewers(7)
          .listen((rs) => emitted.add([for (final r in rs) r.state]));
      await pump();

      await repo.submitReview(prNumber: 7, event: 'APPROVE');
      await pump();
      expect(emitted.last, [PrReviewSubmissionState.approved]);

      // The settle pass sees a rail that already changed and stops without
      // spending another GraphQL read.
      await Future<void>.delayed(const Duration(seconds: 1));
      await pump();
      expect(apiClient.graphqlStub.reviewStateReads, 2);

      await sub.cancel();
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  // -- Reactive (signal-driven) watch streams --------------------------------

  group('change-signal reactivity', () {
    late PrChangeSignals signals;

    setUp(() {
      signals = PrChangeSignals();
    });

    tearDown(() {
      signals.dispose();
    });

    /// Pumps the event loop enough for a signal → SWR pass → emission chain.
    Future<void> pump() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test(
      'watchPullRequest stays open and re-emits on a change signal',
      () async {
        mockPr.pullRequests['o/r/7'] = _testPR(7);
        final repo = _makeRepo(
          db: db,
          apiClient: apiClient,
          changeSignals: signals,
        );

        final titles = <String>[];
        var done = false;
        final sub = repo
            .watchPullRequest(7)
            .listen(
              (pr) => titles.add(pr?.title ?? ''),
              onDone: () => done = true,
            );
        await pump();
        expect(titles, ['Test PR 7']);
        expect(done, isFalse, reason: 'the stream must stay open for signals');

        // GitHub-side change + signal → the open stream re-validates and emits.
        mockPr.pullRequests['o/r/7'] = const GitHubPullRequest(
          number: 7,
          title: 'Updated title',
          body: 'Test body',
          state: 'open',
          isDraft: false,
          userLogin: 'testuser',
          htmlUrl: 'https://github.com/o/r/pull/7',
          externalId: 'node_7',
          headSha: 'abc124',
          baseRef: 'main',
          baseSha: 'base123',
          headRef: 'feature/test',
          requestedReviewers: [],
          assignees: [],
        );
        signals.notify(workspaceId: 'ws1', repoFullName: 'o/r', prNumber: 7);
        await pump();
        expect(titles, ['Test PR 7', 'Updated title']);

        // A signal with nothing changed emits nothing (dedupe).
        signals.notify(workspaceId: 'ws1', repoFullName: 'o/r', prNumber: 7);
        await pump();
        expect(titles, hasLength(2));

        await sub.cancel();
      },
    );

    test('signals for another PR / repo / workspace are ignored', () async {
      mockPr.pullRequests['o/r/7'] = _testPR(7);
      var fetchCount = 0;
      mockPr.getPullRequestHook = (cancelToken) async {
        fetchCount++;
        return mockPr.pullRequests['o/r/7'];
      };
      final repo = _makeRepo(
        db: db,
        apiClient: apiClient,
        changeSignals: signals,
      );

      final sub = repo.watchPullRequest(7).listen((_) {});
      await pump();
      final baseline = fetchCount;

      signals.notify(workspaceId: 'ws1', repoFullName: 'o/r', prNumber: 8);
      signals.notify(workspaceId: 'ws1', repoFullName: 'x/y', prNumber: 7);
      signals.notify(workspaceId: 'ws2', repoFullName: 'o/r', prNumber: 7);
      await pump();
      expect(fetchCount, baseline, reason: 'no foreign signal may refetch');

      await sub.cancel();
    });

    test('checks-only signals do not refetch non-check data', () async {
      mockPr.pullRequests['o/r/7'] = _testPR(7);
      var fetchCount = 0;
      mockPr.getPullRequestHook = (cancelToken) async {
        fetchCount++;
        return mockPr.pullRequests['o/r/7'];
      };
      final repo = _makeRepo(
        db: db,
        apiClient: apiClient,
        changeSignals: signals,
      );

      final sub = repo.watchPullRequest(7).listen((_) {});
      await pump();
      final baseline = fetchCount;

      signals.notify(
        workspaceId: 'ws1',
        repoFullName: 'o/r',
        prNumber: 7,
        checksOnly: true,
      );
      await pump();
      expect(fetchCount, baseline);

      await sub.cancel();
    });

    test('invalidatePullRequest signals open streams to refetch', () async {
      mockPr.pullRequests['o/r/7'] = _testPR(7);
      final repo = _makeRepo(
        db: db,
        apiClient: apiClient,
        changeSignals: signals,
      );

      final titles = <String>[];
      final sub = repo
          .watchPullRequest(7)
          .listen((pr) => titles.add(pr?.title ?? ''));
      await pump();
      expect(titles, ['Test PR 7']);

      mockPr.pullRequests['o/r/7'] = const GitHubPullRequest(
        number: 7,
        title: 'After invalidate',
        body: 'Test body',
        state: 'open',
        isDraft: false,
        userLogin: 'testuser',
        htmlUrl: 'https://github.com/o/r/pull/7',
        externalId: 'node_7',
        headSha: 'abc125',
        baseRef: 'main',
        baseSha: 'base123',
        headRef: 'feature/test',
        requestedReviewers: [],
        assignees: [],
      );
      await repo.invalidatePullRequest(7);
      await pump();
      expect(titles, ['Test PR 7', 'After invalidate']);

      await sub.cancel();
    });

    test('without a signals bus the stream keeps one-shot behavior', () async {
      mockPr.pullRequests['o/r/7'] = _testPR(7);
      final repo = _makeRepo(db: db, apiClient: apiClient);

      // Completes on its own — legacy SWR contract for signal-less hosts.
      final results = await repo.watchPullRequest(7).toList();
      expect(results, hasLength(1));
    });

    test('PR cache keys are repo-scoped (no cross-repo collision)', () async {
      mockPr.pullRequests['o/r/7'] = _testPR(7);
      final repo = _makeRepo(
        db: db,
        apiClient: apiClient,
        changeSignals: signals,
      );
      final sub = repo.watchPullRequest(7).listen((_) {});
      await pump();
      expect(await db.cacheDao.read('ws1', 'prDetail', 'o/r#7'), isNotNull);
      // The bare-number key of the pre-repo-scoped scheme must stay unused.
      expect(await db.cacheDao.read('ws1', 'prDetail', '7'), isNull);
      await sub.cancel();
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
      await db.cacheDao.put(
        'ws1',
        'prDetail',
        'o/r#42',
        '{"number":42,"title":"Cached PR","body":"","state":"open","is_draft":false,'
            '"author":{"login":"cached","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_sha":"aaa","head_ref":"f","base_ref":"m","base_sha":"old-base",'
            '"requested_reviewers":[],"assignees":[]}',
      );

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchPullRequest(42).toList();
      expect(results.length, 2);
      expect(results[0]!.title, 'Cached PR');
      expect(results[1]!.title, 'Test PR 42');
    });

    test('cache miss emits only fresh data', () async {
      mockPr.pullRequests['o/r/1'] = _testPR(1);

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchPullRequest(1).toList();
      expect(results.length, 1);
      expect(results[0]!.number, 1);
    });

    test('swallows network error when cache exists', () async {
      await db.cacheDao.put(
        'ws1',
        'prDetail',
        'o/r#1',
        '{"number":1,"title":"Cached","body":"","state":"open","is_draft":false,'
            '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_sha":"a","head_ref":"f","base_ref":"m","base_sha":"old",'
            '"requested_reviewers":[],"assignees":[]}',
      );
      // Throw an error to simulate network failure.
      mockPr.getPullRequestError = Exception('Network error');

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchPullRequest(1).toList();
      expect(results.length, 1);
      expect(results[0]!.title, 'Cached');
    });

    test('corrupt cache falls through to fetch', () async {
      mockPr.pullRequests['o/r/99'] = _testPR(99);
      await db.cacheDao.put('ws1', 'prDetail', 'o/r#99', '{invalid json');

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchPullRequest(99).toList();
      expect(results.length, 1);
      expect(results[0]!.number, 99);
    });

    test('cache hit for watchDiff emits stale then fresh', () async {
      mockPr.diffs['o/r/42'] = 'fresh diff';
      await db.cacheDao.put('ws1', 'prDiff', 'o/r#42', 'cached diff');

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchDiff(42).toList();
      expect(results, ['cached diff', 'fresh diff']);
    });

    test('cache hit for watchFiles emits cached files', () async {
      await db.cacheDao.put(
        'ws1',
        'prFiles',
        'o/r#1',
        '[{"filename":"cached.dart","status":"added","additions":5,'
            '"deletions":0,"changes":5,"patch":""}]',
      );

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchFiles(1).toList();
      expect(results.length, 1);
      expect(results[0][0].filename, 'cached.dart');
    });

    test('cache hit for watchCommits', () async {
      await db.cacheDao.put(
        'ws1',
        'prCommits',
        'o/r#1',
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

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchCommits(1).toList();
      expect(results.length, 2);
      expect(results[0][0].sha, 'cached');
      expect(results[1][0].sha, 'abc');
    });

    test('cache hit for watchReviews', () async {
      await db.cacheDao.put(
        'ws1',
        'prReviews',
        'o/r#1',
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

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchReviews(1).toList();
      expect(results.length, 2);
      expect(results[0][0].body, 'ok');
      expect(results[1][0].body, 'LGTM');
    });

    test('watchReviews joins GraphQL reactions and marks the viewer', () async {
      mockPr.reviews['o/r/1'] = [
        const GitHubReview(
          id: 5,
          state: GitHubReviewState.approved,
          body: 'LGTM',
          submittedAt: null,
        ),
        const GitHubReview(
          id: 6,
          state: GitHubReviewState.commented,
          body: 'notes',
          submittedAt: null,
        ),
      ];
      apiClient.graphqlStub.reviewReactions = [
        const GitHubReviewReactionSet(
          databaseId: 5,
          nodeId: 'PRR_5',
          reactions: [
            GitHubReviewReaction(id: 'R1', content: '+1', login: 'sam'),
            GitHubReviewReaction(id: 'R2', content: '+1', login: 'ada'),
            GitHubReviewReaction(id: 'R3', content: 'rocket', login: 'ada'),
          ],
        ),
      ];
      mockContent.authenticatedUser = const GitHubUser(
        login: 'sam',
        avatarUrl: '',
      );

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchReviews(1).toList();
      final fresh = results.last;
      expect(fresh[0].reactions, hasLength(2));
      final plusOne = fresh[0].reactions[0];
      expect(plusOne.content, '+1');
      expect(plusOne.count, 2);
      expect(plusOne.usernames, ['sam', 'ada']);
      expect(plusOne.userReacted, isTrue);
      final rocket = fresh[0].reactions[1];
      expect(rocket.userReacted, isFalse);
      // A review the listing did not mention keeps its empty reactions.
      expect(fresh[1].reactions, isEmpty);
    });

    test('watchReviews survives a GraphQL reaction failure', () async {
      mockPr.reviews['o/r/1'] = [
        const GitHubReview(
          id: 5,
          state: GitHubReviewState.approved,
          body: 'LGTM',
          submittedAt: null,
        ),
      ];
      apiClient.graphqlStub.listReviewReactionsError = StateError('graphql');

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchReviews(1).toList();
      expect(results.last[0].body, 'LGTM');
      expect(results.last[0].reactions, isEmpty);
    });

    test('cache hit for watchReviewComments', () async {
      await db.cacheDao.put(
        'ws1',
        'prReviewComments',
        'o/r#1',
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

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchReviewComments(1).toList();
      expect(results.length, 2);
      expect(results[0][0].id, 8);
      expect(results[1][0].id, 10);
    });

    test('cache hit for watchIssueComments', () async {
      await db.cacheDao.put(
        'ws1',
        'prIssueComments',
        'o/r#1',
        '[{"id":15,"body":"cached issue comment"}]',
      );
      mockPr.issueComments['o/r/1'] = [
        const GitHubIssueComment(id: 20, body: 'looks good'),
      ];

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchIssueComments(1).toList();
      expect(results.length, 2);
      expect(results[0][0].id, 15);
      expect(results[1][0].id, 20);
    });

    test('watchFileContent caches and returns stale then fresh', () async {
      mockContent.fileContents['o/r/src/a.dart|main'] = 'fresh content';
      await db.cacheDao.put(
        'ws1',
        'prFileContent',
        'o/r|src/a.dart|main',
        'cached',
      );

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo
          .watchFileContent('src/a.dart', 'main')
          .toList();
      expect(results, ['cached', 'fresh content']);
    });
  });

  // -- Invalidation on mutations -------------------------------------------

  group('CachedPrReviewRepository - invalidation on mutations', () {
    test('invalidatePullRequest removes all PR-scoped cache entries', () async {
      await db.cacheDao.put('ws1', 'prDetail', 'o/r#42', '{}');
      await db.cacheDao.put('ws1', 'prDiff', 'o/r#42', 'diff');
      await db.cacheDao.put('ws1', 'prFiles', 'o/r#42', '[]');
      await db.cacheDao.put('ws1', 'prCommits', 'o/r#42', '[]');
      await db.cacheDao.put('ws1', 'prReviews', 'o/r#42', '[]');
      await db.cacheDao.put('ws1', 'prReviewComments', 'o/r#42', '[]');
      await db.cacheDao.put('ws1', 'prIssueComments', 'o/r#42', '[]');
      await db.cacheDao.put('ws1', 'prCheckRuns', 'o/r#42', '[]');
      await db.cacheDao.put('ws1', 'prReviewerState', 'o/r#42', '[]');
      await db.cacheDao.put('ws1', 'assignableUsers', 'o/r', '[]');

      final repo = _makeRepo(db: db, apiClient: apiClient);
      await repo.invalidatePullRequest(42);

      expect(await db.cacheDao.read('ws1', 'prDetail', 'o/r#42'), isNull);
      expect(await db.cacheDao.read('ws1', 'prDiff', 'o/r#42'), isNull);
      expect(await db.cacheDao.read('ws1', 'prFiles', 'o/r#42'), isNull);
      expect(await db.cacheDao.read('ws1', 'prCommits', 'o/r#42'), isNull);
      expect(await db.cacheDao.read('ws1', 'prReviews', 'o/r#42'), isNull);
      expect(
        await db.cacheDao.read('ws1', 'prReviewComments', 'o/r#42'),
        isNull,
      );
      expect(
        await db.cacheDao.read('ws1', 'prIssueComments', 'o/r#42'),
        isNull,
      );
      expect(await db.cacheDao.read('ws1', 'prCheckRuns', 'o/r#42'), isNull);
      expect(
        await db.cacheDao.read('ws1', 'prReviewerState', 'o/r#42'),
        isNull,
      );
      expect(await db.cacheDao.read('ws1', 'assignableUsers', 'o/r'), '[]');
    });

    test('invalidateDiff removes only diff and files entries', () async {
      await db.cacheDao.put('ws1', 'prDiff', 'o/r#42', 'diff');
      await db.cacheDao.put('ws1', 'prFiles', 'o/r#42', '[]');
      await db.cacheDao.put('ws1', 'prDetail', 'o/r#42', '{}');

      final repo = _makeRepo(db: db, apiClient: apiClient);
      await repo.invalidateDiff(42);

      expect(await db.cacheDao.read('ws1', 'prDiff', 'o/r#42'), isNull);
      expect(await db.cacheDao.read('ws1', 'prFiles', 'o/r#42'), isNull);
      expect(await db.cacheDao.read('ws1', 'prDetail', 'o/r#42'), '{}');
    });

    test('invalidatePullRequest does not affect unrelated PR', () async {
      await db.cacheDao.put('ws1', 'prDetail', 'o/r#42', 'data42');
      await db.cacheDao.put('ws1', 'prDetail', 'o/r#99', 'data99');

      final repo = _makeRepo(db: db, apiClient: apiClient);
      await repo.invalidatePullRequest(42);

      expect(await db.cacheDao.read('ws1', 'prDetail', 'o/r#42'), isNull);
      expect(await db.cacheDao.read('ws1', 'prDetail', 'o/r#99'), 'data99');
    });
  });

  // -- Workspace scoping ---------------------------------------------------

  group('CachedPrReviewRepository - workspace scoping', () {
    test('different workspace IDs are isolated', () async {
      await db.cacheDao.put(
        'ws1',
        'prDetail',
        'o/r#1',
        '{"number":1,"title":"ws1-data","body":"","state":"open","is_draft":false,'
            '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_sha":"s","head_ref":"f","base_sha":"old","base_ref":"m",'
            '"requested_reviewers":[],"assignees":[]}',
      );
      await otherDb.cacheDao.put(
        'ws2',
        'prDetail',
        'o/r#1',
        '{"number":1,"title":"ws2-data","body":"","state":"open","is_draft":false,'
            '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_sha":"s","head_ref":"f","base_sha":"old","base_ref":"m",'
            '"requested_reviewers":[],"assignees":[]}',
      );

      mockPr.pullRequests['o/r/1'] = _testPR(1);

      final repo1 = _makeRepo(db: db, apiClient: apiClient);
      final results1 = await repo1.watchPullRequest(1).toList();
      expect(results1.length, 2);
      expect(results1[0]!.title, 'ws1-data');

      final repo2 = _makeRepo(db: otherDb, apiClient: apiClient);
      final results2 = await repo2.watchPullRequest(1).toList();
      expect(results2.length, 2);
      expect(results2[0]!.title, 'ws2-data');
    });

    test('invalidation cannot reach another workspace', () async {
      await db.cacheDao.put('ws1', 'prDetail', 'o/r#1', 'ws1');
      await otherDb.cacheDao.put('ws2', 'prDetail', 'o/r#1', 'ws2');

      await _makeRepo(db: db, apiClient: apiClient).invalidatePullRequest(1);

      expect(await db.cacheDao.read('ws1', 'prDetail', 'o/r#1'), isNull);
      // Structurally out of reach: ws2's entry lives in a different database
      // file, so no invalidation issued against ws1 can touch it.
      expect(await otherDb.cacheDao.read('ws2', 'prDetail', 'o/r#1'), 'ws2');
    });

    test('same workspace id shares cache', () async {
      await db.cacheDao.put(
        'ws1',
        'prDetail',
        'o/r#42',
        '{"number":42,"title":"shared","body":"","state":"open","is_draft":false,'
            '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_sha":"aaa","head_ref":"f","base_ref":"m","base_sha":"old-base",'
            '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.pullRequests['o/r/42'] = _testPR(42);

      final repoA = _makeRepo(db: db, apiClient: apiClient);
      final resultsA = await repoA.watchPullRequest(42).toList();
      expect(resultsA[0]!.title, 'shared');

      final repoB = _makeRepo(db: db, apiClient: apiClient);
      final resultsB = await repoB.watchPullRequest(42).toList();
      // repoA's fetch updated the cache, so repoB sees the fresh value.
      expect(resultsB.length, 1);
      expect(resultsB[0]!.title, 'Test PR 42');
    });
  });

  // -- Draft methods --------------------------------------------------------

  group('CachedPrReviewRepository - draft methods', () {
    test('upsertDraft delegates to draftDao', () async {
      final repo = _makeRepo(db: db, apiClient: apiClient);
      await repo.upsertDraft(1, 'my draft');
      expect(await db.reviewDao.getDraft('o', 'r', 1), 'my draft');
    });

    test('getDraft delegates to draftDao', () async {
      await db.reviewDao.upsertDraft('o', 'r', 1, 'saved draft');
      final repo = _makeRepo(db: db, apiClient: apiClient);
      expect(await repo.getDraft(1), 'saved draft');
    });

    test('clearDraft delegates to draftDao', () async {
      await db.reviewDao.upsertDraft('o', 'r', 1, 'temp');
      final repo = _makeRepo(db: db, apiClient: apiClient);
      await repo.clearDraft(1);
      expect(await db.reviewDao.getDraft('o', 'r', 1), isNull);
    });
  });

  // -- Diff freshness: head/base sha change ----------------------------------

  group('CachedPrReviewRepository - diff freshness', () {
    test('reuses cache when head and base sha unchanged', () async {
      await db.cacheDao.put('ws1', 'prDiff', 'o/r#42', 'cached diff');
      await db.cacheDao.put(
        'ws1',
        'prDetail',
        'o/r#42',
        '{"number":42,"title":"PR","body":"","state":"open","is_draft":false,'
            '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_sha":"abc123","head_ref":"f","base_sha":"base123","base_ref":"m",'
            '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.pullRequests['o/r/42'] = _testPR(42); // same sha

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchDiff(42).toList();
      expect(results, ['cached diff']);
    });

    test('fetches fresh diff when head sha changed', () async {
      await db.cacheDao.put('ws1', 'prDiff', 'o/r#42', 'old diff');
      await db.cacheDao.put(
        'ws1',
        'prDetail',
        'o/r#42',
        '{"number":42,"title":"PR","body":"","state":"open","is_draft":false,'
            '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_sha":"old-sha","head_ref":"f","base_sha":"base123","base_ref":"m",'
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
        externalId: 'n',
        headSha: 'new-sha',
        baseRef: 'm',
        baseSha: 'base123',
        headRef: 'f',
        requestedReviewers: [],
        assignees: [],
      );

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchDiff(42).toList();
      expect(results, ['old diff', 'fresh diff']);
    });

    test('fetches fresh diff when base sha changed', () async {
      await db.cacheDao.put('ws1', 'prDiff', 'o/r#42', 'stale diff');
      await db.cacheDao.put(
        'ws1',
        'prDetail',
        'o/r#42',
        '{"number":42,"title":"PR","body":"","state":"open","is_draft":false,'
            '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_sha":"abc123","head_ref":"f","base_sha":"old-base","base_ref":"m",'
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
        externalId: 'n',
        headSha: 'abc123',
        baseRef: 'm',
        baseSha: 'new-base',
        headRef: 'f',
        requestedReviewers: [],
        assignees: [],
      );

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchDiff(42).toList();
      expect(results, ['stale diff', 'fresh diff']);
    });
  });

  // -- cancellation safety --------------------------------------------------
  //
  // Navigating between PRs (or pressing back mid-load) tears down the
  // autoDispose stream, which fires the CancelToken and makes any in-flight
  // GitHub request throw a dio cancellation. That cancellation must NEVER
  // escape the SWR generators as an error: in the server's root isolate an
  // unhandled error is fatal and the abrupt VM teardown then races the drift
  // background isolate's sqlite finalizers into a `sqlite3_finalize` segfault.

  group('CachedPrReviewRepository - cancellation safety', () {
    // The prDetail cache the diff freshness probe reads head+base SHA from
    // before it makes its (cancellable) getPullRequest call.
    const prDetailJson =
        '{"number":42,"title":"PR","body":"","state":"open","is_draft":false,'
        '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
        '"head_sha":"abc123","head_ref":"f","base_sha":"base123","base_ref":"m",'
        '"requested_reviewers":[],"assignees":[]}';

    DioException cancelException() => DioException(
      requestOptions: RequestOptions(path: '/pulls/42'),
      type: DioExceptionType.cancel,
    );

    test('watchDiff swallows a cancellation in the freshness probe', () async {
      await db.cacheDao.put('ws1', 'prDiff', 'o/r#42', 'cached diff');
      await db.cacheDao.put('ws1', 'prDetail', 'o/r#42', prDetailJson);
      // The freshness probe's getPullRequest is cancelled.
      mockPr.getPullRequestError = cancelException();

      final repo = _makeRepo(db: db, apiClient: apiClient);

      // Before the fix this threw the DioException out of the stream; now the
      // cancellation is swallowed and only the cached diff is yielded.
      final results = await repo.watchDiff(42).toList();
      expect(results, ['cached diff']);
    });

    test(
      'cancelling the diff subscription mid-probe raises no unhandled error',
      () async {
        await db.cacheDao.put('ws1', 'prDiff', 'o/r#42', 'cached diff');
        await db.cacheDao.put('ws1', 'prDetail', 'o/r#42', prDetailJson);

        // Hold the freshness probe in-flight until the subscription is
        // cancelled, then abort exactly as dio does — wait on the token, throw
        // a cancellation. This is the exact ordering that crashed the server:
        // the error is thrown into an already-cancelled generator.
        final probeStarted = Completer<void>();
        mockPr.getPullRequestHook = (cancelToken) async {
          if (!probeStarted.isCompleted) {
            probeStarted.complete();
          }
          await cancelToken?.whenCancel;
          throw cancelException();
        };

        final repo = _makeRepo(db: db, apiClient: apiClient);

        final zoneErrors = <Object>[];
        await runZonedGuarded(() async {
          final sub = repo.watchDiff(42).listen((_) {});
          await probeStarted.future; // probe is now suspended on the token
          await sub.cancel(); // navigate away → CancelToken.cancel() → abort
          await Future<void>.delayed(Duration.zero);
        }, (error, stack) => zoneErrors.add(error));

        expect(zoneErrors, isEmpty);
      },
    );
  });

  // -- watchPullRequest edge cases ------------------------------------------

  group('CachedPrReviewRepository - watchPullRequest edge cases', () {
    test('rethrows network error when no cache exists', () async {
      mockPr.getPullRequestError = Exception('Boom');
      final repo = _makeRepo(db: db, apiClient: apiClient);

      await expectLater(
        repo.watchPullRequest(1).toList(),
        throwsA(isA<Exception>()),
      );
    });

    test('yields null when API returns null', () async {
      // Not inserting an entry into pullRequests — getPullRequest returns null.

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchPullRequest(42).toList();
      expect(results, [null]);
    });
  });

  // -- watchCommitFiles -----------------------------------------------------

  group('CachedPrReviewRepository - watchCommitFiles', () {
    test('returns empty list for empty sha', () async {
      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchCommitFiles('').toList();
      expect(results, [isEmpty]);
    });

    test('cache hit emits stale then fresh', () async {
      await db.cacheDao.put(
        'ws1',
        'prCommitFiles',
        'o/r|abc123',
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

      final repo = _makeRepo(db: db, apiClient: apiClient);
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
        externalId: 'n',
        headSha: 'abc123',
        baseRef: 'main',
        baseSha: 'base123',
        headRef: 'feature/x',
        requestedReviewers: [],
        assignees: [],
        changedFiles: 5,
      );
      final apiSource = FakePrDiffSource(
        files: [
          PrFile(
            filename: 'src/api.dart',
            status: PrFileStatus.added,
            additions: 10,
            deletions: 0,
            patch: '',
          ),
        ],
      );

      final repo = _makeRepo(
        db: db,
        apiClient: apiClient,
        apiDiffSource: apiSource,
      );
      final results = await repo.watchFiles(42).toList();
      expect(results.length, 1);
      expect(results[0][0].filename, 'src/api.dart');
    });

    test('cache stale yields cached then fresh', () async {
      await db.cacheDao.put(
        'ws1',
        'prFiles',
        'o/r#42',
        '[{"filename":"old.dart","status":"modified","additions":1,'
            '"deletions":0,"changes":1,"patch":""}]',
      );
      await db.cacheDao.put(
        'ws1',
        'prDetail',
        'o/r#42',
        '{"number":42,"title":"PR","body":"","state":"open","is_draft":false,'
            '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_sha":"old-sha","head_ref":"f","base_sha":"base123","base_ref":"m",'
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
        externalId: 'n',
        headSha: 'new-sha',
        baseRef: 'main',
        baseSha: 'base123',
        headRef: 'feature/x',
        requestedReviewers: [],
        assignees: [],
        changedFiles: 5,
      );
      final apiSource = FakePrDiffSource(
        files: [
          PrFile(
            filename: 'new.dart',
            status: PrFileStatus.added,
            additions: 1,
            deletions: 0,
            patch: '',
          ),
        ],
      );

      final repo = _makeRepo(
        db: db,
        apiClient: apiClient,
        apiDiffSource: apiSource,
      );
      final results = await repo.watchFiles(42).toList();
      expect(results.length, 2);
      expect(results[0][0].filename, 'old.dart');
      expect(results[1][0].filename, 'new.dart');
    });

    test('cache current skips re-fetch when sha unchanged', () async {
      await db.cacheDao.put(
        'ws1',
        'prFiles',
        'o/r#42',
        '[{"filename":"fresh.dart","status":"added","additions":2,'
            '"deletions":0,"changes":2,'
            r'"patch":"@@ -0,0 +1,2 @@\n+one\n+two"}]',
      );
      await db.cacheDao.put(
        'ws1',
        'prDetail',
        'o/r#42',
        '{"number":42,"title":"PR","body":"","state":"open","is_draft":false,'
            '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_sha":"abc123","head_ref":"f","base_sha":"base123","base_ref":"m",'
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
        externalId: 'n',
        headSha: 'abc123',
        baseRef: 'main',
        baseSha: 'base123',
        headRef: 'feature/x',
        requestedReviewers: [],
        assignees: [],
        changedFiles: 5,
      );

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchFiles(42).toList();
      // Cache is current — only one emission.
      expect(results.length, 1);
      expect(results[0][0].filename, 'fresh.dart');
    });

    // -- withheld patches (oversized file diffs) ----------------------------
    //
    // A forge drops `patch` once a single file's diff outgrows its per-file
    // response cap: the file still reports its +/- counts, but its body is
    // empty and the viewer renders an expanded accordion with nothing in it.
    // The PR's raw unified diff has no per-file cap, so it is the refill.

    test('backfills a patch the forge withheld from the raw diff', () async {
      mockPr.pullRequests['o/r/42'] = _ghPr(changedFiles: 2);
      mockPr.diffs['o/r/42'] = _rawDiff;
      final apiSource = FakePrDiffSource(
        files: [
          PrFile(
            filename: 'small.dart',
            status: PrFileStatus.modified,
            additions: 1,
            deletions: 1,
            patch: '@@ -1,2 +1,2 @@\n-old\n+new\n keep',
          ),
          // What GitHub actually sends for an oversized file: real counts,
          // no patch.
          PrFile(
            filename: 'huge.json',
            status: PrFileStatus.modified,
            additions: 1,
            deletions: 1,
            patch: '',
          ),
        ],
      );

      final repo = _makeRepo(
        db: db,
        apiClient: apiClient,
        apiDiffSource: apiSource,
      );
      final results = await repo.watchFiles(42).toList();

      // The source's own emission first, then the backfilled one.
      expect(results.length, 2);
      expect(results.first[1].patch, isEmpty);
      final filled = results.last;
      expect(filled[1].filename, 'huge.json');
      expect(filled[1].patch, '@@ -1,3 +1,3 @@\n {\n-  "a": 1\n+  "a": 2\n }');
      // Files that already had a patch are untouched.
      expect(filled[0].patch, '@@ -1,2 +1,2 @@\n-old\n+new\n keep');
      // The refilled list is what gets cached, so the next open is instant.
      final cached = await db.cacheDao.read('ws1', 'prFiles', 'o/r#42');
      expect(cached, contains('@@ -1,3 +1,3 @@'));
    });

    test(
      're-emits nothing when the raw diff cannot supply the patch',
      () async {
        mockPr.pullRequests['o/r/42'] = _ghPr(changedFiles: 1);
        mockPr.diffError = Exception('406 diff too large');
        final apiSource = FakePrDiffSource(
          files: [
            PrFile(
              filename: 'huge.json',
              status: PrFileStatus.modified,
              additions: 900,
              deletions: 4000,
              patch: '',
            ),
          ],
        );

        final repo = _makeRepo(
          db: db,
          apiClient: apiClient,
          apiDiffSource: apiSource,
        );
        final results = await repo.watchFiles(42).toList();

        expect(results.length, 1);
        expect(results.single.single.patch, isEmpty);
      },
    );

    test('does not fetch the raw diff for a pure rename', () async {
      mockPr.pullRequests['o/r/42'] = _ghPr(changedFiles: 1);
      mockPr.diffs['o/r/42'] = _rawDiff;
      final apiSource = FakePrDiffSource(
        files: [
          // A rename with no content change carries no patch legitimately.
          PrFile(
            filename: 'new/name.dart',
            status: PrFileStatus.renamed,
            additions: 0,
            deletions: 0,
            patch: '',
            previousFilename: 'old/name.dart',
          ),
        ],
      );

      final repo = _makeRepo(
        db: db,
        apiClient: apiClient,
        apiDiffSource: apiSource,
      );
      final results = await repo.watchFiles(42).toList();

      expect(results.length, 1);
      expect(mockPr.diffCalls, 0);
    });

    test('revalidates a cached list still missing a withheld patch', () async {
      // Written by a pass whose backfill never ran (or could not complete).
      // The head SHA has not moved, so the SWR fast path would normally serve
      // this and return — leaving the file bodyless until the PR is pushed to.
      await db.cacheDao.put(
        'ws1',
        'prFiles',
        'o/r#42',
        '[{"filename":"huge.json","status":"modified","additions":1,'
            '"deletions":1,"changes":2,"patch":""}]',
      );
      await db.cacheDao.put(
        'ws1',
        'prDetail',
        'o/r#42',
        '{"number":42,"title":"PR","body":"","state":"open","is_draft":false,'
            '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_sha":"abc123","head_ref":"f","base_sha":"base123","base_ref":"m",'
            '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.pullRequests['o/r/42'] = _ghPr(changedFiles: 1);
      mockPr.diffs['o/r/42'] = _rawDiff;
      final apiSource = FakePrDiffSource(
        files: [
          PrFile(
            filename: 'huge.json',
            status: PrFileStatus.modified,
            additions: 1,
            deletions: 1,
            patch: '',
          ),
        ],
      );

      final repo = _makeRepo(
        db: db,
        apiClient: apiClient,
        apiDiffSource: apiSource,
      );
      final results = await repo.watchFiles(42).toList();

      expect(results.last.single.patch, isNotEmpty);
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
        externalId: 'n',
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
        db: db,
        apiClient: apiClient,
        apiDiffSource: errorSource,
      );
      final results = await repo.watchFilesLoad(42).toList();
      expect(results.length, 1);
      expect(results[0].error, isA<Exception>());
      expect(results[0].isComplete, isTrue);
    });

    test('fetch error with cache swallows and uses cache', () async {
      await db.cacheDao.put(
        'ws1',
        'prFiles',
        'o/r#42',
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
        externalId: 'n',
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
        db: db,
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
      await db.cacheDao.put('ws1', 'prDiff', 'o/r#42', 'old diff');
      // Cached PR detail without head.sha.
      await db.cacheDao.put(
        'ws1',
        'prDetail',
        'o/r#42',
        '{"number":42,"title":"PR","body":"","state":"open","is_draft":false,'
            '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_ref":"f","base_sha":"base123","base_ref":"m",'
            '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.diffs['o/r/42'] = 'fresh diff';
      mockPr.pullRequests['o/r/42'] = _testPR(42);

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchDiff(42).toList();
      expect(results, ['old diff', 'fresh diff']);
    });

    test('revalidates when cached base sha is missing', () async {
      await db.cacheDao.put('ws1', 'prDiff', 'o/r#42', 'stale diff');
      // Cached PR detail without base.sha.
      await db.cacheDao.put(
        'ws1',
        'prDetail',
        'o/r#42',
        '{"number":42,"title":"PR","body":"","state":"open","is_draft":false,'
            '"author":{"login":"u","avatar_url":""},"html_url":"","external_id":"n",'
            '"head_sha":"abc123","head_ref":"f","base_ref":"m",'
            '"requested_reviewers":[],"assignees":[]}',
      );
      mockPr.diffs['o/r/42'] = 'fresh diff';
      mockPr.pullRequests['o/r/42'] = _testPR(42);

      final repo = _makeRepo(db: db, apiClient: apiClient);
      final results = await repo.watchDiff(42).toList();
      expect(results, ['stale diff', 'fresh diff']);
    });
  });

  // -- Mutation no-ops (early returns before API call) -----------------------

  group('CachedPrReviewRepository - mutation no-ops', () {
    test('updatePullRequest with both null returns immediately', () async {
      final repo = _makeRepo(db: db, apiClient: apiClient);
      // Should not throw — early return before API call.
      await repo.updatePullRequest(prNumber: 1);
    });

    test('addAssignees with empty list returns immediately', () async {
      final repo = _makeRepo(db: db, apiClient: apiClient);
      await repo.addAssignees(prNumber: 1, logins: const []);
    });

    test('removeAssignees with empty list returns immediately', () async {
      final repo = _makeRepo(db: db, apiClient: apiClient);
      await repo.removeAssignees(prNumber: 1, logins: const []);
    });

    test(
      'requestReviewers with empty userLogins and teamSlugs returns immediately',
      () async {
        final repo = _makeRepo(db: db, apiClient: apiClient);
        await repo.requestReviewers(prNumber: 1);
      },
    );

    test(
      'removeRequestedReviewers with empty lists returns immediately',
      () async {
        final repo = _makeRepo(db: db, apiClient: apiClient);
        await repo.removeRequestedReviewers(prNumber: 1);
      },
    );
  });

  // -- Invalidation edge cases ----------------------------------------------

  group('CachedPrReviewRepository - invalidation edge cases', () {
    test('invalidatePullRequest does not remove prCodeOwnerIds', () async {
      await db.cacheDao.put(
        'ws1',
        'prCodeOwnerIds',
        'o/r#42',
        '{"ids":["alice","bob"]}',
      );
      await db.cacheDao.put('ws1', 'prDetail', 'o/r#42', 'data');

      final repo = _makeRepo(db: db, apiClient: apiClient);
      await repo.invalidatePullRequest(42);

      expect(await db.cacheDao.read('ws1', 'prDetail', 'o/r#42'), isNull);
      expect(
        await db.cacheDao.read('ws1', 'prCodeOwnerIds', 'o/r#42'),
        '{"ids":["alice","bob"]}',
      );
    });
  });
}
