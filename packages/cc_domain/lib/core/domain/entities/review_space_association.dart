/// Status of a review space association.
enum ReviewSpaceStatus {
  /// Requested but no reviewer has started.
  requested,

  /// Reviewers actively working.
  inProgress,

  /// CEO has finalized; waiting for human approval to publish.
  awaitingApproval,

  /// Published / closed.
  completed,
}

/// The longest a review space's name may be (sidebar + tab budgets).
const int kReviewSpaceNameMaxLength = 80;

/// The one name rule for a pull request's backing space:
/// `Review: PR #<number> - <title>` (the title clause dropped when blank),
/// truncated to [kReviewSpaceNameMaxLength]. One function rather than a
/// string per call site: the pipeline's ensure-space step and every PR
/// surface resolve the SAME space, so they must agree on its name.
String reviewSpaceName(int prNumber, String title) {
  final trimmed = title.trim();
  final name = trimmed.isEmpty
      ? 'Review: PR #$prNumber'
      : 'Review: PR #$prNumber - $trimmed';
  return name.length > kReviewSpaceNameMaxLength
      ? name.substring(0, kReviewSpaceNameMaxLength)
      : name;
}

/// Association between a PR review and a messaging space.
///
/// Decouples the PR review context from the messaging context. The messaging
/// layer owns spaces; the PR review layer owns this association.
class ReviewSpaceAssociation {
  /// Creates a new [ReviewSpaceAssociation].
  ReviewSpaceAssociation({
    required this.id,
    required this.spaceId,
    required this.workspaceId,
    required this.prExternalId,
    required this.prNumber,
    required this.repoFullName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier.
  final String id;

  /// Linked space identifier.
  final String spaceId;

  /// Linked workspace identifier.
  final String workspaceId;

  /// GitHub PR node ID.
  final String prExternalId;

  /// GitHub PR number.
  final int prNumber;

  /// Repository full name, e.g. `"owner/repo"`.
  final String repoFullName;

  /// Current status.
  final ReviewSpaceStatus status;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Whether the review has been requested but not started.
  bool get isRequested => status == ReviewSpaceStatus.requested;

  /// Whether the review is in progress.
  bool get isInProgress => status == ReviewSpaceStatus.inProgress;

  /// Whether the review is awaiting human approval.
  bool get isAwaitingApproval => status == ReviewSpaceStatus.awaitingApproval;

  /// Whether the review has been completed.
  bool get isCompleted => status == ReviewSpaceStatus.completed;

  /// Returns a copy with status set to [ReviewSpaceStatus.inProgress].
  ReviewSpaceAssociation markInProgress() =>
      copyWith(status: ReviewSpaceStatus.inProgress);

  /// Returns a copy with status set to [ReviewSpaceStatus.awaitingApproval].
  ReviewSpaceAssociation markAwaitingApproval() =>
      copyWith(status: ReviewSpaceStatus.awaitingApproval);

  /// Returns a copy with status set to [ReviewSpaceStatus.completed].
  ReviewSpaceAssociation markCompleted() =>
      copyWith(status: ReviewSpaceStatus.completed);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewSpaceAssociation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          spaceId == other.spaceId &&
          workspaceId == other.workspaceId &&
          prExternalId == other.prExternalId &&
          prNumber == other.prNumber &&
          repoFullName == other.repoFullName &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    spaceId,
    workspaceId,
    prExternalId,
    prNumber,
    repoFullName,
    status,
    createdAt,
    updatedAt,
  );

  /// Returns a copy with optional overrides.
  ReviewSpaceAssociation copyWith({
    String? id,
    String? spaceId,
    String? workspaceId,
    String? prExternalId,
    int? prNumber,
    String? repoFullName,
    ReviewSpaceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewSpaceAssociation(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      workspaceId: workspaceId ?? this.workspaceId,
      prExternalId: prExternalId ?? this.prExternalId,
      prNumber: prNumber ?? this.prNumber,
      repoFullName: repoFullName ?? this.repoFullName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
