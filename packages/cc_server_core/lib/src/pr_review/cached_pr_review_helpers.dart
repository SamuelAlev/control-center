part of '../cached_pr_review_repository.dart';

/// Backoff for [_CachedPrReviewHelpers._settleReviewerState]. Three tries over
/// ~8s covers the lag observed in practice without turning one review into an
/// open-ended poll.
const _reviewerSettleBackoff = <Duration>[
  Duration(milliseconds: 700),
  Duration(seconds: 2),
  Duration(seconds: 5),
];

extension _CachedPrReviewHelpers on CachedPrReviewRepository {
  /// Re-validates the reviewer rail until the forge shows the review just
  /// submitted (or timeout).
  ///
  /// Forge list endpoints lag POST; without this the rail flickers "pending"
  /// after a successful submit. Bounded polls; gives up rather than spinning
  /// forever.
  Future<void> _settleReviewerState(int prNumber, String? before) async {
    if (before == null) {
      return;
    }
    for (final delay in _reviewerSettleBackoff) {
      await Future<void>.delayed(delay);
      // This runs unawaited, outliving the RPC that started it: the workspace
      // database or the signal bus can be torn down under it (server shutdown,
      // a workspace closing, a test's tearDown). Nothing here is worth more
      // than the refresh button it replaces, and an unhandled error in the
      // server's root isolate is fatal — so give up quietly.
      try {
        final current = await _cache.read(
          _workspaceId,
          _Kind.prReviewerState,
          _prKey(prNumber),
        );
        if (current != null && current != before) {
          return;
        }
        await _invalidatePrKinds(prNumber, const [
          _Kind.prReviewerState,
          _Kind.prReviews,
          _Kind.prDetail,
        ]);
      } on Object {
        return;
      }
    }
  }
}
