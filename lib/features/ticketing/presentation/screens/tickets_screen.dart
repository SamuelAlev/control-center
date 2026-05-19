import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/presentation/ticket_view_mode.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_context_menu.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_detail_panel.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_property_pickers.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Statuses offered by the bulk-action status picker (terminal-reopening and
/// `none` are excluded; illegal transitions per-ticket are simply skipped).
const _bulkStatuses = [
  TicketStatus.backlog,
  TicketStatus.open,
  TicketStatus.inProgress,
  TicketStatus.blocked,
  TicketStatus.inReview,
  TicketStatus.done,
  TicketStatus.cancelled,
];

/// The tickets screen — a Linear-style grouped list (default) or a kanban
/// board, switchable via a persisted view toggle. Creating tickets is done
/// from the sidebar's "New ticket" action (the single entry point).
class TicketsScreen extends ConsumerWidget {
  /// Creates a [TicketsScreen].
  const TicketsScreen({super.key, this.selectedTicketId});

  /// The ticket opened in the detail panel (sourced from the route), or null
  /// when nothing is selected.
  final String? selectedTicketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    if (workspaceId == null) {
      return _EmptyState(message: l10n.noTicketsYet);
    }

    final boardAsync = ref.watch(ticketBoardProvider(workspaceId));
    final viewMode = ref.watch(ticketViewModeProvider);
    final agents =
        ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
            const <Agent>[];
    final agentNames = {for (final a in agents) a.id: a.name};

    return ColoredBox(
      color: t.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            count: boardAsync.asData?.value.values
                    .fold<int>(0, (s, l) => s + l.length) ??
                0,
            viewMode: viewMode,
            onViewMode: (m) {
              ref.read(ticketViewModeProvider.notifier).setMode(m);
              ref.read(ticketSelectionProvider.notifier).clear();
            },
          ),
          Container(height: 1, color: t.borderSecondary),
          Expanded(
            // The bulk-action bar floats over the whole frame (list + detail),
            // pinned to the bottom-centre — not just over the list pane.
            child: Stack(
              children: [
                Positioned.fill(
                  child: boardAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        _EmptyState(message: l10n.failedWithError('$e')),
                    data: (board) {
                      final empty = board.values.every((c) => c.isEmpty);
                      if (empty) {
                        return _EmptyState(message: l10n.noTicketsYet);
                      }
                      if (viewMode == TicketViewMode.board) {
                        return _BoardView(
                          board: board,
                          agentNames: agentNames,
                          workspaceId: workspaceId,
                          onOpen: (id) {
                            ref
                                .read(ticketViewModeProvider.notifier)
                                .setMode(TicketViewMode.list);
                            context.go(ticketDetailRoute(id));
                          },
                        );
                      }
                      final master = _MasterList(
                        board: board,
                        agentNames: agentNames,
                        selectedTicketId: selectedTicketId,
                        workspaceId: workspaceId,
                      );
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final total = constraints.maxWidth;
                          final detail = TicketDetailPanel(
                            key: ValueKey(selectedTicketId),
                            ticketId: selectedTicketId,
                            workspaceId: workspaceId,
                          );
                          // Too narrow to split: show the detail when a ticket
                          // is open, otherwise the master list.
                          if (total < 760) {
                            return selectedTicketId != null ? detail : master;
                          }
                          final masterW =
                              (total * 0.30).clamp(240.0, 360.0);
                          return CcResizable(
                            axis: Axis.horizontal,
                            dividerColor: t.borderPrimary,
                            regions: [
                              CcResizableRegion(
                                initialExtent: masterW,
                                minExtent: 240,
                                builder: (context) => master,
                              ),
                              CcResizableRegion(
                                initialExtent: total - masterW,
                                minExtent: 360,
                                builder: (context) => detail,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Center(child: _BulkActionBar(workspaceId: workspaceId)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.viewMode,
    required this.onViewMode,
  });

  final int count;
  final TicketViewMode viewMode;
  final ValueChanged<TicketViewMode> onViewMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      child: Row(
        children: [
          Text(
            l10n.ticketsTitle,
            style: TextStyle(
              fontSize: 18,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: t.bgSecondary,
              borderRadius: AppRadii.brSm,
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.textTertiary,
              ),
            ),
          ),
          const Spacer(),
          _ViewToggle(mode: viewMode, onChanged: onViewMode),
        ],
      ),
    );
  }
}

/// A small two-segment control to switch between list and board views.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.mode, required this.onChanged});

  final TicketViewMode mode;
  final ValueChanged<TicketViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    Widget segment(TicketViewMode m, IconData icon, String tooltip) {
      final selected = m == mode;
      return Tooltip(
        message: tooltip,
        child: CcTappable(
          onPressed: () => onChanged(m),
          builder: (context, states) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? t.bgPrimary : Colors.transparent,
              borderRadius: AppRadii.brSm,
              boxShadow: selected ? AppShadows.soft : null,
            ),
            child: Icon(
              icon,
              size: 16,
              color: selected ? t.fgSecondary : t.fgQuaternary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: AppRadii.brLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(TicketViewMode.list, LucideIcons.list, l10n.ticketViewList),
          const SizedBox(width: 2),
          segment(
            TicketViewMode.board,
            LucideIcons.columns3,
            l10n.ticketViewBoard,
          ),
        ],
      ),
    );
  }
}

// ── Master list ──────────────────────────────────────────────────────────────

/// The left (master) pane: the status-grouped ticket list. The currently open
/// ticket is highlighted. The bulk-action bar floats over the whole frame (see
/// [TicketsScreen.build]), not just this pane.
class _MasterList extends StatelessWidget {
  const _MasterList({
    required this.board,
    required this.agentNames,
    required this.selectedTicketId,
    required this.workspaceId,
  });

  final Map<TicketStatus, List<Ticket>> board;
  final Map<String, String> agentNames;
  final String? selectedTicketId;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return _TicketListView(
      board: board,
      agentNames: agentNames,
      selectedTicketId: selectedTicketId,
      workspaceId: workspaceId,
    );
  }
}

// ── List view ──────────────────────────────────────────────────────────────

class _TicketListView extends StatelessWidget {
  const _TicketListView({
    required this.board,
    required this.agentNames,
    required this.selectedTicketId,
    required this.workspaceId,
  });

  final Map<TicketStatus, List<Ticket>> board;
  final Map<String, String> agentNames;
  final String? selectedTicketId;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final groups = [
      for (final column in ticketBoardColumns)
        if ((board[column] ?? const []).isNotEmpty)
          (column, board[column] ?? const <Ticket>[]),
    ];
    return ListView.builder(
      // Bottom padding leaves room for the floating bulk-action bar.
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final (status, tickets) = groups[i];
        return _TicketGroup(
          status: status,
          tickets: tickets,
          agentNames: agentNames,
          selectedTicketId: selectedTicketId,
          workspaceId: workspaceId,
        );
      },
    );
  }
}

class _TicketGroup extends StatelessWidget {
  const _TicketGroup({
    required this.status,
    required this.tickets,
    required this.agentNames,
    required this.selectedTicketId,
    required this.workspaceId,
  });

  final TicketStatus status;
  final List<Ticket> tickets;
  final Map<String, String> agentNames;
  final String? selectedTicketId;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // An airy section header — no filled band, generous space above — so
        // the grouped list reads calm and breathable (the JetBrains Air
        // disposition) rather than as stacked gray strips.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              TicketStatusDot(status: status, animate: true),
              const SizedBox(width: 10),
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
          _TicketListRow(
            ticket: ticket,
            assigneeName: _assigneeName(ticket, agentNames),
            isOpen: ticket.id == selectedTicketId,
            workspaceId: workspaceId,
          ),
      ],
    );
  }

  String? _assigneeName(Ticket ticket, Map<String, String> agentNames) {
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

class _TicketListRow extends ConsumerStatefulWidget {
  const _TicketListRow({
    required this.ticket,
    required this.workspaceId,
    this.assigneeName,
    this.isOpen = false,
  });

  final Ticket ticket;
  final String workspaceId;
  final String? assigneeName;

  /// Whether this row's ticket is the one open in the detail panel.
  final bool isOpen;

  @override
  ConsumerState<_TicketListRow> createState() => _TicketListRowState();
}

class _TicketListRowState extends ConsumerState<_TicketListRow> {
  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final ticket = widget.ticket;
    final selected = ref.watch(
      ticketSelectionProvider.select((s) => s.contains(ticket.id)),
    );
    final anySelected = ref.watch(
      ticketSelectionProvider.select((s) => s.isNotEmpty),
    );
    final date =
        MaterialLocalizations.of(context).formatShortMonthDay(ticket.updatedAt);

    return CcTappable(
      onPressed: () => context.go(ticketDetailRoute(ticket.id)),
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final showCheckbox = hovered || selected || anySelected;
        final bg = selected
            ? t.bgBrandPrimary.withValues(alpha: 0.5)
            : widget.isOpen
                ? t.bgSecondary
                : (hovered ? t.bgPrimaryHover : t.bgPrimary);

        return GestureDetector(
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
              color: bg,
              border: Border(
                bottom: BorderSide(color: t.borderSecondary, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 11, 20, 11),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  // Centre so the tappable gets loose constraints — otherwise
                  // the 24px-wide cell forces the 18px checkbox into a wide
                  // rectangle.
                  child: showCheckbox
                      ? Center(
                          child: _RowCheckbox(
                            checked: selected,
                            onTap: () => ref
                                .read(ticketSelectionProvider.notifier)
                                .toggle(ticket.id),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                TicketPriorityIndicator(
                  priority: ticket.priority,
                  showLabel: false,
                ),
                const SizedBox(width: 14),
                TicketStatusDot(status: ticket.status, animate: true),
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
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: t.textQuaternary),
                ),
                const SizedBox(width: 12),
                TicketAssigneeAvatar(name: widget.assigneeName, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A small square checkbox used at the left of a list row. Toggling it selects
/// the ticket for a bulk action without navigating to the ticket.
class _RowCheckbox extends StatelessWidget {
  const _RowCheckbox({required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: checked ? t.fgBrandPrimary : Colors.transparent,
          borderRadius: AppRadii.brSm,
          border: Border.all(
            color: checked ? t.fgBrandPrimary : t.borderPrimary,
            width: 1.5,
          ),
        ),
        child: checked
            ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
            : null,
      ),
    );
  }
}

// ── Bulk action bar ──────────────────────────────────────────────────────────

/// A floating bar pinned to the bottom-center of the list view while one or
/// more tickets are selected. Offers status / priority / delete across the
/// whole selection, plus a clear-selection control.
class _BulkActionBar extends ConsumerWidget {
  const _BulkActionBar({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(ticketSelectionProvider);
    if (selection.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workflow = ref.read(ticketWorkflowServiceProvider);
    final ids = selection.toList();

    return Container(
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: t.borderSecondary),
        boxShadow: AppShadows.golden,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              l10n.selectedCount(selection.length),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
          ),
          _BarDivider(color: t.borderSecondary),
          TicketPropertyPicker(
            trigger: (context, toggle) => TicketTriggerChip(
              bordered: true,
              onTap: toggle,
              child: _BarChipLabel(
                icon: LucideIcons.circleDashed,
                label: l10n.status,
              ),
            ),
            menu: (context, toggle) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in _bulkStatuses)
                    CcTile(
                      leading: TicketStatusDot(status: s),
                      title: ticketStatusLabel(l10n, s),
                      onTap: () {
                        for (final id in ids) {
                          workflow.transitionStatus(
                            id,
                            s,
                            workspaceId: workspaceId,
                            force: true,
                          );
                        }
                        toggle();
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          TicketPropertyPicker(
            trigger: (context, toggle) => TicketTriggerChip(
              bordered: true,
              onTap: toggle,
              child: _BarChipLabel(
                icon: LucideIcons.signalHigh,
                label: l10n.priority,
              ),
            ),
            menu: (context, toggle) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final p in TicketPriority.values)
                    CcTile(
                      leading:
                          TicketPriorityIndicator(priority: p, showLabel: false),
                      title: ticketPriorityLabel(l10n, p),
                      onTap: () {
                        for (final id in ids) {
                          workflow.updateDetails(
                            id,
                            workspaceId: workspaceId,
                            priority: p,
                          );
                        }
                        toggle();
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => _confirmDelete(context, ref, ids),
            icon: LucideIcons.trash2,
            child: Text(l10n.delete),
          ),
          _BarDivider(color: t.borderSecondary),
          Tooltip(
            message: l10n.clearSelection,
            child: CcTappable(
              onPressed: () =>
                  ref.read(ticketSelectionProvider.notifier).clear(),
              builder: (context, states) => Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(LucideIcons.x, size: 16, color: t.fgTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.bulkDeleteTitle,
        content: Text(l10n.bulkDeleteMessage(ids.length)),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final workflow = ref.read(ticketWorkflowServiceProvider);
    for (final id in ids) {
      await workflow.deleteTicket(id, workspaceId: workspaceId);
    }
    ref.read(ticketSelectionProvider.notifier).clear();
  }
}

class _BarChipLabel extends StatelessWidget {
  const _BarChipLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: t.fgTertiary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: t.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BarDivider extends StatelessWidget {
  const _BarDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: color,
    );
  }
}

// ── Board view ─────────────────────────────────────────────────────────────

class _BoardView extends StatelessWidget {
  const _BoardView({
    required this.board,
    required this.agentNames,
    required this.onOpen,
    required this.workspaceId,
  });

  final Map<TicketStatus, List<Ticket>> board;
  final Map<String, String> agentNames;
  final ValueChanged<String> onOpen;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        for (final column in ticketBoardColumns)
          _BoardColumn(
            status: column,
            tickets: board[column] ?? const [],
            agentNames: agentNames,
            onOpen: onOpen,
            workspaceId: workspaceId,
          ),
      ],
    );
  }
}

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.status,
    required this.tickets,
    required this.agentNames,
    required this.onOpen,
    required this.workspaceId,
  });

  final TicketStatus status;
  final List<Ticket> tickets;
  final Map<String, String> agentNames;
  final ValueChanged<String> onOpen;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: ticketColumnTint(t, status),
        borderRadius: AppRadii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                TicketStatusDot(status: status, animate: true),
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              itemCount: tickets.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TicketCard(
                  ticket: tickets[i],
                  assigneeName: agentNames[tickets[i].assignedAgentId],
                  onOpen: onOpen,
                  workspaceId: workspaceId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends ConsumerWidget {
  const _TicketCard({
    required this.ticket,
    required this.onOpen,
    required this.workspaceId,
    this.assigneeName,
  });

  final Ticket ticket;
  final String? assigneeName;
  final ValueChanged<String> onOpen;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final isUser = ticket.assignedAgentId == TicketCollaborator.userSentinel;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => showTicketContextMenu(
        context: context,
        ref: ref,
        position: details.globalPosition,
        ticket: ticket,
        workspaceId: workspaceId,
      ),
      child: AppCard(
      raw: true,
      onTap: () => onOpen(ticket.id),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ticket.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TicketPriorityIndicator(priority: ticket.priority),
              const Spacer(),
              if (assigneeName != null || isUser)
                TicketAssigneeAvatar(name: isUser ? 'You' : assigneeName),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.ticket, size: 40, color: t.fgQuaternary),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: t.textTertiary)),
        ],
      ),
    );
  }
}
