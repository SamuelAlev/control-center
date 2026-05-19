import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the diff is stale (new commits pushed) for a PR detail view.
class PrDetailRefreshState {
  /// PrDetailRefreshState.
  const PrDetailRefreshState({
    this.hasDiffUpdate = false,
    this.refreshing = false,
  });

  /// Whether new commits have been pushed since the diff was last loaded.
  final bool hasDiffUpdate;

  /// Whether a full manual refresh ([PrDetailPollingNotifier.refreshAll]) is
  /// in flight. Lives here (not in the button) so the `pr.detail-refresh`
  /// shortcut spins the toolbar icon too and the spin lasts until every
  /// re-fetch has landed.
  final bool refreshing;

  /// Returns a copy with the given fields replaced.
  PrDetailRefreshState copyWith({bool? hasDiffUpdate, bool? refreshing}) {
    return PrDetailRefreshState(
      hasDiffUpdate: hasDiffUpdate ?? this.hasDiffUpdate,
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

/// Owns the manual refresh actions and diff-staleness flag for a PR detail
/// view. The detail streams themselves are live (the server's open-PR poller
/// pushes re-validations into every open `pr_review.watch*` subscription), so
/// this notifier only backs the *explicit* refresh button/shortcut — a forced
/// re-subscribe for when the user wants freshness right now. Diff staleness
/// is detected by the screen listening for head-SHA changes.
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

  /// Called when a head SHA change is detected after a manual refresh —
  /// marks the diff as stale so the toolbar can prompt for an explicit
  /// "Refresh diff" rather than auto-rerendering the expensive diff.
  void notifyDiffStale() {
    if (!state.hasDiffUpdate) {
      state = state.copyWith(hasDiffUpdate: true);
    }
  }

  /// Drops the cached diff/files for the PR, then invalidates the diff and
  /// files providers and clears the stale flag.
  ///
  /// Busting the cache first is what makes a user-initiated refresh
  /// authoritative: the SWR freshness gate would otherwise short-circuit and
  /// re-serve the stale diff (e.g. when only the base branch moved, leaving
  /// the head SHA unchanged). With the cache rows gone, the re-subscribed
  /// providers are forced to hit the network.
  Future<void> refreshDiff() async {
    await ref.read(prReviewRepositoryProvider).invalidateDiff(prNumber);
    ref.invalidate(prDiffProvider(prNumber));
    // Invalidate the source provider — prFilesProvider derives from it.
    ref.invalidate(prFilesLoadProvider(prNumber));
    ref.invalidate(prFilesProvider(prNumber));
    state = state.copyWith(hasDiffUpdate: false);
  }

  /// Full refresh — re-fetches all PR data including the diff. Invoked by
  /// the toolbar refresh button and the `pr.detail-refresh` shortcut.
  ///
  /// [PrDetailRefreshState.refreshing] (and the returned future) settles only
  /// once every triggered re-fetch has landed, so the refresh icon spins for
  /// the whole fetch — not just its kickoff. Never throws: each surface keeps
  /// its last data / shows its own error.
  Future<void> refreshAll() async {
    if (state.refreshing) {
      return;
    }
    state = state.copyWith(refreshing: true);
    try {
      // An explicit user refresh re-arms attachment recovery: a fresh
      // body_html may now carry working URLs (network recovered, waited out a
      // hiccup).
      _attachmentRefreshes = 0;
      // Bust the server-side SWR rows first (detail, comments, reviews,
      // checks, diff, files, ...): a re-subscribed watch stream replays its
      // cached row as its first emission, so with the rows intact "await the
      // first value" below would settle on stale data instead of the fetch.
      await ref
          .read(prReviewRepositoryProvider)
          .invalidatePullRequest(prNumber);
      state = state.copyWith(hasDiffUpdate: false);
      await Future.wait([
        _refetch(prDetailProvider(prNumber)),
        _refetch(prReviewCommentsProvider(prNumber)),
        _refetch(prIssueCommentsProvider(prNumber)),
        _refetch(prReviewsProvider(prNumber)),
        _refetch(prReviewersProvider(prNumber)),
        _refetch(prTimelineEventsProvider(prNumber)),
        _refetch(prCheckRunsProvider(prNumber)),
        _refetch(prCommitsProvider(prNumber)),
        _refetch(prDiffProvider(prNumber)),
        _refetch(prFilesLoadProvider(prNumber)),
      ]);
      // prFilesProvider bridges prFilesLoadProvider via ref.listen and only
      // emits non-empty lists — invalidate without awaiting (it could hang on
      // a PR with no files).
      ref.invalidate(prFilesProvider(prNumber));
    } catch (_) {
      // The cache bust can fail offline; the refetches degrade to serving the
      // cached rows. Either way the spin settles.
    } finally {
      if (ref.mounted) {
        state = state.copyWith(refreshing: false);
      }
    }
  }

  /// Re-fetches [provider]: invalidates it and — when something is actively
  /// watching it — waits for the re-created stream's first emission, which is
  /// the fresh network fetch now that the server cache rows are gone. An
  /// inactive provider (e.g. the diff while its tab is closed) is only
  /// invalidated, so a refresh never force-loads surfaces nobody is showing.
  Future<void> _refetch<T>(StreamProvider<T> provider) async {
    final active = ref.exists(provider);
    ref.invalidate(provider);
    if (!active) {
      return;
    }
    try {
      await ref.read(provider.future);
    } catch (_) {
      // The surface renders its own error; the refresh just settles.
    }
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
final prDetailPollingProvider = NotifierProvider.family
    .autoDispose<PrDetailPollingNotifier, PrDetailRefreshState, int>(
      PrDetailPollingNotifier.new,
    );
