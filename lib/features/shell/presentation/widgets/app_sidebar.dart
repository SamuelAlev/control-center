import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/dashboard/providers/active_processes_provider.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/shell/presentation/widgets/title_bar_workspace_chip.dart';
import 'package:control_center/features/shell/providers/command_palette_providers.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:control_center/features/ticketing/presentation/widgets/new_project_dialog.dart';
import 'package:control_center/features/ticketing/presentation/widgets/new_ticket_dialog.dart';
import 'package:control_center/features/ticketing/presentation/widgets/project_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

/// Primary application navigation, rendered as a single grouped left sidebar
/// built on forui's [FSidebar] / [FSidebarGroup] / [FSidebarItem].
///
/// Replaces the previous "layered topbar" (title bar + main pill row +
/// conditional settings pill row). The workspace switcher and the promoted
/// "New ticket" action live in the header; theme + settings live in the
/// footer; destinations are grouped Work / Team plus standalone entries.
class AppSidebar extends ConsumerWidget {
  /// Creates an [AppSidebar]. [location] is the current router location, used
  /// to resolve the active item.
  const AppSidebar({super.key, required this.location});

  /// The current matched router location.
  final String location;

  bool _isActive(String route, {bool exact = false}) {
    if (exact) {
      return location == route;
    }
    return location == route || location.startsWith('$route/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final runningCount = ref.watch(activeProcessesProvider).length;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final runningPipelines = workspaceId == null
        ? 0
        : (ref.watch(workspacePipelineRunsProvider(workspaceId)).value ??
                const <PipelineRun>[])
            .where((run) => run.status == PipelineRunStatus.running)
            .length;

    FSidebarItem navItem({
      required IconData icon,
      required String label,
      required String route,
      bool exact = false,
      int badge = 0,
    }) {
      final selected = _isActive(route, exact: exact);
      return FSidebarItem(
        icon: Semantics(label: label, child: Icon(icon)),
        label: badge > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: AppSpacing.sm),
                  _CountBadge(count: badge),
                ],
              )
            : Text(label),
        selected: selected,
        onPress: () => GoRouter.of(context).go(route),
      );
    }

    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return FSidebar(
      style: FSidebarStyleDelta.delta(
        constraints: const BoxConstraints(minWidth: 248, maxWidth: 248),
        decoration: DecorationDelta.boxDelta(color: tokens.sidebar),
        // Items default to a solid (white) `colors.background` fill, which would
        // tile over the warm #F7F5F0 sidebar surface. Make the resting fill
        // transparent so the surface shows through; the selected/hovered/pressed
        // secondary wash is left untouched. This propagates to grouped items, the
        // accordion's nested children, and the footer item via FSidebarData.
        groupStyle: FSidebarGroupStyleDelta.delta(
          itemStyle: FSidebarItemStyleDelta.delta(
            backgroundColor: FVariantsValueDelta.delta([
              FVariantValueDeltaOperation.base(Colors.transparent),
            ]),
          ),
        ),
      ),
      header: const _SidebarHeader(),
      footer: _SidebarFooter(location: location),
      children: [
        FSidebarGroup(
          label: Text(l10n.sidebarGroupWork),
          children: [
            navItem(
              icon: LucideIcons.layoutDashboard,
              label: l10n.navDashboard,
              route: dashboardRoute,
              exact: true,
            ),
            _TicketsAccordion(location: location, workspaceId: workspaceId),
            navItem(
              icon: LucideIcons.gitPullRequest,
              label: l10n.pullRequests,
              route: pullRequestsRoute,
            ),
            navItem(
              icon: LucideIcons.workflow,
              label: l10n.pipelinesScreenTitle,
              route: pipelinesRoute,
              badge: runningPipelines,
            ),
          ],
        ),
        FSidebarGroup(
          label: Text(l10n.sidebarGroupTeam),
          children: [
            navItem(
              icon: LucideIcons.bot,
              label: l10n.agents,
              route: agentsRoute,
              badge: runningCount,
            ),
            navItem(
              icon: LucideIcons.chartColumn,
              label: l10n.navAnalytics,
              route: analyticsRoute,
            ),
          ],
        ),
        FSidebarGroup(
          label: Text(l10n.sidebarGroupKnowledge),
          children: [
            navItem(
              icon: LucideIcons.brain,
              label: l10n.navMemory,
              route: memoryRoute,
            ),
            navItem(
              icon: LucideIcons.newspaper,
              label: l10n.newsfeed,
              route: newsfeedRoute,
            ),
          ],
        ),
      ],
    );
  }
}

/// The "Tickets" entry rendered as a collapsible accordion: pressing the
/// header navigates to all tickets and toggles the project list; the children
/// are "All tickets", one row per (non-archived) project, and a "New project"
/// action. When there is no active workspace it degrades to a plain nav item.
class _TicketsAccordion extends ConsumerWidget {
  const _TicketsAccordion({required this.location, required this.workspaceId});

  final String location;
  final String? workspaceId;

  bool get _ticketsActive =>
      location == ticketsRoute || location.startsWith('$ticketsRoute/');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final wsId = workspaceId;

    if (wsId == null) {
      return FSidebarItem(
        icon: Semantics(
          label: l10n.navTickets,
          child: const Icon(LucideIcons.ticket),
        ),
        label: Text(l10n.navTickets),
        selected: _ticketsActive,
        onPress: () => GoRouter.of(context).go(ticketsRoute),
      );
    }

    final projects =
        (ref.watch(workspaceProjectsProvider(wsId)).asData?.value ??
                const <Project>[])
            .where((p) => p.status != ProjectStatus.archived)
            .toList();
    final onProjectRoute = location.startsWith('/projects/');

    return FSidebarItem(
      icon: Semantics(
        label: l10n.navTickets,
        child: const Icon(LucideIcons.ticket),
      ),
      label: Text(l10n.navTickets),
      initiallyExpanded: _ticketsActive || onProjectRoute,
      onPress: () => GoRouter.of(context).go(ticketsRoute),
      children: [
        FSidebarItem(
          icon: const Icon(LucideIcons.list),
          label: Text(l10n.allTickets),
          selected: _ticketsActive,
          onPress: () => GoRouter.of(context).go(ticketsRoute),
        ),
        for (final p in projects)
          FSidebarItem(
            icon: ProjectGlyph(color: p.color),
            label: Text(p.name, overflow: TextOverflow.ellipsis),
            selected: location == projectOverviewRoute(p.id),
            onPress: () =>
                GoRouter.of(context).go(projectOverviewRoute(p.id)),
          ),
        FSidebarItem(
          icon: const Icon(LucideIcons.plus),
          label: Text(l10n.newProject),
          onPress: () async {
            final id = await showProjectDialog(context);
            if (id != null && context.mounted) {
              GoRouter.of(context).go(projectOverviewRoute(id));
            }
          },
        ),
      ],
    );
  }
}

/// Sidebar header: macOS traffic-light clearance + window drag region, then a
/// single row holding the workspace switcher, a search (command-palette)
/// affordance, and the promoted "New ticket" action.
class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reserve space for the macOS traffic lights (the window uses a hidden
        // native title bar) and let the user drag the window from here.
        const DragToMoveArea(
          child: SizedBox(height: 28, width: double.infinity),
        ),
        // One row: workspace chip (left, ellipsizing) + search + new ticket.
        // The leading inset matches the FSidebarGroup content inset (16) so the
        // chip avatar aligns with the nav item icons below.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
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
                icon: LucideIcons.search,
                tooltip: l10n.commandPalette,
                onPressed: () =>
                    showCommandPalette(context, buildGlobalCommands),
              ),
              const SizedBox(width: AppSpacing.xs),
              _HeaderIconButton(
                icon: LucideIcons.squarePen,
                tooltip: l10n.newTicket,
                filled: true,
                onPressed: () => showNewTicketDialog(context),
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
  const _SidebarFooter({required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Match the horizontal inset that FSidebarGroup applies to the content nav
    // items (its default padding is `symmetric(horizontal: 16)`). The footer
    // is not wrapped in a group, so without this the settings item renders
    // full-width and looks wider than Dashboard/Tickets/etc.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: FSidebarItem(
        icon: Semantics(
          label: l10n.navSettings,
          child: const Icon(LucideIcons.settings),
        ),
        label: Text(l10n.navSettings),
        selected: location.startsWith(settingsRoute),
        onPress: () => GoRouter.of(context).go(settingsAppearanceRoute),
      ),
    );
  }
}

/// Small count pill shown on a sidebar item (e.g. running agents).
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: AppRadii.brSm,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: TextStyle(
          color: colors.primaryForeground,
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
