import 'package:cc_infra/cc_infra_web.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/media/disk_cached_network_image.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/user_profile_pr_queue.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/user_profile_search_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/providers/github_user_profile_provider.dart';
import 'package:control_center/shared/providers/last_checked_provider.dart';
import 'package:control_center/shared/utils/github_avatar_url.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/github_user_profile_header.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A GitHub user's profile: their header (avatar, metadata, contribution
/// heatmap) over a browse-only PR queue that mirrors the main PR list — dense
/// rows, peek, per-repo accordions and keyboard navigation. A state rail
/// (Open / Merged / Closed) filters the queue, with merged/closed history
/// fetched on demand and a search field narrows by title.
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

  /// Whether a manual refresh is in flight, so the refresh icon spins until
  /// BOTH the forced server-side PR sweep and the profile re-fetch settle.
  bool _refreshing = false;

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Forces an immediate server-side GitHub sweep of the workspace's PRs (the
  /// live open-list subscription never re-enters a loading state on its own)
  /// and re-fetches the GitHub profile, spinning the refresh icon until every
  /// fetch settles.
  Future<void> _refresh() async {
    if (_refreshing) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      await Future.wait([
        ref.read(prsByRepoProvider.notifier).forceRefresh(),
        ref.refresh(githubUserProfileProvider(widget.login).future),
      ]);
    } catch (_) {
      // Each surface keeps its last data / shows its own error; the spin
      // just stops.
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final login = widget.login;
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(githubUserProfileProvider(login));
    final displayName = profileAsync.value?.name.isNotEmpty == true
        ? profileAsync.value!.name
        : '@$login';

    // Stamp freshness whenever the workspace PR data (the profile's primary
    // source) lands — covers both first load and post-refresh.
    ref.listen(prsByRepoProvider, (_, next) {
      if (next is AsyncData && !next.isLoading) {
        ref.read(lastCheckedProvider.notifier).stamp('user-profile:$login');
      }
    });
    final lastChecked = ref.watch(
      lastCheckedProvider.select((m) => m['user-profile:$login']),
    );
    final isRefreshing =
        _refreshing ||
        ref.watch(prsByRepoProvider).isLoading ||
        profileAsync.isLoading;

    return PageWrapper(
      title: displayName,
      actions: [
        RefreshControl(
          lastChecked: lastChecked,
          isLoading: isRefreshing,
          tooltip: l10n.refresh,
          onRefresh: _refresh,
        ),
        UserProfileSearchField(login: login, focusNode: _searchFocusNode),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeaderCard(login: login, profileAsync: profileAsync),
            const SizedBox(height: 20),
            Expanded(
              child: UserProfilePrQueue(
                login: login,
                searchFocusNode: _searchFocusNode,
              ),
            ),
          ],
        ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        border: Border.all(color: tokens.borderSecondary),
        borderRadius: BorderRadius.circular(4),
      ),
      child: profileAsync.when(
        loading: () =>
            const SizedBox(height: 80, child: Center(child: CcSpinner())),
        error: (_, _) => Text(
          '@$login',
          style: CcTypography.body.copyWith(color: tokens.textPrimary),
        ),
        data: (profile) {
          if (profile == null) {
            return Text(
              '@$login',
              style: CcTypography.body.copyWith(color: tokens.textPrimary),
            );
          }
          return GitHubUserProfileHeader(
            profile: profile,
            avatarSize: 64,
            heatmapWeeks: 52,
            heatmapInline: true,
            infoFooter:
                _hasMetadata(profile) || profile.organizations.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_hasMetadata(profile)) _MetadataRow(profile: profile),
                      if (profile.organizations.isNotEmpty) ...[
                        if (_hasMetadata(profile)) const SizedBox(height: 8),
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
    final tokens = context.designSystem!;
    final items = <Widget>[];

    void addItem(IconData icon, String text, {VoidCallback? onTap}) {
      if (items.isNotEmpty) {
        items.add(const SizedBox(width: 16));
      }
      items.add(
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: tokens.textTertiary),
              const SizedBox(width: 4),
              if (onTap != null)
                CcLinkText(
                  text,
                  style: CcTypography.caption
                      .copyWith(color: tokens.textTertiary)
                      .copyWith(color: tokens.textPrimary)
                      .withLinkUnderline(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  text,
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
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
      addItem(AppIcons.mapPin, profile.location!);
    }
    if (profile.company?.isNotEmpty == true) {
      // GitHub links an @-prefixed company to that org/user profile; a plain
      // company string is free text and stays non-interactive.
      final company = profile.company!;
      final handle = company.startsWith('@')
          ? company.substring(1).trim()
          : null;
      addItem(
        AppIcons.building2,
        company,
        onTap: handle == null || handle.isEmpty
            ? null
            : () => openExternalUrl('https://github.com/$handle'),
      );
    }
    if (profile.websiteUrl?.isNotEmpty == true) {
      final url = profile.websiteUrl!;
      final display = url
          .replaceFirst(RegExp(r'^https?://'), '')
          .replaceFirst(RegExp(r'/$'), '');
      addItem(AppIcons.link, display, onTap: () => openExternalUrl(url));
    }
    if (profile.twitterUsername?.isNotEmpty == true) {
      addItem(
        AppIcons.atSign,
        '@${profile.twitterUsername}',
        onTap: () =>
            openExternalUrl('https://twitter.com/${profile.twitterUsername}'),
      );
    }

    return Wrap(spacing: 0, runSpacing: 8, children: items);
  }
}

class _OrgRow extends StatelessWidget {
  const _OrgRow({required this.organizations});

  final List<GitHubOrganization> organizations;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: organizations.map((org) {
        return GestureDetector(
          onTap: org.url.isNotEmpty ? () => openExternalUrl(org.url) : null,
          child: CcTooltip(
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
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CcImageFade(
                          image: ResizeImage(
                            DiskCachedNetworkImage(
                              MediaProxyScope.urlOf(
                                context,
                                sizedGitHubAvatarUrl(
                                  org.avatarUrl,
                                  16,
                                  MediaQuery.devicePixelRatioOf(context),
                                ),
                              ),
                            ),
                            width: (16 * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                            height:
                                (16 * MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                          ),
                          fit: BoxFit.cover,
                          placeholder: ColoredBox(color: tokens.bgSecondary),
                          errorBuilder: (_, _) => Icon(
                            AppIcons.building2,
                            size: 14,
                            color: tokens.textTertiary,
                          ),
                        ),
                      ),
                    )
                  else
                    Icon(
                      AppIcons.building2,
                      size: 14,
                      color: tokens.textTertiary,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    org.name.isNotEmpty ? org.name : org.login,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    AppIcons.externalLink,
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
