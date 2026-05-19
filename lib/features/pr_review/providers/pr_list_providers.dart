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
import 'package:control_center/features/pr_review/providers/pr_search_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

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

  /// Returns a copy with the given fields replaced.
  PrsByRepoState copyWith({
    List<RepoPullRequests>? repos,
    Map<String, bool>? hasMore,
    Map<String, int>? nextPage,
    Map<String, bool>? loadingMore,
    Map<String, Set<int>>? reviewedByRepo,
    bool? authenticated,
  }) {
    return PrsByRepoState(
      repos: repos ?? this.repos,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      loadingMore: loadingMore ?? this.loadingMore,
      reviewedByRepo: reviewedByRepo ?? this.reviewedByRepo,
      authenticated: authenticated ?? this.authenticated,
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

/// Joins the server's per-repo open-PR [groups] back to the workspace's [repos]
/// (by id), sorts each repo's PRs and the repos by most-recent activity, and
/// carries the server's [authenticated] flag through to the UI gate.
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
    final prs = [...group.prs]
      ..sort((a, b) => (b.updatedAt ?? _epoch).compareTo(a.updatedAt ?? _epoch));
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
  );
}

/// Async notifier that builds and refreshes the by-repo PR list.
class PrsByRepoNotifier extends AsyncNotifier<PrsByRepoState> {
  @override
  /// Builds and refreshes the by-repo PR list from the active workspace.
  Future<PrsByRepoState> build() async {
    // Keep the list alive across navigation and unrelated widget rebuilds.
    // Without this the provider auto-disposes whenever no widget watches it and
    // re-runs the server fetch on every return. The list still refetches on the
    // events that genuinely change it: the watched dependencies below (active
    // workspace / linked repos) and the explicit `ref.invalidate(...)` refresh
    // paths (refresh button, post-merge).
    ref.keepAlive();

    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const PrsByRepoState(
        repos: [],
        hasMore: {},
        nextPage: {},
        loadingMore: {},
      );
    }

    // Watched so the list re-fetches when the workspace's repo set changes
    // (e.g. a repo is added) and so the server's PR groups can be joined back to
    // the canonical [Repo] entities the client already holds.
    final repos = githubLinkedReposOf(
      ref.watch(reposForWorkspaceProvider(workspaceId)),
    );

    // Thin client: PR fetching runs SERVER-SIDE on the host's gh-authenticated
    // client (the client holds no token). One round trip returns the open PRs
    // grouped per repo with checks already overlaid + whether the SERVER is
    // GitHub-authenticated (drives the connect-GitHub gate).
    final result = await ref
        .watch(openPrListRepositoryProvider)
        .listOpenForWorkspace(workspaceId);
    return _buildStateFromGroups(repos, result);
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
      final data = await ref.read(rpcClientProvider).call('pr.openPageForRepo', {
        'owner': repoEntry.repo.githubOwner,
        'repo': repoEntry.repo.githubRepoName,
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
          nextPage: {
            ...current.nextPage,
            repoId: hasMore ? page + 1 : page,
          },
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
final prsByRepoProvider =
    AsyncNotifierProvider<PrsByRepoNotifier, PrsByRepoState>(
      PrsByRepoNotifier.new,
    );

/// PRs in the active workspace grouped by repo, filtered to a single author.
final prsByAuthorInWorkspaceProvider =
    Provider.family<AsyncValue<List<RepoPullRequests>>, String>((ref, login) {
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
final reviewedByMePrKeysProvider = FutureProvider<Set<String>>((ref) async {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return const {};
  }
  // Server-side gh search (`reviewed-by:<server login>`): the thin client holds
  // no token, so the host resolves the reviewed-by-me set over RPC.
  return ref
      .watch(openPrListRepositoryProvider)
      .reviewedByKeysForWorkspace(workspaceId);
});

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

/// The queue's classified PRs. When a search query is active the population
/// comes from the search port (server-side search across the workspace's
/// repos); otherwise it is the locally-loaded by-repo set. Both paths share the
/// same lane classification so the rest of the screen is search-agnostic.
final prListDataProvider = Provider<AsyncValue<PrListData>>((ref) {
  final query = ref.watch(prSearchQueryProvider);
  final currentLogin = ref
      .watch(githubUserProvider)
      .maybeWhen(data: (user) => user?.login, orElse: () => null);
  final byRepoAsync = query.isActive
      ? ref.watch(prSearchResultsProvider)
      : ref.watch(prsByRepoProvider).whenData((s) => s.repos);

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
