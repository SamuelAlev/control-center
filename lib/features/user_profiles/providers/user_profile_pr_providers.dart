import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/data/mappers/pr_review_mapper.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:dio/dio.dart';
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
  final isAuthed = ref.watch(isGitHubAuthenticatedProvider);
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (!isAuthed || workspaceId == null || login.isEmpty) {
    return (open: 0, draft: 0, merged: 0, closed: 0);
  }
  final repos = githubLinkedReposOf(
    ref.watch(reposForWorkspaceProvider(workspaceId)),
  );
  if (repos.isEmpty) {
    return (open: 0, draft: 0, merged: 0, closed: 0);
  }

  final client = ref.watch(githubApiClientProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  return client.graphql.prCountsByAuthor(
    login: login,
    repos: repos
        .map((r) => (owner: r.githubOwner, name: r.githubRepoName))
        .toList(),
    cancelToken: cancelToken,
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

  CancelToken? _cancelToken;

  @override
  Future<UserClosedPrsState> build() async {
    final isAuthed = ref.watch(isGitHubAuthenticatedProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (!isAuthed || workspaceId == null || login.isEmpty) {
      return UserClosedPrsState.empty;
    }
    final repos = githubLinkedReposOf(
      ref.watch(reposForWorkspaceProvider(workspaceId)),
    );
    if (repos.isEmpty) {
      return UserClosedPrsState.empty;
    }

    final client = ref.watch(githubApiClientProvider);
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    ref.onDispose(cancelToken.cancel);

    final hasMore = <String, bool>{};
    final nextPage = <String, int>{};

    final groups = await Future.wait(
      repos.map((repo) async {
        try {
          final result = await client.pr.searchClosedPullRequestsByAuthor(
            repo.githubOwner,
            repo.githubRepoName,
            login,
            cancelToken: cancelToken,
          );
          if (result.items.isEmpty) {
            return null;
          }
          final prs =
              result.items
                  .map(
                    (gh) =>
                        pullRequestFromGitHub(gh, repoFullName: repo.fullName),
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      (b.updatedAt ?? _epoch).compareTo(a.updatedAt ?? _epoch),
                );
          hasMore[repo.id] = result.hasMore;
          nextPage[repo.id] = 2;
          return RepoPullRequests(repo: repo, prs: prs);
        } catch (_) {
          // Fail soft per repo so one inaccessible repo never sinks the rest.
          return null;
        }
      }),
    );

    final list = groups.whereType<RepoPullRequests>().toList()
      ..sort((a, b) => _topUpdated(b).compareTo(_topUpdated(a)));
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
      final client = ref.read(githubApiClientProvider);

      final result = await client.pr.searchClosedPullRequestsByAuthor(
        repoEntry.repo.githubOwner,
        repoEntry.repo.githubRepoName,
        login,
        page: page,
        cancelToken: _cancelToken,
      );

      final newPrs = result.items
          .map(
            (gh) =>
                pullRequestFromGitHub(gh, repoFullName: repoEntry.repo.fullName),
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

/// The author's paginating merged/closed history, keyed by login. See
/// [UserClosedPrsNotifier].
final userClosedPrsProvider = AsyncNotifierProvider.family<
    UserClosedPrsNotifier, UserClosedPrsState, String>(
  UserClosedPrsNotifier.new,
);

DateTime _topUpdated(RepoPullRequests group) =>
    group.prs.isNotEmpty ? (group.prs.first.updatedAt ?? _epoch) : _epoch;
