import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
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
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_infra/src/network/gitlab/gitlab_api_client.dart';
import 'package:cc_infra/src/network/gitlab/gitlab_pr_mapper.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_award_emoji.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_project.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_tree_entry.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_user.dart';
import 'package:dio/dio.dart';

/// GitLab's implementation of the forge PR port, in merge-request terms.
///
/// Everything vendor-shaped stops here: [GitLabApiClient] speaks REST v4,
/// `gitlab_pr_mapper.dart` translates, and callers above see nothing but
/// domain entities. The three places GitLab genuinely differs from GitHub —
/// and where this adapter therefore does real work rather than a rename — are:
///
/// - **Reviews do not exist as objects.** A verdict is either an approval
///   (`/approvals`) or a reviewer sitting in `requested_changes`
///   (`/reviewers`), so [listReviews] synthesizes submissions from those two
///   and deliberately invents nothing for comment-only feedback.
/// - **Diffs arrive unframed.** GitLab returns hunks plus paths as separate
///   fields; [getPullRequestDiff] rebuilds the `diff --git`/`---`/`+++`
///   headers a unified-diff parser needs.
/// - **Draft state is the title.** A `Draft: ` prefix *is* the flag, which is
///   why [updatePullRequest] re-applies it rather than letting a title edit
///   silently mark a merge request ready.
///
/// Four capabilities are false for GitLab (`viewedStateSync`,
/// `suggestedReviewers`, `stacks`, `notifications`); their methods throw
/// [ForgeUnsupportedError] rather than returning an empty result, because
/// "none" and "this forge cannot tell you" are different answers.
class GitLabForgePrClient implements ForgePrClient {
  /// Creates a [GitLabForgePrClient] for `owner/repo` on the instance [client]
  /// is pointed at.
  ///
  /// [owner] is the namespace path and may be nested
  /// (`group/subgroup`); [repo] is the project name. Together they form the
  /// project coordinate every request is addressed by.
  GitLabForgePrClient({
    required GitLabApiClient client,
    required String owner,
    required String repo,
  }) : _client = client,
       owner = owner,
       repo = repo,
       _projectId = GitLabApiClient.encodeProjectPath('$owner/$repo');

  /// How many pipelines of one commit contribute check runs.
  ///
  /// A commit usually has one or two (a branch pipeline and a merge-request
  /// pipeline). The cap stops a commit that was re-run twenty times from
  /// turning one check refresh into twenty job requests.
  static const int _maxPipelinesPerSha = 5;

  /// How long [mergePullRequest] waits for a background rebase to settle
  /// before reporting that it has not merged.
  static const int _rebasePollAttempts = 20;

  /// Delay between rebase polls.
  static const Duration _rebasePollInterval = Duration(milliseconds: 500);

  /// Posted when a "request changes" verdict arrives without a body, so the
  /// merge request still records the verdict in its discussion.
  static const String _requestChangesFallbackBody = 'Changes requested.';

  /// How many branches the picker gets when the caller names no limit.
  static const int _defaultBranchLimit = 100;

  /// Where GitLab keeps merge-request description templates.
  static const String _prTemplateDirectory = '.gitlab/merge_request_templates';

  /// How many templates are fetched. Each costs one raw read, and a composer
  /// dropdown past this many is unusable anyway.
  static const int _maxPrTemplates = 25;

  final GitLabApiClient _client;
  final String _projectId;

  GitLabUser? _cachedViewer;
  GitLabProject? _cachedProject;

  @override
  ForgeHost get forge => ForgeHost.gitlab;

  @override
  ForgeCapabilities get capabilities => capabilitiesOf(ForgeHost.gitlab);

  @override
  final String owner;

  @override
  final String repo;

  String get _repoFullName => '$owner/$repo';

  // ── Reads ────────────────────────────────────────────────────────────────

  @override
  Future<PullRequest?> getPullRequest(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final mr = await _client.getMergeRequest(
      _projectId,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    if (mr == null) {
      return null;
    }
    return pullRequestFromGitLab(mr, repoFullName: _repoFullName);
  }

  /// One page of this project's open merge requests, most recently updated
  /// first.
  ///
  /// `checksStatus` rides along from each merge request's pipeline — the list
  /// payload carries a `pipeline` object and the detail payload a
  /// `head_pipeline`, and the mapper reads either — so the feed shows CI state
  /// without a follow-up request per row. An instance that omits it simply
  /// reports [PrChecksStatus.none]; there is no extra call to fail.
  /// `reviewDecision` is derived from `detailed_merge_status`, the same signal
  /// [getPullRequest] uses.
  @override
  Future<({List<PullRequest> prs, bool hasMore})> listOpenPullRequests({
    int limit = 100,
    Object? cancelToken,
  }) async {
    final page = await _client.listMergeRequests(
      _projectId,
      state: 'opened',
      perPage: limit,
      cancelToken: _token(cancelToken),
    );
    return (
      prs: <PullRequest>[
        for (final mr in page.items)
          pullRequestFromGitLab(mr, repoFullName: _repoFullName),
      ],
      hasMore: page.hasMore,
    );
  }

  /// Merge requests [login] authored that have been merged, most recently
  /// updated first.
  @override
  Future<List<PullRequest>> listMergedByAuthor(
    String login, {
    int limit = 50,
    Object? cancelToken,
  }) async {
    final handle = login.trim().replaceAll(RegExp(r'^@'), '');
    if (handle.isEmpty) {
      return const <PullRequest>[];
    }
    final page = await _client.listMergeRequests(
      _projectId,
      state: 'merged',
      authorUsername: handle,
      perPage: limit,
      cancelToken: _token(cancelToken),
    );
    return <PullRequest>[
      for (final mr in page.items)
        pullRequestFromGitLab(mr, repoFullName: _repoFullName),
    ];
  }

  /// Whether merge request [prNumber] left the open list by merging.
  ///
  /// Null is the deliberate answer to every uncertainty — a deleted merge
  /// request, a revoked token, a 500, a merge request that is somehow still
  /// open — because the caller fires a "merged" lifecycle event off `true` and
  /// must never do so on a guess. Cancellation still propagates: a cancelled
  /// poll is not an answer.
  @override
  Future<bool?> wasMerged(int prNumber, {Object? cancelToken}) async {
    try {
      final mr = await _client.getMergeRequest(
        _projectId,
        prNumber,
        cancelToken: _token(cancelToken),
      );
      if (mr == null) {
        return null;
      }
      if (mr.mergedAt != null || mr.state == 'merged') {
        return true;
      }
      if (mr.state == 'closed') {
        return false;
      }
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      return null;
    } on Object {
      return null;
    }
  }

  @override
  Future<String> getPullRequestDiff(int prNumber, {Object? cancelToken}) async {
    final diffs = await _client.listMergeRequestDiffs(
      _projectId,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return unifiedDiffFromGitLab(diffs);
  }

  @override
  Future<List<PrFile>> listFiles(
    int prNumber, {
    int? limit,
    Object? cancelToken,
  }) async {
    final diffs = await _client.listMergeRequestDiffs(
      _projectId,
      prNumber,
      limit: limit,
      cancelToken: _token(cancelToken),
    );
    return diffs.map(prFileFromGitLab).toList(growable: false);
  }

  /// {@macro forge_pr_client.listCommits}
  ///
  /// GitLab returns merge-request commits newest-first; the port asks for
  /// oldest-first, so the list is reversed here.
  @override
  Future<List<PrCommit>> listCommits(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final commits = await _client.listMergeRequestCommits(
      _projectId,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return commits.reversed.map(prCommitFromGitLab).toList(growable: false);
  }

  @override
  Future<List<PrFile>> listCommitFiles(
    String sha, {
    Object? cancelToken,
  }) async {
    final diffs = await _client.listCommitDiffs(
      _projectId,
      sha,
      cancelToken: _token(cancelToken),
    );
    return diffs.map(prFileFromGitLab).toList(growable: false);
  }

  /// Submitted verdicts on merge request [prNumber].
  ///
  /// Assembled from the approval summary plus the per-reviewer states, because
  /// GitLab has no review endpoint. Comment-only reviews are not synthesized —
  /// those are notes and surface through [listIssueComments] and
  /// [listReviewComments].
  @override
  Future<List<PrReviewSubmission>> listReviews(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final approvals = await _client.getMergeRequestApprovals(
      _projectId,
      prNumber,
      cancelToken: token,
    );
    final reviewers = await _client.listMergeRequestReviewers(
      _projectId,
      prNumber,
      cancelToken: token,
    );
    return prReviewSubmissionsFromGitLab(
      approvals: approvals,
      reviewers: reviewers,
    );
  }

  /// Inline review comments on merge request [prNumber].
  ///
  /// GitLab's list payloads carry no award-emoji summary, so the returned
  /// comments have empty `reactions`; the caller fetches those per comment via
  /// [listReactions] when it needs them.
  @override
  Future<List<PrCodeReviewComment>> listReviewComments(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final discussions = await _client.listMergeRequestDiscussions(
      _projectId,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return prCodeReviewCommentsFromGitLab(discussions);
  }

  @override
  Future<List<IssueComment>> listIssueComments(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final notes = await _client.listMergeRequestNotes(
      _projectId,
      prNumber,
      cancelToken: _token(cancelToken),
    );
    return issueCommentsFromGitLab(notes);
  }

  /// Always empty on GitLab.
  ///
  /// [PrTimelineEventKind] models exactly two things — a review request made
  /// and withdrawn — and GitLab publishes neither. Its resource-event
  /// endpoints (`resource_label_events`, `resource_state_events`,
  /// `resource_milestone_events`) cover labels, open/close/merge and
  /// milestones; reviewer assignment changes exist only as system notes, whose
  /// wording is untyped, localized prose that would have to be regex-guessed.
  ///
  /// Empty is the honest answer and not a capability lie: no timeline
  /// capability flag exists, and the activity feed simply renders the comment,
  /// review and commit streams it already has.
  @override
  Future<List<PrTimelineEvent>> listTimelineEvents(
    int prNumber, {
    Object? cancelToken,
  }) async => const <PrTimelineEvent>[];

  /// CI results for [headSha], one [CheckRun] per GitLab job.
  ///
  /// A commit can carry several pipelines (a branch run and a merge-request
  /// run, plus retries). They arrive newest-first and the newest occurrence of
  /// a job name wins, so a re-run replaces the run it superseded instead of
  /// appearing twice.
  @override
  Future<List<CheckRun>> listCheckRuns(
    String headSha, {
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final pipelines = await _client.listPipelinesForSha(
      _projectId,
      headSha,
      cancelToken: token,
    );
    final runs = <String, CheckRun>{};
    for (final pipeline in pipelines.take(_maxPipelinesPerSha)) {
      final jobs = await _client.listPipelineJobs(
        _projectId,
        pipeline.id,
        cancelToken: token,
      );
      for (final job in jobs) {
        if (job.name.isEmpty) {
          continue;
        }
        runs.putIfAbsent(
          job.name,
          () => checkRunFromGitLab(job, pipeline: pipeline),
        );
      }
    }
    return runs.values.toList(growable: false);
  }

  /// External commit statuses for [headSha].
  ///
  /// GitLab folds its own CI jobs into the same statuses feed, so returning it
  /// wholesale would duplicate every entry [listCheckRuns] already reports.
  /// Only statuses pointing somewhere that is not a GitLab job page survive —
  /// which is exactly the deploy-preview integrations this list exists for.
  @override
  Future<List<CommitStatus>> listCommitStatuses(
    String headSha, {
    Object? cancelToken,
  }) async {
    final statuses = await _client.listCommitStatuses(
      _projectId,
      headSha,
      cancelToken: _token(cancelToken),
    );
    return <CommitStatus>[
      for (final status in statuses)
        if (isExternalGitLabCommitStatus(status))
          commitStatusFromGitLab(status),
    ];
  }

  @override
  Future<String> getFileContent(
    String path,
    String ref, {
    Object? cancelToken,
  }) => _client.getRawFile(
    _projectId,
    path,
    ref,
    cancelToken: _token(cancelToken),
  );

  /// Not available on GitLab — throws [ForgeUnsupportedError].
  ///
  /// GitLab has no per-file "viewed" state at all, so there is nothing to
  /// read. The app still tracks viewed state locally; it just never syncs.
  @override
  Future<Map<String, PrFileViewedState>> getFileViewedStates(
    int prNumber, {
    Object? cancelToken,
  }) async =>
      throw const ForgeUnsupportedError(ForgeHost.gitlab, 'viewedStateSync');

  /// Who is reviewing merge request [prNumber], and who owns the touched code.
  ///
  /// Three sources are reconciled: assigned reviewers with their states, the
  /// approval summary, and the approval rules (which carry group reviewers and
  /// GitLab's CODEOWNERS equivalent). The rules endpoint is a paid-tier
  /// feature and degrades to "no rules" on instances without it, so a Free
  /// instance yields user rows with no code-owner shields rather than an
  /// error.
  @override
  Future<PrReviewerState> getReviewerState(
    int prNumber, {
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final reviewers = await _client.listMergeRequestReviewers(
      _projectId,
      prNumber,
      cancelToken: token,
    );
    final approvals = await _client.getMergeRequestApprovals(
      _projectId,
      prNumber,
      cancelToken: token,
    );
    final approvalState = await _client.getMergeRequestApprovalState(
      _projectId,
      prNumber,
      cancelToken: token,
    );
    return prReviewerStateFromGitLab(
      reviewers: reviewers,
      approvals: approvals,
      approvalState: approvalState,
    );
  }

  @override
  Future<PrUser?> getAuthenticatedUser({Object? cancelToken}) async {
    final user = await _resolveViewer(_token(cancelToken));
    return user == null ? null : prUserFromGitLab(user);
  }

  /// Everyone who can be assigned to, or asked to review, this project.
  ///
  /// Inherited memberships are included (a subgroup project's reviewers
  /// usually live on the parent group) and Guests are filtered out, since
  /// GitLab refuses to assign them.
  @override
  Future<List<PrUser>> listAssignableUsers({Object? cancelToken}) async {
    final members = await _client.listProjectMembers(
      _projectId,
      cancelToken: _token(cancelToken),
    );
    return <PrUser>[
      for (final member in members)
        if (member.isAssignable) prUserFromGitLabMember(member),
    ];
  }

  /// Project members plus the groups that stand in for reviewer teams.
  ///
  /// The team half is the project's own group namespace and any group the
  /// project is shared with, keyed by full path. GitLab cannot put a group on
  /// a merge request's reviewer list, so [requestReviewers] expands a team
  /// selection into its members — see there.
  @override
  Future<List<PrReviewerCandidate>> listRequestableReviewers({
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final members = await _client.listProjectMembers(
      _projectId,
      cancelToken: token,
    );
    final project = await _resolveProject(token);
    final groups = <GitLabGroupRef>[];
    final namespace = project?.namespace;
    if (namespace != null &&
        namespace.kind == 'group' &&
        namespace.fullPath.isNotEmpty) {
      groups.add(
        GitLabGroupRef(
          id: namespace.id,
          name: namespace.name,
          fullPath: namespace.fullPath,
          avatarUrl: namespace.avatarUrl,
        ),
      );
    }
    groups.addAll(project?.sharedWithGroups ?? const <GitLabGroupRef>[]);
    return reviewerCandidatesFromGitLab(members: members, groups: groups);
  }

  /// Not available on GitLab — throws [ForgeUnsupportedError].
  @override
  Future<List<PrUser>> listSuggestedReviewers(
    int prNumber, {
    Object? cancelToken,
  }) async =>
      throw const ForgeUnsupportedError(ForgeHost.gitlab, 'suggestedReviewers');

  /// Detail and logs for one CI job.
  ///
  /// `steps` comes back empty: a GitLab job is atomic — it runs a script and
  /// produces a trace, with no step breakdown to drill into — so the detail
  /// view shows the (tail-truncated) trace alone.
  @override
  Future<JobRunDetail?> getJobRunDetail(
    int jobId, {
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final job = await _client.getJob(_projectId, jobId, cancelToken: token);
    if (job == null) {
      return null;
    }
    final trace = await _client.getJobTrace(
      _projectId,
      jobId,
      cancelToken: token,
    );
    return jobRunDetailFromGitLab(
      job,
      logs: trace?.text,
      logsTruncated: trace?.truncated ?? false,
    );
  }

  /// The job graph of pipeline [workflowRunId].
  ///
  /// GitLab's pipeline is the analogue of a GitHub workflow run, so
  /// [workflowRunId] is a pipeline id. Its REST job payload carries no `needs`
  /// (only GraphQL does), so edges fall back to stage ordering: every job
  /// depends on the whole preceding stage.
  @override
  Future<WorkflowGraph?> getWorkflowGraph(
    int workflowRunId, {
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final pipeline = await _client.getPipeline(
      _projectId,
      workflowRunId,
      cancelToken: token,
    );
    if (pipeline == null) {
      return null;
    }
    final jobs = await _client.listPipelineJobs(
      _projectId,
      workflowRunId,
      cancelToken: token,
    );
    return workflowGraphFromGitLabJobs(
      jobs,
      name: gitLabPipelineDisplayName(pipeline),
    );
  }

  // ── Compose-PR surface ───────────────────────────────────────────────────

  /// The project's branches, most recently committed first.
  ///
  /// GitLab orders branches by *name* and has no sort-by-activity, so the
  /// ordering the picker needs can only be produced client-side: the branches
  /// are paged in (up to the client's page ceiling of
  /// [kGitLabMaxPages] × [kGitLabMaxPerPage]), sorted by tip date, and only
  /// then truncated to [limit]. Sorting before truncating is the point — a
  /// truncate-first read of a 500-branch project would hand back the
  /// alphabetical head and hide the branch someone pushed a minute ago.
  ///
  /// A project with more branches than the ceiling loses the tail of the
  /// alphabet, which is the same bound every other list in this adapter has.
  @override
  Future<List<ForgeBranch>> listBranches({
    int? limit,
    Object? cancelToken,
  }) async {
    final branches = await _client.listBranches(
      _projectId,
      cancelToken: _token(cancelToken),
    );
    return forgeBranchesFromGitLab(
      branches,
      limit: limit ?? _defaultBranchLimit,
    );
  }

  /// The project's default branch, or an empty string when it cannot be read.
  ///
  /// The compose screen pre-selects this as the merge target, so a failure has
  /// to degrade to "no preselection" rather than blocking the screen — hence
  /// the empty string rather than an exception. Cancellation still propagates.
  @override
  Future<String> getDefaultBranch({Object? cancelToken}) async {
    try {
      final project = await _resolveProject(_token(cancelToken));
      return project?.defaultBranch ?? '';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      return '';
    } on Object {
      return '';
    }
  }

  /// What a merge request from [head] into [base] would contain.
  ///
  /// One request answers it: GitLab's compare endpoint returns both the
  /// commits and the same per-file diff shape the merge-request file list
  /// uses, so the files carry real patches and line counts rather than
  /// placeholders.
  ///
  /// Null means "could not compare" — a branch that does not exist, a ref the
  /// token cannot see, a comparison GitLab declined. That is deliberately
  /// distinct from a comparison with no files, which is how the composer tells
  /// "nothing to merge" from "I could not check".
  @override
  Future<ForgeBranchComparison?> compareBranches({
    required String base,
    required String head,
    Object? cancelToken,
  }) async {
    if (base.trim().isEmpty || head.trim().isEmpty) {
      return null;
    }
    try {
      final comparison = await _client.compareRefs(
        _projectId,
        from: base.trim(),
        to: head.trim(),
        cancelToken: _token(cancelToken),
      );
      if (comparison == null) {
        return null;
      }
      return forgeBranchComparisonFromGitLab(comparison);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      return null;
    } on Object {
      return null;
    }
  }

  /// The project's merge-request description templates, keyed by display name.
  ///
  /// GitLab keeps them as `.md` files in `.gitlab/merge_request_templates/`
  /// and the tree listing carries no content, so each template costs one raw
  /// fetch — capped at [_maxPrTemplates] so a project that has filled the
  /// directory cannot turn opening the composer into fifty requests.
  ///
  /// A missing directory, an empty one, or a template that fails to read all
  /// resolve to "no template" rather than an error: the composer must still
  /// open when a project simply has none.
  @override
  Future<Map<String, String>> listPrTemplates({Object? cancelToken}) async {
    final token = _token(cancelToken);
    final entries = await _client.listRepositoryTree(
      _projectId,
      path: _prTemplateDirectory,
      cancelToken: token,
    );
    final blobs = <GitLabTreeEntry>[
      for (final entry in entries)
        if (entry.isBlob && entry.path.isNotEmpty) entry,
    ];
    if (blobs.isEmpty) {
      return const <String, String>{};
    }

    // The tree listing defaults to the default branch, so the raw reads use
    // the same ref — otherwise a template could be listed from one commit and
    // read from another.
    final project = await _resolveProject(token);
    final ref = (project?.defaultBranch.isNotEmpty ?? false)
        ? project!.defaultBranch
        : 'HEAD';

    final templates = <String, String>{};
    for (final blob in blobs.take(_maxPrTemplates)) {
      final body = await _client.getRawFile(
        _projectId,
        blob.path,
        ref,
        cancelToken: token,
      );
      if (body.isEmpty) {
        continue;
      }
      templates[gitLabTemplateName(blob.name)] = body;
    }
    return templates;
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  /// Opens an inline comment thread on merge request [prNumber].
  ///
  /// [commitSha] is unused: GitLab anchors a position against the merge
  /// request's `diff_refs` triple (base/head/start), not against a single
  /// commit, and those are read from the merge request itself. A merge request
  /// with no diff refs cannot carry an inline comment at all, which throws
  /// rather than silently dropping the comment.
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
    final token = _token(cancelToken);
    final mr = await _client.getMergeRequest(
      _projectId,
      prNumber,
      cancelToken: token,
    );
    final refs = mr?.diffRefs;
    if (refs == null || !refs.isComplete) {
      throw StateError(
        'GitLab merge request !$prNumber in $_repoFullName carries no diff '
        'refs, so an inline comment cannot be anchored.',
      );
    }
    final position = gitLabPositionForAnchor(
      refs: refs,
      path: path,
      line: line,
      side: side,
      startLine: startLine,
      startSide: startSide,
    );
    final discussion = await _client.createDiscussion(
      _projectId,
      prNumber,
      body: body,
      position: position,
      cancelToken: token,
    );
    if (discussion == null) {
      return null;
    }
    for (final note in discussion.notes) {
      final notePosition = note.position;
      if (notePosition != null) {
        return prCodeReviewCommentFromGitLab(note, position: notePosition);
      }
    }
    return null;
  }

  /// Appends a reply to the thread [parentCommentId] belongs to.
  ///
  /// GitLab replies are addressed by *discussion* id (a hex string), while the
  /// domain carries integer note ids. Both spellings are accepted: a numeric
  /// [parentCommentId] is resolved to its discussion by looking it up on the
  /// merge request, anything else is taken as a discussion id already.
  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required String parentCommentId,
    required String body,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final discussionId = await _resolveDiscussionId(
      prNumber,
      parentCommentId,
      token,
    );
    if (discussionId == null) {
      throw StateError(
        'No GitLab discussion found for comment $parentCommentId on '
        '!$prNumber in $_repoFullName.',
      );
    }
    await _client.createDiscussionNote(
      _projectId,
      prNumber,
      discussionId: discussionId,
      body: body,
      cancelToken: token,
    );
  }

  /// Submits a verdict on merge request [prNumber].
  ///
  /// Pending draft notes are published first in one batch — that is what the
  /// `pendingReviewBatching` capability names — so a reviewer's queued inline
  /// comments land together with the verdict rather than trickling out.
  ///
  /// The verdicts then map as GitLab allows:
  /// - **approve** posts the body as a note (when there is one) and calls
  ///   `/approve`.
  /// - **requestChanges** posts the body as a note and withdraws any existing
  ///   approval. GitLab's REST API has no "request changes" verb — the
  ///   reviewer state is only settable through its own UI and GraphQL — so the
  ///   note carries the verdict and the unapprove makes it binding. A verdict
  ///   with no body still posts a short note, so the merge request records
  ///   that changes were asked for.
  /// - **comment** posts the body as a note and casts no verdict.
  @override
  Future<void> submitReview({
    required int prNumber,
    required ForgeReviewVerdict verdict,
    String? body,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    await _publishDraftNotes(prNumber, token);
    final text = body?.trim() ?? '';

    switch (verdict) {
      case ForgeReviewVerdict.approve:
        if (text.isNotEmpty) {
          await _client.createMergeRequestNote(
            _projectId,
            prNumber,
            body: text,
            cancelToken: token,
          );
        }
        await _client.approveMergeRequest(
          _projectId,
          prNumber,
          cancelToken: token,
        );
      case ForgeReviewVerdict.requestChanges:
        await _client.createMergeRequestNote(
          _projectId,
          prNumber,
          body: text.isEmpty ? _requestChangesFallbackBody : text,
          cancelToken: token,
        );
        await _client.unapproveMergeRequest(
          _projectId,
          prNumber,
          cancelToken: token,
        );
      case ForgeReviewVerdict.comment:
        if (text.isNotEmpty) {
          await _client.createMergeRequestNote(
            _projectId,
            prNumber,
            body: text,
            cancelToken: token,
          );
        }
    }
  }

  /// Merges merge request [prNumber].
  ///
  /// `merge_when_pipeline_succeeds` is never set: the port promises to report
  /// what happened, and a deferred merge would report a success that has not
  /// occurred. A rebase merge is two operations on GitLab — `PUT /rebase` runs
  /// in the background, so it is polled to completion before the merge is
  /// attempted, and a rebase still running when the budget runs out returns
  /// `merged: false` with an explanation rather than merging something that
  /// may be mid-rewrite.
  @override
  Future<PrMergeOutcome> mergePullRequest({
    required int prNumber,
    required ForgeMergeMethod method,
    String? commitTitle,
    String? commitMessage,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    if (method == ForgeMergeMethod.rebase) {
      await _client.rebaseMergeRequest(
        _projectId,
        prNumber,
        cancelToken: token,
      );
      final settled = await _awaitRebase(prNumber, token);
      if (!settled) {
        return const PrMergeOutcome(
          merged: false,
          message: 'The rebase is still running. Try merging again shortly.',
        );
      }
    }

    final squash = method == ForgeMergeMethod.squash;
    final message = _composeCommitMessage(commitTitle, commitMessage);
    final merged = await _client.acceptMergeRequest(
      _projectId,
      prNumber,
      squash: squash,
      mergeCommitMessage: squash ? null : message,
      squashCommitMessage: squash ? message : null,
      cancelToken: token,
    );
    if (merged == null) {
      return const PrMergeOutcome(
        merged: false,
        message: 'GitLab returned no merge result.',
      );
    }
    final sha = <String>[
      merged.mergeCommitSha,
      merged.squashCommitSha,
      merged.sha,
    ].firstWhere((candidate) => candidate.isNotEmpty, orElse: () => '');
    return PrMergeOutcome(
      merged: merged.state == 'merged' || merged.mergedAt != null,
      message: merged.mergeError,
      sha: sha.isEmpty ? null : sha,
    );
  }

  @override
  Future<void> closePullRequest(int prNumber, {Object? cancelToken}) async {
    await _client.updateMergeRequest(
      _projectId,
      prNumber,
      stateEvent: 'close',
      cancelToken: _token(cancelToken),
    );
  }

  /// Opens a merge request.
  ///
  /// A draft is expressed the only way GitLab has: by prefixing the title with
  /// `Draft: `.
  @override
  Future<PullRequest> createPullRequest({
    required String title,
    required String body,
    required String headBranch,
    required String baseBranch,
    bool draft = false,
    Object? cancelToken,
  }) async {
    final mr = await _client.createMergeRequest(
      _projectId,
      title: draft ? applyGitLabDraftPrefix(title) : title,
      sourceBranch: headBranch,
      targetBranch: baseBranch,
      description: body,
      cancelToken: _token(cancelToken),
    );
    return pullRequestFromGitLab(mr, repoFullName: _repoFullName);
  }

  /// Edits a merge request's title and/or description.
  ///
  /// A title write against a draft merge request re-applies the `Draft: `
  /// prefix. This is not cosmetic: on GitLab the prefix *is* the draft state,
  /// so sending the bare title the UI displays would silently mark the merge
  /// request ready for review. That costs one read of the merge request, and
  /// only when a title is actually being changed.
  @override
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    String? nextTitle;
    if (title != null) {
      final mr = await _client.getMergeRequest(
        _projectId,
        prNumber,
        cancelToken: token,
      );
      nextTitle = (mr?.draft ?? false) ? applyGitLabDraftPrefix(title) : title;
    }
    await _client.updateMergeRequest(
      _projectId,
      prNumber,
      title: nextTitle,
      description: body,
      cancelToken: token,
    );
  }

  /// Not available on GitLab — throws [ForgeUnsupportedError].
  @override
  Future<void> setFileViewedState({
    required int prNumber,
    required String prExternalId,
    required String path,
    required bool viewed,
    Object? cancelToken,
  }) async =>
      throw const ForgeUnsupportedError(ForgeHost.gitlab, 'viewedStateSync');

  /// Adds assignees to merge request [prNumber].
  ///
  /// GitLab has no add/remove verbs — `assignee_ids` is set wholesale — so the
  /// current assignees are read first and the new ids merged in. Logins are
  /// resolved to numeric ids because that is what the write parameter takes.
  @override
  Future<void> addAssignees({
    required int prNumber,
    required List<String> logins,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    if (logins.isEmpty) {
      return;
    }
    final mr = await _client.getMergeRequest(
      _projectId,
      prNumber,
      cancelToken: token,
    );
    if (mr == null) {
      return;
    }
    final ids = <int>{for (final user in mr.assignees) user.id};
    final resolved = await _resolveUserIds(logins, token);
    ids.addAll(resolved);
    await _client.updateMergeRequest(
      _projectId,
      prNumber,
      assigneeIds: ids.toList(growable: false),
      cancelToken: token,
    );
  }

  /// Removes assignees from merge request [prNumber].
  ///
  /// No id lookups are needed: the current assignees already carry their
  /// handles, so the removal is a filter over what GitLab just returned.
  @override
  Future<void> removeAssignees({
    required int prNumber,
    required List<String> logins,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    if (logins.isEmpty) {
      return;
    }
    final mr = await _client.getMergeRequest(
      _projectId,
      prNumber,
      cancelToken: token,
    );
    if (mr == null) {
      return;
    }
    final drop = _lowercased(logins);
    final ids = <int>[
      for (final user in mr.assignees)
        if (!drop.contains(user.username.toLowerCase())) user.id,
    ];
    await _client.updateMergeRequest(
      _projectId,
      prNumber,
      assigneeIds: ids,
      cancelToken: token,
    );
  }

  /// Requests reviews on merge request [prNumber].
  ///
  /// [teamSlugs] are group full paths. GitLab cannot put a group on a merge
  /// request's reviewer list — only an approval *rule* can name one — so a
  /// team request is expanded into that group's assignable members and each is
  /// added individually. The effect matches the intent ("this group should
  /// look at it"); what is lost is the group appearing as a single row until
  /// somebody reviews.
  @override
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins = const <String>[],
    List<String> teamSlugs = const <String>[],
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final logins = await _expandReviewerLogins(userLogins, teamSlugs, token);
    if (logins.isEmpty) {
      return;
    }
    final mr = await _client.getMergeRequest(
      _projectId,
      prNumber,
      cancelToken: token,
    );
    if (mr == null) {
      return;
    }
    final ids = <int>{for (final user in mr.reviewers) user.id};
    ids.addAll(await _resolveUserIds(logins.toList(growable: false), token));
    await _client.updateMergeRequest(
      _projectId,
      prNumber,
      reviewerIds: ids.toList(growable: false),
      cancelToken: token,
    );
  }

  /// Cancels review requests on merge request [prNumber].
  ///
  /// [teamSlugs] are expanded to their members, mirroring [requestReviewers].
  @override
  Future<void> removeRequestedReviewers({
    required int prNumber,
    List<String> userLogins = const <String>[],
    List<String> teamSlugs = const <String>[],
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final logins = await _expandReviewerLogins(userLogins, teamSlugs, token);
    if (logins.isEmpty) {
      return;
    }
    final mr = await _client.getMergeRequest(
      _projectId,
      prNumber,
      cancelToken: token,
    );
    if (mr == null) {
      return;
    }
    final drop = _lowercased(logins);
    final ids = <int>[
      for (final user in mr.reviewers)
        if (!drop.contains(user.username.toLowerCase())) user.id,
    ];
    await _client.updateMergeRequest(
      _projectId,
      prNumber,
      reviewerIds: ids,
      cancelToken: token,
    );
  }

  /// The award emoji on [target], as raw `(emoji, who)` pairs.
  ///
  /// Shortcodes are translated back into the domain's vocabulary (`thumbsup`
  /// → `+1`) so a reaction listed here and one written by [toggleReaction]
  /// name the same thing.
  @override
  Future<List<ForgeReaction>> listReactions({
    required ForgeReactionTarget target,
    required String targetId,
    required int prNumber,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final List<GitLabAwardEmoji> awards;
    if (target == ForgeReactionTarget.pullRequest) {
      awards = await _client.listMergeRequestAwardEmoji(
        _projectId,
        prNumber,
        cancelToken: token,
      );
    } else {
      awards = await _client.listNoteAwardEmoji(
        _projectId,
        prNumber,
        _requireNoteId(targetId, target),
        cancelToken: token,
      );
    }
    return forgeReactionsFromGitLab(awards);
  }

  /// Adds or removes an award emoji on [target].
  ///
  /// Removal is a two-step on GitLab: awards are individual objects owned by
  /// one user and there is no "delete by emoji name", so the viewer's own
  /// award is located first and deleted by id. GitLab enforces the ownership
  /// itself, so a mismatch surfaces as its error rather than being guessed at
  /// here.
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
    final name = gitLabAwardEmojiName(content);
    final isPullRequest = target == ForgeReactionTarget.pullRequest;
    final noteId = isPullRequest ? 0 : _requireNoteId(targetId, target);

    if (add) {
      if (isPullRequest) {
        await _client.createMergeRequestAwardEmoji(
          _projectId,
          prNumber,
          name: name,
          cancelToken: token,
        );
      } else {
        await _client.createNoteAwardEmoji(
          _projectId,
          prNumber,
          noteId,
          name: name,
          cancelToken: token,
        );
      }
      return;
    }

    final viewer = await _resolveViewer(token);
    final awards = isPullRequest
        ? await _client.listMergeRequestAwardEmoji(
            _projectId,
            prNumber,
            cancelToken: token,
          )
        : await _client.listNoteAwardEmoji(
            _projectId,
            prNumber,
            noteId,
            cancelToken: token,
          );
    for (final award in awards) {
      if (award.name != name) {
        continue;
      }
      if (viewer != null && award.user != null && award.user!.id != viewer.id) {
        continue;
      }
      if (isPullRequest) {
        await _client.deleteMergeRequestAwardEmoji(
          _projectId,
          prNumber,
          award.id,
          cancelToken: token,
        );
      } else {
        await _client.deleteNoteAwardEmoji(
          _projectId,
          prNumber,
          noteId,
          award.id,
          cancelToken: token,
        );
      }
      return;
    }
  }

  /// Uploads [base64Content] to the project and returns its absolute URL.
  ///
  /// GitLab uploads are not commits: there is no branch, no path and no commit
  /// message, so [message] is unused and [path] contributes only its basename
  /// as the stored filename. GitLab answers with a project-relative
  /// `/uploads/<hash>/<name>`, which is joined onto the project's web URL so
  /// the caller gets something that resolves from anywhere.
  @override
  Future<String> uploadContent({
    required String path,
    required String base64Content,
    required String message,
    Object? cancelToken,
  }) async {
    final token = _token(cancelToken);
    final segments = path.split('/').where((part) => part.isNotEmpty).toList();
    final filename = segments.isEmpty ? 'upload' : segments.last;
    final url = await _client.uploadFile(
      _projectId,
      bytes: base64Decode(base64Content),
      filename: filename,
      cancelToken: token,
    );
    if (url == null) {
      throw StateError('GitLab returned no URL for the upload of $filename.');
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final project = await _resolveProject(token);
    final base = project?.webUrl.replaceAll(RegExp(r'/+$'), '') ?? '';
    return base.isEmpty ? url : '$base$url';
  }

  // ── Stacks: not a GitLab concept ─────────────────────────────────────────

  /// Not available on GitLab — throws [ForgeUnsupportedError].
  @override
  Future<List<PrStack>> listStacks({
    int? prNumber,
    Object? cancelToken,
  }) async => throw const ForgeUnsupportedError(ForgeHost.gitlab, 'stacks');

  /// Not available on GitLab — throws [ForgeUnsupportedError].
  @override
  Future<PrStack> createStack({
    required List<int> prNumbers,
    Object? cancelToken,
  }) async => throw const ForgeUnsupportedError(ForgeHost.gitlab, 'stacks');

  /// Not available on GitLab — throws [ForgeUnsupportedError].
  @override
  Future<PrStack?> addToStack({
    required int stackNumber,
    required List<int> prNumbers,
    Object? cancelToken,
  }) async => throw const ForgeUnsupportedError(ForgeHost.gitlab, 'stacks');

  /// Not available on GitLab — throws [ForgeUnsupportedError].
  @override
  Future<PrStack?> unstack({
    required int stackNumber,
    Object? cancelToken,
  }) async => throw const ForgeUnsupportedError(ForgeHost.gitlab, 'stacks');

  // ── Internals ────────────────────────────────────────────────────────────

  /// Narrows the port's opaque cancellation handle to dio's [CancelToken].
  ///
  /// The port keeps it `Object?` so no domain type learns about dio; anything
  /// that is not a token is simply no cancellation.
  static CancelToken? _token(Object? cancelToken) =>
      cancelToken is CancelToken ? cancelToken : null;

  static Set<String> _lowercased(Iterable<String> values) => <String>{
    for (final value in values)
      if (value.trim().isNotEmpty) value.trim().toLowerCase(),
  };

  /// Joins a merge-commit title and body the way git writes them.
  static String? _composeCommitMessage(String? title, String? message) {
    final head = title?.trim() ?? '';
    final tail = message?.trim() ?? '';
    if (head.isEmpty && tail.isEmpty) {
      return null;
    }
    if (head.isEmpty) {
      return tail;
    }
    if (tail.isEmpty) {
      return head;
    }
    return '$head\n\n$tail';
  }

  /// Publishes the viewer's queued draft notes, if there are any.
  ///
  /// The listing comes first so an empty queue costs one cheap read instead of
  /// a publish call that would have nothing to do.
  Future<void> _publishDraftNotes(int prNumber, CancelToken? token) async {
    final drafts = await _client.listDraftNoteIds(
      _projectId,
      prNumber,
      cancelToken: token,
    );
    if (drafts.isEmpty) {
      return;
    }
    await _client.publishDraftNotes(_projectId, prNumber, cancelToken: token);
  }

  /// Polls until GitLab's background rebase of [prNumber] finishes, returning
  /// false when it is still running after the budget.
  Future<bool> _awaitRebase(int prNumber, CancelToken? token) async {
    for (var attempt = 0; attempt < _rebasePollAttempts; attempt++) {
      await Future<void>.delayed(_rebasePollInterval);
      final mr = await _client.getMergeRequest(
        _projectId,
        prNumber,
        includeRebaseInProgress: true,
        cancelToken: token,
      );
      if (mr == null) {
        return false;
      }
      if (!mr.rebaseInProgress) {
        return true;
      }
    }
    return false;
  }

  /// Resolves handles to the numeric ids GitLab's `*_ids` writes take.
  /// Handles that match no account are skipped.
  Future<List<int>> _resolveUserIds(
    List<String> logins,
    CancelToken? token,
  ) async {
    final ids = <int>[];
    for (final login in logins) {
      if (login.trim().isEmpty) {
        continue;
      }
      final user = await _client.findUserByUsername(login, cancelToken: token);
      if (user != null && user.id > 0) {
        ids.add(user.id);
      }
    }
    return ids;
  }

  /// Expands a reviewer selection into plain handles, turning each group full
  /// path in [teamSlugs] into that group's assignable members.
  Future<Set<String>> _expandReviewerLogins(
    List<String> userLogins,
    List<String> teamSlugs,
    CancelToken? token,
  ) async {
    final logins = <String>{
      for (final login in userLogins)
        if (login.trim().isNotEmpty) login.trim(),
    };
    for (final slug in teamSlugs) {
      if (slug.trim().isEmpty) {
        continue;
      }
      final members = await _client.listGroupMembers(
        slug.trim(),
        cancelToken: token,
      );
      for (final member in members) {
        if (member.isAssignable) {
          logins.add(member.username);
        }
      }
    }
    return logins;
  }

  /// Finds the discussion a reply should be appended to.
  ///
  /// Accepts either a numeric note id (resolved by scanning the merge
  /// request's discussions) or a discussion id already.
  Future<String?> _resolveDiscussionId(
    int prNumber,
    String parentCommentId,
    CancelToken? token,
  ) async {
    final trimmed = parentCommentId.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final noteId = int.tryParse(trimmed);
    if (noteId == null) {
      return trimmed;
    }
    final discussions = await _client.listMergeRequestDiscussions(
      _projectId,
      prNumber,
      cancelToken: token,
    );
    for (final discussion in discussions) {
      for (final note in discussion.notes) {
        if (note.id == noteId) {
          return discussion.id;
        }
      }
    }
    return null;
  }

  /// The note id behind a comment reaction target.
  static int _requireNoteId(String targetId, ForgeReactionTarget target) {
    final noteId = int.tryParse(targetId.trim());
    if (noteId == null || noteId <= 0) {
      throw ArgumentError.value(
        targetId,
        'targetId',
        'a ${target.name} reaction on GitLab needs a numeric note id',
      );
    }
    return noteId;
  }

  /// The token's user, fetched once and remembered.
  ///
  /// Only a successful lookup is cached, so a transient failure does not pin a
  /// null viewer for the life of the client.
  Future<GitLabUser?> _resolveViewer(CancelToken? token) async {
    final cached = _cachedViewer;
    if (cached != null) {
      return cached;
    }
    final viewer = await _client.getCurrentUser(cancelToken: token);
    if (viewer != null) {
      _cachedViewer = viewer;
    }
    return viewer;
  }

  /// The project, fetched once and remembered. Same caching rule as
  /// [_resolveViewer].
  Future<GitLabProject?> _resolveProject(CancelToken? token) async {
    final cached = _cachedProject;
    if (cached != null) {
      return cached;
    }
    final project = await _client.getProject(_projectId, cancelToken: token);
    if (project != null) {
      _cachedProject = project;
    }
    return project;
  }
}
