import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/network/github_graphql_client.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/data/mappers/pr_review_mapper.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/domain/usecases/classify_pull_requests_use_case.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_search_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:dio/dio.dart';
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
  });

  /// PRs grouped by repository.
  final List<RepoPullRequests> repos;

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
  }) {
    return PrsByRepoState(
      repos: repos ?? this.repos,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      loadingMore: loadingMore ?? this.loadingMore,
      reviewedByRepo: reviewedByRepo ?? this.reviewedByRepo,
    );
  }
}

/// Converts [batch] (phase-1 result, no checks) into a [PrsByRepoState] with
/// all PRs visible and `checksStatus.none` on every row.
PrsByRepoState _buildStateFromBatch(
  List<Repo> repos,
  GitHubPrBatchResult batch,
) {
  final prsByRepo = <RepoPullRequests>[];
  final hasMoreMap = <String, bool>{};
  final nextPageMap = <String, int>{};
  final reviewedMap = <String, Set<int>>{};

  for (var i = 0; i < repos.length; i++) {
    final repo = repos[i];
    final repoResult = batch.byIndex[i];
    if (repoResult == null) {
      continue;
    }
    final reviewed = <int>{};
    final prs = <PullRequest>[];
    for (final node in repoResult.nodes) {
      final number = (node['number'] as num?)?.toInt() ?? 0;
      final title = node['title'] as String? ?? '';
      if (number <= 0 || title.isEmpty) {
        continue;
      }
      final pr = pullRequestFromGraphQlNode(node, repoFullName: repo.fullName);
      prs.add(pr);
      if (pr.reviewedByMe) {
        reviewed.add(pr.number);
      }
    }
    if (prs.isEmpty) {
      continue;
    }
    prs.sort(
      (a, b) => (b.updatedAt ?? _epoch).compareTo(a.updatedAt ?? _epoch),
    );
    prsByRepo.add(RepoPullRequests(repo: repo, prs: prs));
    hasMoreMap[repo.id] = repoResult.hasMore;
    reviewedMap[repo.id] = reviewed;
    if (repoResult.hasMore) {
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
    loadingMore: {},
    reviewedByRepo: reviewedMap,
  );
}

/// Overlays real `checksStatus` values from [checksMap] onto [phase1]'s PRs.
/// [checksMap] is keyed by repo-input index then by PR number, matching the
/// ordering in [repos]. PRs absent from the map keep `checksStatus.none`.
PrsByRepoState _enrichWithChecks(
  PrsByRepoState phase1,
  List<Repo> repos,
  Map<int, Map<int, String?>> checksMap,
) {
  if (checksMap.isEmpty) {
    return phase1;
  }
  final updatedRepos = phase1.repos
      .map((rp) {
        final repoIdx = repos.indexWhere((r) => r.id == rp.repo.id);
        final checks = repoIdx >= 0 ? checksMap[repoIdx] : null;
        if (checks == null || checks.isEmpty) {
          return rp;
        }
        return RepoPullRequests(
          repo: rp.repo,
          prs: rp.prs
              .map((pr) {
                if (!checks.containsKey(pr.number)) {
                  return pr;
                }
                return pr.copyWith(
                  checksStatus: prChecksStatusFromRollup(checks[pr.number]),
                );
              })
              .toList(growable: false),
        );
      })
      .toList(growable: false);
  return phase1.copyWith(repos: updatedRepos);
}

/// Async notifier that builds and refreshes the by-repo PR list.
class PrsByRepoNotifier extends AsyncNotifier<PrsByRepoState> {
  @override
  /// Builds and refreshes the by-repo PR list from the active workspace.
  Future<PrsByRepoState> build() async {
    // Keep the list alive across navigation and unrelated widget rebuilds.
    // Without this the provider auto-disposes whenever no widget watches it
    // (e.g. switching tabs) and re-runs the full per-repo fan-out (open PRs +
    // reviewed-by-me + metrics — 3 calls per repo) on every return. The list
    // still refetches on the events that genuinely change it: the watched
    // dependencies below (auth / active workspace / linked repos) and the
    // explicit `ref.invalidate(prsByRepoProvider)` refresh paths (refresh
    // button, post-merge).
    ref.keepAlive();

    final client = ref.watch(githubApiClientProvider);
    final isAuthed = ref.watch(isGitHubAuthenticatedProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (!isAuthed || workspaceId == null) {
      return const PrsByRepoState(
        repos: [],
        hasMore: {},
        nextPage: {},
        loadingMore: {},
      );
    }

    final repos = githubLinkedReposOf(
      ref.watch(reposForWorkspaceProvider(workspaceId)),
    );
    if (repos.isEmpty) {
      return const PrsByRepoState(
        repos: [],
        hasMore: {},
        nextPage: {},
        loadingMore: {},
      );
    }

    final repoSpecs = repos
        .map((r) => (owner: r.githubOwner, name: r.githubRepoName))
        .toList(growable: false);

    // The cancel token is shared by both phases. `ref.onDispose` fires
    // synchronously on provider teardown (workspace-switch, tab-away rebuild),
    // cancelling whichever phase is in-flight — the stale result is discarded.
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);

    // Phase 1 — core fields, no statusCheckRollup. The list renders
    // immediately with checksStatus.none on every row; checks are overlaid in
    // phase 2.
    final batch = await client.graphql.fetchOpenPullRequestsBatch(
      repoSpecs,
      cancelToken: cancelToken,
    );
    final phase1 = _buildStateFromBatch(repos, batch);

    // Emit phase 1 so the list is visible while phase 2 runs.
    state = AsyncData(phase1);

    // Phase 2 — checks-only batch. If it fails or is cancelled, return the
    // already-visible phase 1 state unchanged (checks stay none, no regression).
    try {
      final checksMap = await client.graphql.fetchOpenPullRequestsChecks(
        repoSpecs,
        cancelToken: cancelToken,
      );
      return _enrichWithChecks(phase1, repos, checksMap);
    } catch (_) {
      return phase1;
    }
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
      final client = ref.read(githubApiClientProvider);

      final result = await client.pr.listOpenPullRequestsPage(
        repoEntry.repo.githubOwner,
        repoEntry.repo.githubRepoName,
        page: page,
      );

      // The `reviewed-by:@me` search returns the complete set for the repo, so
      // the set captured on the first page already covers later pages — reuse
      // it instead of re-issuing the search on every "load more".
      final reviewedNumbers = current.reviewedByRepo[repoId] ?? const <int>{};

      final newPrs = result.items
          .map(
            (gh) => pullRequestFromGitHub(
              gh,
              repoFullName: repoEntry.repo.fullName,
              reviewedByMe: reviewedNumbers.contains(gh.number),
            ),
          )
          .toList();

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
          hasMore: {...current.hasMore, repoId: result.hasMore},
          nextPage: {
            ...current.nextPage,
            repoId: result.hasMore ? page + 1 : page,
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
  final isAuthed = ref.watch(isGitHubAuthenticatedProvider);
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (!isAuthed || workspaceId == null) {
    return const {};
  }
  final login = ref
      .watch(githubUserProvider)
      .maybeWhen(data: (user) => user?.login, orElse: () => null);
  if (login == null || login.isEmpty) {
    return const {};
  }
  final repos = githubLinkedReposOf(
    ref.watch(reposForWorkspaceProvider(workspaceId)),
  );
  if (repos.isEmpty) {
    return const {};
  }

  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  final client = ref.watch(githubApiClientProvider);
  final pairs = await client.graphql.searchReviewedByPullRequests(
    reviewerLogin: login,
    repos: repos
        .map((r) => (owner: r.githubOwner, name: r.githubRepoName))
        .toList(growable: false),
    cancelToken: cancelToken,
  );
  return {for (final p in pairs) '${p.repoFullName}#${p.number}'};
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
