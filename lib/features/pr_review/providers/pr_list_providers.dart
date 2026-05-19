import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show PullRequestDto;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/open_pr_list_repository.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pull_requests_use_case.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

/// A keepAlive store of last-good values keyed by scope (workspace id,
/// `workspace|login`, …). The autoDispose list/inbox providers seed
/// synchronously from it on rebuild — navigating back to a surface shows the
/// previous visit's data INSTANTLY — and stamp every fresh emission into it,
/// so the next visit is instant too (stale-while-revalidate). Keyed stores
/// (never a single slot) so a workspace switch can't flash another
/// workspace's data.
class LastGoodStore<T> extends Notifier<Map<String, T>> {
  @override
  Map<String, T> build() => const {};

  /// Records [value] as the last good for [key].
  void stamp(String key, T value) => state = {...state, key: value};
}

/// The last open-PR snapshot per workspace, seeded into [prsByRepoProvider]
/// on revisit (see [LastGoodStore]).
final lastGoodOpenPrsProvider =
    NotifierProvider<
      LastGoodStore<PrsByRepoState>,
      Map<String, PrsByRepoState>
    >(LastGoodStore.new);

/// The last `reviewed-by:<me>` key set per workspace, seeded into
/// [reviewedByMePrKeysProvider] on revisit (see [LastGoodStore]).
final lastGoodReviewedKeysProvider =
    NotifierProvider<LastGoodStore<Set<String>>, Map<String, Set<String>>>(
      LastGoodStore.new,
    );

/// Aggregated PR list state grouped by repository.
class PrsByRepoState {
  /// Creates a [PrsByRepoState] with the given repository groupings.
  const PrsByRepoState({
    required this.repos,
    required this.hasMore,
    required this.nextPage,
    required this.loadingMore,
    this.reviewedByRepo = const {},
    this.authenticated = true,
    this.sweeping = false,
    this.inaccessibleRepos = const [],
  });

  /// PRs grouped by repository.
  final List<RepoPullRequests> repos;

  /// Whether the SERVER holds a usable GitHub token. The thin client never holds
  /// a token itself, so the PR list reflects the host's auth: `false` drives the
  /// "connect GitHub on the server" empty state instead of an empty list.
  /// Optimistically `true` so a loading state never flashes that gate.
  final bool authenticated;

  /// Whether each repo has more pages to load, keyed by repo ID.
  final Map<String, bool> hasMore;

  /// Next page number per repo, keyed by repo ID.
  final Map<String, int> nextPage;

  /// Whether each repo is currently loading more, keyed by repo ID.
  final Map<String, bool> loadingMore;

  /// The set of open PR numbers the current user has already reviewed, keyed by
  /// repo id. Captured on the first page (the `reviewed-by:@me` search returns
  /// the complete set for a repo, not a single page), so `loadMore` can label
  /// newly-loaded PRs without re-issuing the search every page.
  final Map<String, Set<int>> reviewedByRepo;

  /// Whether the server is running a GitHub sweep right now (the subscribe
  /// kick, a background tick, or a forced refresh). The snapshot itself is
  /// pushed instantly from the server's persisted cache, so this is the only
  /// signal that fresher data is still on its way — it keeps the refresh icon
  /// spinning for the whole fetch, not just the initial load.
  final bool sweeping;

  /// Linked repos the server's credential cannot access (typically a GitHub
  /// App not installed on the repo's org). Their queues are absent or stale;
  /// the list surface explains why instead of showing silently empty repos.
  final List<InaccessibleRepo> inaccessibleRepos;

  /// Returns a copy with the given fields replaced.
  PrsByRepoState copyWith({
    List<RepoPullRequests>? repos,
    Map<String, bool>? hasMore,
    Map<String, int>? nextPage,
    Map<String, bool>? loadingMore,
    Map<String, Set<int>>? reviewedByRepo,
    bool? authenticated,
    bool? sweeping,
    List<InaccessibleRepo>? inaccessibleRepos,
  }) {
    return PrsByRepoState(
      repos: repos ?? this.repos,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      loadingMore: loadingMore ?? this.loadingMore,
      reviewedByRepo: reviewedByRepo ?? this.reviewedByRepo,
      authenticated: authenticated ?? this.authenticated,
      sweeping: sweeping ?? this.sweeping,
      inaccessibleRepos: inaccessibleRepos ?? this.inaccessibleRepos,
    );
  }
}

/// Provider for the [OpenPrListRepository] — the thin-client PR-list data path.
///
/// PR fetching runs SERVER-SIDE on the host's gh-authenticated GitHub client
/// (the client holds no token), so the list arrives over the
/// `pr.listOpenForWorkspace` RPC op rather than a client-side GitHub call.
final openPrListRepositoryProvider = Provider<OpenPrListRepository>((ref) {
  return RpcOpenPrListRepository(ref.watch(rpcClientProvider));
});

/// The linked repos the server's forge credential cannot access, live — the
/// lite feed behind the repos-settings notice (the PR list reads the same data
/// off [PrsByRepoState.inaccessibleRepos] instead of subscribing twice).
final repoAccessForWorkspaceProvider = StreamProvider.autoDispose
    .family<List<InaccessibleRepo>, String>(
      (ref, workspaceId) => ref
          .watch(openPrListRepositoryProvider)
          .watchRepoAccessForWorkspace(workspaceId),
    );

/// Joins the server's per-repo open-PR `groups` back to the workspace's [repos]
/// (by id), sorts each repo's PRs and the repos by most-recent activity and
/// carries the server's `authenticated` flag through to the UI gate.
PrsByRepoState _buildStateFromGroups(
  List<Repo> repos,
  WorkspaceOpenPrs result,
) {
  final reposById = {for (final r in repos) r.id: r};
  final prsByRepo = <RepoPullRequests>[];
  final hasMoreMap = <String, bool>{};
  final nextPageMap = <String, int>{};

  for (final group in result.groups) {
    final repo = reposById[group.repoId];
    if (repo == null || group.prs.isEmpty) {
      continue;
    }
    final prs = [
      ...group.prs,
    ]..sort((a, b) => (b.updatedAt ?? _epoch).compareTo(a.updatedAt ?? _epoch));
    prsByRepo.add(RepoPullRequests(repo: repo, prs: prs));
    hasMoreMap[repo.id] = group.hasMore;
    if (group.hasMore) {
      nextPageMap[repo.id] = 2;
    }
  }

  prsByRepo.sort((a, b) {
    final aTop = a.prs.isNotEmpty ? (a.prs.first.updatedAt ?? _epoch) : _epoch;
    final bTop = b.prs.isNotEmpty ? (b.prs.first.updatedAt ?? _epoch) : _epoch;
    return bTop.compareTo(aTop);
  });

  return PrsByRepoState(
    repos: prsByRepo,
    hasMore: hasMoreMap,
    nextPage: nextPageMap,
    loadingMore: const {},
    authenticated: result.authenticated,
    sweeping: result.sweepInFlight,
    inaccessibleRepos: result.inaccessibleRepos,
  );
}

/// Async notifier that holds the live by-repo PR list.
class PrsByRepoNotifier extends AsyncNotifier<PrsByRepoState> {
  @override
  /// Subscribes to the server's live open-PR snapshot for the active
  /// workspace. The server's poller pushes a fresh snapshot whenever
  /// GitHub-side state changes (new PR, merge/close, update, CI status), so
  /// the list stays current without a refresh button.
  Future<PrsByRepoState> build() async {
    // Deliberately NOT kept alive: the full open-PR snapshot (titles, bodies,
    // checks for every repo) is one of the largest always-resident client
    // allocations and the sidebar badge that used to require it now rides
    // the server-derived `needsMyReviewCountProvider` instead. The provider
    // lives while a PR surface (list, detail, inbox, palette) watches it and
    // releases the snapshot when the user navigates away; returning
    // re-subscribes to the server's poller snapshot, which is cheap.
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const PrsByRepoState(
        repos: [],
        hasMore: {},
        nextPage: {},
        loadingMore: {},
      );
    }

    // Watched so the subscription restarts when the workspace's repo set
    // changes (e.g. a repo is added) and so the server's PR groups can be
    // joined back to the canonical [Repo] entities the client already holds.
    final repos = forgeLinkedReposOf(
      ref.watch(reposForWorkspaceProvider(workspaceId)),
    );

    // Thin client: PR fetching runs SERVER-SIDE on the host's gh-authenticated
    // client (the client holds no token). Each pushed snapshot carries the open
    // PRs grouped per repo with checks already overlaid + whether the SERVER is
    // GitHub-authenticated (drives the connect-GitHub gate). A pushed snapshot
    // resets pagination state (extra REST pages reload on demand).
    final completer = Completer<PrsByRepoState>();
    final sub = ref
        .watch(openPrListRepositoryProvider)
        .watchOpenForWorkspace(workspaceId)
        .listen(
          (result) {
            final next = _buildStateFromGroups(repos, result);
            ref.read(lastGoodOpenPrsProvider.notifier).stamp(workspaceId, next);
            if (!completer.isCompleted) {
              completer.complete(next);
            } else {
              state = AsyncData(next);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            // Only a pre-first-value failure surfaces as the list's error
            // state; once data is showing, a transient push failure keeps the
            // last good snapshot (the server re-pushes on the next change).
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
        );
    ref.onDispose(sub.cancel);
    // Revisit seed: the previous session's snapshot renders INSTANTLY while
    // the re-subscription's first server push is in flight. Read (never
    // watch) the store — watching it would re-run build on every stamp and
    // churn the subscription.
    final lastGood = ref.read(lastGoodOpenPrsProvider)[workspaceId];
    if (lastGood != null && !completer.isCompleted) {
      completer.complete(lastGood);
    }
    return completer.future;
  }

  /// Explicit user refresh: asks the server to sweep GitHub now (ETag
  /// short-circuits bypassed). The refreshed snapshot arrives over the live
  /// subscription — no re-subscribe needed.
  Future<void> forceRefresh() async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await ref
        .read(openPrListRepositoryProvider)
        .refreshOpenForWorkspace(workspaceId);
  }

  /// Loads the next REST page of open PRs for [repoId] and appends them.
  ///
  /// The first page comes from the batched GraphQL query in [build]; subsequent
  /// pages use the REST `GET /pulls` endpoint (also `CREATED_AT DESC`, so the
  /// pages line up) and reuse the reviewed-by-me set captured on the first page
  /// rather than re-issuing the search. These extra pages aren't metric-enriched
  /// (same as before the GraphQL batch), so their metric chips stay hidden.
  Future<void> loadMore(String repoId) async {
    final current = state.value;
    if (current == null) {
      return;
    }
    if (current.hasMore[repoId] != true) {
      return;
    }
    if (current.loadingMore[repoId] == true) {
      return;
    }

    state = AsyncData(
      current.copyWith(loadingMore: {...current.loadingMore, repoId: true}),
    );

    try {
      final repoEntry = current.repos.firstWhere((r) => r.repo.id == repoId);
      final page = current.nextPage[repoId] ?? 2;

      // The next REST page is fetched SERVER-SIDE over RPC (the thin client
      // holds no GitHub token); the host validates the repo is linked to the
      // bound workspace.
      final data = await ref
          .read(rpcClientProvider)
          .call('pr.openPageForRepo', {
            'owner': repoEntry.repo.remoteOwner,
            'repo': repoEntry.repo.remoteName,
            'page': page,
          });
      final hasMore = data['has_more'] as bool? ?? false;

      // The `reviewed-by:@me` search returns the complete set for the repo, so
      // the set captured on the first page already covers later pages — reuse
      // it instead of re-issuing the search on every "load more".
      final reviewedNumbers = current.reviewedByRepo[repoId] ?? const <int>{};

      final newPrs = [
        for (final m in (data['prs'] as List? ?? const []))
          pullRequestFromWireDto(
            PullRequestDto.fromJson((m as Map).cast<String, dynamic>()),
          ).copyWith(
            reviewedByMe: reviewedNumbers.contains(
              (m['number'] as num?)?.toInt() ?? -1,
            ),
          ),
      ];

      final existing = repoEntry.prs;
      final seen = existing.map((p) => p.number).toSet();
      final merged = <PullRequest>[...existing];
      for (final pr in newPrs) {
        if (seen.add(pr.number)) {
          merged.add(pr);
        }
      }
      merged.sort(
        (a, b) => (b.updatedAt ?? _epoch).compareTo(a.updatedAt ?? _epoch),
      );

      final updatedRepos = current.repos
          .map(
            (r) => r.repo.id == repoId
                ? RepoPullRequests(repo: r.repo, prs: merged)
                : r,
          )
          .toList();

      state = AsyncData(
        current.copyWith(
          repos: updatedRepos,
          hasMore: {...current.hasMore, repoId: hasMore},
          nextPage: {...current.nextPage, repoId: hasMore ? page + 1 : page},
          loadingMore: {...current.loadingMore, repoId: false},
        ),
      );
    } catch (_) {
      final s = state.value;
      if (s != null) {
        state = AsyncData(
          s.copyWith(loadingMore: {...s.loadingMore, repoId: false}),
        );
      }
    }
  }
}

/// Provider for the by-repo PR list, scoped to the active workspace.
///
/// autoDispose: the full open-PR snapshot lives only while a PR surface
/// watches it (see the note in [PrsByRepoNotifier.build]).
final prsByRepoProvider =
    AsyncNotifierProvider.autoDispose<PrsByRepoNotifier, PrsByRepoState>(
      PrsByRepoNotifier.new,
    );

/// PRs in the active workspace grouped by repo, filtered to a single author.
final prsByAuthorInWorkspaceProvider = Provider.autoDispose
    .family<AsyncValue<List<RepoPullRequests>>, String>((ref, login) {
      final async = ref.watch(prsByRepoProvider);
      return async.whenData((s) {
        final norm = login.toLowerCase();
        return s.repos
            .map(
              (r) => RepoPullRequests(
                repo: r.repo,
                prs: r.prs
                    .where((p) => p.author?.login.toLowerCase() == norm)
                    .toList(),
              ),
            )
            .where((r) => r.prs.isNotEmpty)
            .toList();
      });
    });

/// The open PRs in the active workspace the operator has already reviewed,
/// as `"<owner/repo>#<number>"` keys, resolved by one server-side
/// `reviewed-by:<me>` search.
///
/// Watched ONLY while the PR-list "reviewed by me" filter is active (see
/// [prListDataProvider]) — auto-disposing the moment it's toggled off. This is
/// what lets the hot list query (`fetchOpenPullRequestsBatch`) drop its per-PR
/// `latestReviews` connection: the common case (filter off) never fetches this,
/// and when the filter is on it's a single cheap search instead of 10 reviews
/// fetched for every open PR on every load.
///
/// Stale-while-revalidate: a revisit seeds the previous workspace's set from
/// [lastGoodReviewedKeysProvider] instantly (the search is a server-side
/// GitHub call — without the seed, the inbox's "Waiting for author" section
/// pops in empty seconds later), then swaps in the fresh result when it lands.
final reviewedByMePrKeysProvider =
    AsyncNotifierProvider.autoDispose<ReviewedByMePrKeysNotifier, Set<String>>(
      ReviewedByMePrKeysNotifier.new,
    );

/// Holds the reviewed-by-me key set; see [reviewedByMePrKeysProvider].
class ReviewedByMePrKeysNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const {};
    }
    final lastGood = ref.read(lastGoodReviewedKeysProvider)[workspaceId];
    final fresh = _fetch(workspaceId);
    if (lastGood == null) {
      return fresh;
    }
    var disposed = false;
    ref.onDispose(() => disposed = true);
    unawaited(
      fresh.then(
        (keys) {
          if (!disposed) {
            state = AsyncData(keys);
          }
        },
        onError: (_) {
          // A failed refresh keeps the stale set — better-stale-than-broken.
        },
      ),
    );
    return lastGood;
  }

  /// Server-side gh search (`reviewed-by:<server login>`): the thin client
  /// holds no token, so the host resolves the reviewed-by-me set over RPC.
  Future<Set<String>> _fetch(String workspaceId) async {
    final keys = await ref
        .read(openPrListRepositoryProvider)
        .reviewedByKeysForWorkspace(workspaceId);
    ref.read(lastGoodReviewedKeysProvider.notifier).stamp(workspaceId, keys);
    return keys;
  }

  /// Explicit user refresh: refetches and replaces the set, keeping the
  /// current value visible until the search lands (the inbox's refresh
  /// affordance spins on its own `_refreshing` flag for the duration).
  Future<void> refreshNow() async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    try {
      state = AsyncData(await _fetch(workspaceId));
    } catch (_) {
      // Keep the last good set — the surface shows its own error affordance.
    }
  }
}

/// Overlays `reviewedByMe` onto the PRs whose `"<repoFullName>#<number>"` is in
/// [reviewedKeys], so the "reviewed by me" filter works without the list query
/// carrying per-PR review data. Only invoked while that filter is active.
List<RepoPullRequests> _overlayReviewedByMe(
  List<RepoPullRequests> repos,
  Set<String> reviewedKeys,
) {
  return repos
      .map(
        (rp) => RepoPullRequests(
          repo: rp.repo,
          prs: rp.prs
              .map(
                (pr) => reviewedKeys.contains('${pr.repoFullName}#${pr.number}')
                    ? pr.copyWith(reviewedByMe: true)
                    : pr,
              )
              .toList(growable: false),
        ),
      )
      .toList(growable: false);
}

/// The classified PRs of the workspace's loaded by-repo set — the population
/// the filter menu's facet counts (via [prListPopulationProvider]) and other
/// PR surfaces (the context rail) run over.
final prListDataProvider = Provider.autoDispose<AsyncValue<PrListData>>((ref) {
  final currentLogin = ref
      .watch(githubUserProvider)
      .maybeWhen(data: (user) => user?.login, orElse: () => null);
  final byRepoAsync = ref.watch(prsByRepoProvider).whenData((s) => s.repos);

  // `reviewedByMe` is no longer carried by the list query (its `latestReviews`
  // connection was dropped). Only when the "reviewed by me" filter is on do we
  // fetch the reviewed set lazily and overlay it; otherwise that provider is
  // never watched, so it never fetches.
  final reviewedByMeActive = ref.watch(
    prListFiltersProvider.select((f) => f.reviewedByMe),
  );
  final reviewedKeys = reviewedByMeActive
      ? (ref.watch(reviewedByMePrKeysProvider).value ?? const <String>{})
      : const <String>{};

  return byRepoAsync.whenData((repos) {
    final byRepo = reviewedKeys.isEmpty
        ? repos
        : _overlayReviewedByMe(repos, reviewedKeys);
    return const ClassifyPullRequestsUseCase().execute(
      byRepo: byRepo,
      currentUserLogin: currentLogin,
    );
  });
});

/// Every PR loaded into the queue, flattened across repos — the population
/// the filter menu's facet counts and the filter bar run over.
final prListPopulationProvider = Provider.autoDispose<List<PullRequest>>((ref) {
  final data = ref.watch(prListDataProvider).value;
  return [
    for (final group in data?.byRepo ?? const <RepoPullRequests>[])
      ...group.prs,
  ];
});

/// The PR queue's filter scope: its own filter state over the loaded queue.
final prListFilterScope = PrFilterScope(
  filters: prListFiltersProvider,
  population: prListPopulationProvider,
);
