import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/service_status/presentation/widgets/service_status_indicator.dart';
import 'package:control_center/features/shell/presentation/widgets/app_sidebar_header.dart';
import 'package:control_center/features/shell/presentation/widgets/offline_pending_pill.dart';
import 'package:control_center/features/shell/providers/sidebar_providers.dart';
import 'package:control_center/features/ticketing/presentation/widgets/new_project_dialog.dart';
import 'package:control_center/features/ticketing/presentation/widgets/project_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/calendar_day_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Primary application navigation, rendered as a single grouped left sidebar
/// built on cc_ui's [CcSidebar] / [CcSidebarGroup] / [CcSidebarItem].
///
/// Replaces the previous "layered topbar" (title bar + main pill row +
/// conditional settings pill row). The workspace switcher and a search
/// (command-palette) affordance live in the header; the per-user pillars
/// (newsfeed, observability) + settings live in the footer; workspace
/// destinations are grouped in the body plus standalone entries.
class AppSidebar extends ConsumerWidget {
  /// Creates an [AppSidebar]. [location] is the current router location and
  /// [workspaceId] the active workspace (both sourced from the route), used to
  /// build prefixed navigation targets and resolve the active item.
  const AppSidebar({
    super.key,
    required this.location,
    required this.workspaceId,
  });

  /// The current matched router location.
  final String location;

  /// The active workspace id from the route (`:workspaceId`).
  final String workspaceId;

  /// Active-item check against the *logical* route (prefix-stripped), so it is
  /// independent of which workspace is in the URL. [logicalPath] is e.g.
  /// `/inbox` or `/tickets`.
  bool _isActive(String logicalPath, {bool exact = false}) {
    final logical = workspaceShellLogicalRoute(location);
    if (exact) {
      return logical == logicalPath;
    }
    return logical == logicalPath || logical.startsWith('$logicalPath/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final collapsed = ref.watch(sidebarCollapsedProvider);
    // A pre-reduced int feed, not the run list: the run stream re-emits on
    // every pipeline mutation (progress ticks, step transitions), which would
    // otherwise rebuild all of this chrome and its count is settled so a
    // sub-second housekeeping run can't blink the badge on and off.
    final runningPipelines =
        ref.watch(runningPipelineCountProvider(workspaceId)).value ?? 0;

    CcSidebarItem navItem({
      required IconData icon,
      required String label,
      required String logicalPath,
      required String target,
      bool exact = false,
      int badge = 0,
      Widget Function(Color color, double size)? iconBuilder,
    }) {
      final selected = _isActive(logicalPath, exact: exact);
      return CcSidebarItem(
        icon: icon,
        label: label,
        iconBuilder: iconBuilder,
        badge: badge > 0 ? _CountBadge(count: badge, selected: selected) : null,
        selected: selected,
        onPressed: () => GoRouter.of(context).go(target),
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
      footer: _SidebarFooter(
        location: location,
        workspaceId: workspaceId,
        collapsed: collapsed,
      ),
      // The workspace nav is a fixed set of destinations, so it is pinned and
      // only the spaces list below it scrolls: one scrollbar, and its thumb
      // reports the length of the space list rather than of the whole panel.
      pinnedChildren: [
        CcSidebarGroup(
          label: l10n.sidebarGroupWorkspace,
          collapsible: true,
          children: [
            navItem(
              icon: AppIcons.inbox,
              label: l10n.inboxTitle,
              logicalPath: '/inbox',
              target: inboxRoute(workspaceId),
              badge: ref.watch(inboxCountProvider),
            ),
            // The accordion's project children are full-width rows; in rail
            // mode the entry flattens to its plain icon-only nav item. The
            // slot reads the (deferred) sidebar scope itself, so the swap
            // lands exactly when the items flip their geometry.
            _TicketsNavSlot(location: location, workspaceId: workspaceId),
            navItem(
              icon: AppIcons.gitPullRequest,
              label: l10n.pullRequests,
              logicalPath: '/pull-requests',
              target: pullRequestsRoute(workspaceId),
            ),
            navItem(
              icon: AppIcons.calendar,
              // The Phosphor glyph hardcodes a "12"; render the signed-in
              // user's LOCAL day of month into the blank outline instead.
              iconBuilder: (color, size) =>
                  CalendarDayIcon(color: color, size: size),
              label: l10n.navCalendar,
              logicalPath: '/calendar',
              target: calendarRoute(workspaceId),
            ),
            navItem(
              icon: AppIcons.audioLines,
              label: l10n.navMeetings,
              logicalPath: '/meetings',
              target: meetingsRoute(workspaceId),
            ),
            navItem(
              icon: AppIcons.workflow,
              label: l10n.pipelinesScreenTitle,
              logicalPath: '/pipelines',
              target: pipelinesRoute(workspaceId),
              badge: runningPipelines,
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
        const _SidebarDivider(),
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
        _SpacesNavSlot(location: location, workspaceId: workspaceId),
      ],
    );
  }
}

/// The Tickets entry of the global sidebar: the [_TicketsAccordion] expanded,
/// a single icon-only nav item in the rail. A dedicated widget so the swap is
/// driven by [CcSidebarScope] — the same deferred, animation-aware flag the
/// items themselves flip on — rather than the instantly-updating provider.
class _TicketsNavSlot extends StatelessWidget {
  const _TicketsNavSlot({required this.location, required this.workspaceId});

  final String location;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final collapsed = CcSidebarScope.collapsedOf(context) ?? false;
    if (!collapsed) {
      return _TicketsAccordion(location: location, workspaceId: workspaceId);
    }
    final l10n = AppLocalizations.of(context);
    final logical = workspaceShellLogicalRoute(location);
    return CcSidebarItem(
      icon: AppIcons.ticket,
      label: l10n.navTickets,
      selected: logical == '/tickets' || logical.startsWith('/tickets/'),
      onPressed: () => GoRouter.of(context).go(ticketsRoute(workspaceId)),
    );
  }
}

/// The Spaces slot of the global sidebar: the inline space list
/// ([ConversationsSidebarSection]) expanded, a single icon opening the
/// spaces directory page in the rail. Scope-driven like [_TicketsNavSlot].
class _SpacesNavSlot extends StatelessWidget {
  const _SpacesNavSlot({required this.location, required this.workspaceId});

  final String location;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final collapsed = CcSidebarScope.collapsedOf(context) ?? false;
    if (!collapsed) {
      return const ConversationsSidebarSection();
    }
    final l10n = AppLocalizations.of(context);
    final logical = workspaceShellLogicalRoute(location);
    return CcSidebarGroup(
      children: [
        CcSidebarItem(
          icon: AppIcons.messagesSquare,
          label: l10n.spaces,
          selected: logical == '/spaces' || logical.startsWith('/spaces/'),
          onPressed: () => GoRouter.of(context).go(spacesRoute(workspaceId)),
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
/// here from a header [CcSidebarItem] plus an [AnimatedSize]-gated list of
/// indented child items.
class _TicketsAccordion extends ConsumerStatefulWidget {
  const _TicketsAccordion({required this.location, required this.workspaceId});

  final String location;
  final String workspaceId;

  @override
  ConsumerState<_TicketsAccordion> createState() => _TicketsAccordionState();
}

class _TicketsAccordionState extends ConsumerState<_TicketsAccordion> {
  // Sticky open/closed state. Seeded from the route, then auto-expanded when
  // entering the tickets/projects area — but never auto-collapsed on leaving,
  // so navigating away from "All tickets" no longer snaps the accordion shut.
  late bool _expanded = _isTicketsArea(widget.location);

  bool get _ticketsActive {
    final logical = workspaceShellLogicalRoute(widget.location);
    return logical == '/tickets' || logical.startsWith('/tickets/');
  }

  static bool _isTicketsArea(String location) {
    final logical = workspaceShellLogicalRoute(location);
    return logical == '/tickets' ||
        logical.startsWith('/tickets/') ||
        logical.startsWith('/projects/');
  }

  @override
  void didUpdateWidget(covariant _TicketsAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand only when entering the tickets/projects area from elsewhere;
    // a manual collapse while already inside the area is respected and
    // leaving the area never forces it closed.
    if (_isTicketsArea(widget.location) &&
        !_isTicketsArea(oldWidget.location)) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wsId = widget.workspaceId;

    final projects =
        (ref.watch(workspaceProjectsProvider(wsId)).asData?.value ??
                const <Project>[])
            .where((p) => p.status != ProjectStatus.archived)
            .toList();

    final expanded = _expanded;
    // While the rail is animating (or settled) the children lose their indent:
    // at the rail's width the indent would push the rows past the edge.
    final railMode =
        (CcSidebarScope.collapsedOf(context) ?? false) ||
        (CcSidebarScope.transitioningOf(context) ?? false);

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
          onPressed: () => GoRouter.of(context).go(ticketsRoute(wsId)),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: EdgeInsets.only(left: railMode ? 0 : AppSpacing.md),
                  // A label-less group so the children keep the sidebar's 4px
                  // inter-item rhythm.
                  child: CcSidebarGroup(
                    children: [
                      CcSidebarItem(
                        icon: AppIcons.list,
                        label: l10n.allTickets,
                        selected: _ticketsActive,
                        onPressed: () =>
                            GoRouter.of(context).go(ticketsRoute(wsId)),
                      ),
                      for (final p in projects)
                        () {
                          final selected =
                              widget.location ==
                              projectOverviewRoute(wsId, p.id);
                          return CcSidebarItem(
                            icon: AppIcons.dot,
                            label: p.name,
                            selected: selected,
                            badge: ProjectGlyph(
                              color: p.color,
                              onBrandFill: selected,
                            ),
                            onPressed: () => GoRouter.of(
                              context,
                            ).go(projectOverviewRoute(wsId, p.id)),
                          );
                        }(),
                      CcSidebarItem(
                        icon: AppIcons.plus,
                        label: l10n.newProject,
                        onPressed: () async {
                          final id = await showProjectDialog(
                            context,
                            workspaceId: wsId,
                          );
                          if (id != null && context.mounted) {
                            GoRouter.of(
                              context,
                            ).go(projectOverviewRoute(wsId, id));
                          }
                        },
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
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
      builder:
          (context, states) => AnimatedRotation(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            turns: expanded ? 0 : -0.25,
            child: Icon(
              AppIcons.chevronDown,
              size: 14,
              color:
                  states.contains(WidgetState.hovered)
                      ? t.textSecondary
                      : t.textTertiary,
            ),
          ),
    );
  }
}

/// Sidebar footer: theme toggle and Settings.
class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter({
    required this.location,
    required this.workspaceId,
    this.collapsed = false,
  });

  final String location;
  final String workspaceId;

  /// Rail mode: the text-only [OfflinePendingPill] doesn't fit the 54px rail,
  /// so it's dropped.
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final logical = workspaceShellLogicalRoute(location);
    // The scope's deferred flag wins over the constructor's: the pill is also
    // dropped while the width is animating, where it would clip.
    final railMode =
        (CcSidebarScope.collapsedOf(context) ?? collapsed) ||
        (CcSidebarScope.transitioningOf(context) ?? false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SidebarDivider(),
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
            CcSidebarItem(
              icon: AppIcons.newspaper,
              label: l10n.newsfeed,
              selected: logical.startsWith('/newsfeed'),
              onPressed: () =>
                  GoRouter.of(context).go(newsfeedRoute(workspaceId)),
            ),
            CcSidebarItem(
              icon: AppIcons.gauge,
              label: l10n.navObservability,
              selected: logical.startsWith('/observability'),
              onPressed: () =>
                  GoRouter.of(context).go(observabilityRoute(workspaceId)),
            ),
            CcSidebarItem(
              icon: AppIcons.settings,
              label: l10n.navSettings,
              selected: logical.startsWith('/settings'),
              // The settings landing is Profile & identity, the first item in
              // the sub-sidebar — not whichever page the sidebar happened to
              // name.
              onPressed: () =>
                  GoRouter.of(context).go(settingsProfileRoute(workspaceId)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Small count pill shown on a sidebar item (e.g. running agents).
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.selected});

  final int count;

  /// Whether the pill rides [CcSidebarItem]'s selected row. That row is a
  /// solid `bgBrandSolid` fill — the accent pill IS the fill's hue there, so
  /// it inverts: `accentOn` pill, `bgBrandSolid` digits (4.5:1+ on white in
  /// both brightnesses). Same treatment as the space rows'
  /// `_PrCountAdornment`.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    // The row's fill and ink lerp over CcMotion.fast; the pill travels WITH
    // them on one tween, or a white pill snaps on while the row is still its
    // pale mid-lerp self.
    return TweenAnimationBuilder<double>(
      duration: CcMotion.fast,
      curve: CcMotion.standard,
      tween: Tween<double>(end: selected ? 1 : 0),
      builder: (context, progress, _) => Container(
        constraints: const BoxConstraints(minWidth: 18),
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Color.lerp(t.accent, t.accentOn, progress),
          borderRadius: AppRadii.brSm,
        ),
        alignment: Alignment.center,
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            color: Color.lerp(t.accentOn, t.bgBrandSolid, progress),
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A sidebar hairline divider drawn edge-to-edge, carrying its own vertical
/// breathing room. [CcSidebar] pads its content by [AppSpacing.sm] on each
/// side, so the divider bleeds out via an [OverflowBox] (which permits
/// overflow by design, unlike negative padding, which asserts in debug) with
/// its height bounded so the footer's unbounded column constraints can't trip
/// it. The [AppSpacing.xs] vertical padding plus the neighbouring groups' own
/// [AppSpacing.xs] padding totals 8px — matching the sidebar's horizontal
/// content inset so the air reads uniform on all sides.
class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: 1,
          child: OverflowBox(
            maxWidth: constraints.maxWidth + 2 * AppSpacing.sm,
            child: const CcDivider(),
          ),
        ),
      ),
    );
  }
}
