import 'package:cc_domain/features/pr_review/domain/entities/pr_label.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';

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

/// GitHub's rolled-up review decision for a pull request.
///
/// Mirrors the GraphQL `reviewDecision` enum, collapsed to the states the
/// inbox distinguishes. [none] means the repo requires no reviews and none
/// were given, or the field hasn't been fetched yet — so the UI shows nothing.
enum PrReviewDecision {
  /// No decision: not fetched yet, or no reviews given/required.
  none,

  /// The repo requires a review that hasn't been given yet.
  reviewRequired,

  /// At least one reviewer has requested changes.
  changesRequested,

  /// The PR is approved.
  approved;

  /// Parses either the GraphQL wire value (`CHANGES_REQUESTED`) or the
  /// stored `.name` form (`changesRequested`).
  static PrReviewDecision fromString(String? value) => switch (value) {
    'REVIEW_REQUIRED' || 'reviewRequired' => PrReviewDecision.reviewRequired,
    'CHANGES_REQUESTED' ||
    'changesRequested' => PrReviewDecision.changesRequested,
    'APPROVED' || 'approved' => PrReviewDecision.approved,
    _ => PrReviewDecision.none,
  };
}

/// GitHub's authoritative mergeable state for a pull request.
///
/// Returned by the REST API as `mergeable_state`. This is the ground-truth
/// signal from GitHub that already factors in branch protection, codeowner
/// reviews, required checks and merge conflicts.
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
  /// Creates a new [PullRequest].
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
    this.externalId = '',
    this.headSha = '',
    this.baseRef = '',
    this.baseSha = '',
    this.headRef = '',
    this.requestedReviewers = const <PrUser>[],
    this.requestedTeamSlugs = const <String>[],
    this.assignees = const <PrUser>[],
    this.labels = const <PrLabel>[],
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
    this.reviewDecision = PrReviewDecision.none,
  }) {
    if (number <= 0) {
      throw ArgumentError('PR number must be positive');
    }
    if (title.isEmpty) {
      throw ArgumentError('PR title must not be empty');
    }
  }

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
  final String externalId;

  /// SHA of the head commit.
  final String headSha;

  /// Base branch ref name.
  final String baseRef;

  /// SHA of the base branch tip. Used by the diff/files cache to detect the
  /// base branch advancing — GitHub renders a three-dot diff, so the rendered
  /// diff can change even when [headSha] is unchanged.
  final String baseSha;

  /// Head branch ref name.
  final String headRef;

  /// Users requested to review this PR.
  final List<PrUser> requestedReviewers;

  /// Slugs of teams still requested to review this PR (GitHub drops a team
  /// from `reviewRequests` once any member submits a review).
  final List<String> requestedTeamSlugs;

  /// Users assigned to this PR.
  final List<PrUser> assignees;

  /// Forge labels currently on the PR, in the order the forge returned.
  final List<PrLabel> labels;

  /// Timestamp.
  final DateTime? mergedAt;

  /// Whether the current viewer has reviewed this PR.
  final bool reviewedByMe;

  /// Reactions on the PR.
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

  /// GitHub's rolled-up review decision. [PrReviewDecision.none] when not
  /// enriched (the lean list/search endpoints omit it).
  final PrReviewDecision reviewDecision;

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
    PrReviewDecision? reviewDecision,
    bool? reviewedByMe,
    List<ReactionGroup>? reactions,
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
      externalId: externalId,
      headSha: headSha,
      baseRef: baseRef,
      baseSha: baseSha,
      headRef: headRef,
      requestedReviewers: requestedReviewers,
      requestedTeamSlugs: requestedTeamSlugs,
      assignees: assignees,
      labels: labels,
      mergedAt: mergedAt,
      reviewedByMe: reviewedByMe ?? this.reviewedByMe,
      reactions: reactions ?? this.reactions,
      bodyHtml: bodyHtml,
      changedFiles: changedFiles ?? this.changedFiles,
      commitsCount: commitsCount,
      additions: additions ?? this.additions,
      deletions: deletions ?? this.deletions,
      commentsCount: commentsCount ?? this.commentsCount,
      checksStatus: checksStatus ?? this.checksStatus,
      mergeableState: mergeableState ?? this.mergeableState,
      reviewDecision: reviewDecision ?? this.reviewDecision,
    );
  }

  /// Whether the PR is open.
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
  bool get isPriority =>
      requestedReviewers.isNotEmpty || requestedTeamSlugs.isNotEmpty;

  /// Whether [other] is the same pull request as this one — the same number
  /// in the same repo — regardless of how either snapshot's fields differ.
  ///
  /// Keyed on `(id, repoFullName)`: the mappers set `id` to the PR NUMBER,
  /// which is unique only within its repo, so `id` alone made repo-a#33373
  /// the same PR as repo-b#33373. Use this (or [identityKey]) wherever the
  /// question is "which PR", never `==`.
  bool isSamePr(PullRequest other) =>
      id == other.id && repoFullName == other.repoFullName;

  /// A stable key for "which PR" (see [isSamePr]), for maps, sets and
  /// provider families that must survive a snapshot's fields changing.
  ({int id, String repoFullName}) get identityKey =>
      (id: id, repoFullName: repoFullName);

  /// Value equality over every field.
  ///
  /// Two snapshots of the same PR with a different title, body or head SHA are
  /// NOT equal. Riverpod drops an emission equal to the previous one, so the
  /// former identity-only `==` swallowed every later detail update — a fresh
  /// fetch after a stale cache, an edited body, a new head commit. Identity
  /// questions use [isSamePr] / [identityKey].
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PullRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          number == other.number &&
          repoFullName == other.repoFullName &&
          title == other.title &&
          body == other.body &&
          bodyHtml == other.bodyHtml &&
          state == other.state &&
          isDraft == other.isDraft &&
          _sameUser(author, other.author) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          htmlUrl == other.htmlUrl &&
          externalId == other.externalId &&
          headSha == other.headSha &&
          baseRef == other.baseRef &&
          baseSha == other.baseSha &&
          headRef == other.headRef &&
          _sameUsers(requestedReviewers, other.requestedReviewers) &&
          _listEquals(requestedTeamSlugs, other.requestedTeamSlugs) &&
          _sameUsers(assignees, other.assignees) &&
          _listEquals(labels, other.labels) &&
          mergedAt == other.mergedAt &&
          reviewedByMe == other.reviewedByMe &&
          _listEquals(reactions, other.reactions) &&
          changedFiles == other.changedFiles &&
          commitsCount == other.commitsCount &&
          additions == other.additions &&
          deletions == other.deletions &&
          commentsCount == other.commentsCount &&
          checksStatus == other.checksStatus &&
          mergeableState == other.mergeableState &&
          reviewDecision == other.reviewDecision;

  /// Hash code over the identity plus the fields most likely to differ
  /// between snapshots — consistent with [==], cheap on a large [body].
  @override
  int get hashCode => Object.hash(
    id,
    repoFullName,
    title,
    body.length,
    state,
    isDraft,
    updatedAt,
    headSha,
    baseSha,
  );

  /// [PrUser.==] compares the login only; a rendered snapshot also shows the
  /// avatar and display name.
  static bool _sameUser(PrUser? a, PrUser? b) =>
      identical(a, b) ||
      a != null &&
          b != null &&
          a.login == b.login &&
          a.avatarUrl == b.avatarUrl &&
          a.name == b.name;

  static bool _sameUsers(List<PrUser> a, List<PrUser> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (!_sameUser(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
