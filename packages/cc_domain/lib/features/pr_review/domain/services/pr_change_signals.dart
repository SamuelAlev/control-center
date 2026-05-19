import 'dart:async';

/// A change signal for one repo's pull-request data.
///
/// Emitted server-side whenever something detects that GitHub-side PR state
/// moved — the open-PR list poller (updated PR, new head, closed/merged), the
/// notifications poller (review requested, new comment), or a local mutation
/// (merge, review submit, cache invalidation). Open `pr_review.watch*` streams
/// subscribe to these to re-run their stale-while-revalidate pass, which is
/// what turns the formerly one-shot SWR reads into live, push-updating
/// subscriptions.
class PrChangeSignal {
  /// Creates a [PrChangeSignal].
  const PrChangeSignal({
    required this.workspaceId,
    required this.repoFullName,
    this.prNumber,
    this.checksOnly = false,
  });

  /// The workspace whose PR data changed.
  final String workspaceId;

  /// The GitHub repository in `owner/name` form.
  final String repoFullName;

  /// The affected PR number, or null when the whole repo's list changed.
  final int? prNumber;

  /// True when only CI/check state moved (the check-status poll). Streams
  /// serving non-check data skip these so a checks tick never refetches
  /// comments/reviews/diffs.
  final bool checksOnly;
}

/// In-memory broadcast bus for [PrChangeSignal]s.
///
/// One instance lives in the server runtime and is shared by the producers
/// (open-PR poller, notifications poller, PR mutations) and the consumers
/// (the `CachedPrReviewRepository` watch streams). Purely ephemeral — nothing
/// is persisted and a signal simply prompts subscribers to revalidate their
/// own cache, so a missed signal degrades to the pre-existing
/// revalidate-on-subscribe behavior, never to wrong data.
class PrChangeSignals {
  final StreamController<PrChangeSignal> _controller =
      StreamController<PrChangeSignal>.broadcast();

  /// Publishes a change for `(workspaceId, repoFullName)`, optionally narrowed
  /// to one [prNumber]. No-op after [dispose].
  void notify({
    required String workspaceId,
    required String repoFullName,
    int? prNumber,
    bool checksOnly = false,
  }) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(
      PrChangeSignal(
        workspaceId: workspaceId,
        repoFullName: repoFullName,
        prNumber: prNumber,
        checksOnly: checksOnly,
      ),
    );
  }

  /// The signals affecting [prNumber] in `(workspaceId, repoFullName)`.
  ///
  /// A repo-level signal (one carrying no PR number) matches every PR watcher
  /// of that repo; pass a null [prNumber] to receive every signal for the
  /// repo. Matching is exact on the ids the server already holds (both sides
  /// source them from the same linked-repo row), so no normalization is
  /// applied.
  Stream<PrChangeSignal> watch({
    required String workspaceId,
    required String repoFullName,
    int? prNumber,
  }) {
    return _controller.stream.where(
      (s) =>
          s.workspaceId == workspaceId &&
          s.repoFullName == repoFullName &&
          (prNumber == null || s.prNumber == null || s.prNumber == prNumber),
    );
  }

  /// Closes the bus (open watchers' streams complete).
  void dispose() {
    _controller.close();
  }
}
