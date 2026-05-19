import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/job_run_detail.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_thread_state.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_stack.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_infra/src/network/github_graphql_client.dart';
import 'package:cc_infra/src/network/models/github_check_run.dart';
import 'package:cc_infra/src/network/models/github_job_run.dart';
import 'package:cc_infra/src/network/models/github_pull_request.dart';
import 'package:cc_infra/src/network/models/github_reaction.dart';
import 'package:cc_infra/src/network/models/github_workflow_run.dart';
import 'package:cc_infra/src/network/pr_review_mapper.dart';
import 'package:cc_infra/src/network/workflow_graph_parser.dart';
import 'package:dio/dio.dart';

/// GitHub's implementation of [ForgePrClient].
///
/// A thin anti-corruption adapter: every method delegates to the existing
/// [GitHubApiClient] sub-clients (`pr` / `graphql` / `content`) and maps the
/// wire models through `pr_review_mapper.dart` before returning. It holds no
/// cache, no drafts and no local-git fallback — those live above this seam in
/// the repository that composes it, so the adapter is a pure
/// "one network call, one mapping" surface.
///
/// One instance serves exactly one `owner/repo` pair; the coordinate is fixed
/// at construction and no method takes it again.
class GitHubForgePrClient implements ForgePrClient {
  /// Creates a [GitHubForgePrClient] for [owner]/[repo] over [client].
  GitHubForgePrClient({
    required GitHubApiClient client,
    required this.owner,
    required this.repo,
  }) : _client = client;

  final GitHubApiClient _client;

  @override
  final String owner;

  @override
  final String repo;

  /// The authenticated user's login, resolved lazily and kept for the lifetime
  /// of this client. Needed by [toggleReaction] to find the reaction to delete;
  /// the port deliberately does not thread it through every call.
  String? _viewerLogin;

  @override
  ForgeHost get forge => ForgeHost.github;

  @override
  ForgeCapabilities get capabilities => capabilitiesOf(ForgeHost.github);

  /// `owner/repo`, the form [PullRequest.repoFullName] carries.
  String get _repoFullName => '$owner/$repo';

  /// Narrows the port's dio-free [Object] token back to a dio [CancelToken].
  /// Anything else (including null) means "no cancellation".
  static CancelToken? _token(Object? cancelToken) =>
      cancelToken is CancelToken ? cancelToken : null;

  /// Whether [error] is a dio request cancellation, which callers treat as a
  /// benign teardown signal rather than a failure.
  static bool _isCancellation(Object error) =>
      error is DioException && error.type == DioExceptionType.cancel;

  // ── Reads ──────────────────────────────────────────────────────────────

  @override
  Future<PullRequest?> getPullRequest(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final gh = await _client.pr.getPullRequest(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    if (gh == null) {
      return null;
    }
    return pullRequestFromGitHub(gh, repoFullName: _repoFullName);
  }

  /// One page of open pull requests, in GitHub's `CREATED_AT DESC` order.
  ///
  /// Served by the same enriched GraphQL query the workspace poller uses, with
  /// this repo as a one-element batch: it carries diff size, comment count and
  /// requested reviewers (users *and* teams) in one round-trip, none of which
  /// the REST list endpoint returns. The checks/review-decision overlay is a
  /// best-effort second pass — a failure leaves rows at
  /// [PrChecksStatus.none] rather than failing the list.
  ///
  /// GitHub's page is fixed at 100, so [limit] only ever truncates; a truncated
  /// page reports `hasMore: true`.
  @override
  Future<({List<PullRequest> prs, bool hasMore})> listOpenPullRequests({
    int limit = 100,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final specs = [(owner: owner, name: repo)];
    final batch = await _client.graphql.fetchOpenPullRequestsBatch(
      specs,
      cancelToken: token,
    );
    // An absent alias means GitHub errored for this repo (no access, renamed);
    // an accessible repo with an empty queue comes back present-but-empty.
    final page = batch.byIndex[0];
    if (page == null) {
      return (prs: const <PullRequest>[], hasMore: false);
    }

    var overlays = <int, GitHubPrStatusOverlay>{};
    try {
      final byIndex = await _client.graphql.fetchOpenPullRequestsChecks(
        specs,
        cancelToken: token,
      );
      overlays = byIndex[0] ?? const {};
    } on Object {
      // Checks are best-effort; rows keep checksStatus.none on failure.
    }

    final prs = <PullRequest>[];
    for (final node in page.nodes) {
      final number = (node['number'] as num?)?.toInt() ?? 0;
      final title = node['title'] as String? ?? '';
      if (number <= 0 || title.isEmpty) {
        continue;
      }
      var pr = pullRequestFromGraphQlNode(node, repoFullName: _repoFullName);
      final overlay = overlays[pr.number];
      if (overlay != null) {
        pr = pr.copyWith(
          checksStatus: prChecksStatusFromRollup(overlay.checksRollup),
          reviewDecision: PrReviewDecision.fromString(overlay.reviewDecision),
        );
      }
      prs.add(pr);
    }

    if (prs.length > limit) {
      return (
        prs: List<PullRequest>.unmodifiable(prs.take(limit)),
        hasMore: true,
      );
    }
    return (prs: List<PullRequest>.unmodifiable(prs), hasMore: page.hasMore);
  }

  @override
  Future<List<PullRequest>> listMergedByAuthor(
    String login, {
    int limit = 50,
    Object? cancelToken,
  }) async {
    final result = await _client.pr.searchClosedPullRequestsByAuthor(
      owner,
      repo,
      login,
      cancelToken: _token(cancelToken),
    );
    // GitHub has no `state:merged`: a merged PR is `state:closed` with
    // `merged_at` set, so the recovered timestamp is the only thing separating
    // it from a PR that was closed unmerged.
    final merged = <GitHubPullRequest>[
      for (final gh in result.items)
        if (gh.mergedAt != null) gh,
    ]..sort((a, b) => b.mergedAt!.compareTo(a.mergedAt!));
    return List<PullRequest>.unmodifiable([
      for (final gh in merged.take(limit))
        pullRequestFromGitHub(gh, repoFullName: _repoFullName),
    ]);
  }

  @override
  Future<bool?> wasMerged(int prNumber, {Object? cancelToken}) async {
    try {
      final gh = await _client.pr.getPullRequest(
        owner,
        repo,
        prNumber,
        cancelToken: _token(cancelToken),
      );
      // A PR the poller can no longer resolve (404, revoked access, transient
      // failure) is "unknown", never "closed unmerged" — reporting a merge that
      // did not happen would fire the wrong lifecycle event.
      if (gh == null) {
        return null;
      }
      return gh.mergedAt != null;
    } on Object {
      return null;
    }
  }

  @override
  Future<String> getPullRequestDiff(int prNumber, {Object? cancelToken}) {
    return _client.pr.getPullRequestDiff(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
  }

  @override
  Future<List<PrFile>> listFiles(
    int prNumber, {
    int? limit,
    Object? cancelToken,
  }) async {
    // GitHub caps its files endpoint at 3 000 entries (30 pages of 100) and the
    // page stream stops there on its own; a smaller [limit] just stops sooner.
    final files = <PrFile>[];
    await for (final page in _client.pr.streamPullRequestFiles(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    )) {
      for (final gh in page) {
        files.add(prFileFromGitHub(gh));
      }
      if (limit != null && files.length >= limit) {
        return List<PrFile>.unmodifiable(files.take(limit));
      }
    }
    return List<PrFile>.unmodifiable(files);
  }

  @override
  Future<List<PrCommit>> listCommits(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final commits = await _client.pr.listAllPullRequestCommits(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return commits.map(prCommitFromGitHub).toList(growable: false);
  }

  @override
  Future<List<PrFile>> listCommitFiles(
    String sha, {
    Object? cancelToken,
  }) async {
    final files = await _client.pr.getCommitFiles(
      owner,
      repo,
      sha,
      cancelToken: _token(cancelToken),
    );
    return files.map(prFileFromGitHub).toList(growable: false);
  }

  @override
  Future<List<PrReviewSubmission>> listReviews(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final reviews = await _client.pr.listPullRequestReviews(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return reviews.map(prReviewSubmissionFromGitHub).toList(growable: false);
  }

  @override
  Future<List<PrReviewReactions>> listReviewReactions(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final sets = await _client.graphql.listReviewReactions(
      owner: owner,
      repo: repo,
      number: prNumber,
      cancelToken: _token(cancelToken),
    );
    return [
      for (final s in sets)
        PrReviewReactions(
          reviewId: s.databaseId,
          reactions: [
            for (final r in s.reactions)
              ForgeReaction(content: r.content, login: r.login),
          ],
        ),
    ];
  }

  @override
  Future<List<PrCodeReviewComment>> listReviewComments(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final comments = await _client.pr.listPullRequestReviewComments(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return comments.map(prCodeReviewCommentFromGitHub).toList(growable: false);
  }

  @override
  Future<List<PrReviewThreadState>> listReviewThreadStates(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final threads = await _client.graphql.listReviewThreads(
      owner: owner,
      repo: repo,
      number: prNumber,
      cancelToken: _token(cancelToken),
    );
    return [
      for (final t in threads)
        PrReviewThreadState(
          id: t.id,
          commentIds: t.commentIds,
          isResolved: t.isResolved,
          isOutdated: t.isOutdated,
        ),
    ];
  }

  @override
  Future<List<IssueComment>> listIssueComments(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final comments = await _client.pr.listIssueComments(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return comments.map(issueCommentFromGitHub).toList(growable: false);
  }

  @override
  Future<List<PrTimelineEvent>> listTimelineEvents(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final events = await _client.pr.listTimelineEvents(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return events
        .map(prTimelineEventFromGitHub)
        .nonNulls
        .toList(growable: false);
  }

  @override
  Future<List<CheckRun>> listCheckRuns(
    String headSha, {
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    // Fetch check runs and workflow runs concurrently — the check-runs API only
    // knows about the individual job (e.g. "Unit test (1)") and not its parent
    // workflow, so the results are joined by `check_suite_id` to recover the
    // workflow name from the actions/runs API.
    final results = await Future.wait([
      _client.pr.listCheckRuns(owner, repo, headSha, cancelToken: token),
      _client.pr.listWorkflowRuns(owner, repo, headSha, cancelToken: token),
    ]);
    final checkRuns = results[0] as List<GitHubCheckRun>;
    final workflowRuns = results[1] as List<GitHubWorkflowRun>;

    // Keep only the LATEST run per workflow file. Both endpoints answer with
    // every run ever created for the commit — a `push` / `pull_request` twin of
    // the same workflow, a manual re-run — and each run renders as its own
    // card, so the same jobs would appear once per run. Run ids are monotonic,
    // so the max id per workflow path is the current run.
    final latestRunByWorkflow = <String, GitHubWorkflowRun>{};
    for (final w in workflowRuns) {
      final key = w.path.isNotEmpty ? w.path : w.name;
      final current = latestRunByWorkflow[key];
      if (current == null || w.id > current.id) {
        latestRunByWorkflow[key] = w;
      }
    }
    final latestRuns = latestRunByWorkflow.values.toList(growable: false);
    final actionsSuites = <int>{
      for (final w in workflowRuns)
        if (w.checkSuiteId != 0) w.checkSuiteId,
    };
    final latestSuites = <int>{
      for (final w in latestRuns)
        if (w.checkSuiteId != 0) w.checkSuiteId,
    };
    bool isActionsCheck(GitHubCheckRun c) =>
        c.checkSuiteId != null && actionsSuites.contains(c.checkSuiteId);
    String dedupeKeyFor(GitHubCheckRun c) => isActionsCheck(c)
        ? 'suite:${c.checkSuiteId}:${c.name}'
        : 'app:${c.appName}:${c.name}';
    bool isSuperseded(GitHubCheckRun c) =>
        isActionsCheck(c) && !latestSuites.contains(c.checkSuiteId);

    // Within the surviving runs, collapse re-created check runs: a "re-run
    // failed jobs" attempt mints a new check run for the same job under the
    // same suite and external apps re-report the same check on retry. Per
    // (suite|app, name) only the newest id stays.
    final latestIdByKey = <String, int>{};
    for (final c in checkRuns) {
      if (isSuperseded(c)) {
        continue;
      }
      final key = dedupeKeyFor(c);
      final current = latestIdByKey[key];
      if (current == null || c.id > current) {
        latestIdByKey[key] = c.id;
      }
    }
    final visibleCheckRuns = [
      for (final c in checkRuns)
        if (!isSuperseded(c) && latestIdByKey[dedupeKeyFor(c)] == c.id) c,
    ];
    final workflowBySuite = <int, String>{
      for (final w in latestRuns)
        if (w.checkSuiteId != 0) w.checkSuiteId: _displayNameFor(w),
    };

    // Resolve the Actions job backing each check run: the jobs of every
    // referenced workflow run expose their `check_run_url`, whose trailing id
    // is the check-run id. A failed jobs call degrades to a null job id (the
    // flat-list fallback), never fails the whole call.
    final runIdBySuite = <int, int>{
      for (final w in latestRuns)
        if (w.checkSuiteId != 0) w.checkSuiteId: w.id,
    };
    final referencedRunIds = <int>{
      for (final c in visibleCheckRuns)
        if (c.checkSuiteId != null && runIdBySuite.containsKey(c.checkSuiteId))
          runIdBySuite[c.checkSuiteId]!,
    };
    final jobIdByCheckRunId = <int, int>{};
    await Future.wait(
      referencedRunIds.map((runId) async {
        List<GitHubJobRun> jobs;
        try {
          jobs = await _client.pr.listWorkflowRunJobs(
            owner,
            repo,
            runId,
            cancelToken: token,
          );
        } on Object catch (e) {
          if (_isCancellation(e)) {
            rethrow;
          }
          return;
        }
        for (final j in jobs) {
          final checkRunId = int.tryParse(j.checkRunUrl.split('/').last);
          if (checkRunId != null) {
            jobIdByCheckRunId[checkRunId] = j.id;
          }
        }
      }),
    );

    return visibleCheckRuns
        .map((c) {
          final base = checkRunFromGitHub(c);
          final suite = c.checkSuiteId;
          final wf = suite == null ? null : workflowBySuite[suite];
          return base.copyWith(
            workflowName: (wf == null || wf.isEmpty) ? null : wf,
            jobId: jobIdByCheckRunId[c.id],
            workflowRunId: suite == null ? null : runIdBySuite[suite],
          );
        })
        .toList(growable: false);
  }

  /// Display name for a workflow run: prefer the explicit `name:` from the
  /// YAML, fall back to the workflow file basename (e.g. `tests-pr.yaml`) when
  /// the run was triggered before the workflow was named.
  static String _displayNameFor(GitHubWorkflowRun w) {
    if (w.name.isNotEmpty) {
      return w.name;
    }
    if (w.path.isEmpty) {
      return '';
    }
    final slash = w.path.lastIndexOf('/');
    return slash < 0 ? w.path : w.path.substring(slash + 1);
  }

  @override
  Future<List<CommitStatus>> listCommitStatuses(
    String headSha, {
    Object? cancelToken,
  }) async {
    final statuses = await _client.pr.listCommitStatuses(
      owner,
      repo,
      headSha,
      cancelToken: _token(cancelToken),
    );
    return statuses.map(commitStatusFromGitHub).toList(growable: false);
  }

  @override
  Future<String> getFileContent(
    String path,
    String ref, {
    Object? cancelToken,
  }) {
    return _client.content.getFileContent(
      owner,
      repo,
      path,
      ref,
      cancelToken: _token(cancelToken),
    );
  }

  @override
  Future<Map<String, PrFileViewedState>> getFileViewedStates(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final raw = await _client.graphql.getFileViewedStates(
      owner: owner,
      repo: repo,
      number: prNumber,
      cancelToken: _token(cancelToken),
    );
    return <String, PrFileViewedState>{
      for (final entry in raw.entries)
        entry.key: PrFileViewedStateExtension.fromWireName(entry.value),
    };
  }

  /// Who is reviewing this PR, plus the code-owner identities GitHub currently
  /// flags.
  ///
  /// [PrReviewerState.codeOwnerIdentities] carries `user:<login>` / `team:<slug>`
  /// identities — the same spelling as [PrReviewer.identity] — because GitHub
  /// lets a *team* own a path, which a bare login cannot express. It reflects
  /// only what this response flagged: GitHub drops `asCodeOwner` once a request
  /// is satisfied, so a caller that wants the shield to survive the
  /// pending→reviewed transition unions these identities into its own
  /// persisted set.
  @override
  Future<PrReviewerState> getReviewerState(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final state = await _client.graphql.getPullRequestReviewState(
      owner: owner,
      repo: repo,
      number: prNumber,
      cancelToken: _token(cancelToken),
    );
    return PrReviewerState(
      reviewers: prReviewersFromReviewState(state),
      codeOwnerIdentities: codeOwnerIdentitiesFromReviewState(state),
    );
  }

  @override
  Future<PrUser?> getAuthenticatedUser({Object? cancelToken}) async {
    final user = await _client.content.getAuthenticatedUser(
      cancelToken: _token(cancelToken),
    );
    if (user == null) {
      return null;
    }
    _viewerLogin = user.login;
    return PrUser(
      login: user.login,
      avatarUrl: user.avatarUrl,
      name: user.name,
    );
  }

  @override
  Future<List<PrUser>> listAssignableUsers({Object? cancelToken}) {
    // GraphQL, not REST: the REST assignees list is a Simple User and carries
    // no display name.
    return _client.graphql.listAssignableUsers(
      owner,
      repo,
      cancelToken: _token(cancelToken),
    );
  }

  @override
  Future<List<PrReviewerCandidate>> listRequestableReviewers({
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final users = await listAssignableUsers(cancelToken: token);
    final teams = await _client.pr.listRequestableTeams(
      owner,
      repo,
      cancelToken: token,
    );
    return <PrReviewerCandidate>[
      for (final u in users) PrReviewerCandidate.user(u),
      for (final t in teams)
        PrReviewerCandidate(
          kind: ReviewerKind.team,
          key: t.slug,
          label: t.name,
          avatarUrl: t.avatarUrl,
        ),
    ];
  }

  @override
  Future<List<PrUser>> listSuggestedReviewers(
    int prNumber, {
    Object? cancelToken,
  }) {
    return _client.graphql.getSuggestedReviewers(
      owner: owner,
      repo: repo,
      number: prNumber,
      cancelToken: _token(cancelToken),
    );
  }

  // ── Compose-PR surface ─────────────────────────────────────────────────

  /// Branches ordered by tip-commit recency, unknown dates last.
  ///
  /// GraphQL rather than the REST branch list: only it carries the tip commit's
  /// date and author, which is what makes the picker's ordering (and the
  /// caller's "my branches first" grouping, via [ForgeBranch.lastCommitAuthor])
  /// possible without a per-branch follow-up call.
  @override
  Future<List<ForgeBranch>> listBranches({
    int? limit,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final defaultBranch = await getDefaultBranch(cancelToken: token);
    final activity = await _client.graphql.listBranchesWithActivity(
      owner,
      repo,
      cancelToken: token,
    );
    final sorted = activity.toList()
      ..sort((a, b) {
        final da = a.committedDate;
        final db = b.committedDate;
        if (da == null && db == null) {
          return 0;
        }
        if (da == null) {
          return 1;
        }
        if (db == null) {
          return -1;
        }
        return db.compareTo(da);
      });
    return List<ForgeBranch>.unmodifiable([
      for (final b in limit == null ? sorted : sorted.take(limit))
        ForgeBranch(
          name: b.name,
          lastCommitAt: b.committedDate,
          lastCommitAuthor: b.authorLogin ?? '',
          isDefault: defaultBranch.isNotEmpty && b.name == defaultBranch,
        ),
    ]);
  }

  @override
  Future<String> getDefaultBranch({Object? cancelToken}) async {
    try {
      return await _client.pr.getDefaultBranch(
        owner,
        repo,
        cancelToken: _token(cancelToken),
      );
    } on Object catch (e) {
      if (_isCancellation(e)) {
        rethrow;
      }
      // An unreachable or unreadable repo yields "unknown", which the pickers
      // render as no branch being flagged default.
      return '';
    }
  }

  @override
  Future<ForgeBranchComparison?> compareBranches({
    required String base,
    required String head,
    Object? cancelToken,
  }) async {
    try {
      final comparison = await _client.pr.compareBranches(
        owner,
        repo,
        base: base,
        head: head,
        cancelToken: _token(cancelToken),
      );
      return ForgeBranchComparison(
        files: comparison.files.map(prFileFromGitHub).toList(growable: false),
        commits: comparison.commits
            .map(prCommitFromGitHub)
            .toList(growable: false),
        additions: comparison.additions,
        deletions: comparison.deletions,
        totalCommits: comparison.totalCommits,
      );
    } on Object catch (e) {
      if (_isCancellation(e)) {
        rethrow;
      }
      // A missing ref (404) or a comparison GitHub declines is "could not
      // check", which the compose guard must tell apart from "no changes".
      return null;
    }
  }

  /// The repo's PR templates, keyed by display name.
  ///
  /// GitHub's single conventional template has no title of its own, so it is
  /// keyed by its filename stem, [_defaultTemplateKey]. Named templates from a
  /// `PULL_REQUEST_TEMPLATE/` directory keep their humanized filename, which
  /// cannot collide with that key (the humanizer turns `_` into a space).
  @override
  Future<Map<String, String>> listPrTemplates({Object? cancelToken}) async {
    final templates = await _client.graphql.fetchPullRequestTemplates(
      owner,
      repo,
      cancelToken: _token(cancelToken),
    );
    return Map<String, String>.unmodifiable(<String, String>{
      for (final t in templates)
        (t.name.isNotEmpty ? t.name : _defaultTemplateKey): t.body,
    });
  }

  /// Key for GitHub's single untitled `pull_request_template.md`.
  static const String _defaultTemplateKey = 'pull_request_template';

  @override
  Future<JobRunDetail?> getJobRunDetail(
    int jobId, {
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final job = await _client.pr.getJobRun(
      owner,
      repo,
      jobId,
      cancelToken: token,
    );
    if (job == null) {
      return null;
    }
    String? logs;
    var truncated = false;
    if (job.status == 'completed') {
      final result = await _client.pr.getJobLogs(
        owner,
        repo,
        jobId,
        cancelToken: token,
      );
      logs = result?.text;
      truncated = result?.truncated ?? false;
    }
    return jobRunDetailFromGitHub(job, logs: logs, logsTruncated: truncated);
  }

  @override
  Future<WorkflowGraph?> getWorkflowGraph(
    int workflowRunId, {
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final run = await _client.pr.getWorkflowRun(
      owner,
      repo,
      workflowRunId,
      cancelToken: token,
    );
    if (run == null || run.path.isEmpty) {
      return null;
    }
    try {
      final source = await _client.content.getFileContent(
        owner,
        repo,
        run.path,
        run.headSha,
        cancelToken: token,
      );
      return workflowGraphFromYaml(source);
    } on Object catch (e) {
      if (_isCancellation(e)) {
        rethrow;
      }
      // Moved or deleted workflow file — the caller falls back to a flat list.
      return null;
    }
  }

  // ── Writes ─────────────────────────────────────────────────────────────

  @override
  Future<PrCodeReviewComment?> postReviewComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
    Object? cancelToken,
  }) async {
    final comment = await _client.pr.postReviewComment(
      owner,
      repo,
      prNumber: prNumber,
      commitSha: commitSha,
      path: path,
      line: line,
      side: side,
      body: body,
      startLine: startLine,
      startSide: startSide,
      cancelToken: _token(cancelToken),
    );
    return prCodeReviewCommentFromGitHub(comment);
  }

  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required String parentCommentId,
    required String body,
    Object? cancelToken,
  }) async {
    await _client.pr.replyToReviewComment(
      owner,
      repo,
      prNumber: prNumber,
      parentCommentId: _numericId(parentCommentId, 'parentCommentId'),
      body: body,
      cancelToken: _token(cancelToken),
    );
  }

  @override
  Future<void> postIssueComment({
    required int prNumber,
    required String body,
    Object? cancelToken,
  }) async {
    await _client.pr.createIssueComment(
      owner,
      repo,
      prNumber: prNumber,
      body: body,
      cancelToken: _token(cancelToken),
    );
  }

  /// GitHub comment/issue ids are integers; the port passes them as opaque
  /// strings because other forges use non-numeric ids. A value that is not a
  /// GitHub id is a caller bug, so it fails loudly instead of silently
  /// no-op-ing against the wrong resource.
  static int _numericId(String value, String name) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw ArgumentError.value(value, name, 'must be a numeric GitHub id');
    }
    return parsed;
  }

  @override
  Future<void> setReviewThreadResolved({
    required int prNumber,
    required String threadId,
    required bool resolved,
    Object? cancelToken,
  }) async {
    await _client.graphql.setReviewThreadResolved(
      threadId: threadId,
      resolved: resolved,
      cancelToken: _token(cancelToken),
    );
  }

  @override
  Future<void> submitReview({
    required int prNumber,
    required ForgeReviewVerdict verdict,
    String? body,
    List<Map<String, dynamic>> comments = const [],
    Object? cancelToken,
  }) async {
    await _client.pr.submitReview(
      owner,
      repo,
      prNumber: prNumber,
      event: switch (verdict) {
        ForgeReviewVerdict.approve => 'APPROVE',
        ForgeReviewVerdict.requestChanges => 'REQUEST_CHANGES',
        ForgeReviewVerdict.comment => 'COMMENT',
      },
      body: body,
      comments: comments.isEmpty ? null : comments,
      cancelToken: _token(cancelToken),
    );
  }

  @override
  Future<PrMergeOutcome> mergePullRequest({
    required int prNumber,
    required ForgeMergeMethod method,
    String? commitTitle,
    String? commitMessage,
    Object? cancelToken,
  }) async {
    final result = await _client.pr.mergePullRequest(
      owner,
      repo,
      prNumber: prNumber,
      mergeMethod: method.wire,
      commitTitle: commitTitle,
      commitMessage: commitMessage,
      cancelToken: _token(cancelToken),
    );
    return PrMergeOutcome(
      merged: result['merged'] as bool? ?? false,
      message: result['message'] as String? ?? '',
      sha: result['sha'] as String?,
    );
  }

  @override
  Future<void> closePullRequest(int prNumber, {Object? cancelToken}) async {
    await _client.pr.closePullRequest(
      owner,
      repo,
      prNumber: prNumber,
      cancelToken: _token(cancelToken),
    );
  }

  @override
  Future<void> setPullRequestDraft({
    required int prNumber,
    required bool draft,
    Object? cancelToken,
  }) async {
    // GraphQL-only on GitHub: REST cannot write `draft` after creation.
    await _client.graphql.setPullRequestDraft(
      owner: owner,
      repo: repo,
      number: prNumber,
      draft: draft,
      cancelToken: _token(cancelToken),
    );
  }

  @override
  Future<PullRequest> createPullRequest({
    required String title,
    required String body,
    required String headBranch,
    required String baseBranch,
    bool draft = false,
    Object? cancelToken,
  }) async {
    final created = await _client.pr.createPullRequest(
      owner,
      repo,
      title: title,
      body: body,
      head: headBranch,
      base: baseBranch,
      draft: draft,
      cancelToken: _token(cancelToken),
    );
    return pullRequestFromGitHub(
      GitHubPullRequest.fromJson(created),
      repoFullName: _repoFullName,
    );
  }

  @override
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
    Object? cancelToken,
  }) async {
    if (title == null && body == null) {
      return;
    }
    await _client.pr.updatePullRequest(
      owner,
      repo,
      prNumber: prNumber,
      title: title,
      body: body,
      cancelToken: _token(cancelToken),
    );
  }

  @override
  Future<void> setFileViewedState({
    required int prNumber,
    required String prExternalId,
    required String path,
    required bool viewed,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    if (viewed) {
      await _client.graphql.markFileAsViewed(
        pullRequestId: prExternalId,
        path: path,
        cancelToken: token,
      );
    } else {
      await _client.graphql.unmarkFileAsViewed(
        pullRequestId: prExternalId,
        path: path,
        cancelToken: token,
      );
    }
  }

  @override
  Future<void> addAssignees({
    required int prNumber,
    required List<String> logins,
    Object? cancelToken,
  }) async {
    // GitHub caps assignees at 10 per call — chunk larger requests.
    for (final chunk in _chunk(logins, _assigneesPerCall)) {
      await _client.pr.addAssignees(
        owner,
        repo,
        prNumber: prNumber,
        logins: chunk,
        cancelToken: _token(cancelToken),
      );
    }
  }

  @override
  Future<void> removeAssignees({
    required int prNumber,
    required List<String> logins,
    Object? cancelToken,
  }) async {
    for (final chunk in _chunk(logins, _assigneesPerCall)) {
      await _client.pr.removeAssignees(
        owner,
        repo,
        prNumber: prNumber,
        logins: chunk,
        cancelToken: _token(cancelToken),
      );
    }
  }

  /// GitHub's per-call assignee ceiling.
  static const int _assigneesPerCall = 10;

  static Iterable<List<T>> _chunk<T>(List<T> items, int size) sync* {
    for (var i = 0; i < items.length; i += size) {
      final end = (i + size) > items.length ? items.length : i + size;
      yield items.sublist(i, end);
    }
  }

  @override
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
    Object? cancelToken,
  }) async {
    await _client.pr.requestReviewers(
      owner,
      repo,
      prNumber: prNumber,
      reviewers: userLogins,
      teamReviewers: teamSlugs,
      cancelToken: _token(cancelToken),
    );
  }

  @override
  Future<void> removeRequestedReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
    Object? cancelToken,
  }) async {
    await _client.pr.removeRequestedReviewers(
      owner,
      repo,
      prNumber: prNumber,
      reviewers: userLogins,
      teamReviewers: teamSlugs,
      cancelToken: _token(cancelToken),
    );
  }

  @override
  Future<List<ForgeReaction>> listReactions({
    required ForgeReactionTarget target,
    required String targetId,
    required int prNumber,
    Object? cancelToken,
  }) async {
    // A review summary's reactions have no REST endpoint — they only exist
    // on the GraphQL review node, listed per PR and matched by databaseId.
    if (target == ForgeReactionTarget.review) {
      final set = _reviewReactionSet(
        await _client.graphql.listReviewReactions(
          owner: owner,
          repo: repo,
          number: prNumber,
          cancelToken: _token(cancelToken),
        ),
        _numericId(targetId, 'targetId'),
      );
      return [
        for (final r in set?.reactions ?? const <GitHubReviewReaction>[])
          ForgeReaction(content: r.content, login: r.login),
      ];
    }
    final reactions = await _listRawReactions(
      target: target,
      targetId: targetId,
      prNumber: prNumber,
      cancelToken: _token(cancelToken),
    );
    return <ForgeReaction>[
      for (final r in reactions)
        ForgeReaction(content: r.content, login: r.user?.login ?? ''),
    ];
  }

  /// The reaction endpoint for [target], answering with the wire model so the
  /// removal path in [toggleReaction] keeps the reaction ids that
  /// [ForgeReaction] deliberately drops.
  Future<List<GitHubReaction>> _listRawReactions({
    required ForgeReactionTarget target,
    required String targetId,
    required int prNumber,
    CancelToken? cancelToken,
  }) {
    return switch (target) {
      ForgeReactionTarget.reviewComment =>
        _client.pr.listReviewCommentReactions(
          owner,
          repo,
          commentId: _numericId(targetId, 'targetId'),
          cancelToken: cancelToken,
        ),
      ForgeReactionTarget.issueComment => _client.pr.listIssueCommentReactions(
        owner,
        repo,
        commentId: _numericId(targetId, 'targetId'),
        cancelToken: cancelToken,
      ),
      ForgeReactionTarget.pullRequest => _client.pr.listIssueReactions(
        owner,
        repo,
        issueNumber: prNumber,
        cancelToken: cancelToken,
      ),
      // Unreachable: the review target is answered from GraphQL before this
      // helper runs — REST has no review-reactions endpoint at all.
      ForgeReactionTarget.review => throw StateError(
        'review reactions have no REST lane',
      ),
    };
  }

  @override
  Future<void> toggleReaction({
    required ForgeReactionTarget target,
    required String targetId,
    required int prNumber,
    required String content,
    required bool add,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    // A review summary is the one target with no REST lane: both the subject
    // handle and the reaction ids are GraphQL node ids.
    if (target == ForgeReactionTarget.review) {
      await _toggleReviewReaction(
        reviewId: _numericId(targetId, 'targetId'),
        prNumber: prNumber,
        content: content,
        add: add,
        cancelToken: token,
      );
      return;
    }
    // A PR reacts through the issues API keyed by its own number; a comment
    // target carries its numeric comment id in [targetId].
    final id = target == ForgeReactionTarget.pullRequest
        ? prNumber
        : _numericId(targetId, 'targetId');

    if (add) {
      switch (target) {
        case ForgeReactionTarget.reviewComment:
          await _client.pr.createReviewCommentReaction(
            owner,
            repo,
            commentId: id,
            content: content,
            cancelToken: token,
          );
        case ForgeReactionTarget.issueComment:
          await _client.pr.createIssueCommentReaction(
            owner,
            repo,
            commentId: id,
            content: content,
            cancelToken: token,
          );
        case ForgeReactionTarget.pullRequest:
          await _client.pr.createIssueReaction(
            owner,
            repo,
            issueNumber: id,
            content: content,
            cancelToken: token,
          );
        // Unreachable: the review target returned to GraphQL above.
        case ForgeReactionTarget.review:
          throw StateError('review reactions have no REST lane');
      }
      return;
    }

    // GitHub deletes a reaction by its own id, so removal is a read-then-delete
    // of the viewer's matching rows.
    final login = await _resolveViewerLogin(token);
    final existing = await _listRawReactions(
      target: target,
      targetId: targetId,
      prNumber: prNumber,
      cancelToken: token,
    );
    for (final r in existing) {
      if (r.user?.login != login || r.content != content) {
        continue;
      }
      switch (target) {
        case ForgeReactionTarget.reviewComment:
          await _client.pr.deleteReviewCommentReaction(
            owner,
            repo,
            commentId: id,
            reactionId: r.id,
            cancelToken: token,
          );
        case ForgeReactionTarget.issueComment:
          await _client.pr.deleteIssueCommentReaction(
            owner,
            repo,
            commentId: id,
            reactionId: r.id,
            cancelToken: token,
          );
        case ForgeReactionTarget.pullRequest:
          await _client.pr.deleteIssueReaction(
            owner,
            repo,
            issueNumber: id,
            reactionId: r.id,
            cancelToken: token,
          );
        // Unreachable: the review target returned to GraphQL above.
        case ForgeReactionTarget.review:
          throw StateError('review reactions have no REST lane');
      }
    }
  }

  /// Adds or removes a reaction on a review summary, entirely over GraphQL:
  /// `addReaction` takes the review's node id as its subject and
  /// `removeReaction` takes the reaction's own node id, neither of which the
  /// REST review payload exposes. The per-PR listing is what resolves both.
  Future<void> _toggleReviewReaction({
    required int reviewId,
    required int prNumber,
    required String content,
    required bool add,
    required CancelToken? cancelToken,
  }) async {
    final sets = await _client.graphql.listReviewReactions(
      owner: owner,
      repo: repo,
      number: prNumber,
      cancelToken: cancelToken,
    );
    final set = _reviewReactionSet(sets, reviewId);
    if (set == null) {
      throw StateError(
        'Review #$reviewId not found on $owner/$repo#$prNumber; its '
        'reactions cannot be toggled.',
      );
    }
    if (add) {
      await _client.graphql.addReaction(
        subjectId: set.nodeId,
        content: content,
        cancelToken: cancelToken,
      );
      return;
    }
    // Same read-then-delete shape as the REST targets: delete only the
    // viewer's matching rows, by each reaction's own node id.
    final login = await _resolveViewerLogin(cancelToken);
    for (final r in set.reactions) {
      if (r.login == login && r.content == content) {
        await _client.graphql.removeReaction(
          reactionId: r.id,
          cancelToken: cancelToken,
        );
      }
    }
  }

  /// The reaction set for [reviewId], or null when the listing did not
  /// include that review.
  GitHubReviewReactionSet? _reviewReactionSet(
    List<GitHubReviewReactionSet> sets,
    int reviewId,
  ) {
    for (final s in sets) {
      if (s.databaseId == reviewId) {
        return s;
      }
    }
    return null;
  }

  /// The authenticated user's login, cached after the first successful lookup.
  ///
  /// A failure resolves to null, which makes the reaction-removal filter match
  /// nothing rather than delete somebody else's reaction.
  Future<String?> _resolveViewerLogin(CancelToken? cancelToken) async {
    final cached = _viewerLogin;
    if (cached != null) {
      return cached;
    }
    try {
      final user = await _client.content.getAuthenticatedUser(
        cancelToken: cancelToken,
      );
      return _viewerLogin = user?.login;
    } on Object {
      return null;
    }
  }

  @override
  Future<String> uploadContent({
    required String path,
    required String base64Content,
    required String message,
    Object? cancelToken,
  }) {
    return _client.content.createFileContent(
      owner,
      repo,
      path,
      base64Content,
      message,
      cancelToken: _token(cancelToken),
    );
  }

  // ── Stacks ─────────────────────────────────────────────────────────────

  @override
  Future<List<PrStack>> listStacks({int? prNumber, Object? cancelToken}) async {
    // Single page (100 stacks): a repo realistically has a handful and the
    // [prNumber] filter always fits in one page.
    final result = await _client.pr.listStacks(
      owner,
      repo,
      pullRequest: prNumber,
      cancelToken: _token(cancelToken),
    );
    return [for (final s in result.items) prStackFromGitHub(s)];
  }

  @override
  Future<PrStack> createStack({
    required List<int> prNumbers,
    Object? cancelToken,
  }) async {
    final stack = await _client.pr.createStack(
      owner,
      repo,
      prNumbers,
      cancelToken: _token(cancelToken),
    );
    return prStackFromGitHub(stack);
  }

  @override
  Future<PrStack?> addToStack({
    required int stackNumber,
    required List<int> prNumbers,
    Object? cancelToken,
  }) async {
    final stack = await _client.pr.addToStack(
      owner,
      repo,
      stackNumber,
      prNumbers,
      cancelToken: _token(cancelToken),
    );
    return prStackFromGitHub(stack);
  }

  @override
  Future<PrStack?> unstack({
    required int stackNumber,
    Object? cancelToken,
  }) async {
    final stack = await _client.pr.unstack(
      owner,
      repo,
      stackNumber,
      cancelToken: _token(cancelToken),
    );
    if (stack == null) {
      return null;
    }
    return prStackFromGitHub(stack);
  }
}
