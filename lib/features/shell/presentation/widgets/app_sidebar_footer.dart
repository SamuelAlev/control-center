part of 'app_sidebar.dart';

/// Sidebar footer: the per-operator surfaces, one icon strip when expanded and
/// a stack of squares in the rail, which is too narrow for a row.
class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter({required this.workspaceId, this.collapsed = false});

  final String workspaceId;

  /// Rail mode: the text-only [OfflinePendingPill] doesn't fit the 54px rail,
  /// so it's dropped.
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // The scope's deferred flag wins over the constructor's, so the strip
    // holds until the width animation lands and swaps to the stack only then.
    final rail = CcSidebarScope.collapsedOf(context) ?? collapsed;
    // The pill is also dropped while the width is animating, where it would
    // clip.
    final transitioning = CcSidebarScope.transitioningOf(context) ?? false;
    // Everything here follows the operator rather than any workspace's
    // content. Newsfeed lives here — not in the workspace group — because the
    // feed list is per-USER, and the external services service status watches
    // are not workspace content either.
    final leading = <Widget>[
      _ShellNavItem(
        icon: AppIcons.newspaper,
        label: l10n.newsfeed,
        logicalPath: '/newsfeed',
        match: ShellNavMatch.prefix,
        target: newsfeedRoute(workspaceId),
      ),
      // No libmpv (a stock Linux desktop): nothing could play.
      if (ref.watch(mediaPlaybackAvailableProvider))
        const SoundscapeSidebarEntry(),
      const FocusSidebarEntry(),
    ];
    final trailing = <Widget>[
      // Always mounted and never selected: a status surface, not a
      // destination — tapping it opens the flyout above it.
      const ServiceStatusSidebarEntry(),
      _ShellNavItem(
        icon: AppIcons.gauge,
        label: l10n.navObservability,
        logicalPath: '/observability',
        match: ShellNavMatch.prefix,
        target: observabilityRoute(workspaceId),
      ),
      SidebarHelpMenu(workspaceId: workspaceId),
      _ShellNavItem(
        icon: AppIcons.settings,
        label: l10n.navSettings,
        logicalPath: '/settings',
        match: ShellNavMatch.prefix,
        // The settings landing is Appearance, the first item in You.
        target: settingsAppearanceRoute(workspaceId),
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SidebarHairline(),
        if (!rail && !transitioning) const OfflinePendingPill(),
        // sm: the divider brings 4px below itself; 4+8=12px matches the
        // sidebar's own md padding under the strip, and the body's md vertical
        // container padding above the first group.
        const SizedBox(height: AppSpacing.sm),
        if (rail)
          CcSidebarGroup(children: [...leading, ...trailing])
        else
          CcSidebarToolbar(leading: leading, trailing: trailing),
      ],
    );
  }
}
