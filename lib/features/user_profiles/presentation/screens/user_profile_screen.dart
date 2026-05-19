import 'package:control_center/core/network/models/github_user_profile.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/user_profile_pr_queue.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/user_profile_search_field.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/user_profile_state_rail.dart';
import 'package:control_center/shared/providers/github_user_profile_provider.dart';
import 'package:control_center/shared/widgets/github_user_profile_header.dart';
import 'package:control_center/shared/widgets/github_user_status_badge.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// A GitHub user's profile: their header (avatar, metadata, contribution
/// heatmap) over a browse-only PR queue that mirrors the main PR list — dense
/// rows, peek, per-repo accordions, and keyboard navigation. A state rail
/// (Open / Merged / Closed) filters the queue, with merged/closed history
/// fetched on demand, and a search field narrows by title.
class UserProfileScreen extends ConsumerStatefulWidget {
  /// Creates a [UserProfileScreen] for [login].
  const UserProfileScreen({super.key, required this.login});

  /// The GitHub login whose profile is shown.
  final String login;

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  // Owned here (not in the queue) so it survives the queue's ProviderScope and
  // the `/` + ⌘F shortcuts can focus the field, which lives in the header.
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'profile-pr-search');

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final login = widget.login;
    final profileAsync = ref.watch(githubUserProfileProvider(login));
    final displayName = profileAsync.value?.name.isNotEmpty == true
        ? profileAsync.value!.name
        : '@$login';

    return PageWrapper(
      title: displayName,
      actions: [
        UserProfileSearchField(login: login, focusNode: _searchFocusNode),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          _ProfileHeaderCard(login: login, profileAsync: profileAsync),
          const SizedBox(height: 24),
          UserProfileStateRail(login: login),
          const SizedBox(height: 20),
          UserProfilePrQueue(login: login, searchFocusNode: _searchFocusNode),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends ConsumerWidget {
  const _ProfileHeaderCard({required this.login, required this.profileAsync});

  final String login;
  final AsyncValue<GitHubUserProfile?> profileAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        border: Border.all(color: tokens.borderSecondary),
        borderRadius: BorderRadius.circular(4),
      ),
      child: profileAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: FCircularProgress()),
        ),
        error: (_, _) => Text(
          '@$login',
          style: theme.textTheme.titleSmall?.copyWith(color: tokens.textPrimary),
        ),
        data: (profile) {
          if (profile == null) {
            return Text(
              '@$login',
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: tokens.textPrimary),
            );
          }
          final status = profile.status;
          final showStatus = status != null && statusHasContent(status);

          return GitHubUserProfileHeader(
            profile: profile,
            avatarSize: 64,
            heatmapWeeks: 52,
            heatmapInline: true,
            nameTrailing: showStatus
                ? GitHubUserStatusBadge(status: status)
                : null,
            infoFooter: _hasMetadata(profile) || profile.organizations.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_hasMetadata(profile))
                        _MetadataRow(profile: profile),
                      if (profile.organizations.isNotEmpty) ...[
                        if (_hasMetadata(profile))
                          const SizedBox(height: 8),
                        _OrgRow(organizations: profile.organizations),
                      ],
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  bool _hasMetadata(GitHubUserProfile p) =>
      (p.location?.isNotEmpty ?? false) ||
      (p.company?.isNotEmpty ?? false) ||
      (p.websiteUrl?.isNotEmpty ?? false) ||
      (p.twitterUsername?.isNotEmpty ?? false);
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.profile});

  final GitHubUserProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final items = <Widget>[];

    void addItem(IconData icon, String text, {VoidCallback? onTap}) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 16));
      items.add(
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: colors.mutedForeground),
              const SizedBox(width: 4),
              Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: onTap != null ? colors.primary : colors.mutedForeground,
                  decoration: onTap != null ? TextDecoration.underline : null,
                  decorationColor: colors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    if (profile.location?.isNotEmpty == true) {
      addItem(LucideIcons.mapPin, profile.location!);
    }
    if (profile.company?.isNotEmpty == true) {
      addItem(LucideIcons.building2, profile.company!);
    }
    if (profile.websiteUrl?.isNotEmpty == true) {
      final url = profile.websiteUrl!;
      final display = url
          .replaceFirst(RegExp(r'^https?://'), '')
          .replaceFirst(RegExp(r'/$'), '');
      addItem(
        LucideIcons.link,
        display,
        onTap: () => launchUrl(Uri.parse(url)),
      );
    }
    if (profile.twitterUsername?.isNotEmpty == true) {
      addItem(
        LucideIcons.atSign,
        '@${profile.twitterUsername}',
        onTap: () => launchUrl(
          Uri.parse('https://twitter.com/${profile.twitterUsername}'),
        ),
      );
    }

    return Wrap(
      spacing: 0,
      runSpacing: 8,
      children: items,
    );
  }
}

class _OrgRow extends StatelessWidget {
  const _OrgRow({required this.organizations});

  final List<GitHubOrganization> organizations;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: organizations.map((org) {
        return GestureDetector(
          onTap: org.url.isNotEmpty
              ? () => launchUrl(Uri.parse(org.url))
              : null,
          child: Tooltip(
            message: org.name.isNotEmpty ? org.name : org.login,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.bgPrimary,
                border: Border.all(color: tokens.borderSecondary),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (org.avatarUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Image.network(
                        org.avatarUrl,
                        width: 16,
                        height: 16,
                        errorBuilder: (_, _, _) => Icon(
                          LucideIcons.building2,
                          size: 14,
                          color: tokens.textTertiary,
                        ),
                      ),
                    )
                  else
                    Icon(LucideIcons.building2, size: 14,
                        color: tokens.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    org.name.isNotEmpty ? org.name : org.login,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.externalLink,
                    size: 10,
                    color: tokens.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
