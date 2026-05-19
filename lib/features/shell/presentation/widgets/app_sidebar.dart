import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/shell/presentation/widgets/title_bar_workspace_chip.dart';
import 'package:control_center/features/shell/providers/command_palette_providers.dart';
import 'package:control_center/features/ticketing/presentation/widgets/new_project_dialog.dart';
import 'package:control_center/features/ticketing/presentation/widgets/new_ticket_dialog.dart';
import 'package:control_center/features/ticketing/presentation/widgets/project_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Primary application navigation, rendered as a single grouped left sidebar
/// built on cc_ui's [CcSidebar] / [CcSidebarGroup] / [CcSidebarItem].
///
/// Replaces the previous "layered topbar" (title bar + main pill row +
/// conditional settings pill row). The workspace switcher and the promoted
/// "New ticket" action live in the header; analytics + settings live in the
/// footer; destinations are grouped Work / Team plus standalone entries.
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
  /// `/dashboard` or `/tickets`.
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
    final t = context.designSystem ?? DesignSystemTokens.light();
    final runningPipelines =
        (ref.watch(workspacePipelineRunsProvider(workspaceId)).value ??
                const <PipelineRun>[])
            .where((run) => run.status == PipelineRunStatus.running)
            .length;

    CcSidebarItem navItem({
      required IconData icon,
      required String label,
      required String logicalPath,
      required String target,
      bool exact = false,
      int badge = 0,
    }) {
      final selected = _isActive(logicalPath, exact: exact);
      return CcSidebarItem(
        icon: icon,
        label: label,
        badge: badge > 0 ? _CountBadge(count: badge) : null,
        selected: selected,
        onPressed: () => GoRouter.of(context).go(target),
      );
    }

    return CcSidebar(
      header: _SidebarHeader(workspaceId: workspaceId),
      footer: _SidebarFooter(location: location, workspaceId: workspaceId),
      trailingBorder: BorderSide(color: t.borderPrimary),
      children: [
        CcSidebarGroup(
          label: l10n.sidebarGroupWork,
          collapsible: true,
          children: [
            navItem(
              icon: AppIcons.layoutDashboard,
              label: l10n.navDashboard,
              logicalPath: '/dashboard',
              target: dashboardRoute(workspaceId),
              exact: true,
            ),
            navItem(
              icon: AppIcons.calendar,
              label: l10n.navCalendar,
              logicalPath: '/calendar',
              target: calendarRoute(workspaceId),
            ),
            _TicketsAccordion(location: location, workspaceId: workspaceId),
            navItem(
              icon: AppIcons.gitPullRequest,
              label: l10n.pullRequests,
              logicalPath: '/pull-requests',
              target: pullRequestsRoute(workspaceId),
            ),
            navItem(
              icon: AppIcons.workflow,
              label: l10n.pipelinesScreenTitle,
              logicalPath: '/pipelines',
              target: pipelinesRoute(workspaceId),
              badge: runningPipelines,
            ),
          ],
        ),
        CcSidebarGroup(
          label: l10n.sidebarGroupKnowledge,
          collapsible: true,
          children: [
            navItem(
              icon: AppIcons.newspaper,
              label: l10n.newsfeed,
              logicalPath: '/newsfeed',
              target: newsfeedRoute(workspaceId),
            ),
            navItem(
              icon: AppIcons.audioLines,
              label: l10n.navMeetings,
              logicalPath: '/meetings',
              target: meetingsRoute(workspaceId),
            ),
            navItem(
              icon: AppIcons.brain,
              label: l10n.navMemory,
              logicalPath: '/memory',
              target: memoryRoute(workspaceId),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: _SidebarDivider(),
        ),
        // The conversation surface (DMs + groups) lives inline so channels are
        // reachable directly from the global sidebar; the messaging screen
        // itself is now conversation + optional terminal (its inner sidebar is
        // gone). There is no wrapping "Conversations" group — the Direct
        // messages and Groups sections are top-level collapsible accordions in
        // their own right. Per-channel highlight + status come from
        // ConversationsSidebarSection.
        const ConversationsSidebarSection(),
      ],
    );
  }
}

/// The "Tickets" entry rendered as a collapsible accordion: pressing the
/// header navigates to all tickets, while a trailing chevron toggles the
/// project list; the children are "All tickets", one row per (non-archived)
/// project, and a "New project" action. When there is no active workspace it
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
    // a manual collapse while already inside the area is respected, and
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
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CcSidebarItem(
                        icon: AppIcons.list,
                        label: l10n.allTickets,
                        selected: _ticketsActive,
                        onPressed: () =>
                            GoRouter.of(context).go(ticketsRoute(wsId)),
                      ),
                      for (final p in projects)
                        CcSidebarItem(
                          icon: AppIcons.dot,
                          label: p.name,
                          selected:
                              widget.location ==
                              projectOverviewRoute(wsId, p.id),
                          badge: ProjectGlyph(color: p.color),
                          onPressed: () => GoRouter.of(
                            context,
                          ).go(projectOverviewRoute(wsId, p.id)),
                        ),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          turns: expanded ? 0 : -0.25,
          child: Icon(AppIcons.chevronDown, size: 14, color: t.textTertiary),
        ),
      ),
    );
  }
}

/// Sidebar header: macOS traffic-light clearance + window drag region, then a
/// single row holding the workspace switcher, a search (command-palette)
/// affordance, and the promoted "New ticket" action.
class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.workspaceId});

  /// The active workspace id from the route, supplied to the promoted
  /// "New ticket" action so the dialog does not resolve it implicitly.
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // On macOS the window uses a hidden native title bar, so reserve space for
    // the traffic-light controls. On web/Windows/Linux there are no native
    // controls in this corner, so collapse the reserve to a few pixels that
    // vertically center the 34px workspace-chip row against the 40px title-bar
    // breadcrumb to its right ((40 - 34) / 2).
    final hasMacTrafficLights =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final topReserve = hasMacTrafficLights ? 28.0 : 3.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reserve space for the macOS traffic lights (the window uses a hidden
        // native title bar) and let the user drag the window from here.
        WindowDragArea(
          child: SizedBox(height: topReserve, width: double.infinity),
        ),
        // One row: workspace chip (left, ellipsizing) + search + new ticket.
        // No leading inset so the chip's hover pill aligns with the nav item
        // pills below (both start at the sidebar content's left edge).
        Padding(
          padding: const EdgeInsets.fromLTRB(
            0,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              // Align (not Expanded directly) keeps the chip's hover pill sized
              // to its content while still claiming the free space that pushes
              // the actions to the right.
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TitleBarWorkspaceChip(avatarSize: 28, fontSize: 15),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _HeaderIconButton(
                icon: AppIcons.search,
                tooltip: l10n.commandPalette,
                onPressed: () =>
                    showCommandPalette(context, buildGlobalCommands),
              ),
              const SizedBox(width: AppSpacing.xs),
              _HeaderIconButton(
                icon: AppIcons.squarePen,
                tooltip: l10n.newTicket,
                filled: true,
                onPressed: () =>
                    showNewTicketDialog(context, workspaceId: workspaceId),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A compact 34px square icon button used in the sidebar header. [filled]
/// renders it as a subtly tinted, bordered button (the promoted "New ticket"
/// action); otherwise it is a ghost button that tints only on hover (search).
class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool filled;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final base = widget.filled ? t.bgSecondary : Colors.transparent;
    final bg = _hovered ? t.bgPrimaryHover : base;
    final fg = widget.filled ? t.fgSecondary : t.fgTertiary;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadii.brSm,
              border: widget.filled
                  ? Border.all(color: t.borderSecondary)
                  : null,
            ),
            child: Icon(widget.icon, size: 16, color: fg),
          ),
        ),
      ),
    );
  }
}

/// Sidebar footer: theme toggle and Settings.
class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter({required this.location, required this.workspaceId});

  final String location;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final logical = workspaceShellLogicalRoute(location);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SidebarDivider(),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: CcSidebarItem(
            icon: AppIcons.chartColumn,
            label: l10n.navAnalytics,
            selected: logical.startsWith('/analytics'),
            onPressed: () =>
                GoRouter.of(context).go(analyticsRoute(workspaceId)),
          ),
        ),
        CcSidebarItem(
          icon: AppIcons.settings,
          label: l10n.navSettings,
          selected: logical.startsWith('/settings'),
          onPressed: () =>
              GoRouter.of(context).go(settingsAppearanceRoute(workspaceId)),
        ),
      ],
    );
  }
}

/// Small count pill shown on a sidebar item (e.g. running agents).
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: t.accent,
        borderRadius: AppRadii.brSm,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: TextStyle(
          color: t.accentOn,
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A sidebar hairline divider. It sits inside [CcSidebar]'s content padding so
/// it aligns with the items rather than running edge-to-edge — the previous
/// negative-padding "full-bleed" trick asserted in debug
/// (`RenderPadding` requires non-negative insets).
class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();

  @override
  Widget build(BuildContext context) {
    return const CcDivider();
  }
}
