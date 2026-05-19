import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/presentation/widgets/new_project_dialog.dart';
import 'package:control_center/features/ticketing/presentation/widgets/new_ticket_dialog.dart';
import 'package:control_center/features/ticketing/presentation/widgets/project_visuals.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_context_menu.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The dedicated landing for a single project: its name, status, description,
/// progress, and tickets grouped by status. Reached from the sidebar accordion
/// or by opening a project. Out-of-workspace / missing projects fall back to an
/// empty state.
class ProjectOverviewScreen extends ConsumerWidget {
  /// Creates a [ProjectOverviewScreen].
  const ProjectOverviewScreen({super.key, required this.projectId});

  /// The project being shown.
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    if (workspaceId == null) {
      return _Empty(message: l10n.noProjectsYet);
    }

    final project = ref.watch(
      projectByIdProvider((workspaceId: workspaceId, projectId: projectId)),
    );
    if (project == null) {
      return _Empty(message: l10n.noProjectsYet);
    }

    final tickets =
        (ref.watch(workspaceTicketsProvider(workspaceId)).asData?.value ??
                const <Ticket>[])
            .where((t) => t.projectId == projectId)
            .toList();
    final agents =
        ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
            const <Agent>[];
    final agentNames = {for (final a in agents) a.id: a.name};

    final board = <TicketStatus, List<Ticket>>{
      for (final c in TicketBoardColumns.all) c: <Ticket>[],
    };
    for (final ticket in tickets) {
      board[TicketBoardColumns.columnFor(ticket.status)]!.add(ticket);
    }
    final doneCount = tickets.where((t) => t.status.isTerminal).length;

    return ColoredBox(
      color: t.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            project: project,
            workspaceId: workspaceId,
            ticketCount: tickets.length,
            doneCount: doneCount,
          ),
          Container(height: 1, color: t.borderSecondary),
          Expanded(
            child: tickets.isEmpty
                ? _Empty(message: l10n.projectTicketsEmpty)
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      for (final column in TicketBoardColumns.all)
                        if ((board[column] ?? const []).isNotEmpty)
                          _StatusGroup(
                            status: column,
                            tickets: board[column]!,
                            agentNames: agentNames,
                            workspaceId: workspaceId,
                          ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.project,
    required this.workspaceId,
    required this.ticketCount,
    required this.doneCount,
  });

  final Project project;
  final String workspaceId;
  final int ticketCount;
  final int doneCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final progress = ticketCount == 0 ? 0.0 : doneCount / ticketCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProjectGlyph(color: project.color, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  project.name,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ProjectStatusBadge(status: project.status),
              const SizedBox(width: 8),
              FButton(
                onPress: () async {
                  final id = await showNewTicketDialog(context);
                  if (id != null) {
                    await ref.read(ticketWorkflowServiceProvider).setProject(
                          id,
                          project.id,
                          workspaceId: workspaceId,
                        );
                  }
                },
                mainAxisSize: MainAxisSize.min,
                prefix: const Icon(LucideIcons.plus, size: 16),
                child: Text(l10n.newTicket),
              ),
              const SizedBox(width: 6),
              _ProjectMenu(project: project, workspaceId: workspaceId),
            ],
          ),
          if (project.description != null &&
              project.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(
                project.description!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: t.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: t.bgSecondary,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(t.fgSuccessPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.projectProgress(doneCount, ticketCount),
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectStatusBadge extends StatelessWidget {
  const _ProjectStatusBadge({required this.status});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final (color, bg) = switch (status) {
      ProjectStatus.active => (t.fgBrandPrimary, t.bgBrandPrimary),
      ProjectStatus.completed => (t.fgSuccessPrimary, t.bgSuccessPrimary),
      ProjectStatus.archived => (t.fgQuaternary, t.bgSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5),
        borderRadius: AppRadii.brSm,
      ),
      child: Text(
        projectStatusLabel(l10n, status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ProjectMenu extends ConsumerStatefulWidget {
  const _ProjectMenu({required this.project, required this.workspaceId});

  final Project project;
  final String workspaceId;

  @override
  ConsumerState<_ProjectMenu> createState() => _ProjectMenuState();
}

class _ProjectMenuState extends ConsumerState<_ProjectMenu>
    with SingleTickerProviderStateMixin {
  late final FPopoverController _controller = FPopoverController(vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final service = ref.read(projectServiceProvider);
    final project = widget.project;
    final isArchived = project.status == ProjectStatus.archived;
    final isCompleted = project.status == ProjectStatus.completed;

    return FPopoverMenu.tiles(
      control: FPopoverControl.managed(controller: _controller),
      menu: [
        FTileGroup(
          children: [
            FTile(
              prefix: const Icon(LucideIcons.squarePen, size: 16),
              title: Text(l10n.editProject),
              onPress: () {
                _controller.toggle();
                showProjectDialog(context, existing: project);
              },
            ),
            FTile(
              prefix: const Icon(LucideIcons.circleCheck, size: 16),
              title: Text(
                isCompleted ? l10n.markProjectActive : l10n.markProjectCompleted,
              ),
              onPress: () {
                service.update(
                  project.id,
                  workspaceId: widget.workspaceId,
                  status: isCompleted
                      ? ProjectStatus.active
                      : ProjectStatus.completed,
                );
                _controller.toggle();
              },
            ),
            FTile(
              prefix: Icon(
                isArchived ? LucideIcons.archiveRestore : LucideIcons.archive,
                size: 16,
              ),
              title: Text(
                isArchived ? l10n.restoreProject : l10n.archiveProject,
              ),
              onPress: () {
                if (isArchived) {
                  service.update(
                    project.id,
                    workspaceId: widget.workspaceId,
                    status: ProjectStatus.active,
                  );
                } else {
                  service.archive(project.id, workspaceId: widget.workspaceId);
                }
                _controller.toggle();
              },
            ),
          ],
        ),
        FTileGroup(
          children: [
            FTile(
              prefix: Icon(LucideIcons.trash2, size: 16, color: t.fgErrorPrimary),
              title: Text(
                l10n.deleteProject,
                style: TextStyle(color: t.fgErrorPrimary),
              ),
              onPress: () {
                _controller.toggle();
                _confirmDelete(context, ref, project, widget.workspaceId);
              },
            ),
          ],
        ),
      ],
      child: FTappable(
        onPress: _controller.toggle,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(LucideIcons.ellipsis, size: 18, color: t.fgTertiary),
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Project project,
  String workspaceId,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showFDialog<bool>(
    context: context,
    builder: (ctx, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: Text(l10n.deleteProject),
      body: Text(l10n.deleteProjectConfirm(project.name)),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FButton(
                onPress: () => Navigator.pop(ctx, false),
                variant: FButtonVariant.outline,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: () => Navigator.pop(ctx, true),
                variant: FButtonVariant.destructive,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.delete),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return;
  }
  await ref
      .read(projectServiceProvider)
      .delete(project.id, workspaceId: workspaceId);
  if (context.mounted) {
    context.go(ticketsRoute);
  }
}

class _StatusGroup extends StatelessWidget {
  const _StatusGroup({
    required this.status,
    required this.tickets,
    required this.agentNames,
    required this.workspaceId,
  });

  final TicketStatus status;
  final List<Ticket> tickets;
  final Map<String, String> agentNames;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: t.bgSecondary.withValues(alpha: 0.5),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            children: [
              TicketStatusDot(status: status),
              const SizedBox(width: 8),
              Text(
                ticketStatusLabel(l10n, status),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${tickets.length}',
                style: TextStyle(fontSize: 12, color: t.textQuaternary),
              ),
            ],
          ),
        ),
        for (final ticket in tickets)
          _ProjectTicketRow(
            ticket: ticket,
            assigneeName: _assigneeName(ticket),
            workspaceId: workspaceId,
          ),
      ],
    );
  }

  String? _assigneeName(Ticket ticket) {
    final id = ticket.assignedAgentId;
    if (id == null) {
      return null;
    }
    if (id == TicketCollaborator.userSentinel) {
      return 'You';
    }
    return agentNames[id] ?? id;
  }
}

class _ProjectTicketRow extends ConsumerStatefulWidget {
  const _ProjectTicketRow({
    required this.ticket,
    required this.assigneeName,
    required this.workspaceId,
  });

  final Ticket ticket;
  final String? assigneeName;
  final String workspaceId;

  @override
  ConsumerState<_ProjectTicketRow> createState() => _ProjectTicketRowState();
}

class _ProjectTicketRowState extends ConsumerState<_ProjectTicketRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final ticket = widget.ticket;
    return FTappable(
      onPress: () => context.go(ticketDetailRoute(ticket.id)),
      onHoverChange: (h) => setState(() => _hovered = h),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) => showTicketContextMenu(
          context: context,
          ref: ref,
          position: details.globalPosition,
          ticket: ticket,
          workspaceId: widget.workspaceId,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _hovered ? t.bgPrimaryHover : t.bgPrimary,
            border: Border(
              bottom: BorderSide(color: t.borderSecondary, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 10, 20, 10),
          child: Row(
            children: [
              TicketPriorityIndicator(priority: ticket.priority, showLabel: false),
              const SizedBox(width: 14),
              TicketStatusDot(status: ticket.status),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ticket.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TicketAssigneeAvatar(name: widget.assigneeName, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ColoredBox(
      color: t.bgPrimary,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.box, size: 40, color: t.fgQuaternary),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: t.textTertiary)),
          ],
        ),
      ),
    );
  }
}
