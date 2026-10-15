part of 'app_sidebar.dart';

/// Sidebar footer: theme toggle and Settings.
class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.workspaceId, this.collapsed = false});

  final String workspaceId;

  /// Rail mode: the text-only [OfflinePendingPill] doesn't fit the 54px rail,
  /// so it's dropped.
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The scope's deferred flag wins over the constructor's: the pill is also
    // dropped while the width is animating, where it would clip.
    final railMode =
        (CcSidebarScope.collapsedOf(context) ?? collapsed) ||
        (CcSidebarScope.transitioningOf(context) ?? false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SidebarHairline(),
        if (!railMode) const OfflinePendingPill(),
        // sm: the divider brings 4px below itself; 4+8=12px matches the
        // body's md vertical container padding above the first group.
        const SizedBox(height: AppSpacing.sm),
        // A label-less group gives the footer items the same 4px inter-item
        // rhythm as the body's groups. Service status leads it — the external
        // services it watches are not workspace content either, so it follows
        // the operator like the per-USER pillars below. Newsfeed lives here —
        // not in the workspace group — because the feed list is per-USER: it
        // follows the signed-in human across workspaces, like Observability
        // and Settings rather than any workspace's content.
        CcSidebarGroup(
          children: [
            // Always mounted and never selected: a status surface, not a
            // destination — tapping it opens the flyout to the right.
            const ServiceStatusSidebarEntry(),
            _ShellNavItem(
              icon: AppIcons.newspaper,
              label: l10n.newsfeed,
              logicalPath: '/newsfeed',
              match: ShellNavMatch.prefix,
              target: newsfeedRoute(workspaceId),
            ),
            _ShellNavItem(
              icon: AppIcons.gauge,
              label: l10n.navObservability,
              logicalPath: '/observability',
              match: ShellNavMatch.prefix,
              target: observabilityRoute(workspaceId),
            ),
            _ShellNavItem(
              icon: AppIcons.settings,
              label: l10n.navSettings,
              logicalPath: '/settings',
              match: ShellNavMatch.prefix,
              // The settings landing is Appearance, the first item in You.
              target: settingsAppearanceRoute(workspaceId),
            ),
          ],
        ),
      ],
    );
  }
}
