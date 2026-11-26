import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the diff is stale (new commits pushed) for a PR detail view.
class PrDetailRefreshState {
  /// PrDetailRefreshState.
  const PrDetailRefreshState({
    this.hasDiffUpdate = false,
    this.refreshing = false,
    this.refreshingDiff = false,
  });

  /// Whether new commits have been pushed since the diff was last loaded.
  final bool hasDiffUpdate;

  /// Whether a full manual refresh ([PrDetailPollingNotifier.refreshAll]) is
  /// in flight. Lives here (not in the button) so the `pr.detail-refresh`
  /// shortcut spins the toolbar icon too and the spin lasts until every
  /// re-fetch has landed.
  final bool refreshing;

  /// Whether a diff refresh ([PrDetailPollingNotifier.refreshDiff]) is in flight.
  final bool refreshingDiff;

  /// Returns a copy with the given fields replaced.
  PrDetailRefreshState copyWith({
    bool? hasDiffUpdate,
    bool? refreshing,
    bool? refreshingDiff,
  }) {
    return PrDetailRefreshState(
      hasDiffUpdate: hasDiffUpdate ?? this.hasDiffUpdate,
      refreshing: refreshing ?? this.refreshing,
      refreshingDiff: refreshingDiff ?? this.refreshingDiff,
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
  PrDetailPollingNotifier(this.pr);

  /// The PR this notifier manages: repo coords + number, so every repository
  /// call and provider invalidation lands on the PR's OWN repo (a number alone
  /// is ambiguous across repos).
  final PrRef pr;

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
  bool _needsServerCacheBust = false;

  @override
  PrDetailRefreshState build() {
    return const PrDetailRefreshState();
  }

  /// Called when a head SHA change or local worktree push/sync is detected —
  /// marks the diff as stale. When [bustServerCache] is true (e.g. a worktree
  /// commit/push or sync), [refreshDiff] will explicitly delete the server's
  /// cached diff/files rows before refetching and passive stream updates will
  /// not clear the flag.
  void notifyDiffStale({bool bustServerCache = false}) {
    if (bustServerCache) {
      _needsServerCacheBust = true;
    }
    if (!state.hasDiffUpdate) {
      state = state.copyWith(hasDiffUpdate: true);
    }
  }

  /// Clears the stale flag when a fresh passive stream load has landed and no
  /// explicit server-cache bust is pending.
  void clearDiffStaleIfFresh() {
    if (_needsServerCacheBust || !state.hasDiffUpdate) {
      return;
    }
    state = state.copyWith(hasDiffUpdate: false);
  }

  /// Refreshes the diff and files providers and clears the stale flag.
  ///
  /// When [bustServerCache] is true (the default for manual user refreshes, or
  /// whenever [_needsServerCacheBust] was flagged), drops the server-side
  /// cached diff/files rows first so the SWR freshness gate cannot
  /// short-circuit. Automatic refreshes triggered by switching back to a stale
  /// Diff tab pass `bustServerCache: false` unless a worktree mutation flagged
  /// [_needsServerCacheBust].
  Future<void> refreshDiff({bool? bustServerCache}) async {
    if (state.refreshingDiff || state.refreshing) {
      return;
    }
    final shouldBust = (bustServerCache ?? true) || _needsServerCacheBust;
    _needsServerCacheBust = false;
    state = state.copyWith(hasDiffUpdate: false, refreshingDiff: true);
    try {
      if (shouldBust) {
        final repository = ref.read(prRepositoryProvider(pr));
        if (repository != null) {
          await repository.invalidateDiff(pr.number);
        }
      }
      await Future.wait([
        _refetch(prDiffProvider(pr)),
        _refetch(prFileIndexProvider(pr)),
        _refetch(prFilesLoadProvider(pr)),
      ]);
      // prFilesProvider bridges prFilesLoadProvider via ref.listen and only
      // emits non-empty lists — invalidate without awaiting (it could hang on
      // a PR with no files).
      ref.invalidate(prFilesProvider(pr));
    } catch (_) {
      // Cache bust or refetch errors are surfaced by the diff providers.
    } finally {
      if (ref.mounted) {
        state = state.copyWith(refreshingDiff: false);
      }
    }
  }

  /// Refreshes the diff only if it is currently marked stale.
  Future<void> refreshDiffIfStale() async {
    if (!state.hasDiffUpdate) {
      return;
    }
    await refreshDiff(bustServerCache: false);
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
      _needsServerCacheBust = false;
      // Bust the server-side SWR rows first (detail, comments, reviews,
      // checks, diff, files, ...): a re-subscribed watch stream replays its
      // cached row as its first emission, so with the rows intact "await the
      // first value" below would settle on stale data instead of the fetch.
      final repository = ref.read(prRepositoryProvider(pr));
      if (repository != null) {
        await repository.invalidatePullRequest(pr.number);
      }
      state = state.copyWith(hasDiffUpdate: false);
      await Future.wait([
        _refetch(prDetailProvider(pr)),
        _refetch(prReviewCommentsProvider(pr)),
        _refetch(prReviewCommentIndexProvider(pr)),
        _refetch(prIssueCommentsProvider(pr)),
        _refetch(prReviewsProvider(pr)),
        _refetch(prReviewersProvider(pr)),
        _refetch(prTimelineEventsProvider(pr)),
        _refetch(prCheckRunsProvider(pr)),
        _refetch(prCommitsProvider(pr)),
        _refetch(prDiffProvider(pr)),
        _refetch(prFileIndexProvider(pr)),
        _refetch(prFilesLoadProvider(pr)),
      ]);
      // prFilesProvider bridges prFilesLoadProvider via ref.listen and only
      // emits non-empty lists — invalidate without awaiting (it could hang on
      // a PR with no files).
      ref.invalidate(prFilesProvider(pr));
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
    final repository = ref.read(prRepositoryProvider(pr));
    if (repository != null) {
      repository.invalidatePullRequest(pr.number);
    }
    ref.invalidate(prDetailProvider(pr));
  }
}

/// Per-PR notifier provider. Lives as long as the PR detail screen has
/// watchers; auto-disposes when navigation leaves.
final prDetailPollingProvider = NotifierProvider.family
    .autoDispose<PrDetailPollingNotifier, PrDetailRefreshState, PrRef>(
      PrDetailPollingNotifier.new,
    );
