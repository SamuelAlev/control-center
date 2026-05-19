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
import 'package:cc_domain/features/pr_review/domain/value_objects/pending_review_comment.dart';

/// Pr review repository.
abstract class PrReviewRepository {
  /// Watch pull request.
  Stream<PullRequest?> watchPullRequest(int prNumber);

  /// Watch diff.
  Stream<String> watchDiff(int prNumber);

  /// Stream of changed files for a PR.
  Stream<List<PrFile>> watchFiles(int prNumber);

  /// Watch file content.
  Stream<String> watchFileContent(String path, String ref);

  /// Stream of commits for a PR.
  Stream<List<PrCommit>> watchCommits(int prNumber);

  /// Stream of files changed in a single commit.
  Stream<List<PrFile>> watchCommitFiles(String sha);

  /// Stream of review submissions for a PR.
  Stream<List<PrReviewSubmission>> watchReviews(int prNumber);

  /// Stream of inline review comments for a PR.
  Stream<List<PrCodeReviewComment>> watchReviewComments(int prNumber);

  /// Stream of top-level issue comments for a PR.
  Stream<List<IssueComment>> watchIssueComments(int prNumber);

  /// Stream of conversation-timeline events (review requests and request
  /// removals) for a PR, feeding the Overview activity feed.
  Stream<List<PrTimelineEvent>> watchTimelineEvents(int prNumber);

  /// Stream of CI check runs for a PR.
  Stream<List<CheckRun>> watchCheckRuns(int prNumber);

  /// Fetches live detail for one GitHub Actions job: current step progress
  /// plus, once published, its (tail-truncated) logs. Null when the job id
  /// doesn't resolve (non-Actions check, deleted run, insufficient
  /// permission).
  Future<JobRunDetail?> getJobRunDetail(int jobId);

  /// Fetches the parsed job graph (`needs` edges) of one workflow run, read
  /// from the workflow YAML at the run's head SHA. Null when the run or its
  /// workflow file can't be read.
  Future<WorkflowGraph?> getWorkflowGraph(int workflowRunId);

  /// Stream of commit statuses for a PR head (the Statuses API, distinct from
  /// check runs). Carries the `target_url` that deploy-preview integrations
  /// (Netlify, some Vercel setups) publish their live preview URL through.
  Stream<List<CommitStatus>> watchCommitStatuses(int prNumber);

  /// Invalidate pull request.
  Future<void> invalidatePullRequest(int prNumber);

  /// Drops the cached diff and file list for a PR so the next read is forced
  /// to hit the network. Used by the user-initiated "refresh diff" action,
  /// which must be authoritative rather than honouring the SWR freshness gate.
  Future<void> invalidateDiff(int prNumber);

  /// Mark file as viewed.
  Future<void> markFileAsViewed({
    required int prNumber,
    required String externalId,
    required String path,
    required bool viewed,
  });

  /// Post a new inline review comment on GitHub.
  Future<Map<String, dynamic>> postReviewComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
  });

  /// Reply to review comment.
  Future<void> replyToReviewComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  });

  /// Upsert draft.
  Future<void> upsertDraft(int prNumber, String text);

  /// Get draft.
  Future<String?> getDraft(int prNumber);

  /// Clear draft.
  Future<void> clearDraft(int prNumber);

  /// Upload content.
  Future<String> uploadContent(
    String path,
    String base64Content,
    String message,
  );

  /// Toggle a reaction on a review comment.
  Future<void> toggleReviewCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  });

  /// Toggle a reaction on an issue comment.
  Future<void> toggleIssueCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  });

  /// Toggle a reaction on the pull request itself.
  Future<void> togglePullRequestReaction({
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  });

  /// Toggle a reaction on a review submission's summary.
  Future<void> toggleReviewReaction({
    required int reviewId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  });

  /// Submit a PR review (approve, request changes, or comment).
  ///
  /// [comments] are inline comments queued for this review; passing them here
  /// (rather than posting them first) is what makes the review ONE event on the
  /// PR. Forges that cannot batch post them individually, then the verdict.
  Future<void> submitReview({
    required int prNumber,
    required String event,
    String? body,
    List<PendingReviewComment> comments = const [],
  });

  /// Marks an inline review thread resolved, or reopens it.
  ///
  /// [threadId] is the forge's thread id, carried on
  /// [PrCodeReviewComment.threadId]. Throws on a forge without the
  /// `commentThreadResolution` capability rather than silently no-op-ing —
  /// a resolve that quietly did nothing would read as "settled" to the one
  /// person who cannot see the PR.
  Future<void> setReviewThreadResolved({
    required int prNumber,
    required String threadId,
    required bool resolved,
  });

  /// Merge a pull request.
  ///
  /// [mergeMethod] must be one of: "squash", "merge", "rebase".
  /// Returns a map with `merged`, `message` and `sha` from GitHub.
  /// [idempotencyKey] (PRD 19 §3) dedupes a retried merge (e.g. one item of a
  /// bulk merge) so it never double-calls GitHub.
  Future<Map<String, dynamic>> mergePullRequest({
    required int prNumber,
    required String mergeMethod,
    String? commitTitle,
    String? commitMessage,
    String? idempotencyKey,
  });

  /// Close a pull request (set state to "closed").
  Future<void> closePullRequest({required int prNumber});

  /// Move a pull request between draft and ready-for-review.
  ///
  /// [draft] true converts an open pull request back to a draft; false marks a
  /// draft ready for review. Only meaningful on a forge whose `draftToggle`
  /// capability is true.
  Future<void> setPullRequestDraft({
    required int prNumber,
    required bool draft,
  });

  /// Lists the pull request stacks of the repo, optionally filtered to the
  /// stack containing PR [prNumber]. Each stack's entries run bottom to top.
  Future<List<PrStack>> listStacks({int? prNumber});

  /// Creates a stack from [prNumbers], ordered bottom to top. GitHub rejects
  /// the call unless each PR's base ref matches the previous PR's head ref.
  Future<PrStack> createStack({required List<int> prNumbers});

  /// Appends [prNumbers] (ordered from the current top upward) onto the stack
  /// [stackNumber]. Returns the updated stack.
  Future<PrStack?> addToStack({
    required int stackNumber,
    required List<int> prNumbers,
  });

  /// Removes the unmerged pull requests from the stack [stackNumber]. Returns
  /// the updated stack, or null when nothing remained and the stack dissolved.
  Future<PrStack?> unstack({required int stackNumber});

  /// Update a pull request's [title] and/or [body]. Only the provided fields
  /// are sent.
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
  });

  /// Add the given user [logins] as assignees on the PR.
  Future<void> addAssignees({
    required int prNumber,
    required List<String> logins,
  });

  /// Remove the given user [logins] from the PR's assignees.
  Future<void> removeAssignees({
    required int prNumber,
    required List<String> logins,
  });

  /// Request reviews from the given user [userLogins] and team [teamSlugs].
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins,
    List<String> teamSlugs,
  });

  /// Cancel review requests for the given user [userLogins] and team
  /// [teamSlugs].
  Future<void> removeRequestedReviewers({
    required int prNumber,
    List<String> userLogins,
    List<String> teamSlugs,
  });

  /// Stream of enriched reviewers (users + teams, with code-owner flags and
  /// the team↔member review merge) for a PR.
  Stream<List<PrReviewer>> watchReviewers(int prNumber);

  /// Lists users who can be assigned to / requested as reviewers on this repo.
  Future<List<PrUser>> listAssignableUsers();

  /// Lists candidates that can be requested as reviewers — users and teams.
  Future<List<PrReviewerCandidate>> listRequestableReviewers();

  /// Lists GitHub's suggested reviewers for a PR (recommended from git-blame
  /// authorship and prior review history). PR-scoped, unlike the repo-wide
  /// [listRequestableReviewers].
  Future<List<PrUser>> listSuggestedReviewers(int prNumber);
}

/// No-op implementation returned for a repo whose forge has no registered
/// provider — an unconnected or unsupported forge.
///
/// Reading empty rather than throwing is what keeps one unconnected forge from
/// breaking a mixed workspace: the surface for that repo shows "connect
/// `<forge>`" while every other forge's repos keep working.
class EmptyPrReviewRepository implements PrReviewRepository {
  /// Creates a no-op [EmptyPrReviewRepository].
  const EmptyPrReviewRepository();

  @override
  Stream<PullRequest?> watchPullRequest(int prNumber) => Stream.value(null);

  @override
  Stream<String> watchDiff(int prNumber) => Stream.value('');

  @override
  Stream<List<PrFile>> watchFiles(int prNumber) =>
      Stream.value(const <PrFile>[]);

  @override
  Stream<String> watchFileContent(String path, String ref) => Stream.value('');

  @override
  Stream<List<PrCommit>> watchCommits(int prNumber) =>
      Stream.value(const <PrCommit>[]);

  @override
  Stream<List<PrFile>> watchCommitFiles(String sha) =>
      Stream.value(const <PrFile>[]);

  @override
  Stream<List<PrReviewSubmission>> watchReviews(int prNumber) =>
      Stream.value(const <PrReviewSubmission>[]);

  @override
  Stream<List<PrCodeReviewComment>> watchReviewComments(int prNumber) =>
      Stream.value(const <PrCodeReviewComment>[]);

  @override
  Stream<List<IssueComment>> watchIssueComments(int prNumber) =>
      Stream.value(const <IssueComment>[]);

  @override
  Stream<List<PrTimelineEvent>> watchTimelineEvents(int prNumber) =>
      Stream.value(const <PrTimelineEvent>[]);

  @override
  Stream<List<CheckRun>> watchCheckRuns(int prNumber) =>
      Stream.value(const <CheckRun>[]);

  @override
  Future<JobRunDetail?> getJobRunDetail(int jobId) async => null;

  @override
  Future<WorkflowGraph?> getWorkflowGraph(int workflowRunId) async => null;

  @override
  Stream<List<CommitStatus>> watchCommitStatuses(int prNumber) =>
      Stream.value(const <CommitStatus>[]);

  @override
  Future<void> invalidatePullRequest(int prNumber) async {}

  @override
  Future<void> invalidateDiff(int prNumber) async {}

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
  }) async {
    return {'id': 0};
  }

  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) async {}

  @override
  Future<void> upsertDraft(int prNumber, String text) async {}

  @override
  Future<String?> getDraft(int prNumber) async => null;

  @override
  Future<void> clearDraft(int prNumber) async {}

  @override
  Future<String> uploadContent(
    String path,
    String base64Content,
    String message,
  ) async {
    return '';
  }

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
    required int prNumber,
    required String mergeMethod,
    String? commitTitle,
    String? commitMessage,
    String? idempotencyKey,
  }) async {
    return {};
  }

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
      throw UnsupportedError('No forge is connected for this repository');

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
  Stream<List<PrReviewer>> watchReviewers(int prNumber) =>
      Stream.value(const <PrReviewer>[]);

  @override
  Future<List<PrUser>> listAssignableUsers() async => const <PrUser>[];

  @override
  Future<List<PrReviewerCandidate>> listRequestableReviewers() async =>
      const <PrReviewerCandidate>[];

  @override
  Future<List<PrUser>> listSuggestedReviewers(int prNumber) async =>
      const <PrUser>[];
}
