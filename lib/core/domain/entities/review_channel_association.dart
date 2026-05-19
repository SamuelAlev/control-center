/// Status of a review channel association.
enum ReviewChannelStatus {
  /// Requested but no reviewer has started.
  requested,
  /// Reviewers actively working.
  inProgress,
  /// CEO has finalized; waiting for human approval to publish.
  awaitingApproval,
  /// Published / closed.
  completed,
}

/// Association between a PR review and a messaging channel.
///
/// Decouples the PR review context from the messaging context. The messaging
/// layer owns channels; the PR review layer owns this association.
class ReviewChannelAssociation {
  /// Creates a new [ReviewChannelAssociation].
  ReviewChannelAssociation({
    required this.id,
    required this.channelId,
    required this.workspaceId,
    required this.prNodeId,
    required this.prNumber,
    required this.repoFullName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier.
  final String id;

  /// Linked channel identifier.
  final String channelId;

  /// Linked workspace identifier.
  final String workspaceId;

  /// GitHub PR node ID.
  final String prNodeId;

  /// GitHub PR number.
  final int prNumber;

  /// Repository full name, e.g. `"owner/repo"`.
  final String repoFullName;

  /// Current status.
  final ReviewChannelStatus status;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Whether the review has been requested but not started.
  bool get isRequested => status == ReviewChannelStatus.requested;

  /// Whether the review is in progress.
  bool get isInProgress => status == ReviewChannelStatus.inProgress;

  /// Whether the review is awaiting human approval.
  bool get isAwaitingApproval => status == ReviewChannelStatus.awaitingApproval;

  /// Whether the review has been completed.
  bool get isCompleted => status == ReviewChannelStatus.completed;

  /// Returns a copy with status set to [ReviewChannelStatus.inProgress].
  ReviewChannelAssociation markInProgress() => copyWith(
    status: ReviewChannelStatus.inProgress,
  );

  /// Returns a copy with status set to [ReviewChannelStatus.awaitingApproval].
  ReviewChannelAssociation markAwaitingApproval() => copyWith(
    status: ReviewChannelStatus.awaitingApproval,
  );

  /// Returns a copy with status set to [ReviewChannelStatus.completed].
  ReviewChannelAssociation markCompleted() => copyWith(
    status: ReviewChannelStatus.completed,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewChannelAssociation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          channelId == other.channelId &&
          workspaceId == other.workspaceId &&
          prNodeId == other.prNodeId &&
          prNumber == other.prNumber &&
          repoFullName == other.repoFullName &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    channelId,
    workspaceId,
    prNodeId,
    prNumber,
    repoFullName,
    status,
    createdAt,
    updatedAt,
  );

  /// Returns a copy with optional overrides.
  ReviewChannelAssociation copyWith({
    String? id,
    String? channelId,
    String? workspaceId,
    String? prNodeId,
    int? prNumber,
    String? repoFullName,
    ReviewChannelStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewChannelAssociation(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      workspaceId: workspaceId ?? this.workspaceId,
      prNodeId: prNodeId ?? this.prNodeId,
      prNumber: prNumber ?? this.prNumber,
      repoFullName: repoFullName ?? this.repoFullName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
