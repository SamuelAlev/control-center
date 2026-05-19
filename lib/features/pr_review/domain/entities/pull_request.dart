import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/reaction_group.dart';

/// Pr state.
enum PrState {
  /// Open.
  open,

  /// Closed.
  closed,

  /// Merged.
  merged,
}

/// Rolled-up CI/check status for a pull request's head commit.
///
/// Mirrors GitHub's `statusCheckRollup.state`, collapsed to the four states
/// the list view distinguishes. [none] means no checks are configured or the
/// rollup hasn't been fetched yet, so the UI shows nothing.
enum PrChecksStatus {
  /// No checks configured, or not yet fetched.
  none,

  /// At least one check is still running or queued (and none have failed).
  pending,

  /// Every check succeeded.
  passing,

  /// At least one check failed or errored.
  failing,
}

/// GitHub's authoritative mergeable state for a pull request.
///
/// Returned by the REST API as `mergeable_state`. This is the ground-truth
/// signal from GitHub that already factors in branch protection, codeowner
/// reviews, required checks, and merge conflicts.
enum PrMergeableState {
  /// No conflicts and all requirements met — the PR can be merged.
  clean,

  /// Merge commit can't be created due to merge conflicts.
  dirty,

  /// Mergeability hasn't been computed yet.
  unknown,

  /// Blocked by branch protection rules (e.g. missing required review).
  blocked,

  /// Head ref is behind the base branch.
  behind,

  /// Failing or timed-out checks.
  unstable,

  /// Custom hooks are blocking the merge.
  hasHooks,

  /// State not recognised by the client — keep as a fallback so new GitHub
  /// values don't crash the parser.
  unrecognized;

  /// Parses the REST API `mergeable_state` string.
  static PrMergeableState fromString(String? value) => switch (value) {
    'clean' => PrMergeableState.clean,
    'dirty' => PrMergeableState.dirty,
    'unknown' => PrMergeableState.unknown,
    'blocked' => PrMergeableState.blocked,
    'behind' => PrMergeableState.behind,
    'unstable' => PrMergeableState.unstable,
    'has_hooks' => PrMergeableState.hasHooks,
    _ => PrMergeableState.unrecognized,
  };
}

/// PrStateExtension helpers.
extension PrStateExtension on PrState {
  /// Name.
  String get name {
    switch (this) {
      case PrState.open:
        return 'open';
      case PrState.closed:
        return 'closed';
      case PrState.merged:
        return 'merged';
    }
  }

  /// From string.
  static PrState fromString(String value) {
    switch (value) {
      case 'open':
        return PrState.open;
      case 'closed':
        return PrState.closed;
      case 'merged':
        return PrState.merged;
      default:
        return PrState.open;
    }
  }
}

/// Pull request.
class PullRequest {
  /// Creates a new [Pull request].
  PullRequest({
    required this.id,
    required this.number,
    required this.title,
    required this.body,
    required this.state,
    required this.isDraft,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    required this.repoFullName,
    required this.htmlUrl,
    this.nodeId = '',
    this.headSha = '',
    this.baseRef = '',
    this.headRef = '',
    this.requestedReviewers = const <PrUser>[],
    this.assignees = const <PrUser>[],
    this.mergedAt,
    this.reviewedByMe = false,
    this.reactions = const [],
    this.bodyHtml,
    this.changedFiles = 0,
    this.commitsCount = 0,
    this.additions = 0,
    this.deletions = 0,
    this.commentsCount = 0,
    this.checksStatus = PrChecksStatus.none,
    this.mergeableState = PrMergeableState.unknown,
  }) : assert(number > 0, 'PR number must be positive'),
       assert(title.isNotEmpty, 'PR title must not be empty');

  /// Identifier.
  final int id;

  /// PR number within the repository.
  final int number;

  /// PR title.
  final String title;

  /// PR description body (raw markdown).
  final String body;

  /// PR body rendered to HTML by GitHub. Carries pre-signed URLs for
  /// private user-attachments that the raw [body] only references by UUID.
  /// Null when the PR was fetched without the `full+json` media type.
  final String? bodyHtml;

  /// PR state.
  final PrState state;

  /// Whether this PR is a draft.
  final bool isDraft;

  /// User.
  final PrUser? author;

  /// Timestamp.
  final DateTime? createdAt;

  /// Timestamp.
  final DateTime? updatedAt;

  /// Repository full name (owner/repo).
  final String repoFullName;

  /// URL to view the PR on GitHub.
  final String htmlUrl;

  /// Global node ID used for GraphQL mutations.
  final String nodeId;

  /// SHA of the head commit.
  final String headSha;

  /// Base branch ref name.
  final String baseRef;

  /// Head branch ref name.
  final String headRef;

  /// Users requested to review this PR.
  final List<PrUser> requestedReviewers;

  /// Users assigned to this PR.
  final List<PrUser> assignees;

  /// Timestamp.
  final DateTime? mergedAt;
  final bool reviewedByMe;
  final List<ReactionGroup> reactions;

  /// Total number of changed files. From GitHub's `changed_files` field.
  /// May be 0 when fetched from a list endpoint that omits the field.
  final int changedFiles;

  /// Total number of commits in the PR. From GitHub's `commits` field.
  /// May be 0 when fetched from a list endpoint that omits the field.
  final int commitsCount;

  /// Lines added across the PR. 0 when not enriched (the REST list endpoint
  /// omits it; the GraphQL metrics fetch supplies it).
  final int additions;

  /// Lines removed across the PR. 0 when not enriched.
  final int deletions;

  /// Number of issue comments on the PR. 0 when not enriched.
  final int commentsCount;

  /// Rolled-up CI/check status for the head commit. [PrChecksStatus.none]
  /// when not enriched or no checks are configured.
  final PrChecksStatus checksStatus;

  /// GitHub's authoritative mergeable state. [PrMergeableState.unknown] when
  /// not yet fetched or the list endpoint hasn't returned it.
  final PrMergeableState mergeableState;

  /// Returns a copy with the given fields replaced. Used to merge best-effort
  /// GraphQL metrics (diff size, comments, checks) onto a PR loaded from the
  /// REST list endpoint without refetching.
  PullRequest copyWith({
    int? additions,
    int? deletions,
    int? commentsCount,
    int? changedFiles,
    PrChecksStatus? checksStatus,
    PrMergeableState? mergeableState,
    bool? reviewedByMe,
  }) {
    return PullRequest(
      id: id,
      number: number,
      title: title,
      body: body,
      state: state,
      isDraft: isDraft,
      author: author,
      createdAt: createdAt,
      updatedAt: updatedAt,
      repoFullName: repoFullName,
      htmlUrl: htmlUrl,
      nodeId: nodeId,
      headSha: headSha,
      baseRef: baseRef,
      headRef: headRef,
      requestedReviewers: requestedReviewers,
      assignees: assignees,
      mergedAt: mergedAt,
      reviewedByMe: reviewedByMe ?? this.reviewedByMe,
      reactions: reactions,
      bodyHtml: bodyHtml,
      changedFiles: changedFiles ?? this.changedFiles,
      commitsCount: commitsCount,
      additions: additions ?? this.additions,
      deletions: deletions ?? this.deletions,
      commentsCount: commentsCount ?? this.commentsCount,
      checksStatus: checksStatus ?? this.checksStatus,
      mergeableState: mergeableState ?? this.mergeableState,
    );
  }

  bool get isOpen => state == PrState.open;

  /// Whether the PR is closed (but not merged).
  bool get isClosed => state == PrState.closed;

  /// Whether the PR has been merged.
  bool get isMerged => state == PrState.merged;

  /// Whether the PR is open and not a draft.
  bool get canMerge => isOpen && !isDraft;

  /// Whether the PR has been inactive longer than [threshold].
  bool isStale(Duration threshold) {
    final lastActivity = updatedAt ?? createdAt;
    if (lastActivity == null) {
      return false;
    }

    return DateTime.now().difference(lastActivity) > threshold;
  }

  /// Whether the PR has requested reviewers awaiting review.
  bool get isPriority => requestedReviewers.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PullRequest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
