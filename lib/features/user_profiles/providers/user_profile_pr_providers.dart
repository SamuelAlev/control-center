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

/// The merged + closed pull requests authored by `login` across the active
/// workspace's GitHub-linked repos, grouped by repo and most-recently-updated
/// first.
///
/// Fetched lazily: the provider is only watched once the Merged or Closed card
/// is activated, so a profile issues no history requests until the operator
/// asks for them. One `/search/issues` request per repo; merged/closed PRs are
/// not metric-enriched (no diff-size / check chips), matching the non-open
/// search shape. Repos with no matches are omitted.
final userClosedPrsProvider =
    FutureProvider.family<List<RepoPullRequests>, String>((ref, login) async {
  final isAuthed = ref.watch(isGitHubAuthenticatedProvider);
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (!isAuthed || workspaceId == null || login.isEmpty) {
    return const [];
  }
  final repos = githubLinkedReposOf(
    ref.watch(reposForWorkspaceProvider(workspaceId)),
  );
  if (repos.isEmpty) {
    return const [];
  }

  final client = ref.watch(githubApiClientProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  final groups = await Future.wait(
    repos.map((repo) async {
      try {
        final items = await client.pr.searchClosedPullRequestsByAuthor(
          repo.githubOwner,
          repo.githubRepoName,
          login,
          cancelToken: cancelToken,
        );
        if (items.isEmpty) {
          return null;
        }
        final prs =
            items
                .map(
                  (gh) =>
                      pullRequestFromGitHub(gh, repoFullName: repo.fullName),
                )
                .toList()
              ..sort(
                (a, b) => (b.updatedAt ?? _epoch).compareTo(a.updatedAt ?? _epoch),
              );
        return RepoPullRequests(repo: repo, prs: prs);
      } catch (_) {
        // Fail soft per repo so one inaccessible repo never sinks the rest.
        return null;
      }
    }),
  );

  return groups.whereType<RepoPullRequests>().toList()
    ..sort((a, b) => _topUpdated(b).compareTo(_topUpdated(a)));
});

DateTime _topUpdated(RepoPullRequests group) =>
    group.prs.isNotEmpty ? (group.prs.first.updatedAt ?? _epoch) : _epoch;
