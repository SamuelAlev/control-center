import 'package:cc_data/cc_data.dart' show pullRequestFromWireDto;
import 'package:cc_domain/cc_domain.dart' show PullRequestDto;
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

/// The state axis a user profile filters its PR list on. Open PRs come from the
/// already-loaded workspace queue (`prsByAuthorInWorkspaceProvider`); merged
/// and closed PRs are fetched on demand — only once their card is activated —
/// via [userClosedPrsProvider].
enum ProfilePrState {
  /// Open, non-draft pull requests.
  open,

  /// Open draft pull requests (kept distinct from open and from closed).
  draft,

  /// Merged pull requests.
  merged,

  /// Closed-without-merging pull requests.
  closed,
}

/// Classifies [pr] onto the profile's state axis. Drafts are only their own
/// bucket while still open; once closed (or merged) a PR is closed/merged, not
/// draft — so the Draft and Closed cards never overlap. Merge is detected via
/// `mergedAt` (GitHub reports merged PRs as `state: closed`).
ProfilePrState profilePrStateOf(PullRequest pr) {
  if (pr.isOpen) {
    return pr.isDraft ? ProfilePrState.draft : ProfilePrState.open;
  }
  if (pr.mergedAt != null) {
    return ProfilePrState.merged;
  }
  return ProfilePrState.closed;
}

/// Per-login set of active PR states on a user profile. Opens showing only
/// open PRs; merged/closed are opt-in (multi-select), so the operator can view
/// e.g. open + merged together. Keyed by login so each profile keeps its own
/// selection.
class UserProfileStateFilterNotifier extends Notifier<Set<ProfilePrState>> {
  /// Creates a [UserProfileStateFilterNotifier] for [login].
  UserProfileStateFilterNotifier(this.login);

  /// The GitHub login this filter belongs to.
  final String login;

  @override
  Set<ProfilePrState> build() => const {ProfilePrState.open};

  /// Toggles [profileState] in or out of the active set.
  void toggle(ProfilePrState profileState) {
    final next = Set<ProfilePrState>.of(state);
    if (!next.add(profileState)) {
      next.remove(profileState);
    }
    state = next;
  }
}

/// Provides the active PR-state set for a profile, keyed by login.
final userProfileStateFilterProvider = NotifierProvider.family<
    UserProfileStateFilterNotifier, Set<ProfilePrState>, String>(
  UserProfileStateFilterNotifier.new,
);

/// Per-login free-text search over a profile's PR titles. The profile is
/// already scoped to one author, so this filters the loaded set locally (by
/// title / number) rather than issuing a server search.
class UserProfileSearchNotifier extends Notifier<String> {
  /// Creates a [UserProfileSearchNotifier] for [login].
  UserProfileSearchNotifier(this.login);

  /// The GitHub login this search belongs to.
  final String login;

  @override
  String build() => '';

  /// Replaces the search text.
  void set(String value) => state = value;

  /// Clears the search text.
  void clear() => state = '';
}

/// Provides the profile search text, keyed by login.
final userProfileSearchProvider =
    NotifierProvider.family<UserProfileSearchNotifier, String, String>(
  UserProfileSearchNotifier.new,
);

/// True PR counts authored by `login` across the active workspace's
/// GitHub-linked repos, split into the four state-rail buckets (open / draft /
/// merged / closed-unmerged). Read from GitHub search `issueCount`s in one
/// batched request, so they are accurate regardless of how many PRs exist —
/// unlike counting the (100/repo-capped) fetched history in
/// [userClosedPrsProvider]. Watched eagerly by the rail but rendered
/// non-blocking: the cards show while this resolves. Zeros when unauthed / no
/// repos.
final userPrCountsProvider = FutureProvider.family<
    ({int open, int draft, int merged, int closed}), String>((ref, login) async {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null || login.isEmpty) {
    return (open: 0, draft: 0, merged: 0, closed: 0);
  }
  // Counted SERVER-SIDE on the host's gh client (the thin client holds no
  // token); the host resolves the workspace's linked repos itself.
  final data = await ref
      .watch(rpcClientProvider)
      .call('pr.countsByAuthorForWorkspace', {'login': login});
  return (
    open: (data['open'] as num?)?.toInt() ?? 0,
    draft: (data['draft'] as num?)?.toInt() ?? 0,
    merged: (data['merged'] as num?)?.toInt() ?? 0,
    closed: (data['closed'] as num?)?.toInt() ?? 0,
  );
});

/// The author's merged + closed history, grouped by repo, with per-repo
/// pagination so the queue can page past the first 100 via "load more".
class UserClosedPrsState {
  /// Creates a [UserClosedPrsState].
  const UserClosedPrsState({
    required this.repos,
    required this.hasMore,
    required this.nextPage,
    required this.loadingMore,
  });

  /// Repos (with matches) and their loaded merged/closed PRs.
  final List<RepoPullRequests> repos;

  /// Whether more pages remain, keyed by repo id.
  final Map<String, bool> hasMore;

  /// The next page to fetch, keyed by repo id.
  final Map<String, int> nextPage;

  /// Whether a "load more" is in flight, keyed by repo id.
  final Map<String, bool> loadingMore;

  /// The not-yet-loaded / no-repos resting state.
  static const empty = UserClosedPrsState(
    repos: [],
    hasMore: {},
    nextPage: {},
    loadingMore: {},
  );

  /// Returns a copy with the given fields replaced.
  UserClosedPrsState copyWith({
    List<RepoPullRequests>? repos,
    Map<String, bool>? hasMore,
    Map<String, int>? nextPage,
    Map<String, bool>? loadingMore,
  }) {
    return UserClosedPrsState(
      repos: repos ?? this.repos,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// The merged + closed pull requests authored by `login` across the active
/// workspace's GitHub-linked repos, grouped by repo and most-recently-updated
/// first, with per-repo "load more" pagination.
///
/// Fetched lazily: the provider is only watched once the Merged or Closed card
/// is activated, so a profile issues no history requests until the operator
/// asks for them. One `/search/issues` page per repo up front; [loadMore] pages
/// in the next 100 on demand. Merged/closed PRs are not metric-enriched (no
/// diff-size / check chips), matching the non-open search shape. Repos with no
/// matches are omitted. The accurate totals (which can exceed what's loaded)
/// come from [userPrCountsProvider], not this list's length.
class UserClosedPrsNotifier extends AsyncNotifier<UserClosedPrsState> {
  /// Creates a [UserClosedPrsNotifier] for [login] (the family key).
  UserClosedPrsNotifier(this.login);

  /// The GitHub login whose merged/closed history this notifier holds.
  final String login;

  @override
  Future<UserClosedPrsState> build() async {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null || login.isEmpty) {
      return UserClosedPrsState.empty;
    }
    // First page comes SERVER-SIDE over RPC (the thin client holds no GitHub
    // token); join the per-repo groups back to the workspace's [Repo] entities.
    // `loadMore` still pages via the client GitHub client and so is desktop-only
    // until a paginated server op lands.
    final repos = githubLinkedReposOf(
      ref.watch(reposForWorkspaceProvider(workspaceId)),
    );
    if (repos.isEmpty) {
      return UserClosedPrsState.empty;
    }
    final reposById = {for (final r in repos) r.id: r};

    final groups = await ref
        .watch(openPrListRepositoryProvider)
        .closedByAuthorForWorkspace(workspaceId, login);

    final hasMore = <String, bool>{};
    final nextPage = <String, int>{};
    final list = <RepoPullRequests>[];
    for (final g in groups) {
      final repo = reposById[g.repoId];
      if (repo == null || g.prs.isEmpty) {
        continue;
      }
      final prs = [...g.prs]
        ..sort(
          (a, b) => (b.updatedAt ?? _epoch).compareTo(a.updatedAt ?? _epoch),
        );
      list.add(RepoPullRequests(repo: repo, prs: prs));
      hasMore[repo.id] = g.hasMore;
      nextPage[repo.id] = 2;
    }
    list.sort((a, b) => _topUpdated(b).compareTo(_topUpdated(a)));
    return UserClosedPrsState(
      repos: list,
      hasMore: hasMore,
      nextPage: nextPage,
      loadingMore: const {},
    );
  }

  /// Pages in the next batch of merged/closed PRs for [repoId], merging them
  /// (deduped by number) into that repo's group. No-ops when nothing more
  /// remains or a load is already in flight.
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

      // The next page is fetched SERVER-SIDE over RPC (the thin client holds no
      // GitHub token); the host validates the repo is linked to the workspace.
      final data = await ref
          .read(rpcClientProvider)
          .call('pr.closedByAuthorPageForRepo', {
            'owner': repoEntry.repo.githubOwner,
            'repo': repoEntry.repo.githubRepoName,
            'login': login,
            'page': page,
          });
      final hasMore = data['has_more'] as bool? ?? false;

      final newPrs = [
        for (final m in (data['prs'] as List? ?? const []))
          pullRequestFromWireDto(
            PullRequestDto.fromJson((m as Map).cast<String, dynamic>()),
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

/// The author's paginating merged/closed history, keyed by login. See
/// [UserClosedPrsNotifier].
final userClosedPrsProvider = AsyncNotifierProvider.family<
    UserClosedPrsNotifier, UserClosedPrsState, String>(
  UserClosedPrsNotifier.new,
);

DateTime _topUpdated(RepoPullRequests group) =>
    group.prs.isNotEmpty ? (group.prs.first.updatedAt ?? _epoch) : _epoch;
