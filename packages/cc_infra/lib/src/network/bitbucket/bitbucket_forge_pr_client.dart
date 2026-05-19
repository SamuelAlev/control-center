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
import 'package:cc_infra/src/network/bitbucket/bitbucket_api_client.dart';
import 'package:cc_infra/src/network/bitbucket/bitbucket_pr_mapper.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_pull_request.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_user.dart';
import 'package:dio/dio.dart';

/// The Bitbucket Cloud adapter for [ForgePrClient].
///
/// Bitbucket is the thinnest of the three forges, and this class is where that
/// stops being the rest of the app's problem. Where Bitbucket has the concept,
/// it is mapped; where it does not, the method throws [ForgeUnsupportedError]
/// naming the capability rather than returning an empty result that would read
/// as "none" instead of "this forge cannot tell you".
///
/// The structural gaps, all mirrored by a false flag in the Bitbucket row of
/// `kForgeCapabilities`:
///
/// * **No batched review.** There is no pending/draft state, so a multi-comment
///   review posts comment by comment and the author sees them arrive
///   individually. A review body accompanying a verdict becomes a separate
///   comment posted just before the verdict.
/// * **No review resource.** A verdict is a mutable flag on a participation
///   row, so reviews have no id, no body and no history.
/// * **No commit-sha anchoring on comments.** An inline comment is pinned to
///   the pull request's current diff, not to a revision of it.
/// * **No assignees, no teams, no viewed state, no reactions, no stacks, no
///   CI job detail, no attachment upload, no draft pull requests.**
///
/// [owner] is the Bitbucket **workspace slug** — the first path segment of a
/// repository URL, the same position GitHub's owner occupies.
class BitbucketForgePrClient implements ForgePrClient {
  /// Creates a [BitbucketForgePrClient] for `owner/repo` over [client].
  BitbucketForgePrClient({
    required BitbucketApiClient client,
    required this.owner,
    required this.repo,
  }) : _client = client {
    if (owner.isEmpty || repo.isEmpty) {
      throw ArgumentError('owner and repo must not be empty');
    }
  }

  final BitbucketApiClient _client;

  /// The Bitbucket workspace slug.
  @override
  final String owner;

  /// The repository slug.
  @override
  final String repo;

  @override
  ForgeHost get forge => ForgeHost.bitbucket;

  @override
  ForgeCapabilities get capabilities => capabilitiesOf(ForgeHost.bitbucket);

  // ── Reads ────────────────────────────────────────────────────────────────

  @override
  Future<PullRequest?> getPullRequest(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final pr = await _client.getPullRequest(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return pr == null ? null : _toDomain(pr);
  }

  /// One page of this repository's open pull requests, most-recently-updated
  /// first.
  ///
  /// [limit] is clamped to 50 by `BitbucketApiClient.pullRequestPageLen` — the
  /// pull request collection's own `pagelen` ceiling, lower than the rest of
  /// the API's.
  ///
  /// `reviewDecision` rolls up from the participant verdicts exactly as
  /// [getPullRequest] does, which is only possible because the request asks
  /// Bitbucket to expand the roster into the list representation; see
  /// `BitbucketApiClient.listPullRequestsPage`.
  @override
  Future<({List<PullRequest> prs, bool hasMore})> listOpenPullRequests({
    int limit = _defaultListLimit,
    Object? cancelToken,
  }) async {
    final page = await _client.listPullRequestsPage(
      owner,
      repo,
      limit: limit,
      cancelToken: _token(cancelToken),
    );
    return (
      prs: page.items.map(_toDomain).toList(growable: false),
      hasMore: page.hasMore,
    );
  }

  /// Merged pull requests authored by [login], most recently merged first.
  ///
  /// Bitbucket filters by author with a BBQL predicate, and the field to filter
  /// on depends on which spelling [login] is: `PrUser.login` maps from an
  /// account's `nickname` and falls back to its `account_id`, so both are
  /// possible. The shape of [login] picks which to try first and the other is
  /// tried when that returns nothing — so a wrong guess costs one extra request
  /// rather than a wrongly-empty section.
  ///
  /// "Most recently merged" is approximated by `-updated_on`: Bitbucket
  /// publishes no merge timestamp, so the sort key is the last change to the
  /// pull request, which is the merge itself unless something touched it after.
  @override
  Future<List<PullRequest>> listMergedByAuthor(
    String login, {
    int limit = _defaultListLimit,
    Object? cancelToken,
  }) async {
    final handle = login.trim();
    if (handle.isEmpty) {
      return const <PullRequest>[];
    }
    final token = _token(cancelToken);
    final literal = BitbucketApiClient.bbqlLiteral(handle);
    final fields = _looksLikeAccountId(handle)
        ? const <String>['author.account_id', 'author.nickname']
        : const <String>['author.nickname', 'author.account_id'];

    for (final field in fields) {
      final page = await _client.listPullRequestsPage(
        owner,
        repo,
        state: 'MERGED',
        limit: limit,
        query: '$field=$literal',
        cancelToken: token,
      );
      if (page.items.isNotEmpty) {
        return page.items.map(_toDomain).toList(growable: false);
      }
    }
    return const <PullRequest>[];
  }

  /// Whether a pull request left the open list by merging.
  ///
  /// `true` for `MERGED`, `false` for `DECLINED`/`SUPERSEDED`, and `null` for
  /// anything else. "Anything else" deliberately includes a pull request that
  /// reads back as still `OPEN` — the caller asks this about one that vanished
  /// from the open list, so an open answer means the two reads disagree and the
  /// honest report is "unresolved", not a closure that did not happen.
  ///
  /// This is the one read that swallows its errors: a 404 or an API failure
  /// returns `null` rather than propagating, because the caller fires a merged
  /// lifecycle event off `true` and must be able to tell "not merged" from
  /// "could not tell". A cancellation still propagates — that is the caller
  /// standing down, not the forge failing to answer.
  @override
  Future<bool?> wasMerged(int prNumber, {Object? cancelToken}) async {
    try {
      final pr = await _client.getPullRequest(
        owner,
        repo,
        prNumber,
        cancelToken: _token(cancelToken),
      );
      if (pr == null) {
        return null;
      }
      return switch (pr.state.toUpperCase()) {
        'MERGED' => true,
        'DECLINED' || 'SUPERSEDED' => false,
        _ => null,
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      return null;
    }
  }

  @override
  Future<String> getPullRequestDiff(int prNumber, {Object? cancelToken}) =>
      _client.getPullRequestDiff(
        owner,
        repo,
        prNumber,
        cancelToken: _token(cancelToken),
      );

  /// {@template bitbucket_files}
  /// Bitbucket's diffstat carries per-file counts but no patch text, so this
  /// makes a second call for the unified diff and joins the hunks back on by
  /// path. That is what lets the diff viewer render a Bitbucket pull request
  /// with the same data it gets from GitHub; without it every file would arrive
  /// with an empty patch.
  ///
  /// [limit] truncates the mapped result. It does not shrink either request —
  /// Bitbucket has no per-file cap on the diff and no way to ask for the first
  /// N files — so a capped call still pays for the whole diff.
  ///
  /// Very large pull requests are truncated by
  /// `BitbucketApiClient.maxPages` (1000 diffstat entries); callers that need
  /// completeness past that fall back to the local git source.
  /// {@endtemplate}
  @override
  Future<List<PrFile>> listFiles(
    int prNumber, {
    int? limit,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final entries = await _client.listPullRequestDiffstat(
      owner,
      repo,
      prNumber,
      cancelToken: token,
    );
    final diff = await _client.getPullRequestDiff(
      owner,
      repo,
      prNumber,
      cancelToken: token,
    );
    final patches = patchesByPathFromUnifiedDiff(diff);
    final files = <PrFile>[
      for (final entry in entries)
        prFileFromBitbucket(entry, patch: patches[entry.path] ?? ''),
    ];
    if (limit != null && limit > 0 && files.length > limit) {
      return files.sublist(0, limit);
    }
    return files;
  }

  @override
  Future<List<PrCommit>> listCommits(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final commits = await _client.listPullRequestCommits(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    // Bitbucket returns commits newest-first; the port contracts oldest-first.
    return commits.reversed.map(prCommitFromBitbucket).toList(growable: false);
  }

  /// The files changed by one commit.
  ///
  /// {@macro bitbucket_files}
  @override
  Future<List<PrFile>> listCommitFiles(
    String sha, {
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final entries = await _client.listDiffstat(
      owner,
      repo,
      sha,
      cancelToken: token,
    );
    final diff = await _client.getDiff(owner, repo, sha, cancelToken: token);
    final patches = patchesByPathFromUnifiedDiff(diff);
    return <PrFile>[
      for (final entry in entries)
        prFileFromBitbucket(entry, patch: patches[entry.path] ?? ''),
    ];
  }

  /// The submitted verdicts on a pull request.
  ///
  /// Read off the pull request's participants, since Bitbucket has no review
  /// resource. Every submission therefore carries an empty body and id 0 —
  /// there is no prose and no id for one to have.
  @override
  Future<List<PrReviewSubmission>> listReviews(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final pr = await _client.getPullRequest(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    if (pr == null) {
      return const <PrReviewSubmission>[];
    }
    return prReviewSubmissionsFromBitbucket(pr);
  }

  /// The inline (file-anchored) comments on a pull request.
  ///
  /// Bitbucket serves inline and top-level comments from one endpoint, so this
  /// and [listIssueComments] partition the same response. Deleted comments —
  /// which Bitbucket keeps as content-free tombstones — are dropped.
  @override
  Future<List<PrCodeReviewComment>> listReviewComments(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final comments = await _client.listPullRequestComments(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return <PrCodeReviewComment>[
      for (final comment in comments)
        if (comment.isInline && !comment.deleted)
          prCodeReviewCommentFromBitbucket(comment),
    ];
  }

  /// Bitbucket has no resolvable-thread concept this adapter reads
  /// (`commentThreadResolution` is false), so no thread state is known and a
  /// resolve is refused rather than silently doing nothing.
  @override
  Future<List<PrReviewThreadState>> listReviewThreadStates(
    int prNumber, {
    Object? cancelToken,
  }) async => const <PrReviewThreadState>[];

  @override
  Future<void> setReviewThreadResolved({
    required int prNumber,
    required String threadId,
    required bool resolved,
    Object? cancelToken,
  }) async => throw const ForgeUnsupportedError(
    ForgeHost.bitbucket,
    'commentThreadResolution',
  );

  @override
  Future<List<IssueComment>> listIssueComments(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final comments = await _client.listPullRequestComments(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return <IssueComment>[
      for (final comment in comments)
        if (!comment.isInline && !comment.deleted)
          issueCommentFromBitbucket(comment),
    ];
  }

  /// Review-request events, recovered by diffing the reviewer roster across the
  /// pull request's activity feed.
  ///
  /// Bitbucket records no discrete review-request event; see
  /// [prTimelineEventsFromBitbucket] for exactly how far that approximation
  /// goes. Approval and comment activity produce no events — the domain models
  /// only the two review-request kinds and those signals ride their own
  /// streams.
  @override
  Future<List<PrTimelineEvent>> listTimelineEvents(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final activity = await _client.listPullRequestActivity(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return prTimelineEventsFromBitbucket(activity);
  }

  /// CI results for [headSha], from Bitbucket's build statuses.
  ///
  /// Bitbucket has one status API rather than GitHub's separate checks and
  /// statuses, so this and [listCommitStatuses] map the same response two ways
  /// — as check runs for the checks list and as statuses for the deploy-preview
  /// lookup. Pipelines runs are deliberately not merged in: a run publishes a
  /// build status of its own, so including both would double-count it.
  @override
  Future<List<CheckRun>> listCheckRuns(
    String headSha, {
    Object? cancelToken,
  }) async {
    final statuses = await _client.listCommitStatuses(
      owner,
      repo,
      headSha,
      cancelToken: _token(cancelToken),
    );
    return statuses.map(checkRunFromBitbucketStatus).toList(growable: false);
  }

  @override
  Future<List<CommitStatus>> listCommitStatuses(
    String headSha, {
    Object? cancelToken,
  }) async {
    final statuses = await _client.listCommitStatuses(
      owner,
      repo,
      headSha,
      cancelToken: _token(cancelToken),
    );
    return statuses.map(commitStatusFromBitbucket).toList(growable: false);
  }

  @override
  Future<String> getFileContent(
    String path,
    String ref, {
    Object? cancelToken,
  }) => _client.getFileContent(
    owner,
    repo,
    path,
    ref,
    cancelToken: _token(cancelToken),
  );

  /// Always throws: Bitbucket has no per-file viewed state.
  /// Capability: `viewedStateSync`.
  @override
  Future<Map<String, PrFileViewedState>> getFileViewedStates(
    int prNumber, {
    Object? cancelToken,
  }) =>
      throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'viewedStateSync');

  /// Who is reviewing this pull request.
  ///
  /// `codeOwnerIdentities` is always empty: Bitbucket has no CODEOWNERS
  /// equivalent, so this is "cannot tell you" rather than "nobody".
  @override
  Future<PrReviewerState> getReviewerState(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final pr = await _client.getPullRequest(
      owner,
      repo,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    if (pr == null) {
      return PrReviewerState.empty;
    }
    return PrReviewerState(reviewers: prReviewersFromBitbucket(pr));
  }

  @override
  Future<PrUser?> getAuthenticatedUser({Object? cancelToken}) async {
    final user = await _client.getCurrentUser(cancelToken: _token(cancelToken));
    return user == null ? null : prUserFromBitbucket(user);
  }

  /// The workspace's members.
  ///
  /// Bitbucket has no per-repository assignee roster, so workspace membership
  /// is the pool — which is also why `listAssignableUsers` and
  /// [listRequestableReviewers] resolve to the same people.
  @override
  Future<List<PrUser>> listAssignableUsers({Object? cancelToken}) async {
    final members = await _listMembers(_token(cancelToken));
    return members.map(prUserFromBitbucket).toList(growable: false);
  }

  /// The workspace's members, as reviewer candidates.
  ///
  /// Users only: Bitbucket cannot request a review from a group, which is the
  /// `teamReviewers` capability being false.
  @override
  Future<List<PrReviewerCandidate>> listRequestableReviewers({
    Object? cancelToken,
  }) async {
    final members = await _listMembers(_token(cancelToken));
    return <PrReviewerCandidate>[
      for (final member in members)
        PrReviewerCandidate.user(prUserFromBitbucket(member)),
    ];
  }

  /// Bitbucket's own reviewer suggestions, from the repository's default
  /// reviewers.
  ///
  /// Default reviewers are configured per repository, not computed per pull
  /// request, so [prNumber] does not narrow the result — every pull request in
  /// this repository gets the same suggestions.
  @override
  Future<List<PrUser>> listSuggestedReviewers(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final users = await _client.listDefaultReviewers(
      owner,
      repo,
      cancelToken: _token(cancelToken),
    );
    return users.map(prUserFromBitbucket).toList(growable: false);
  }

  // ── Compose-PR surface ───────────────────────────────────────────────────

  /// The repository's branches, most-recently-committed first.
  ///
  /// Costs two requests: Bitbucket's branch listing does not mark the default
  /// branch, so the repository is read alongside it to resolve `isDefault`.
  @override
  Future<List<ForgeBranch>> listBranches({
    int? limit,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final branches = await _client.listBranches(
      owner,
      repo,
      limit: limit,
      cancelToken: token,
    );
    final defaultBranch = await _client.getDefaultBranch(
      owner,
      repo,
      cancelToken: token,
    );
    return forgeBranchesFromBitbucket(branches, defaultBranch: defaultBranch);
  }

  @override
  Future<String> getDefaultBranch({Object? cancelToken}) =>
      _client.getDefaultBranch(owner, repo, cancelToken: _token(cancelToken));

  /// Compares [base] with [head] — what a pull request between them would
  /// contain.
  ///
  /// Bitbucket has no compare endpoint, so this is assembled from three reads:
  /// the diffstat of `head..base` for the files, the same range's unified diff
  /// for their patches, and a `commits/{head}?exclude={base}` range read for
  /// the commits. The patches are sliced exactly as [listFiles] does, so the
  /// compose screen previews a diff identical to the one the pull request will
  /// show once it exists.
  ///
  /// The comparison is ONE-DIRECTIONAL, which is all Bitbucket offers: it
  /// answers "what does head have that base lacks" and never the reverse.
  ///
  /// `totalCommits` is Bitbucket's own count when it reports one and otherwise
  /// the number of commits actually received — which the page cap can truncate
  /// on a very large range.
  ///
  /// Returns null when any of the reads fails, so the caller can tell "nothing
  /// to compare" from "could not check". A cancellation still propagates.
  @override
  Future<ForgeBranchComparison?> compareBranches({
    required String base,
    required String head,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final spec = '$head..$base';
    try {
      final entries = await _client.listDiffstat(
        owner,
        repo,
        spec,
        cancelToken: token,
      );
      final diff = await _client.getDiff(owner, repo, spec, cancelToken: token);
      final range = await _client.listCommitsExcluding(
        owner,
        repo,
        head,
        exclude: base,
        cancelToken: token,
      );

      final patches = patchesByPathFromUnifiedDiff(diff);
      final files = <PrFile>[
        for (final entry in entries)
          prFileFromBitbucket(entry, patch: patches[entry.path] ?? ''),
      ];
      var additions = 0;
      var deletions = 0;
      for (final file in files) {
        additions += file.additions;
        deletions += file.deletions;
      }

      return ForgeBranchComparison(
        files: files,
        // Bitbucket returns a commit range newest-first; the port contracts
        // oldest-first, as `listCommits` does.
        commits: range.items.reversed
            .map(prCommitFromBitbucket)
            .toList(growable: false),
        additions: additions,
        deletions: deletions,
        totalCommits: range.size ?? range.items.length,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      return null;
    }
  }

  /// Always throws: Bitbucket Cloud has no repository-stored pull request
  /// description templates. Capability: `prTemplates`.
  @override
  Future<Map<String, String>> listPrTemplates({Object? cancelToken}) =>
      throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'prTemplates');

  /// Always throws: a Bitbucket build status has no steps or logs behind it.
  /// Capability: `ciJobDetail`.
  @override
  Future<JobRunDetail?> getJobRunDetail(int jobId, {Object? cancelToken}) =>
      throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'ciJobDetail');

  /// Always throws: Bitbucket publishes no job dependency graph.
  /// Capability: `ciJobDetail`.
  @override
  Future<WorkflowGraph?> getWorkflowGraph(
    int workflowRunId, {
    Object? cancelToken,
  }) => throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'ciJobDetail');

  // ── Writes ───────────────────────────────────────────────────────────────

  /// Posts an inline comment.
  ///
  /// [commitSha] is IGNORED: Bitbucket anchors an inline comment to the pull
  /// request's current diff, with no revision to pin it to. [startLine] and
  /// [startSide] are ignored for the same reason — Bitbucket's anchor is a
  /// single `{from, to}` pair with no multi-line form, so a range comment lands
  /// on its [line].
  ///
  /// [side] `LEFT` anchors to the pre-image (`from`); anything else anchors to
  /// the post-image (`to`).
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
    final onOldSide = side.toUpperCase() == 'LEFT';
    final comment = await _client.createPullRequestComment(
      owner,
      repo,
      prNumber,
      <String, dynamic>{
        'content': <String, dynamic>{'raw': body},
        'inline': <String, dynamic>{
          'path': path,
          if (onOldSide) 'from': line else 'to': line,
        },
      },
      cancelToken: _token(cancelToken),
    );
    return comment == null ? null : prCodeReviewCommentFromBitbucket(comment);
  }

  /// Replies in an existing comment thread.
  ///
  /// Bitbucket keys the parent by integer id, so [parentCommentId] must parse
  /// as one; anything else is a caller bug and throws [ArgumentError] rather
  /// than posting a detached top-level comment.
  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required String parentCommentId,
    required String body,
    Object? cancelToken,
  }) async {
    final parentId = int.tryParse(parentCommentId.trim());
    if (parentId == null) {
      throw ArgumentError.value(
        parentCommentId,
        'parentCommentId',
        'Bitbucket comment ids are integers',
      );
    }
    await _client.createPullRequestComment(
      owner,
      repo,
      prNumber,
      <String, dynamic>{
        'content': <String, dynamic>{'raw': body},
        'parent': <String, dynamic>{'id': parentId},
      },
      cancelToken: _token(cancelToken),
    );
  }

  @override
  Future<void> postIssueComment({
    required int prNumber,
    required String body,
    Object? cancelToken,
  }) async {
    await _client.createPullRequestComment(
      owner,
      repo,
      prNumber,
      <String, dynamic>{
        'content': <String, dynamic>{'raw': body},
      },
      cancelToken: _token(cancelToken),
    );
  }

  /// Submits a review verdict.
  ///
  /// Bitbucket has no batched review (`pendingReviewBatching` is false), so a
  /// verdict and its prose are two separate writes: when [body] is given
  /// alongside an approve or request-changes verdict it is posted as a comment
  /// FIRST, then the verdict. That order means the reasoning is already on the
  /// pull request by the time the author is notified of the verdict; the
  /// reverse would notify them of a block with nothing to read.
  ///
  /// A [ForgeReviewVerdict.comment] verdict is just the comment. It needs a
  /// non-empty [body] — a comment-only review with nothing to say is a caller
  /// bug, not a no-op — and throws [ArgumentError] otherwise.
  @override
  Future<void> submitReview({
    required int prNumber,
    required ForgeReviewVerdict verdict,
    String? body,
    List<Map<String, dynamic>> comments = const [],
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    // Bitbucket has no pending-review state at all (`pendingReviewBatching` is
    // false), so a batched review is unbundled here: every inline comment is
    // posted individually, then the verdict. Reviewers on the PR see them
    // arrive one by one — that is the forge's ceiling, not a shortcut.
    for (final c in comments) {
      await postReviewComment(
        prNumber: prNumber,
        commitSha: '',
        path: c['path'] as String? ?? '',
        line: (c['line'] as num?)?.toInt() ?? 0,
        side: c['side'] as String? ?? 'RIGHT',
        body: c['body'] as String? ?? '',
        startLine: (c['start_line'] as num?)?.toInt(),
        startSide: c['start_side'] as String?,
        cancelToken: cancelToken,
      );
    }
    final text = body?.trim() ?? '';

    if (verdict == ForgeReviewVerdict.comment) {
      if (text.isEmpty) {
        throw ArgumentError.value(
          body,
          'body',
          'a comment-only review requires a body',
        );
      }
      await _client.createPullRequestComment(
        owner,
        repo,
        prNumber,
        <String, dynamic>{
          'content': <String, dynamic>{'raw': text},
        },
        cancelToken: token,
      );
      return;
    }

    if (text.isNotEmpty) {
      await _client.createPullRequestComment(
        owner,
        repo,
        prNumber,
        <String, dynamic>{
          'content': <String, dynamic>{'raw': text},
        },
        cancelToken: token,
      );
    }

    switch (verdict) {
      case ForgeReviewVerdict.approve:
        await _client.approvePullRequest(
          owner,
          repo,
          prNumber,
          cancelToken: token,
        );
      case ForgeReviewVerdict.requestChanges:
        await _client.requestChanges(owner, repo, prNumber, cancelToken: token);
      case ForgeReviewVerdict.comment:
        break;
    }
  }

  /// Merges a pull request.
  ///
  /// [ForgeMergeMethod.rebase] maps to Bitbucket's `fast_forward`, which is an
  /// APPROXIMATION: fast-forward moves the destination branch to the source tip
  /// and fails when the branches have diverged, where a rebase would replay the
  /// commits. Bitbucket Cloud offers no rebase-and-merge strategy, and
  /// fast-forward is the only one that likewise leaves no merge commit.
  ///
  /// [commitTitle] and [commitMessage] are folded into Bitbucket's single
  /// `message` field, since it has no separate title.
  ///
  /// Bitbucket may answer 202 and merge asynchronously. That returns
  /// `merged: false` with an explanatory message rather than an optimistic
  /// true — the caller re-reads the pull request to learn the outcome.
  @override
  Future<PrMergeOutcome> mergePullRequest({
    required int prNumber,
    required ForgeMergeMethod method,
    String? commitTitle,
    String? commitMessage,
    Object? cancelToken,
  }) async {
    final message = <String>[
      if (commitTitle != null && commitTitle.isNotEmpty) commitTitle,
      if (commitMessage != null && commitMessage.isNotEmpty) commitMessage,
    ].join('\n\n');

    final result = await _client
        .mergePullRequest(owner, repo, prNumber, <String, dynamic>{
          'merge_strategy': switch (method) {
            ForgeMergeMethod.squash => 'squash',
            ForgeMergeMethod.merge => 'merge_commit',
            ForgeMergeMethod.rebase => 'fast_forward',
          },
          if (message.isNotEmpty) 'message': message,
        }, cancelToken: _token(cancelToken));

    final pr = result.pullRequest;
    if (pr == null) {
      return PrMergeOutcome(
        merged: false,
        message: result.statusCode == 202
            ? 'Bitbucket accepted the merge and is completing it '
                  'asynchronously.'
            : 'Bitbucket returned no pull request for the merge.',
      );
    }
    return PrMergeOutcome(
      merged: pr.isMerged,
      message: pr.reason,
      sha: pr.mergeCommitHash.isEmpty ? null : pr.mergeCommitHash,
    );
  }

  /// Declines a pull request — Bitbucket's spelling of closing without
  /// merging.
  @override
  Future<void> closePullRequest(int prNumber, {Object? cancelToken}) =>
      _client.declinePullRequest(
        owner,
        repo,
        prNumber,
        cancelToken: _token(cancelToken),
      );

  /// Not available on Bitbucket Cloud — throws [ForgeUnsupportedError].
  ///
  /// Unlike [createPullRequest], which quietly ignores `draft` because opening
  /// a visible pull request still does what the caller wanted, there is no
  /// approximation of "mark ready" on a forge with no draft state. The
  /// `draftToggle` capability is false, so the UI never offers this.
  @override
  Future<void> setPullRequestDraft({
    required int prNumber,
    required bool draft,
    Object? cancelToken,
  }) async =>
      throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'draftToggle');

  /// Opens a pull request.
  ///
  /// [draft] is accepted and IGNORED: Bitbucket Cloud has no draft pull
  /// requests, so a draft request opens a normal, immediately-reviewable pull
  /// request. This does not throw — refusing to create the pull request at all
  /// would be a worse answer than creating a visible one.
  @override
  Future<PullRequest> createPullRequest({
    required String title,
    required String body,
    required String headBranch,
    required String baseBranch,
    bool draft = false,
    Object? cancelToken,
  }) async {
    final created = await _client.createPullRequest(
      owner,
      repo,
      <String, dynamic>{
        'title': title,
        'description': body,
        'source': <String, dynamic>{
          'branch': <String, dynamic>{'name': headBranch},
        },
        'destination': <String, dynamic>{
          'branch': <String, dynamic>{'name': baseBranch},
        },
      },
      cancelToken: _token(cancelToken),
    );
    if (created == null) {
      throw StateError('Bitbucket returned no pull request for the create.');
    }
    return _toDomain(created);
  }

  /// Edits a pull request's title and/or body.
  ///
  /// Only the supplied fields are sent, as the port contracts. Bitbucket
  /// applies a `PUT` to a pull request as a partial update, so an omitted field
  /// is left alone rather than cleared.
  @override
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
    Object? cancelToken,
  }) async {
    final payload = <String, dynamic>{'title': ?title, 'description': ?body};
    if (payload.isEmpty) {
      return;
    }
    await _client.updatePullRequest(
      owner,
      repo,
      prNumber,
      payload,
      cancelToken: _token(cancelToken),
    );
  }

  /// Always throws: Bitbucket stores no per-file viewed state.
  /// Capability: `viewedStateSync`.
  @override
  Future<void> setFileViewedState({
    required int prNumber,
    required String prExternalId,
    required String path,
    required bool viewed,
    Object? cancelToken,
  }) =>
      throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'viewedStateSync');

  /// Always throws: a Bitbucket pull request has no assignee distinct from its
  /// reviewers. Use [requestReviewers] instead.
  @override
  Future<void> addAssignees({
    required int prNumber,
    required List<String> logins,
    Object? cancelToken,
  }) => throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'assignees');

  /// Always throws: see [addAssignees].
  @override
  Future<void> removeAssignees({
    required int prNumber,
    required List<String> logins,
    Object? cancelToken,
  }) => throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'assignees');

  /// Adds reviewers to a pull request.
  ///
  /// Bitbucket has no reviewer endpoint: the roster is a field of the pull
  /// request, so this reads it, unions in the requested accounts and PUTs the
  /// whole array back. That is a read-modify-write, so a concurrent roster
  /// change between the two calls is lost.
  ///
  /// Reviewers are keyed by account uuid, which no caller has, so each login is
  /// resolved through the workspace membership. An unresolvable login throws
  /// [ArgumentError] rather than being silently dropped — a review request that
  /// quietly went nowhere is worse than one that failed.
  ///
  /// [teamSlugs] must be empty; Bitbucket cannot request a review from a group.
  @override
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
    Object? cancelToken,
  }) => _mutateReviewers(
    prNumber: prNumber,
    userLogins: userLogins,
    teamSlugs: teamSlugs,
    cancelToken: cancelToken,
    add: true,
  );

  /// Removes reviewers from a pull request. The mirror of [requestReviewers],
  /// with the same read-modify-write and the same `teamReviewers` refusal.
  @override
  Future<void> removeRequestedReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
    Object? cancelToken,
  }) => _mutateReviewers(
    prNumber: prNumber,
    userLogins: userLogins,
    teamSlugs: teamSlugs,
    cancelToken: cancelToken,
    add: false,
  );

  /// Always throws: Bitbucket has no reaction API.
  /// Capability: `reactions`.
  @override
  Future<List<ForgeReaction>> listReactions({
    required ForgeReactionTarget target,
    required String targetId,
    required int prNumber,
    Object? cancelToken,
  }) => throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'reactions');

  /// Always throws: Bitbucket has no reaction API.
  /// Capability: `reactions`.
  @override
  Future<List<PrReviewReactions>> listReviewReactions(
    int prNumber, {
    Object? cancelToken,
  }) => throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'reactions');

  /// Always throws: Bitbucket has no reaction API.
  /// Capability: `reactions`.
  @override
  Future<void> toggleReaction({
    required ForgeReactionTarget target,
    required String targetId,
    required int prNumber,
    required String content,
    required bool add,
    Object? cancelToken,
  }) => throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'reactions');

  /// Always throws: Bitbucket has no comment-attachment upload comparable to
  /// GitHub's, so there is nowhere to host a pasted image. Committing the bytes
  /// to the repository instead would put a screenshot in the user's history,
  /// which is a different and worse operation than the caller asked for.
  @override
  Future<String> uploadContent({
    required String path,
    required String base64Content,
    required String message,
    Object? cancelToken,
  }) => throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'uploadContent');

  // ── Stacks ───────────────────────────────────────────────────────────────

  /// Always throws: Bitbucket has no stacked-pull-request concept.
  /// Capability: `stacks`.
  @override
  Future<List<PrStack>> listStacks({int? prNumber, Object? cancelToken}) =>
      throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'stacks');

  /// Always throws: see [listStacks]. Capability: `stacks`.
  @override
  Future<PrStack> createStack({
    required List<int> prNumbers,
    Object? cancelToken,
  }) => throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'stacks');

  /// Always throws: see [listStacks]. Capability: `stacks`.
  @override
  Future<PrStack?> addToStack({
    required int stackNumber,
    required List<int> prNumbers,
    Object? cancelToken,
  }) => throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'stacks');

  /// Always throws: see [listStacks]. Capability: `stacks`.
  @override
  Future<PrStack?> unstack({required int stackNumber, Object? cancelToken}) =>
      throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'stacks');

  // ── Internals ────────────────────────────────────────────────────────────

  /// Default page size for the feed reads. Matches Bitbucket's own ceiling for
  /// the pull request collection, so the default asks for as much as one round
  /// trip can carry.
  static const int _defaultListLimit = BitbucketApiClient.pullRequestPageLen;

  /// Whether [handle] is shaped like an Atlassian account id rather than a
  /// Bitbucket nickname.
  ///
  /// Account ids carry a `:` (`557057:9d0a4c6f-…`), which a nickname cannot.
  /// This only chooses which BBQL field to try FIRST — both spellings are
  /// tried — so a misjudged handle costs a request, never a wrong result.
  static bool _looksLikeAccountId(String handle) => handle.contains(':');

  PullRequest _toDomain(BitbucketPullRequest pr) =>
      pullRequestFromBitbucket(pr, owner: owner, repo: repo);

  Future<List<BitbucketUser>> _listMembers(CancelToken? cancelToken) async {
    final members = await _client.listWorkspaceMembers(
      owner,
      cancelToken: cancelToken,
    );
    return <BitbucketUser>[for (final member in members) ?member.user];
  }

  Future<void> _mutateReviewers({
    required int prNumber,
    required List<String> userLogins,
    required List<String> teamSlugs,
    required bool add,
    Object? cancelToken,
  }) async {
    if (teamSlugs.isNotEmpty) {
      throw const ForgeUnsupportedError(ForgeHost.bitbucket, 'teamReviewers');
    }
    if (userLogins.isEmpty) {
      return;
    }
    final token = _token(cancelToken);

    final pr = await _client.getPullRequest(
      owner,
      repo,
      prNumber,
      cancelToken: token,
    );
    if (pr == null) {
      throw StateError('Pull request $owner/$repo#$prNumber does not exist.');
    }

    final members = await _listMembers(token);
    final byHandle = <String, BitbucketUser>{
      for (final member in members)
        if (member.handle.isNotEmpty) member.handle.toLowerCase(): member,
      // An account may publish a nickname AND be addressed by its account id;
      // index both so either spelling resolves.
      for (final member in members)
        if (member.accountId.isNotEmpty) member.accountId.toLowerCase(): member,
    };

    final targets = <String>{};
    for (final login in userLogins) {
      final key = login.trim().toLowerCase();
      final match = byHandle[key];
      if (match == null || match.uuid.isEmpty) {
        throw ArgumentError.value(
          login,
          'userLogins',
          'no member of the "$owner" Bitbucket workspace matches this handle',
        );
      }
      targets.add(match.uuid);
    }

    final uuids = <String>{
      for (final reviewer in pr.reviewers)
        if (reviewer.uuid.isNotEmpty) reviewer.uuid,
    };
    if (add) {
      uuids.addAll(targets);
    } else {
      uuids.removeAll(targets);
    }

    await _client.updatePullRequest(owner, repo, prNumber, <String, dynamic>{
      // The title rides along deliberately: Bitbucket rejects a pull request
      // update that would leave it without one, and re-sending the current
      // title makes the write a no-op for that field.
      'title': pr.title,
      'reviewers': <Map<String, dynamic>>[
        for (final uuid in uuids) <String, dynamic>{'uuid': uuid},
      ],
    }, cancelToken: token);
  }

  /// Narrows the port's untyped cancellation handle to Dio's.
  ///
  /// The port keeps it [Object] so `cc_domain` never learns about Dio; a
  /// handle of any other type is simply not a cancellation this adapter can
  /// honour and is dropped rather than throwing.
  static CancelToken? _token(Object? cancelToken) =>
      cancelToken is CancelToken ? cancelToken : null;
}
