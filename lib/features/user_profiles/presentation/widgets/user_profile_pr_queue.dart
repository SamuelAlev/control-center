import 'package:control_center/features/user_profiles/presentation/widgets/github_profile_pr_queue.dart';
import 'package:control_center/features/user_profiles/providers/user_profile_pr_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A GitHub user's all-state pull-request browser.
class UserProfilePrQueue extends ConsumerWidget {
  /// Creates a user profile PR queue.
  const UserProfilePrQueue({
    super.key,
    required this.login,
    required this.searchFocusNode,
  });

  /// Profile login.
  final String login;

  /// Search focus target used by `/` and ⌘F.
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GitHubProfilePrQueue(
      profileKey: 'user:${login.toLowerCase()}',
      activity: ref.watch(userProfileActivityProvider(login)),
      emptyMessage: AppLocalizations.of(context).noPrsByUserInWorkspace(login),
      searchFocusNode: searchFocusNode,
    );
  }
}

/// A GitHub team's all-state pull-request browser.
class TeamProfilePrQueue extends ConsumerWidget {
  /// Creates a team profile PR queue.
  const TeamProfilePrQueue({
    super.key,
    required this.organization,
    required this.slug,
    required this.searchFocusNode,
  });

  /// Owning organization login.
  final String organization;

  /// Team slug.
  final String slug;

  /// Search focus target used by `/` and ⌘F.
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = (organization: organization, slug: slug);
    return GitHubProfilePrQueue(
      profileKey: 'team:${organization.toLowerCase()}/${slug.toLowerCase()}',
      activity: ref.watch(teamProfileActivityProvider(team)),
      emptyMessage: AppLocalizations.of(
        context,
      ).noPrsByTeamInWorkspace('@$organization/$slug'),
      searchFocusNode: searchFocusNode,
    );
  }
}
