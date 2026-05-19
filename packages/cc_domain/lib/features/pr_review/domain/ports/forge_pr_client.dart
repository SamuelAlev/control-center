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
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';

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

  /// Reads a [PrMergeOutcome] off the wire.
  factory PrMergeOutcome.fromJson(Map<String, dynamic> json) => PrMergeOutcome(
    merged: json['merged'] as bool? ?? false,
    message: json['message'] as String? ?? '',
    sha: json['sha'] as String?,
  );

  /// Whether the merge went through.
  final bool merged;

  /// The forge's human-readable explanation (empty when it gave none).
  final String message;

  /// The resulting merge commit SHA, when the forge reports one.
  final String? sha;

  /// Wire form. The keys match what the PR-review RPC op has always returned.
  Map<String, dynamic> toJson() => {
    'merged': merged,
    'message': message,
    if (sha != null) 'sha': sha,
  };
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
/// This is the seam the whole multi-forge feature turns on. Everything above it
/// — SWR caching, review drafts, the RPC catalog, the UI — speaks only domain
/// entities and never learns which forge answered. Everything below it is one
/// vendor's REST/GraphQL vocabulary, confined to that vendor's adapter together
/// with its wire models and mappers.
///
/// Three rules for implementers:
///
/// 1. **Return domain entities, never wire models.** The adapter owns the
///    anti-corruption mapping; nothing vendor-shaped may escape it.
/// 2. **Honour [capabilities].** A method whose capability flag is false must
///    throw [ForgeUnsupportedError], not return a plausible-looking empty
///    result — an empty list means "none", which is a different claim from
///    "this forge cannot tell you". The UI hides the affordance either way,
///    so the throw only fires when something bypassed the check.
/// 3. **Numbers are per-repo, ids are opaque.** [PullRequest.number] is the
///    user-facing per-repo integer (GitHub PR number, GitLab MR `iid`,
///    Bitbucket PR id); [PullRequest.externalId] is whatever globally-unique
///    string the forge uses and is never parsed by callers.
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
  Future<PullRequest?> getPullRequest(int prNumber, {Object? cancelToken});

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
    Object? cancelToken,
  });

  /// Pull requests authored by [login] that have been MERGED, most recently
  /// merged first. Backs the inbox's "merging and recently merged" section.
  Future<List<PullRequest>> listMergedByAuthor(
    String login, {
    int limit,
    Object? cancelToken,
  });

  /// Whether [prNumber] left the open list by being merged (true) or closed
  /// unmerged (false); null when it cannot be resolved.
  ///
  /// The poller asks this about a PR that vanished between two passes, so
  /// "unknown" must stay distinguishable from "closed" — reporting a merge that
  /// did not happen would fire the wrong lifecycle event.
  Future<bool?> wasMerged(int prNumber, {Object? cancelToken});

  /// The unified diff for a PR.
  Future<String> getPullRequestDiff(int prNumber, {Object? cancelToken});

  /// The files a PR touches. [limit] caps how many are fetched; an adapter that
  /// hits its forge's own ceiling returns what it has (callers fall back to the
  /// local git source for very large PRs).
  Future<List<PrFile>> listFiles(
    int prNumber, {
    int? limit,
    Object? cancelToken,
  });

  /// The commits on a PR, oldest first.
  Future<List<PrCommit>> listCommits(int prNumber, {Object? cancelToken});

  /// The files changed by a single commit.
  Future<List<PrFile>> listCommitFiles(String sha, {Object? cancelToken});

  /// Submitted reviews (approvals, change requests, comment-only reviews).
  Future<List<PrReviewSubmission>> listReviews(
    int prNumber, {
    Object? cancelToken,
  });

  /// Inline (file-anchored) review comments.
  Future<List<PrCodeReviewComment>> listReviewComments(
    int prNumber, {
    Object? cancelToken,
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
    Object? cancelToken,
  });

  /// Top-level conversation comments.
  Future<List<IssueComment>> listIssueComments(
    int prNumber, {
    Object? cancelToken,
  });

  /// Timeline events (review requested/removed, …) for the activity feed.
  Future<List<PrTimelineEvent>> listTimelineEvents(
    int prNumber, {
    Object? cancelToken,
  });

  /// CI results for [headSha]. Capability: `ciChecks`.
  Future<List<CheckRun>> listCheckRuns(String headSha, {Object? cancelToken});

  /// Commit statuses for [headSha] — the separate, older status API where
  /// deploy-preview integrations publish their URLs. Empty on forges that fold
  /// statuses into checks.
  Future<List<CommitStatus>> listCommitStatuses(
    String headSha, {
    Object? cancelToken,
  });

  /// Raw file content at [ref].
  Future<String> getFileContent(String path, String ref, {Object? cancelToken});

  /// Per-file viewed state for the current viewer, keyed by path.
  /// Capability: `viewedStateSync`.
  Future<Map<String, PrFileViewedState>> getFileViewedStates(
    int prNumber, {
    Object? cancelToken,
  });

  /// Who is reviewing this PR and who owns the touched code.
  Future<PrReviewerState> getReviewerState(int prNumber, {Object? cancelToken});

  /// The authenticated user, or null when the client is unauthenticated.
  Future<PrUser?> getAuthenticatedUser({Object? cancelToken});

  /// Users who can be assigned to, or asked to review, this repo.
  Future<List<PrUser>> listAssignableUsers({Object? cancelToken});

  /// Everything that can be asked for a review — users plus, where the forge
  /// has them, teams/groups. Capability for the team half: `teamReviewers`.
  Future<List<PrReviewerCandidate>> listRequestableReviewers({
    Object? cancelToken,
  });

  /// The forge's own reviewer suggestions for a PR.
  /// Capability: `suggestedReviewers`.
  Future<List<PrUser>> listSuggestedReviewers(
    int prNumber, {
    Object? cancelToken,
  });

  // ── Compose-PR surface ───────────────────────────────────────────────────

  /// The repository's branches, most recently committed first.
  ///
  /// Backs the base/head pickers, which is why it carries activity rather than
  /// bare names: a repo's useful branch is almost always its newest.
  Future<List<ForgeBranch>> listBranches({int? limit, Object? cancelToken});

  /// The repository's default branch name, or an empty string when unknown.
  Future<String> getDefaultBranch({Object? cancelToken});

  /// Compares [base] with [head] — what a pull request between them would
  /// contain. Null when the refs cannot be compared (a missing branch, or a
  /// forge that declines the comparison).
  Future<ForgeBranchComparison?> compareBranches({
    required String base,
    required String head,
    Object? cancelToken,
  });

  /// The repository's pull-request description templates, keyed by a display
  /// name. Empty on forges without them. Capability: `prTemplates`.
  Future<Map<String, String>> listPrTemplates({Object? cancelToken});

  /// Step-level detail and logs for one CI job. Capability: `ciJobDetail`.
  Future<JobRunDetail?> getJobRunDetail(int jobId, {Object? cancelToken});

  /// The `needs` graph of one CI run. Capability: `ciJobDetail`.
  Future<WorkflowGraph?> getWorkflowGraph(
    int workflowRunId, {
    Object? cancelToken,
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
    Object? cancelToken,
  });

  /// Replies to an existing inline comment thread.
  Future<void> replyToReviewComment({
    required int prNumber,
    required String parentCommentId,
    required String body,
    Object? cancelToken,
  });

  /// Posts a top-level comment on the PR conversation timeline (the issues
  /// comment lane, not an inline diff thread).
  Future<void> postIssueComment({
    required int prNumber,
    required String body,
    Object? cancelToken,
  });

  /// Marks a review thread resolved (or reopens it).
  ///
  /// [threadId] is a [PrReviewThreadState.id], not a comment id. Capability:
  /// `commentThreadResolution`.
  Future<void> setReviewThreadResolved({
    required int prNumber,
    required String threadId,
    required bool resolved,
    Object? cancelToken,
  });

  /// Submits a review verdict, optionally with a body.
  ///
  /// [comments] attaches inline comments to the same submission, which is what
  /// makes a batched review one event on the PR instead of N drive-by comments
  /// followed by a verdict. Each entry is `{path, line, side, body,
  /// start_line?, start_side?}`. Forges without `pendingReviewBatching` post
  /// them individually first; the caller does not need to know which.
  Future<void> submitReview({
    required int prNumber,
    required ForgeReviewVerdict verdict,
    String? body,
    List<Map<String, dynamic>> comments = const [],
    Object? cancelToken,
  });

  /// Merges a pull request.
  Future<PrMergeOutcome> mergePullRequest({
    required int prNumber,
    required ForgeMergeMethod method,
    String? commitTitle,
    String? commitMessage,
    Object? cancelToken,
  });

  /// Closes a pull request without merging.
  Future<void> closePullRequest(int prNumber, {Object? cancelToken});

  /// Moves a pull request between draft and ready-for-review.
  ///
  /// [draft] true converts an open PR back to a draft; false marks a draft
  /// ready for review. Capability: `draftToggle`.
  Future<void> setPullRequestDraft({
    required int prNumber,
    required bool draft,
    Object? cancelToken,
  });

  /// Opens a pull request and returns it.
  Future<PullRequest> createPullRequest({
    required String title,
    required String body,
    required String headBranch,
    required String baseBranch,
    bool draft = false,
    Object? cancelToken,
  });

  /// Edits a PR's title and/or body. Only non-null fields are sent.
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
    Object? cancelToken,
  });

  /// Marks a file viewed or unviewed. Capability: `viewedStateSync`.
  Future<void> setFileViewedState({
    required int prNumber,
    required String prExternalId,
    required String path,
    required bool viewed,
    Object? cancelToken,
  });

  /// Adds assignees.
  Future<void> addAssignees({
    required int prNumber,
    required List<String> logins,
    Object? cancelToken,
  });

  /// Removes assignees.
  Future<void> removeAssignees({
    required int prNumber,
    required List<String> logins,
    Object? cancelToken,
  });

  /// Requests reviews. [teamSlugs] requires the `teamReviewers` capability.
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins,
    List<String> teamSlugs,
    Object? cancelToken,
  });

  /// Cancels review requests.
  Future<void> removeRequestedReviewers({
    required int prNumber,
    List<String> userLogins,
    List<String> teamSlugs,
    Object? cancelToken,
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
    Object? cancelToken,
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
    Object? cancelToken,
  });

  /// Adds or removes a reaction. Capability: `reactions`.
  Future<void> toggleReaction({
    required ForgeReactionTarget target,
    required String targetId,
    required int prNumber,
    required String content,
    required bool add,
    Object? cancelToken,
  });

  /// Commits [base64Content] at [path] and returns its public URL — used to
  /// host images pasted into a review comment.
  Future<String> uploadContent({
    required String path,
    required String base64Content,
    required String message,
    Object? cancelToken,
  });

  // ── Stacks (capability: `stacks`) ────────────────────────────────────────

  /// Lists stacks, optionally only the one containing [prNumber].
  Future<List<PrStack>> listStacks({int? prNumber, Object? cancelToken});

  /// Creates a stack from [prNumbers], bottom to top.
  Future<PrStack> createStack({
    required List<int> prNumbers,
    Object? cancelToken,
  });

  /// Appends [prNumbers] onto an existing stack.
  Future<PrStack?> addToStack({
    required int stackNumber,
    required List<int> prNumbers,
    Object? cancelToken,
  });

  /// Removes the unmerged PRs from a stack.
  Future<PrStack?> unstack({required int stackNumber, Object? cancelToken});
}
