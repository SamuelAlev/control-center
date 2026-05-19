import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the diff is stale (new commits pushed) for a PR detail view.
class PrDetailRefreshState {
  /// PrDetailRefreshState.
  const PrDetailRefreshState({this.hasDiffUpdate = false});

  /// Whether new commits have been pushed since the diff was last loaded.
  final bool hasDiffUpdate;

  /// Returns a copy with the given fields replaced.
  PrDetailRefreshState copyWith({bool? hasDiffUpdate}) {
    return PrDetailRefreshState(
      hasDiffUpdate: hasDiffUpdate ?? this.hasDiffUpdate,
    );
  }
}

/// Owns the manual refresh actions and diff-staleness flag for a PR detail
/// view. Refreshes are user-driven (refresh button / shortcut) — there is
/// no background polling. Diff staleness is detected by the screen
/// listening for head-SHA changes after each manual refresh.
class PrDetailPollingNotifier extends Notifier<PrDetailRefreshState> {
  /// PrDetailPollingNotifier.
  PrDetailPollingNotifier(this.prNumber);

  /// PR number this notifier manages.
  final int prNumber;

  /// A pre-signed attachment URL carries a JWT that expires after 5 minutes;
  /// re-fetching the PR detail mints a fresh one, so a single recovery
  /// refresh fixes a genuinely-stale URL. But if an image fails for a
  /// *persistent* reason (a PAT can't fetch the asset, a 404, an unexpected
  /// content-type), the fresh JWT doesn't help: every refetch changes the URL,
  /// which resets the image widget's one-shot failure guard, which fires the
  /// callback again — an unbounded refetch loop. Cap recovery at one attempt
  /// per view session; the attachment-card fallback covers the broken image.
  static const _maxAttachmentRefreshes = 1;
  int _attachmentRefreshes = 0;

  @override
  PrDetailRefreshState build() {
    return const PrDetailRefreshState();
  }

  void _refreshLight() {
    ref.invalidate(prDetailProvider(prNumber));
    ref.invalidate(prReviewCommentsProvider(prNumber));
    ref.invalidate(prIssueCommentsProvider(prNumber));
    ref.invalidate(prReviewsProvider(prNumber));
    ref.invalidate(prReviewersProvider(prNumber));
    ref.invalidate(prCheckRunsProvider(prNumber));
    ref.invalidate(prCommitsProvider(prNumber));
  }

  /// Called when a head SHA change is detected after a manual refresh —
  /// marks the diff as stale so the toolbar can prompt for an explicit
  /// "Refresh diff" rather than auto-rerendering the expensive diff.
  void notifyDiffStale() {
    if (!state.hasDiffUpdate) {
      state = state.copyWith(hasDiffUpdate: true);
    }
  }

  /// Invalidates diff and files providers and clears the stale flag.
  void refreshDiff() {
    ref.invalidate(prDiffProvider(prNumber));
    // Invalidate the source provider — prFilesProvider derives from it.
    ref.invalidate(prFilesLoadProvider(prNumber));
    ref.invalidate(prFilesProvider(prNumber));
    state = state.copyWith(hasDiffUpdate: false);
  }

  /// Full refresh — re-fetches all PR data including the diff. Invoked by
  /// the toolbar refresh button and the `pr.detail-refresh` shortcut.
  void refreshAll() {
    // An explicit user refresh re-arms attachment recovery: a fresh body_html
    // may now carry working URLs (network recovered, waited out a hiccup).
    _attachmentRefreshes = 0;
    _refreshLight();
    refreshDiff();
  }

  /// Re-fetches the PR detail to recover a stale pre-signed attachment URL
  /// (the JWT expires after 5 minutes). Bounded to [_maxAttachmentRefreshes]
  /// per view session so a persistently-broken image can't loop the fetch.
  void invalidateAttachments() {
    if (_attachmentRefreshes >= _maxAttachmentRefreshes) {
      return;
    }
    _attachmentRefreshes++;
    ref.read(prReviewRepositoryProvider).invalidatePullRequest(prNumber);
    ref.invalidate(prDetailProvider(prNumber));
  }
}

/// Per-PR notifier provider. Lives as long as the PR detail screen has
/// watchers; auto-disposes when navigation leaves.
final prDetailPollingProvider =
    NotifierProvider.family.autoDispose<
      PrDetailPollingNotifier,
      PrDetailRefreshState,
      int
    >(PrDetailPollingNotifier.new);
