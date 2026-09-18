import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Provides profile search text, keyed by `user:<login>` or `team:<org>/<slug>`.
final userProfileSearchProvider =
    NotifierProvider.family<UserProfileSearchNotifier, String, String>(
      UserProfileSearchNotifier.new,
    );

/// Fetches all-state workspace PR activity and delivery metrics for a user.
final userProfileActivityProvider = FutureProvider.autoDispose
    .family<GitHubProfileActivity, String>((ref, login) async {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null ||
          login.trim().isEmpty ||
          ref.watch(isDemoServerProvider)) {
        return GitHubProfileActivity.empty;
      }
      return ref
          .watch(openPrListRepositoryProvider)
          .profileActivityForUser(workspaceId, login);
    });

/// Fetches all-state workspace PR activity and delivery metrics for a team.
final teamProfileActivityProvider = FutureProvider.autoDispose
    .family<GitHubProfileActivity, ({String organization, String slug})>((
      ref,
      team,
    ) async {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null ||
          team.organization.trim().isEmpty ||
          team.slug.trim().isEmpty ||
          ref.watch(isDemoServerProvider)) {
        return GitHubProfileActivity.empty;
      }
      return ref
          .watch(openPrListRepositoryProvider)
          .profileActivityForTeam(workspaceId, team.organization, team.slug);
    });

/// State rail for a GitHub profile's all-state PR browser.
enum ProfilePrStateFilter {
  /// Every returned PR.
  all,

  /// Open PRs, including drafts.
  open,

  /// Merged PRs.
  merged,

  /// Closed without merging.
  closed,
}

/// Profile-local PR state, keyed by `user:<login>` or `team:<org>/<slug>`.
class ProfilePrStateFilterNotifier extends Notifier<ProfilePrStateFilter> {
  /// Creates a state filter for [profileKey].
  ProfilePrStateFilterNotifier(this.profileKey);

  /// Stable profile key.
  final String profileKey;

  @override
  ProfilePrStateFilter build() => ProfilePrStateFilter.all;

  /// Selects [value].
  void set(ProfilePrStateFilter value) => state = value;
}

/// Provides one profile's selected PR state.
final profilePrStateFilterProvider =
    NotifierProvider.family<
      ProfilePrStateFilterNotifier,
      ProfilePrStateFilter,
      String
    >(ProfilePrStateFilterNotifier.new);
