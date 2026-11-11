import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show PullRequestDto;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/open_pr_list_repository.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pull_requests_use_case.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart'
    show viewerLoginsProvider;
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_table_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

/// Keeps an in-memory revisit seed inside the same authenticated user's
/// workspace. An unresolved identity must never reuse a previous user's seed.
String? _prListScopeKey(String workspaceId, String? userId) =>
    userId == null ? null : '$userId|$workspaceId';

/// A keepAlive store of last-good values keyed by authenticated user and
/// workspace (and forge login for user-specific searches).
/// AutoDispose list/inbox providers seed synchronously from it on revisit.
class LastGoodStore<T> extends Notifier<Map<String, T>> {
  @override
  Map<String, T> build() => const {};

  /// Records [value] as the last good for [key].
  void stamp(String key, T value) => state = {...state, key: value};

  /// Drops a revoked snapshot so it cannot seed another visit.
  void remove(String key) => state = {...state}..remove(key);
}

/// The last open-PR snapshot per authenticated user and workspace, seeded
/// into [prsByRepoProvider] on revisit.
final lastGoodOpenPrsProvider =
    NotifierProvider<
      LastGoodStore<PrsByRepoState>,
      Map<String, PrsByRepoState>
    >(LastGoodStore.new);

/// The last `reviewed-by:<me>` key set per user, workspace and forge login,
/// seeded into [reviewedByMePrKeysProvider] on revisit.
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
    this.authenticated = true,
    this.scopeKey,
    this.sweeping = false,
    this.repoAccess = const [],
    this.hiddenRepos = const [],
    this.totalCount = const {},
    this.extraPrs = const {},
    this.loadMoreFailed = const {},
  });

  /// PRs grouped by repository: the live first page plus any [extraPrs]
  /// loaded behind it, merged.
  final List<RepoPullRequests> repos;

  /// Each repo's open PR count across every page, keyed by repo ID, as the
  /// forge reports it. Absent when the forge gives no total.
  final Map<String, int> totalCount;

  /// PRs loaded past the first page (via [PrsByRepoNotifier.loadMore]), keyed
  /// by repo ID. Disjoint from the first page; already merged into [repos].
  /// Kept apart so a pushed snapshot (which only carries the first page) can
  /// re-merge them instead of truncating the list back to one page.
  final Map<String, List<PullRequest>> extraPrs;

  /// Whether the last page load for a repo failed, keyed by repo ID. The list
  /// then offers a retry instead of loading again on its own.
  final Map<String, bool> loadMoreFailed;

  /// Authenticated account/workspace that produced this snapshot.
  final String? scopeKey;

  /// Whether the SERVER holds a usable GitHub token. The thin client never holds
  /// a token itself, so the PR list reflects the host's auth: `false` drives the
  /// "connect GitHub on the server" empty state instead of an empty list.
  /// Optimistically `true` so a loading state never flashes that gate.
  final bool authenticated;

  /// Whether each repo has more pages to load, keyed by repo ID.
  final Map<String, bool> hasMore;

  /// Next page number per repo, keyed by repo ID. Every page before it is
  /// loaded.
  final Map<String, int> nextPage;

  /// Whether each repo is currently loading more, keyed by repo ID.
  final Map<String, bool> loadingMore;

  /// Whether the server is running a GitHub sweep right now (the subscribe
  /// kick, a background tick, or a forced refresh). The snapshot itself is
  /// pushed instantly from the server's persisted cache, so this is the only
  /// signal that fresher data is still on its way — it keeps the refresh icon
  /// spinning for the whole fetch, not just the initial load.
  final bool sweeping;

  /// Linked repos automation cannot reach (the GitHub App not installed on
  /// the owner, the repo not selected, a suspended installation, the
  /// accountable person without access). Their queues are absent; the list
  /// surface explains why and offers the fix.
  final List<RepoAccessIssue> repoAccess;

  /// Linked repos left out of the reader's view, as counts per forge and
  /// reason: not signed in to that forge here, their account cannot see
  /// them, no grant in this workspace, or not checked yet.
  final List<HiddenRepos> hiddenRepos;

  /// Paging state per repo that still has open PRs past its loaded pages.
  Map<String, PrRepoPaging> get paging => {
    for (final entry in hasMore.entries)
      if (entry.value)
        entry.key: (
          hasMore: true,
          loading: loadingMore[entry.key] ?? false,
          failed: loadMoreFailed[entry.key] ?? false,
        ),
  };

  /// Returns a copy with the given fields replaced.
  PrsByRepoState copyWith({
    List<RepoPullRequests>? repos,
    Map<String, bool>? hasMore,
    Map<String, int>? nextPage,
    Map<String, bool>? loadingMore,
    bool? authenticated,
    String? scopeKey,
    bool? sweeping,
    List<RepoAccessIssue>? repoAccess,
    List<HiddenRepos>? hiddenRepos,
    Map<String, int>? totalCount,
    Map<String, List<PullRequest>>? extraPrs,
    Map<String, bool>? loadMoreFailed,
  }) {
    return PrsByRepoState(
      repos: repos ?? this.repos,
      scopeKey: scopeKey ?? this.scopeKey,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      loadingMore: loadingMore ?? this.loadingMore,
      authenticated: authenticated ?? this.authenticated,
      sweeping: sweeping ?? this.sweeping,
      repoAccess: repoAccess ?? this.repoAccess,
      hiddenRepos: hiddenRepos ?? this.hiddenRepos,
      totalCount: totalCount ?? this.totalCount,
      extraPrs: extraPrs ?? this.extraPrs,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
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

/// The linked repos automation cannot reach, live — the lite feed behind the
/// repos-settings notice (the PR list reads the same data off
/// [PrsByRepoState.repoAccess] instead of subscribing twice).
final repoAccessForWorkspaceProvider = StreamProvider.autoDispose
    .family<List<RepoAccessIssue>, String>(
      (ref, workspaceId) => ref
          .watch(openPrListRepositoryProvider)
          .watchRepoAccessForWorkspace(workspaceId),
    );

/// Sorts [prs] by most-recent activity (updated-desc).
List<PullRequest> _byUpdatedDesc(Iterable<PullRequest> prs) => [...prs]
  ..sort((a, b) => (b.updatedAt ?? _epoch).compareTo(a.updatedAt ?? _epoch));

/// A pushed snapshot plus, per repo, the last page whose loaded rows may no
/// longer line up with the new first page and need re-reading.
typedef _PushedState = ({PrsByRepoState state, Map<String, int> staleThrough});

/// Joins the server's per-repo open-PR `groups` back to the workspace's [repos]
/// (by id), sorts each repo's PRs and the repos by most-recent activity and
/// carries the server's `authenticated` flag through to the UI gate.
///
/// The server only pushes each repo's first page. Pages the user already
/// loaded behind it ([previous]'s [PrsByRepoState.extraPrs], same scope only)
/// are re-merged so a push never truncates a scrolled list. When the first
/// page's membership or the repo's total changed, those pages may have
/// shifted; the repo is reported in `staleThrough` so they are re-read.
_PushedState _buildStateFromGroups(
  List<Repo> repos,
  WorkspaceOpenPrs result,
  String? scopeKey, {
  PrsByRepoState? previous,
}) {
  final carry = previous != null && previous.scopeKey == scopeKey
      ? previous
      : null;
  final reposById = {for (final r in repos) r.id: r};
  final prsByRepo = <RepoPullRequests>[];
  final hasMoreMap = <String, bool>{};
  final nextPageMap = <String, int>{};
  final totalMap = <String, int>{};
  final extrasMap = <String, List<PullRequest>>{};
  final staleThrough = <String, int>{};

  for (final group in result.groups) {
    final repo = reposById[group.repoId];
    if (repo == null || group.prs.isEmpty) {
      continue;
    }
    final total = group.totalCount;
    if (total != null) {
      totalMap[repo.id] = total;
    }
    final firstNumbers = {for (final pr in group.prs) pr.number};
    final previousExtras = carry?.extraPrs[repo.id] ?? const <PullRequest>[];
    final extras = group.hasMore
        ? [
            for (final pr in previousExtras)
              if (!firstNumbers.contains(pr.number)) pr,
          ]
        : const <PullRequest>[];
    prsByRepo.add(
      RepoPullRequests(
        repo: repo,
        prs: _byUpdatedDesc([...group.prs, ...extras]),
      ),
    );
    if (extras.isEmpty) {
      hasMoreMap[repo.id] = group.hasMore;
      if (group.hasMore) {
        nextPageMap[repo.id] = 2;
      }
      continue;
    }
    extrasMap[repo.id] = extras;
    final nextPage = carry!.nextPage[repo.id] ?? 2;
    hasMoreMap[repo.id] = carry.hasMore[repo.id] ?? true;
    nextPageMap[repo.id] = nextPage;
    final extraNumbers = {for (final pr in previousExtras) pr.number};
    final previousFirst = {
      for (final group in carry.repos)
        if (group.repo.id == repo.id)
          for (final pr in group.prs)
            if (!extraNumbers.contains(pr.number)) pr.number,
    };
    final shifted =
        previousFirst.length != firstNumbers.length ||
        !previousFirst.containsAll(firstNumbers) ||
        carry.totalCount[repo.id] != total;
    if (shifted) {
      staleThrough[repo.id] = nextPage - 1;
    }
  }

  prsByRepo.sort((a, b) {
    final aTop = a.prs.isNotEmpty ? (a.prs.first.updatedAt ?? _epoch) : _epoch;
    final bTop = b.prs.isNotEmpty ? (b.prs.first.updatedAt ?? _epoch) : _epoch;
    return bTop.compareTo(aTop);
  });

  return (
    state: PrsByRepoState(
      repos: prsByRepo,
      scopeKey: scopeKey,
      hasMore: hasMoreMap,
      nextPage: nextPageMap,
      loadingMore: carry?.loadingMore ?? const {},
      loadMoreFailed: carry?.loadMoreFailed ?? const {},
      authenticated: result.authenticated,
      sweeping: result.sweepInFlight,
      repoAccess: result.repoAccess,
      hiddenRepos: result.hiddenRepos,
      totalCount: totalMap,
      extraPrs: extrasMap,
    ),
    staleThrough: staleThrough,
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
    final userId = ref.watch(currentUserIdProvider);
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
    // carries only each repo's first page; pages already loaded behind it are
    // re-merged (see [_buildStateFromGroups]).
    final completer = Completer<PrsByRepoState>();
    final scopeKey = _prListScopeKey(workspaceId, userId);
    final sub = ref
        .watch(openPrListRepositoryProvider)
        .watchOpenForWorkspace(workspaceId)
        .listen(
          (result) {
            final pushed = _buildStateFromGroups(
              repos,
              result,
              scopeKey,
              previous: completer.isCompleted ? state.value : null,
            );
            final next = pushed.state;
            if (scopeKey != null) {
              ref.read(lastGoodOpenPrsProvider.notifier).stamp(scopeKey, next);
            }
            if (!completer.isCompleted) {
              completer.complete(next);
            } else {
              state = AsyncData(next);
            }
            for (final stale in pushed.staleThrough.entries) {
              unawaited(_reloadExtras(stale.key, stale.value));
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            // The transport suppresses transient outages after a snapshot.
            // An emitted error is authoritative (e.g. access was revoked).
            if (scopeKey != null) {
              ref.read(lastGoodOpenPrsProvider.notifier).remove(scopeKey);
            }
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            } else {
              state = AsyncError(error, stackTrace);
            }
          },
        );
    ref.onDispose(sub.cancel);
    // Revisit seed: the previous session's snapshot renders INSTANTLY while
    // the re-subscription's first server push is in flight. Read (never
    // watch) the store — watching it would re-run build on every stamp and
    // churn the subscription.
    final lastGood = scopeKey == null
        ? null
        : ref.read(lastGoodOpenPrsProvider)[scopeKey];
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

  /// Loads the next REST page of open PRs for [repoId] and appends them —
  /// the list's infinite scroll.
  ///
  /// The first page comes from the server's live snapshot; later pages use
  /// the REST `GET /pulls` endpoint (also `CREATED_AT DESC`, so the pages line
  /// up). These extra pages aren't metric-enriched, so their metric chips stay
  /// hidden. A failure is recorded in [PrsByRepoState.loadMoreFailed] so the
  /// list offers a retry rather than looping on its own.
  Future<void> loadMore(String repoId) async {
    final current = state.value;
    if (current == null ||
        current.hasMore[repoId] != true ||
        current.loadingMore[repoId] == true) {
      return;
    }
    final repo = _repoById(current, repoId);
    if (repo == null) {
      return;
    }
    final page = current.nextPage[repoId] ?? 2;
    _setLoading(repoId, loading: true);
    try {
      final result = await _fetchPage(repo, page);
      // Re-read: a pushed snapshot may have replaced the state meanwhile.
      final latest = state.value;
      if (latest == null || _repoById(latest, repoId) == null) {
        return;
      }
      final extras = [
        ...latest.extraPrs[repoId] ?? const <PullRequest>[],
        ...result.prs,
      ];
      state = AsyncData(
        _withExtras(
          latest,
          repoId,
          extras,
          hasMore: result.hasMore,
          nextPage: page + 1,
        ),
      );
    } on Object {
      _setLoading(repoId, loading: false, failed: true);
    }
  }

  /// Loads the next page of every repo with more to load (and no load in
  /// flight or failed). A filtered list calls this until it has read every
  /// page: a filter or count over only the first pages would be wrong.
  void loadNextPages() {
    final current = state.value;
    if (current == null) {
      return;
    }
    for (final entry in current.paging.entries) {
      if (!entry.value.loading && !entry.value.failed) {
        unawaited(loadMore(entry.key));
      }
    }
  }

  /// Re-reads pages 2..[throughPage] for [repoId] after the first page
  /// shifted under them (a PR opened or closed), replacing the loaded rows in
  /// one swap so the list never shrinks while they load.
  Future<void> _reloadExtras(String repoId, int throughPage) async {
    final current = state.value;
    if (current == null || current.loadingMore[repoId] == true) {
      return;
    }
    final repo = _repoById(current, repoId);
    if (repo == null) {
      return;
    }
    _setLoading(repoId, loading: true);
    try {
      final extras = <PullRequest>[];
      var hasMore = true;
      var page = 2;
      for (; page <= throughPage && hasMore; page++) {
        final result = await _fetchPage(repo, page);
        extras.addAll(result.prs);
        hasMore = result.hasMore;
      }
      final latest = state.value;
      if (latest == null || _repoById(latest, repoId) == null) {
        return;
      }
      state = AsyncData(
        _withExtras(latest, repoId, extras, hasMore: hasMore, nextPage: page),
      );
    } on Object {
      _setLoading(repoId, loading: false, failed: true);
    }
  }

  static Repo? _repoById(PrsByRepoState state, String repoId) => state.repos
      .where((r) => r.repo.id == repoId)
      .map((r) => r.repo)
      .firstOrNull;

  void _setLoading(String repoId, {required bool loading, bool? failed}) {
    final s = state.value;
    if (s == null) {
      return;
    }
    state = AsyncData(
      s.copyWith(
        loadingMore: {...s.loadingMore, repoId: loading},
        loadMoreFailed: {...s.loadMoreFailed, repoId: failed ?? false},
      ),
    );
  }

  /// One REST page of [repo]'s open PRs, fetched SERVER-SIDE over RPC (the
  /// thin client holds no GitHub token); the host validates the repo is
  /// linked to the call's workspace (the client stamps the active one).
  Future<({List<PullRequest> prs, bool hasMore})> _fetchPage(
    Repo repo,
    int page,
  ) async {
    final data = await ref.read(rpcClientProvider).call('pr.openPageForRepo', {
      'owner': repo.remoteOwner,
      'repo': repo.remoteName,
      'page': page,
    });
    return (
      prs: [
        for (final m in (data['prs'] as List? ?? const []))
          pullRequestFromWireDto(
            PullRequestDto.fromJson((m as Map).cast<String, dynamic>()),
          ),
      ],
      hasMore: data['has_more'] as bool? ?? false,
    );
  }

  /// [state] with [repoId]'s loaded-past-the-first-page rows replaced by
  /// [extras] (minus anything the live first page already holds) and merged
  /// into its group.
  static PrsByRepoState _withExtras(
    PrsByRepoState state,
    String repoId,
    List<PullRequest> extras, {
    required bool hasMore,
    required int nextPage,
  }) {
    final oldExtras = {
      for (final pr in state.extraPrs[repoId] ?? const <PullRequest>[])
        pr.number,
    };
    final repos = <RepoPullRequests>[];
    var kept = const <PullRequest>[];
    for (final group in state.repos) {
      if (group.repo.id != repoId) {
        repos.add(group);
        continue;
      }
      final first = [
        for (final pr in group.prs)
          if (!oldExtras.contains(pr.number)) pr,
      ];
      final seen = {for (final pr in first) pr.number};
      kept = [
        for (final pr in extras)
          if (seen.add(pr.number)) pr,
      ];
      repos.add(
        RepoPullRequests(
          repo: group.repo,
          prs: _byUpdatedDesc([...first, ...kept]),
        ),
      );
    }
    return state.copyWith(
      repos: repos,
      extraPrs: {...state.extraPrs, repoId: kept},
      hasMore: {...state.hasMore, repoId: hasMore},
      nextPage: {...state.nextPage, repoId: nextPage},
      loadingMore: {...state.loadingMore, repoId: false},
      loadMoreFailed: {...state.loadMoreFailed, repoId: false},
    );
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
  String? _scopeKey;

  /// Identity of the active review search; retained AsyncValues from another
  /// login are not valid filter input during a dependency reload.
  String? get scopeKey => _scopeKey;

  @override
  Future<Set<String>> build() async {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    _scopeKey = null;
    if (workspaceId == null) {
      return const {};
    }
    final userId = ref.watch(currentUserIdProvider);
    final login = ref.watch(currentUserLoginProvider).toLowerCase();
    final scopeKey = _prListScopeKey(workspaceId, userId);
    final key = scopeKey == null || login.isEmpty ? null : '$scopeKey|$login';
    final completer = Completer<Set<String>>();
    final repository = ref.watch(openPrListRepositoryProvider);
    final stream = repository is RpcOpenPrListRepository
        ? repository.watchReviewedByKeysForWorkspace(workspaceId)
        : Stream.fromFuture(repository.reviewedByKeysForWorkspace(workspaceId));
    final sub = stream.listen(
      (keys) {
        _scopeKey = key;
        if (key != null) {
          ref.read(lastGoodReviewedKeysProvider.notifier).stamp(key, keys);
        }
        if (!completer.isCompleted) {
          completer.complete(keys);
        } else {
          state = AsyncData(keys);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _scopeKey = key;
        if (key != null) {
          ref.read(lastGoodReviewedKeysProvider.notifier).remove(key);
        }
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        } else {
          state = AsyncError(error, stackTrace);
        }
      },
    );
    ref.onDispose(sub.cancel);
    final lastGood = key == null
        ? null
        : ref.read(lastGoodReviewedKeysProvider)[key];
    if (lastGood != null && !completer.isCompleted) {
      _scopeKey = key;
      completer.complete(lastGood);
    }
    return completer.future;
  }

  /// Server-side gh search (`reviewed-by:<server login>`): the thin client
  /// holds no token, so the host resolves the reviewed-by-me set over RPC.
  Future<Set<String>> _fetch(String workspaceId, String? key) async {
    final keys = await ref
        .read(openPrListRepositoryProvider)
        .reviewedByKeysForWorkspace(workspaceId);
    if (key != null) {
      ref.read(lastGoodReviewedKeysProvider.notifier).stamp(key, keys);
    }
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
    final userId = ref.read(currentUserIdProvider);
    final login = ref.read(currentUserLoginProvider).toLowerCase();
    final scopeKey = _prListScopeKey(workspaceId, userId);
    final key = scopeKey == null || login.isEmpty ? null : '$scopeKey|$login';
    try {
      final keys = await _fetch(workspaceId, key);
      if (!ref.mounted ||
          ref.read(activeWorkspaceIdProvider) != workspaceId ||
          ref.read(currentUserIdProvider) != userId ||
          ref.read(currentUserLoginProvider).toLowerCase() != login) {
        return;
      }
      _scopeKey = key;
      state = AsyncData(keys);
    } catch (_) {
      // Keep the last good set — the surface shows its own error affordance.
    }
  }
}

/// Overlays `reviewedByMe` onto the PRs whose `"<repoFullName>#<number>"` is in
/// [reviewedKeys], so the "reviewed by me" filter works without the list query
/// carrying per-PR review data. Only invoked while that filter is active.
List<RepoPullRequests> overlayReviewedByMe(
  List<RepoPullRequests> repos,
  Set<String> reviewedKeys,
) {
  return repos
      .map(
        (rp) => RepoPullRequests(
          repo: rp.repo,
          prs: rp.prs
              .map((pr) {
                final reviewed = reviewedKeys.contains(
                  '${pr.repoFullName}#${pr.number}',
                );
                return pr.reviewedByMe == reviewed
                    ? pr
                    : pr.copyWith(reviewedByMe: reviewed);
              })
              .toList(growable: false),
        ),
      )
      .toList(growable: false);
}

/// The classified PRs of the workspace's loaded by-repo set — the population
/// the filter menu's facet counts (via [prListPopulationProvider]) and other
/// PR surfaces (the context rail) run over.
final prListDataProvider = Provider.autoDispose<AsyncValue<PrListData>>((ref) {
  // Per forge: a GitLab repo's reviewers are matched against the viewer's
  // GitLab login. The provider reads `.value`, so the connection lookup
  // retrying does not reclassify every row as "not mine" for a frame; while
  // nothing has resolved yet nothing is filtered.
  final viewerLogins = ref.watch(viewerLoginsProvider);
  final queue = ref.watch(prsByRepoProvider);
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  final userId = ref.watch(currentUserIdProvider);
  final expectedScope = workspaceId == null
      ? null
      : _prListScopeKey(workspaceId, userId);
  final sourceScope = queue.value?.scopeKey;
  final scopedQueue = sourceScope != null && sourceScope != expectedScope
      ? const AsyncLoading<PrsByRepoState>()
      : queue;
  if (scopedQueue.hasError) {
    return AsyncError(scopedQueue.error!, scopedQueue.stackTrace!);
  }
  final byRepoAsync = scopedQueue.whenData((s) => s.repos);

  // Only fetch the optional reviewed-by search while its filter is active.
  final reviewedByMeActive = ref.watch(
    prListFiltersProvider.select((filters) => filters.reviewedByMe),
  );
  final reviewed = reviewedByMeActive
      ? ref.watch(reviewedByMePrKeysProvider)
      : null;
  if (reviewed != null) {
    final login = ref.watch(currentUserLoginProvider).toLowerCase();
    final expectedReviewedScope = expectedScope == null || login.isEmpty
        ? null
        : '$expectedScope|$login';
    if (expectedReviewedScope == null ||
        ref.read(reviewedByMePrKeysProvider.notifier).scopeKey !=
            expectedReviewedScope ||
        !reviewed.hasValue && !reviewed.hasError) {
      return const AsyncLoading<PrListData>();
    }
    if (reviewed.hasError) {
      return AsyncError(reviewed.error!, reviewed.stackTrace!);
    }
  }
  final reviewedKeys = reviewed?.value ?? const <String>{};

  return byRepoAsync.whenData((repos) {
    final byRepo = reviewedByMeActive
        ? overlayReviewedByMe(repos, reviewedKeys)
        : repos;
    return const ClassifyPullRequestsUseCase().execute(
      byRepo: byRepo,
      viewerLoginByForge: viewerLogins.isEmpty ? null : viewerLogins,
    );
  });
});

/// Every PR loaded into the queue, flattened across repos — the population
/// the filter menu's facet counts and the filter bar run over.
final prListPopulationProvider = Provider.autoDispose<List<PullRequest>>((ref) {
  final snapshot = ref.watch(prListDataProvider);
  final data = snapshot.hasError ? null : snapshot.value;
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
