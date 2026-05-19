import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';

/// The conversation state of one inline review thread, as the forge sees it.
///
/// A review *comment* and a review *thread* are different objects on every
/// forge: the comment carries the body and the anchor, the thread carries the
/// conversation state (resolved / outdated) and the id that resolving addresses.
/// GitHub's REST review-comment payload has no resolution field at all — it is
/// GraphQL-only (`pullRequest.reviewThreads`) — so a client reading only REST
/// renders every resolved conversation as still open.
///
/// [commentIds] are the forge's numeric comment ids (GitHub's `databaseId`), so
/// a fetched comment can be stamped with its thread's state without a second
/// per-comment round trip.
class PrReviewThreadState {
  /// Creates a [PrReviewThreadState].
  const PrReviewThreadState({
    required this.id,
    required this.commentIds,
    this.isResolved = false,
    this.isOutdated = false,
  });

  /// The forge's thread id — opaque, and the handle `setReviewThreadResolved`
  /// takes. On GitHub this is the GraphQL node id, not a number.
  final String id;

  /// Numeric ids of the comments belonging to this thread, in forge order.
  final List<int> commentIds;

  /// Whether the conversation has been marked resolved.
  final bool isResolved;

  /// Whether the diff line the thread anchors to no longer exists.
  final bool isOutdated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrReviewThreadState &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isResolved == other.isResolved &&
          isOutdated == other.isOutdated;

  @override
  int get hashCode => Object.hash(id, isResolved, isOutdated);

  @override
  String toString() =>
      'PrReviewThreadState($id, resolved: $isResolved, '
      'outdated: $isOutdated, ${commentIds.length} comments)';
}

/// Stamps every comment in [comments] with the state of the thread it belongs
/// to, matching on the forge's numeric comment ids.
///
/// A comment no thread claims is returned untouched — unresolved, which is the
/// safe direction: hiding review feedback because a side query came back thin
/// loses the feedback, while showing a settled conversation costs a click.
List<PrCodeReviewComment> withReviewThreadState(
  List<PrCodeReviewComment> comments,
  List<PrReviewThreadState> threads,
) {
  if (comments.isEmpty || threads.isEmpty) {
    return comments;
  }
  final byComment = <int, PrReviewThreadState>{
    for (final t in threads)
      for (final id in t.commentIds) id: t,
  };
  return [
    for (final c in comments)
      if (byComment[c.id] case final PrReviewThreadState t)
        c.copyWith(threadId: t.id, isResolved: t.isResolved)
      else
        c,
  ];
}
