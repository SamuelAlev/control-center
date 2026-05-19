/// Domain port for publishing a finalized PR review to the version-control
/// host (GitHub today). Implemented in the data layer by a service that owns
/// the network client; the MCP tool and any pipeline body depend on this
/// abstraction, not the concrete adapter.
library;

/// Which review nodes to publish to the host.
enum ReviewPublishSelection {
  /// Only findings with at least one peer confirmation (the precision-first
  /// default — matches the consensus rule the verdict is built on).
  consensus,

  /// All open findings that are not dismissed or resolved, regardless of
  /// confirmation.
  allOpen,
}

/// Outcome of publishing a review.
class PublishReviewResult {
  /// Creates a [PublishReviewResult].
  const PublishReviewResult({
    required this.reviewId,
    required this.event,
    required this.findingCount,
    required this.inlineCount,
    required this.usedFallback,
  });

  /// Host review id.
  final int reviewId;

  /// The submitted event (`APPROVE` / `REQUEST_CHANGES` / `COMMENT`).
  final String event;

  /// Total findings published (inline + body).
  final int findingCount;

  /// Findings posted as inline line-anchored comments (0 when the body
  /// fallback was used).
  final int inlineCount;

  /// Whether the host rejected the line anchors so the findings were folded
  /// into the body instead.
  final bool usedFallback;
}

/// Publishes a workspace's structured review findings to the VCS host as a
/// single pull-request review.
abstract class ReviewPublisherPort {
  /// Publishes the review for [spaceId]. [workspaceId] is required and
  /// enforced — a space owned by another workspace must be rejected, never
  /// leaked across the boundary.
  ///
  /// [actingUserId] names the human who asked for it, and decides whose name
  /// the review carries on the host: a person pressing "publish to GitHub"
  /// publishes as themselves, while an agent auto-publishing its own review
  /// passes null and lands as the server's app identity. That split is the
  /// point — a review nobody clicked must not borrow somebody's account.
  Future<PublishReviewResult> publish({
    required String workspaceId,
    required String spaceId,
    ReviewPublishSelection selection = ReviewPublishSelection.consensus,
    bool approveOnShip = false,
    String? actingUserId,
  });
}
