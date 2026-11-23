import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/job_run_detail.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_label.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_thread_state.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_stack.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_cancel_token.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pending_review_comment.dart';

export 'package:cc_domain/features/pr_review/domain/ports/forge_cancel_token.dart';

/// Optional exhaustive head-ref history, for forges whose capabilities carry
/// [ForgeCapability.branchHistory]. A failed/truncated read throws; it must
/// never look like an empty history to callers checking whether every PR was
/// merged.
abstract interface class ForgeBranchPrHistoryClient {
  /// All PRs ever created from [branch] in this client repository.
  Future<List<PullRequest>> listPullRequestsForBranch(String branch);
}

/// Optional numbered pages of the open list beyond the first ("load more"),
/// for forges whose capabilities carry [ForgeCapability.openListPaging].
abstract interface class ForgeOpenPrPagingClient {
  /// Page [page] (1-based) of open pull requests, newest first.
  Future<({List<PullRequest> prs, bool hasMore})> listOpenPullRequestsPage(
    int page,
  );
}

/// Optional one-request change probe of the open list, for forges with no
/// conditional (ETag) list request. The poller re-reads a repo's whole open
/// list only when this fingerprint moves; a forge without it is re-read on
/// every pass.
abstract interface class ForgeOpenPrChangeProbeClient {
  /// A fingerprint of the open list: the open count (where the forge reports
  /// one) and the most recently updated open pull request with its update
  /// time — one page of size one, ordered by update. Opening, closing,
  /// merging or updating any open pull request moves it. Throws on a failed
  /// read; an access denial surfaces as a `NetworkException` with code
  /// `auth_error` or `not_found`.
  Future<String> openPullRequestsFingerprint();
}

/// Optional targeted reads behind the author-facing notifications, for forges
/// whose capabilities carry [ForgeCapability.mergeSignals]. Each throws on a
/// failed read; the poller logs it and degrades the notification's copy, never
/// its correctness.
abstract interface class ForgeMergeSignalsClient {
  /// The forge's own mergeable verdict for one pull request.
  /// [PrMergeableState.unknown] means "not computed yet", never "blocked".
  Future<PrMergeableState> mergeState(int prNumber);

  /// The login of the most recent approving review, or null when nobody has
  /// approved.
  Future<String?> latestApprover(int prNumber);

  /// The first failing check on the pull request's head, or null when none
  /// is failing.
  Future<({String name, String? url})?> firstFailingCheck(int prNumber);
}

/// How a review verdict is expressed, independent of any forge's spelling.
///
/// GitHub sends `APPROVE`/`REQUEST_CHANGES`/`COMMENT`, GitLab approves through
/// a separate endpoint and comments through another, and Bitbucket has
/// `approve`/`request-changes` as distinct verbs. Callers name the intent;
/// each adapter translates.
enum ForgeReviewVerdict {
  /// Approve the change.
  approve,

  /// Block the change pending updates.
  requestChanges,

  /// Leave feedback without a verdict.
  comment,
}

/// Decides whether pull request [prNumber] may be approved through [client],
/// which is about to send that approval. Throws to refuse it; nothing has
/// reached the forge by then.
///
/// Every forge adapter takes one and consults it in [ForgePrClient.submitReview]
/// before anything of an [ForgeReviewVerdict.approve] is sent (its inline
/// comments and body included), so there is exactly one place an approval
/// passes on every forge, whichever surface asked for it.
typedef ForgeApprovalGuard =
    Future<void> Function(ForgePrClient client, int prNumber);

/// How a merge should be performed.
enum ForgeMergeMethod {
  /// Squash all commits into one.
  squash,

  /// Create a merge commit.
  merge,

  /// Rebase the commits onto the base branch.
  rebase;

  /// Parses a wire value, defaulting to [squash] for anything unrecognized.
  static ForgeMergeMethod fromWire(String? wire) => switch (wire) {
    'merge' => ForgeMergeMethod.merge,
    'rebase' => ForgeMergeMethod.rebase,
    _ => ForgeMergeMethod.squash,
  };

  /// The canonical wire spelling.
  String get wire => name;
}

/// The outcome of a merge attempt.
class PrMergeOutcome {
  /// Creates a [PrMergeOutcome].
  const PrMergeOutcome({required this.merged, required this.message, this.sha});

  /// Whether the merge went through.
  final bool merged;

  /// The forge's human-readable explanation (empty when it gave none).
  final String message;

  /// The resulting merge commit SHA, when the forge reports one.
  final String? sha;

  @override
  bool operator ==(Object other) =>
      other is PrMergeOutcome &&
      other.merged == merged &&
      other.message == message &&
      other.sha == sha;

  @override
  int get hashCode => Object.hash(merged, message, sha);
}

/// A pull request's changed files as the forge listed them.
class PrFileListing {
  /// Creates a [PrFileListing].
  const PrFileListing(this.files, {this.truncated = false});

  /// The files, in the forge's order.
  final List<PrFile> files;

  /// The forge stopped listing at its own cap (GitHub's 3 000 files,
  /// GitLab's and Bitbucket's 1 000 rows), so [files] is not the whole pull
  /// request. Never set because a caller passed a smaller `limit`.
  final bool truncated;
}

/// What a reaction is attached to.
enum ForgeReactionTarget {
  /// An inline review comment.
  reviewComment,

  /// A top-level conversation comment.
  issueComment,

  /// The pull request itself.
  pullRequest,

  /// A review submission's summary (the verdict card in the conversation).
  review,
}

/// One reaction, as stored by the forge: the emoji shortcode and who left it.
///
/// Callers aggregate these into `ReactionGroup`s. Keeping the raw pairs at this
/// layer is what lets the caller answer "did *I* react?" without the adapter
/// needing to know who the viewer is.
class ForgeReaction {
  /// Creates a [ForgeReaction].
  const ForgeReaction({required this.content, required this.login});

  /// The emoji shortcode (`+1`, `rocket`, …).
  final String content;

  /// The account that left it. Empty when the forge withholds it.
  final String login;
}

/// The reactions on one review summary, keyed by the review id the REST-shape
/// `PrReviewSubmission.id` already carries.
///
/// A separate lookup because forges expose review reactions nothing like
/// comment reactions: GitHub's REST review payload has no reactions field at
/// all — they only ride the GraphQL review node — so the adapter answers this
/// from a lane the comment paths never use. One round trip per PR, not one
/// per review; the caller joins by [reviewId].
class PrReviewReactions {
  /// Creates a [PrReviewReactions].
  const PrReviewReactions({required this.reviewId, required this.reactions});

  /// The review the reactions sit on.
  final int reviewId;

  /// The raw `(emoji, who)` pairs — same contract as [ForgeReaction].
  final List<ForgeReaction> reactions;
}

/// The reviewer picture for one PR: who was asked, who answered, and who owns
/// the touched code.
///
/// Forges model this very differently — GitHub has requested reviewers plus a
/// CODEOWNERS-derived flag, GitLab has assigned reviewers plus approval rules,
/// Bitbucket has default reviewers plus per-participant approval — so the
/// adapter is what reconciles them into this one shape.
class PrReviewerState {
  /// Creates a [PrReviewerState].
  const PrReviewerState({
    required this.reviewers,
    this.codeOwnerIdentities = const {},
  });

  /// An empty state, for forges or PRs with no reviewer information.
  static const PrReviewerState empty = PrReviewerState(reviewers: []);

  /// Every reviewer (users and, where the forge has them, teams/groups) with
  /// their current verdict.
  final List<PrReviewer> reviewers;

  /// Reviewer identities that own some touched path, spelled the same way as
  /// `PrReviewer.identity` (`user:<login>` / `team:<slug>`).
  ///
  /// Identities rather than bare logins because a *team* can own code, which a
  /// login cannot express. Empty on forges with no code-owner concept — that
  /// is "we cannot tell", never "nobody owns this".
  final Set<String> codeOwnerIdentities;
}

/// A branch on a forge, with just enough context for the compose-PR pickers to
/// order and describe it.
class ForgeBranch {
  /// Creates a [ForgeBranch].
  const ForgeBranch({
    required this.name,
    this.lastCommitAt,
    this.lastCommitAuthor = '',
    this.isDefault = false,
  });

  /// The branch name, without a `refs/heads/` prefix.
  final String name;

  /// When the branch tip was committed, when the forge reports it. Null sorts
  /// last — a branch with no known activity must not lead the picker.
  final DateTime? lastCommitAt;

  /// Who authored the tip commit. Empty when the forge withholds it.
  final String lastCommitAuthor;

  /// Whether this is the repository's default branch.
  final bool isDefault;
}

/// The result of comparing two refs: what a pull request between them would
/// contain.
///
/// Carries the actual files and commits, not just counts, because the compose
/// screen previews the diff before the PR exists.
class ForgeBranchComparison {
  /// Creates a [ForgeBranchComparison].
  const ForgeBranchComparison({
    this.files = const [],
    this.commits = const [],
    this.additions = 0,
    this.deletions = 0,
    this.totalCommits = 0,
  });

  /// The files the comparison touches, with patches where the forge supplies
  /// them.
  final List<PrFile> files;

  /// The commits the comparison covers, oldest first.
  final List<PrCommit> commits;

  /// Lines added across [files].
  final int additions;

  /// Lines removed across [files].
  final int deletions;

  /// Total commits the forge reports, which may exceed `commits.length` when
  /// the comparison was truncated.
  final int totalCommits;

  /// Whether there is anything to open a pull request for.
  bool get hasChanges => files.isNotEmpty || commits.isNotEmpty;
}

/// A forge's pull-request API, in domain terms.
///
/// Multi-forge seam: above speaks domain only; below is vendor wire+mappers.
/// Return domain entities, never wire models. Honour [capabilities] — unsupported
/// methods throw [ForgeUnsupportedError] (empty ≠ unsupported).
/// [PullRequest.number] is per-repo; [PullRequest.externalId] is opaque.
abstract interface class ForgePrClient {
  /// The forge this client talks to.
  ForgeHost get forge;

  /// What this forge can do. Mirrors `capabilitiesOf(forge)`; exposed here so
  /// callers holding only a client can gate without a second lookup.
  ForgeCapabilities get capabilities;

  /// The `owner`/`namespace`/`workspace` half of the repo coordinate.
  String get owner;

  /// The repository name.
  String get repo;

  // ── Reads ────────────────────────────────────────────────────────────────

  /// Fetches one pull request, or null when it does not exist.
  Future<PullRequest?> getPullRequest(int prNumber, {ForgeCancelToken? cancelToken});

  /// One page of this repo's OPEN pull requests, most-recently-updated first.
  ///
  /// This is what the workspace poller fans out over. It is per-repo rather
  /// than per-forge because a workspace's repos may sit in unrelated
  /// namespaces, and because a forge that fails for one repo must not blank the
  /// others.
  ///
  /// `hasMore` reports whether the forge had further pages, so the UI can offer
  /// "load more" without a second probe.
  Future<({List<PullRequest> prs, bool hasMore})> listOpenPullRequests({
    int limit,
    ForgeCancelToken? cancelToken,
  });

  /// Pull requests authored by [login] that have been MERGED, most recently
  /// merged first ([sortMostRecentlyMergedFirst]). Backs the inbox's "merging
  /// and recently merged" section.
  Future<List<PullRequest>> listMergedByAuthor(
    String login, {
    int limit,
    ForgeCancelToken? cancelToken,
  });

  /// How [prNumber] left the open list ([closedPrOutcomeOf]): merged, closed
  /// unmerged, or answered "not found" (404) by the forge. Null when it is
  /// still open or cannot be read; every other failure except a cancellation
  /// answers null, and a cancellation rethrows.
  ///
  /// The poller asks this about a PR that vanished between two passes, so
  /// "unknown" must stay distinguishable from "closed" — reporting a merge that
  /// did not happen would fire the wrong lifecycle event. A PR merely pushed
  /// off the first page of a long open list is still open, hence null.
  /// [ClosedPrOutcome.notFound] is only the forge's word for this one PR: a
  /// token that lost the whole repository answers the same, so the caller
  /// decides whether the repository was readable at the time.
  Future<ClosedPrOutcome?> closedOutcome(
    int prNumber, {
    ForgeCancelToken? cancelToken,
  });

  /// The unified diff for a PR.
  Future<String> getPullRequestDiff(int prNumber, {ForgeCancelToken? cancelToken});

  /// The files a PR touches. [limit] caps how many are fetched; an adapter that
  /// hits its forge's own ceiling returns what it has with
  /// [PrFileListing.truncated] set, so the reader can say the list is partial
  /// rather than present it as the whole change.
  Future<PrFileListing> listFiles(
    int prNumber, {
    int? limit,
    ForgeCancelToken? cancelToken,
  });

  /// The commits on a PR, oldest first.
  Future<List<PrCommit>> listCommits(int prNumber, {ForgeCancelToken? cancelToken});

  /// The files changed by a single commit.
  Future<List<PrFile>> listCommitFiles(String sha, {ForgeCancelToken? cancelToken});

  /// Submitted reviews (approvals, change requests, comment-only reviews).
  Future<List<PrReviewSubmission>> listReviews(
    int prNumber, {
    ForgeCancelToken? cancelToken,
  });

  /// Inline (file-anchored) review comments.
  Future<List<PrCodeReviewComment>> listReviewComments(
    int prNumber, {
    ForgeCancelToken? cancelToken,
  });

  /// The conversation state of every inline review thread on the PR.
  ///
  /// Split from [listReviewComments] because forges model it separately: on
  /// GitHub the comment list is REST and carries no resolution field, while the
  /// thread objects live in GraphQL. Returns empty on a forge without
  /// `commentThreadResolution`; callers gate on the capability rather than
  /// treating empty as "nothing is resolved".
  Future<List<PrReviewThreadState>> listReviewThreadStates(
    int prNumber, {
    ForgeCancelToken? cancelToken,
  });

  /// Top-level conversation comments.
  Future<List<IssueComment>> listIssueComments(
    int prNumber, {
    ForgeCancelToken? cancelToken,
  });

  /// Timeline events (review requested/removed, …) for the activity feed.
  Future<List<PrTimelineEvent>> listTimelineEvents(
    int prNumber, {
    ForgeCancelToken? cancelToken,
  });

  /// CI results for [headSha]. Capability: `ciChecks`.
  Future<List<CheckRun>> listCheckRuns(String headSha, {ForgeCancelToken? cancelToken});

  /// Commit statuses for [headSha] — the separate, older status API where
  /// deploy-preview integrations publish their URLs. Empty on forges that fold
  /// statuses into checks.
  Future<List<CommitStatus>> listCommitStatuses(
    String headSha, {
    ForgeCancelToken? cancelToken,
  });

  /// Raw file content at [ref].
  Future<String> getFileContent(String path, String ref, {ForgeCancelToken? cancelToken});

  /// Raw file bytes at [ref] (a commit SHA, branch or tag — never a blob SHA).
  ///
  /// Used for image/SVG diffs. Same endpoints as [getFileContent] with a
  /// bytes response type so rasters are not decoded as UTF-8.
  Future<Uint8List> getFileBytes(
    String path,
    String ref, {
    ForgeCancelToken? cancelToken,
  });

  /// Per-file viewed state for the current viewer, keyed by path.
  /// Capability: `viewedStateSync`.
  Future<Map<String, PrFileViewedState>> getFileViewedStates(
    int prNumber, {
    ForgeCancelToken? cancelToken,
  });

  /// Who is reviewing this PR and who owns the touched code.
  Future<PrReviewerState> getReviewerState(int prNumber, {ForgeCancelToken? cancelToken});

  /// The authenticated user, or null when the client is unauthenticated.
  Future<PrUser?> getAuthenticatedUser({ForgeCancelToken? cancelToken});

  /// Users who can be assigned to, or asked to review, this repo.
  Future<List<PrUser>> listAssignableUsers({ForgeCancelToken? cancelToken});

  /// Everything that can be asked for a review — users plus, where the forge
  /// has them, teams/groups. Capability for the team half: `teamReviewers`.
  Future<List<PrReviewerCandidate>> listRequestableReviewers({
    ForgeCancelToken? cancelToken,
  });

  /// The forge's own reviewer suggestions for a PR.
  /// Capability: `suggestedReviewers`.
  Future<List<PrUser>> listSuggestedReviewers(
    int prNumber, {
    ForgeCancelToken? cancelToken,
  });

  // ── Compose-PR surface ───────────────────────────────────────────────────

  /// The repository's branches, most recently committed first.
  ///
  /// Backs the base/head pickers, which is why it carries activity rather than
  /// bare names: a repo's useful branch is almost always its newest.
  Future<List<ForgeBranch>> listBranches({int? limit, ForgeCancelToken? cancelToken});

  /// The repository's default branch name, or an empty string when unknown.
  Future<String> getDefaultBranch({ForgeCancelToken? cancelToken});

  /// Compares [base] with [head] — what a pull request between them would
  /// contain. Null when the refs cannot be compared (a missing branch, or a
  /// forge that declines the comparison).
  Future<ForgeBranchComparison?> compareBranches({
    required String base,
    required String head,
    ForgeCancelToken? cancelToken,
  });

  /// The repository's pull-request description templates, keyed by a display
  /// name. Empty on forges without them. Capability: `prTemplates`.
  Future<Map<String, String>> listPrTemplates({ForgeCancelToken? cancelToken});

  /// Step-level detail and logs for one CI job. Capability: `ciJobDetail`.
  Future<JobRunDetail?> getJobRunDetail(int jobId, {ForgeCancelToken? cancelToken});

  /// The `needs` graph of one CI run. Capability: `ciJobDetail`.
  Future<WorkflowGraph?> getWorkflowGraph(
    int workflowRunId, {
    ForgeCancelToken? cancelToken,
  });

  // ── Writes ───────────────────────────────────────────────────────────────

  /// Posts an inline review comment and returns it as stored by the forge.
  ///
  /// [line]/[side] anchor to the diff; [startLine]/[startSide] extend it to a
  /// multi-line range. Adapters translate this to their own anchor shape
  /// (GitLab positions, Bitbucket `{from,to}`).
  Future<PrCodeReviewComment?> postReviewComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
    ForgeCancelToken? cancelToken,
  });

  /// Posts a comment on [path] as a whole, anchored to no diff line, and
  /// returns it as stored by the forge.
  ///
  /// This is how a file with no diff rows (a rename without changes, a binary
  /// or image) gets commented on. Adapters translate it to their own
  /// file-level shape (GitHub `subject_type: file`, GitLab `position_type:
  /// file`, Bitbucket an inline anchor with only a path).
  Future<PrCodeReviewComment?> postFileComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required String body,
    ForgeCancelToken? cancelToken,
  });

  /// Replies to an existing inline comment thread.
  Future<void> replyToReviewComment({
    required int prNumber,
    required String parentCommentId,
    required String body,
    ForgeCancelToken? cancelToken,
  });

  /// Posts a top-level comment on the PR conversation timeline (the issues
  /// comment lane, not an inline diff thread).
  Future<void> postIssueComment({
    required int prNumber,
    required String body,
    ForgeCancelToken? cancelToken,
  });

  /// Replaces the body of a top-level conversation comment.
  ///
  /// [commentId] is the forge's issue-comment / note id, carried as a string
  /// because GitLab and Bitbucket ids are not GitHub's integers at this
  /// seam. Used to persist a GFM task-list toggle without opening the
  /// editor.
  Future<void> updateIssueComment({
    required int prNumber,
    required String commentId,
    required String body,
    ForgeCancelToken? cancelToken,
  });

  /// Deletes a top-level conversation comment.
  ///
  /// [commentId] is the forge's issue-comment / note id. The forge refuses a
  /// caller who is neither the author nor a writer; that refusal propagates.
  Future<void> deleteIssueComment({
    required int prNumber,
    required String commentId,
    ForgeCancelToken? cancelToken,
  });

  /// Replaces the body of one inline review comment. [commentId] is the
  /// forge's review comment / discussion-note id. The forge refuses a caller
  /// who may not edit it; that refusal propagates.
  Future<void> updateReviewComment({
    required int prNumber,
    required String commentId,
    required String body,
    ForgeCancelToken? cancelToken,
  });

  /// Deletes one inline review comment. [commentId] is the forge's review
  /// comment / discussion-note id.
  Future<void> deleteReviewComment({
    required int prNumber,
    required String commentId,
    ForgeCancelToken? cancelToken,
  });

  /// Marks a review thread resolved (or reopens it).
  ///
  /// [threadId] is a [PrReviewThreadState.id], not a comment id. Capability:
  /// `commentThreadResolution`.
  Future<void> setReviewThreadResolved({
    required int prNumber,
    required String threadId,
    required bool resolved,
    ForgeCancelToken? cancelToken,
  });

  /// Submits a review verdict, optionally with a body.
  ///
  /// [comments] attaches inline comments to the same submission, which is what
  /// makes a batched review one event on the PR instead of N drive-by comments
  /// followed by a verdict. Forges without `pendingReviewBatching` post them
  /// individually first; the caller does not need to know which.
  ///
  /// Answers the forge's id for the submitted review when it has one (GitHub's
  /// review id), null on forges where a verdict is not one addressable record.
  /// A verdict a forge cannot express ([ForgeReviewVerdict.requestChanges]
  /// without [ForgeCapability.requestChanges]) throws [ForgeUnsupportedError];
  /// callers degrade it to a comment first. An approval first passes the
  /// client's [ForgeApprovalGuard], which may refuse it.
  Future<int?> submitReview({
    required int prNumber,
    required ForgeReviewVerdict verdict,
    String? body,
    List<PendingReviewComment> comments = const [],
    ForgeCancelToken? cancelToken,
  });

  /// Merges a pull request.
  Future<PrMergeOutcome> mergePullRequest({
    required int prNumber,
    required ForgeMergeMethod method,
    String? commitTitle,
    String? commitMessage,
    ForgeCancelToken? cancelToken,
  });

  /// Closes a pull request without merging.
  Future<void> closePullRequest(int prNumber, {ForgeCancelToken? cancelToken});

  /// Moves a pull request between draft and ready-for-review.
  ///
  /// [draft] true converts an open PR back to a draft; false marks a draft
  /// ready for review. Capability: `draftToggle`.
  Future<void> setPullRequestDraft({
    required int prNumber,
    required bool draft,
    ForgeCancelToken? cancelToken,
  });

  /// Opens a pull request and returns it.
  Future<PullRequest> createPullRequest({
    required String title,
    required String body,
    required String headBranch,
    required String baseBranch,
    bool draft = false,
    ForgeCancelToken? cancelToken,
  });

  /// Edits a PR's title and/or body. Only non-null fields are sent.
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
    ForgeCancelToken? cancelToken,
  });

  /// Marks a file viewed or unviewed. Capability: `viewedStateSync`.
  Future<void> setFileViewedState({
    required int prNumber,
    required String prExternalId,
    required String path,
    required bool viewed,
    ForgeCancelToken? cancelToken,
  });

  /// Adds assignees.
  Future<void> addAssignees({
    required int prNumber,
    required List<String> logins,
    ForgeCancelToken? cancelToken,
  });

  /// Removes assignees.
  Future<void> removeAssignees({
    required int prNumber,
    required List<String> logins,
    ForgeCancelToken? cancelToken,
  });

  /// Labels defined on the repository, the set a pull request can wear.
  /// Capability: `labels`.
  Future<List<PrLabel>> listLabels({ForgeCancelToken? cancelToken});

  /// Adds [names] to the pull request. Capability: `labels`.
  ///
  /// Names that the repository does not define are the forge's problem: GitHub
  /// rejects them, GitLab may create them. Callers offer only [listLabels].
  Future<void> addLabels({
    required int prNumber,
    required List<String> names,
    ForgeCancelToken? cancelToken,
  });

  /// Removes [names] from the pull request. Capability: `labels`.
  Future<void> removeLabels({
    required int prNumber,
    required List<String> names,
    ForgeCancelToken? cancelToken,
  });

  /// Requests reviews. [teamSlugs] requires the `teamReviewers` capability.
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins,
    List<String> teamSlugs,
    ForgeCancelToken? cancelToken,
  });

  /// Cancels review requests.
  Future<void> removeRequestedReviewers({
    required int prNumber,
    List<String> userLogins,
    List<String> teamSlugs,
    ForgeCancelToken? cancelToken,
  });

  /// Lists the individual reactions on a target. Capability: `reactions`.
  ///
  /// Returns the raw `(emoji, who)` pairs rather than pre-grouped counts,
  /// because the caller — not the adapter — knows which account is the viewer
  /// and therefore which reactions are "mine".
  Future<List<ForgeReaction>> listReactions({
    required ForgeReactionTarget target,
    required String targetId,
    required int prNumber,
    ForgeCancelToken? cancelToken,
  });

  /// Lists every review summary's reactions on a PR. Capability:
  /// `reactions`.
  ///
  /// Reviews are listed whole because no forge exposes them through the
  /// per-target reaction endpoint shape [listReactions] serves — GitHub
  /// needs its GraphQL lane for these. An empty list is a valid answer
  /// (nothing reacted, or the forge has no review summaries to react to).
  Future<List<PrReviewReactions>> listReviewReactions(
    int prNumber, {
    ForgeCancelToken? cancelToken,
  });

  /// Adds or removes a reaction. Capability: `reactions`.
  Future<void> toggleReaction({
    required ForgeReactionTarget target,
    required String targetId,
    required int prNumber,
    required String content,
    required bool add,
    ForgeCancelToken? cancelToken,
  });

  /// Commits [base64Content] at [path] and returns its public URL — used to
  /// host images pasted into a review comment.
  Future<String> uploadContent({
    required String path,
    required String base64Content,
    required String message,
    ForgeCancelToken? cancelToken,
  });

  // ── Stacks (capability: `stacks`) ────────────────────────────────────────

  /// Lists stacks, optionally only the one containing [prNumber].
  Future<List<PrStack>> listStacks({int? prNumber, ForgeCancelToken? cancelToken});

  /// Creates a stack from [prNumbers], bottom to top.
  Future<PrStack> createStack({
    required List<int> prNumbers,
    ForgeCancelToken? cancelToken,
  });

  /// Appends [prNumbers] onto an existing stack.
  Future<PrStack?> addToStack({
    required int stackNumber,
    required List<int> prNumbers,
    ForgeCancelToken? cancelToken,
  });

  /// Removes the unmerged PRs from a stack.
  Future<PrStack?> unstack({required int stackNumber, ForgeCancelToken? cancelToken});
}

/// How a pull request that left the open list ended
/// ([ForgePrClient.closedOutcome]).
enum ClosedPrOutcome {
  /// Merged.
  merged,

  /// Closed without merging.
  closed,

  /// The forge answers 404 for it while the repository stays readable: a
  /// deleted pull request, or one hidden from this credential (GitHub hides
  /// an archived pull request from an App token).
  notFound,
}

/// The [ForgePrClient.closedOutcome] answer for [pr] as just read from the
/// forge, where null means the forge answered 404: still open → null.
ClosedPrOutcome? closedPrOutcomeOf(PullRequest? pr) => switch (pr?.state) {
  PrState.merged => ClosedPrOutcome.merged,
  PrState.closed => ClosedPrOutcome.closed,
  PrState.open => null,
  null => ClosedPrOutcome.notFound,
};

/// Sorts [prs] in place into [ForgePrClient.listMergedByAuthor] order: most
/// recently merged first, a PR with no merge time last (by update time).
void sortMostRecentlyMergedFirst(List<PullRequest> prs) {
  int compare(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }
    return b.compareTo(a);
  }

  prs.sort((a, b) {
    final byMerge = compare(a.mergedAt, b.mergedAt);
    return byMerge != 0 ? byMerge : compare(a.updatedAt, b.updatedAt);
  });
}
