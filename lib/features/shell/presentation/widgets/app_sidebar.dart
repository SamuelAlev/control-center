import 'dart:async';

import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/service_status/presentation/widgets/service_status_indicator.dart';
import 'package:control_center/features/settings/presentation/widgets/settings_sidebar_nav.dart';
import 'package:control_center/features/shell/presentation/widgets/app_sidebar_header.dart';
import 'package:control_center/features/shell/presentation/widgets/offline_pending_pill.dart';
import 'package:control_center/features/shell/presentation/widgets/sidebar_chrome.dart';
import 'package:control_center/features/shell/providers/shell_route_providers.dart';
import 'package:control_center/features/shell/providers/sidebar_providers.dart';
import 'package:control_center/features/ticketing/presentation/widgets/new_project_dialog.dart';
import 'package:control_center/features/ticketing/presentation/widgets/project_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/calendar_day_icon.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'app_sidebar_nav_item.dart';

/// Primary application navigation, rendered as a single grouped left sidebar
/// built on cc_ui's [CcSidebar] / [CcSidebarGroup] / [CcSidebarItem] /
/// [CcSidebarBranch].
///
/// Replaces the previous "layered topbar" (title bar + main pill row +
/// conditional settings pill row). The workspace switcher and a search
/// (command-palette) affordance live in the header; the per-user pillars
/// (newsfeed, observability) + settings live in the footer; workspace
/// destinations sit in the body with no section header, always expanded.
///
/// Settings is a drill-in rather than a second sidebar: on a settings route
/// everything below the header slides over to the settings destinations
/// ([SettingsSidebarNav]) behind an "Exit settings" row, and back out again on
/// leaving. The header stays put so the workspace switcher never moves.
///
/// Takes no route parameters on purpose. The sidebar reads the router through
/// [routerPathProvider] and its derivations, so a navigation rebuilds only the
/// rows whose highlight changed (each [_ShellNavItem] selects its own flag)
/// instead of this whole tree, every nav item and the space list.
class AppSidebar extends ConsumerStatefulWidget {
  /// Creates an [AppSidebar].
  const AppSidebar({super.key});

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  /// The last location outside settings — where "Exit settings" returns to.
  String? _returnLocation;

  GoRouter? _router;
  ProviderSubscription<String>? _pathSubscription;

  static bool _isSettings(String logical) => logical.startsWith('/settings');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (identical(router, _router)) {
      return;
    }
    _router = router;
    _pathSubscription?.close();
    // A listener, not a watch: remembering where settings was entered from
    // must not rebuild the sidebar on every navigation.
    _pathSubscription = ref.listenManual(
      routerPathProvider(router),
      (_, path) => _rememberReturnLocation(path),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _pathSubscription?.close();
    super.dispose();
  }

  void _rememberReturnLocation(String path) {
    if (!_isSettings(workspaceShellLogicalRoute(path))) {
      _returnLocation = path;
    }
  }

  /// Leaves settings for the page it was entered from. A deep link straight
  /// into settings, or a workspace switch made from inside it, has nothing in
  /// this workspace to return to, so it lands on the inbox.
  void _exitSettings(String workspaceId) {
    final remembered = _returnLocation;
    final target =
        remembered != null && remembered.startsWith('/workspaces/$workspaceId/')
        ? remembered
        : inboxRoute(workspaceId);
    GoRouter.of(context).go(target);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    // The shell only renders for `/workspaces/:workspaceId/…` routes, so the
    // workspace id is present; it changes only on a workspace switch.
    final workspaceId = ref.watch(routeWorkspaceIdProvider(router));
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final inSettings = ref.watch(
      shellLogicalRouteProvider(router).select(_isSettings),
    );
    if (inSettings) {
      return _buildSettings(
        context,
        workspaceId: workspaceId,
        collapsed: collapsed,
      );
    }

    return CcSidebar(
      collapsed: collapsed,
      header: AppSidebarHeader(collapsed: collapsed),
      headerGap: AppSpacing.xs,
      // No gap above the footer: the spaces list is the last thing in the body
      // and it scrolls, so a band of dead air below it just made the scrollbar
      // thumb stop short of the footer's hairline. The footer's own divider
      // already carries [AppSpacing.xs] of air on top.
      footerGap: 0,
      footer: _SidebarFooter(workspaceId: workspaceId, collapsed: collapsed),
      // The workspace nav is a fixed set of destinations, so it is pinned and
      // only the spaces list below it scrolls: one scrollbar, and its thumb
      // reports the length of the space list rather than of the whole panel.
      // No eyebrow and no caret: these destinations are always shown.
      pinnedChildren: [
        CcSidebarGroup(
          children: [
            _ShellNavItem(
              icon: AppIcons.inbox,
              label: l10n.inboxTitle,
              logicalPath: '/inbox',
              target: inboxRoute(workspaceId),
              badge: (ref, selected) =>
                  _countBadge(ref.watch(inboxCountProvider), selected),
            ),
            // The accordion's project children are full-width rows; in rail
            // mode the entry flattens to its plain icon-only nav item. The
            // slot reads the (deferred) sidebar scope itself, so the swap
            // lands exactly when the items flip their geometry.
            _TicketsNavSlot(workspaceId: workspaceId),
            _ShellNavItem(
              icon: AppIcons.gitPullRequest,
              label: l10n.pullRequests,
              logicalPath: '/pull-requests',
              target: pullRequestsRoute(workspaceId),
            ),
            _ShellNavItem(
              icon: AppIcons.calendar,
              // The Phosphor glyph hardcodes a "12"; render the signed-in
              // user's LOCAL day of month into the blank outline instead.
              iconBuilder: (color, size) =>
                  CalendarDayIcon(color: color, size: size),
              label: l10n.navCalendar,
              logicalPath: '/calendar',
              target: calendarRoute(workspaceId),
            ),
            _ShellNavItem(
              icon: AppIcons.audioLines,
              label: l10n.navMeetings,
              logicalPath: '/meetings',
              target: meetingsRoute(workspaceId),
            ),
            _ShellNavItem(
              icon: AppIcons.workflow,
              label: l10n.pipelinesScreenTitle,
              logicalPath: '/pipelines',
              target: pipelinesRoute(workspaceId),
              // A pre-reduced int feed, not the run list: the run stream
              // re-emits on every pipeline mutation (progress ticks, step
              // transitions), and its count is settled so a sub-second
              // housekeeping run can't blink the badge on and off. Watched
              // by this row alone, so a count change repaints only it.
              badge: (ref, selected) => _countBadge(
                ref.watch(runningPipelineCountProvider(workspaceId)).value ?? 0,
                selected,
              ),
            ),
            // No "Plans" destination: a plan belongs to the conversation that
            // produced it, so Plan Studio opens as an editor tab from the plan's
            // own row in the chat (see `openPlanStudio`). The `/plans` hub stays
            // a routable deep link, just not a global sidebar entry.
          ],
        ),
        // The divider carries its own [AppSpacing.xs] vertical air; with the
        // neighbouring groups' [AppSpacing.xs] padding the total 8px matches
        // the sidebar's horizontal content inset — uniform spacing all around.
        const SidebarHairline(),
      ],
      children: [
        // The conversation surface (DMs + groups) lives inline so spaces are
        // reachable directly from the global sidebar; the messaging screen
        // itself is now conversation + optional terminal (its inner sidebar is
        // gone). There is no wrapping "Conversations" group — the Direct
        // messages and Groups sections are top-level collapsible accordions in
        // their own right. Per-space highlight + status come from
        // ConversationsSidebarSection.
        //
        // In rail mode the list can't render, so spaces collapse to a single
        // icon that opens the spaces directory page — a settings-like
        // surface with its own filtered space list sidebar. The slot reads
        // the (deferred) sidebar scope itself, so the list folds into the
        // icon exactly when the nav items flip their geometry.
        _SpacesNavSlot(workspaceId: workspaceId),
      ],
    );
  }

  /// The settings drill-in: the same header, an exit row pinned above the
  /// settings destinations, and no footer (it is one exit away).
  Widget _buildSettings(
    BuildContext context, {
    required String workspaceId,
    required bool collapsed,
  }) {
    final l10n = AppLocalizations.of(context);
    return CcSidebar(
      collapsed: collapsed,
      depth: 1,
      header: AppSidebarHeader(collapsed: collapsed),
      headerGap: AppSpacing.xs,
      pinnedChildren: [
        CcSidebarGroup(
          children: [
            CcSidebarItem(
              // Mirrors under RTL: points at the edge the global nav returns to.
              icon: AppIcons.chevronLeft,
              label: l10n.exitSettings,
              onPressed: () => _exitSettings(workspaceId),
            ),
          ],
        ),
        const SidebarHairline(),
      ],
      children: [_SettingsNavSlot(workspaceId: workspaceId)],
    );
  }
}

/// The trailing count pill, or nothing at zero.
Widget? _countBadge(int count, bool selected) =>
    count > 0 ? SidebarCountBadge(count: count, selected: selected) : null;

/// The settings destinations. Its own consumer so moving between settings
/// pages rebuilds the destination list, not the drill-in around it.
class _SettingsNavSlot extends ConsumerWidget {
  const _SettingsNavSlot({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(routerPathProvider(GoRouter.of(context)));
    return SettingsSidebarNav(location: location, workspaceId: workspaceId);
  }
}

/// The Tickets entry of the global sidebar: the [_TicketsAccordion] expanded,
/// a single icon-only nav item in the rail. A dedicated widget so the swap is
/// driven by [CcSidebarScope] — the same deferred, animation-aware flag the
/// items themselves flip on — rather than the instantly-updating provider.
class _TicketsNavSlot extends StatelessWidget {
  const _TicketsNavSlot({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final collapsed = CcSidebarScope.collapsedOf(context) ?? false;
    if (!collapsed) {
      return _TicketsAccordion(workspaceId: workspaceId);
    }
    final l10n = AppLocalizations.of(context);
    return _ShellNavItem(
      icon: AppIcons.ticket,
      label: l10n.navTickets,
      logicalPath: '/tickets',
      target: ticketsRoute(workspaceId),
    );
  }
}

/// The Spaces slot of the global sidebar: the inline space list
/// ([ConversationsSidebarSection]) expanded, a single icon opening the
/// spaces directory page in the rail. Scope-driven like [_TicketsNavSlot].
class _SpacesNavSlot extends StatelessWidget {
  const _SpacesNavSlot({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final collapsed = CcSidebarScope.collapsedOf(context) ?? false;
    if (!collapsed) {
      return const ConversationsSidebarSection();
    }
    final l10n = AppLocalizations.of(context);
    return CcSidebarGroup(
      children: [
        _ShellNavItem(
          icon: AppIcons.messagesSquare,
          label: l10n.spaces,
          logicalPath: '/spaces',
          target: spacesRoute(workspaceId),
        ),
      ],
    );
  }
}

/// The "Tickets" entry rendered as a collapsible accordion: pressing the
/// header navigates to all tickets, while a trailing chevron toggles the
/// project list; the children are "All tickets", one row per (non-archived)
/// project and a "New project" action. When there is no active workspace it
/// degrades to a plain nav item.
///
/// [CcSidebarItem] is a flat row with no nesting, so the accordion is composed
/// here from a header [CcSidebarItem] plus a [CcCollapsible]-gated
/// [CcSidebarBranch] (tree rail, flush children, nested hover). The composite
/// is not itself a [CcFluidHoverTarget], so the enclosing group treats it as
/// a hover boundary: the header row and the nested branch keep their own
/// wash instead of the parent highlighting Inbox or Pull requests.
class _TicketsAccordion extends ConsumerStatefulWidget {
  const _TicketsAccordion({required this.workspaceId});

  final String workspaceId;

  @override
  ConsumerState<_TicketsAccordion> createState() => _TicketsAccordionState();
}

class _TicketsAccordionState extends ConsumerState<_TicketsAccordion> {
  // Sticky open/closed state. Seeded from the route on the first build, then
  // auto-expanded when entering the tickets/projects area — but never
  // auto-collapsed on leaving, so navigating away from "All tickets" no
  // longer snaps the accordion shut.
  bool? _expanded;

  static bool _isTicketsArea(String logical) =>
      logical == '/tickets' ||
      logical.startsWith('/tickets/') ||
      logical.startsWith('/projects/');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wsId = widget.workspaceId;
    final router = GoRouter.of(context);
    final area = shellLogicalRouteProvider(router).select(_isTicketsArea);
    // Auto-expand only when entering the tickets/projects area from
    // elsewhere; a manual collapse while already inside the area is respected
    // and leaving the area never forces it closed. A listener, so other
    // navigations never rebuild the accordion.
    ref.listen<bool>(area, (previous, inArea) {
      if (inArea && previous != true && _expanded != true) {
        setState(() => _expanded = true);
      }
    });
    final bool expanded = _expanded ?? ref.read(area);
    _expanded = expanded;

    final projects =
        (ref.watch(workspaceProjectsProvider(wsId)).asData?.value ??
                const <Project>[])
            .where((p) => p.status != ProjectStatus.archived)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CcSidebarItem(
          icon: AppIcons.ticket,
          label: l10n.navTickets,
          // The header is a group container, not a selectable leaf; the active
          // state is owned by the "All tickets" child (and project children).
          selected: false,
          badge: _ExpandChevron(
            expanded: expanded,
            onTap: () => setState(() => _expanded = !expanded),
          ),
          onPressed: () => router.go(ticketsRoute(wsId)),
        ),
        CcCollapsible(
          expanded: expanded,
          child: CcSidebarBranch(
            children: [
              _ShellNavItem(
                icon: AppIcons.list,
                label: l10n.allTickets,
                logicalPath: '/tickets',
                target: ticketsRoute(wsId),
              ),
              for (final p in projects)
                _ShellNavItem(
                  key: ValueKey(p.id),
                  icon: AppIcons.dot,
                  label: p.name,
                  logicalPath: '/projects/${p.id}',
                  match: ShellNavMatch.exact,
                  target: projectOverviewRoute(wsId, p.id),
                  badge: (_, selected) =>
                      ProjectGlyph(color: p.color, onBrandFill: selected),
                ),
              CcSidebarItem(
                icon: AppIcons.plus,
                label: l10n.newProject,
                onPressed: () => unawaited(_newProject(context, wsId)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _newProject(BuildContext context, String wsId) async {
    final router = GoRouter.of(context);
    final id = await showProjectDialog(context, workspaceId: wsId);
    if (id != null && context.mounted) {
      router.go(projectOverviewRoute(wsId, id));
    }
  }
}

/// A small rotating chevron used as the trailing affordance on the Tickets
/// accordion header. Tapping it toggles the project list without navigating.
class _ExpandChevron extends StatelessWidget {
  const _ExpandChevron({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcTappable(
      onPressed: onTap,
      semanticLabel: expanded ? l10n.collapse : l10n.expand,
      builder: (context, states) => AnimatedRotation(
        duration: CcMotion.resolveToggle(context, CcMotion.moderate),
        curve: CcMotion.standard,
        turns: expanded ? 0 : -0.25,
        child: Icon(
          AppIcons.chevronDown,
          size: 14,
          color: states.contains(WidgetState.hovered)
              ? t.textSecondary
              : t.textTertiary,
        ),
      ),
    );
  }
}

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
