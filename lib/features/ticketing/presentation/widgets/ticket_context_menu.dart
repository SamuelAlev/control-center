import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_link.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/presentation/widgets/project_visuals.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_picker_dialog.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Statuses offered in the context menu (terminal-reopening excluded; illegal
/// per-ticket transitions are skipped by the workflow service).
const _menuStatuses = [
  TicketStatus.backlog,
  TicketStatus.open,
  TicketStatus.inProgress,
  TicketStatus.blocked,
  TicketStatus.inReview,
  TicketStatus.done,
  TicketStatus.cancelled,
];

/// The dependency relations offered by the "Relate to" submenu, in the order
/// shown in the screenshots.
const _relateKinds = [
  TicketRelationKind.subIssueOf,
  TicketRelationKind.parentOf,
  TicketRelationKind.relatedTo,
  TicketRelationKind.blockedBy,
  TicketRelationKind.blocking,
  TicketRelationKind.duplicateOf,
];

/// Opens the Linear-style cascading context menu for [ticket] at [position]
/// (the global pointer location). Built as an overlay so its flyout submenus
/// escape any clipping ancestor; dismissed by tapping outside or pressing Esc.
void showTicketContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Offset position,
  required Ticket ticket,
  required String workspaceId,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  void dismiss() {
    if (entry.mounted) {
      entry.remove();
    }
  }

  final entries = _buildEntries(
    context: context,
    ref: ref,
    ticket: ticket,
    workspaceId: workspaceId,
    dismiss: dismiss,
  );

  entry = OverlayEntry(
    builder: (_) => _ContextMenuOverlay(
      position: position,
      entries: entries,
      onDismiss: dismiss,
    ),
  );
  overlay.insert(entry);
}

// ── Entry model ──────────────────────────────────────────────────────────────

sealed class _MenuEntry {
  const _MenuEntry();
}

class _MenuAction extends _MenuEntry {
  const _MenuAction({
    required this.leading,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.destructive = false,
  });

  final Widget leading;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool destructive;
}

class _MenuSub extends _MenuEntry {
  const _MenuSub({
    required this.leading,
    required this.label,
    required this.children,
  });

  final Widget leading;
  final String label;
  final List<_MenuEntry> children;
}

class _MenuDivider extends _MenuEntry {
  const _MenuDivider();
}

// ── Entry assembly ───────────────────────────────────────────────────────────

List<_MenuEntry> _buildEntries({
  required BuildContext context,
  required WidgetRef ref,
  required Ticket ticket,
  required String workspaceId,
  required VoidCallback dismiss,
}) {
  final l10n = AppLocalizations.of(context);
  final workflow = ref.read(ticketWorkflowServiceProvider);
  final linkService = ref.read(ticketLinkServiceProvider);
  final agents =
      ref.read(workspaceAgentsProvider(workspaceId)).asData?.value ??
          const <Agent>[];
  final projects =
      (ref.read(workspaceProjectsProvider(workspaceId)).asData?.value ??
              const <Project>[])
          .where((p) => p.status != ProjectStatus.archived)
          .toList();

  // Status submenu.
  final statusChildren = <_MenuEntry>[
    for (final s in _menuStatuses)
      _MenuAction(
        leading: TicketStatusDot(status: s),
        label: ticketStatusLabel(l10n, s),
        selected: s == ticket.status,
        onTap: () {
          workflow.transitionStatus(ticket.id, s,
              workspaceId: workspaceId, force: true);
          dismiss();
        },
      ),
  ];

  // Priority submenu.
  final priorityChildren = <_MenuEntry>[
    for (final p in TicketPriority.values)
      _MenuAction(
        leading: TicketPriorityIndicator(priority: p, showLabel: false),
        label: ticketPriorityLabel(l10n, p),
        selected: p == ticket.priority,
        onTap: () {
          workflow.updateDetails(
            ticket.id,
            workspaceId: workspaceId,
            priority: p,
          );
          dismiss();
        },
      ),
  ];

  // Assignee submenu.
  final assigneeChildren = <_MenuEntry>[
    _MenuAction(
      leading: const TicketAssigneeAvatar(name: null, size: 18),
      label: l10n.unassigned,
      selected: ticket.assignedAgentId == null,
      onTap: () {
        workflow.assign(ticket.id, workspaceId: workspaceId);
        dismiss();
      },
    ),
    _MenuAction(
      leading: const TicketAssigneeAvatar(name: 'You', size: 18),
      label: 'You',
      selected: ticket.assignedAgentId == TicketCollaborator.userSentinel,
      onTap: () {
        workflow.assign(
          ticket.id,
          workspaceId: workspaceId,
          agentId: TicketCollaborator.userSentinel,
        );
        dismiss();
      },
    ),
    for (final a in agents)
      _MenuAction(
        leading: TicketAssigneeAvatar(name: a.name, size: 18),
        label: a.name,
        selected: ticket.assignedAgentId == a.id,
        onTap: () {
          workflow.assign(ticket.id, workspaceId: workspaceId, agentId: a.id);
          dismiss();
        },
      ),
  ];

  // Project submenu.
  final projectChildren = <_MenuEntry>[
    _MenuAction(
      leading: Icon(LucideIcons.circleSlash, size: 16, color: _hintColor(context)),
      label: l10n.noProject,
      selected: ticket.projectId == null,
      onTap: () {
        workflow.setProject(ticket.id, null, workspaceId: workspaceId);
        dismiss();
      },
    ),
    for (final p in projects)
      _MenuAction(
        leading: ProjectGlyph(color: p.color),
        label: p.name,
        selected: ticket.projectId == p.id,
        onTap: () {
          workflow.setProject(ticket.id, p.id, workspaceId: workspaceId);
          dismiss();
        },
      ),
  ];

  // "Relate to" submenu — each opens the ticket picker.
  Future<void> pickAndRelate(TicketRelationKind kind) async {
    dismiss();
    final otherId = await showTicketPickerDialog(
      context,
      workspaceId: workspaceId,
      title: ticketRelationMenuLabel(l10n, kind),
      excludeTicketIds: {ticket.id},
    );
    if (otherId == null || !context.mounted) {
      return;
    }
    try {
      switch (kind) {
        case TicketRelationKind.subIssueOf:
          await workflow.setParent(ticket.id, otherId,
              workspaceId: workspaceId);
        case TicketRelationKind.parentOf:
          await workflow.setParent(otherId, ticket.id,
              workspaceId: workspaceId);
        default:
          await linkService.addRelation(
            workspaceId: workspaceId,
            subjectTicketId: ticket.id,
            otherTicketId: otherId,
            kind: kind,
          );
      }
    } on ArgumentError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${e.message}')));
      }
    }
  }

  final relateChildren = <_MenuEntry>[
    for (final kind in _relateKinds)
      _MenuAction(
        leading: Icon(
          ticketRelationIcon(kind),
          size: 16,
          color: _hintColor(context),
        ),
        label: ticketRelationMenuLabel(l10n, kind),
        onTap: () => pickAndRelate(kind),
      ),
  ];

  return [
    _MenuSub(
      leading: Icon(LucideIcons.circleDashed, size: 16, color: _hintColor(context)),
      label: l10n.status,
      children: statusChildren,
    ),
    _MenuSub(
      leading: Icon(LucideIcons.signalHigh, size: 16, color: _hintColor(context)),
      label: l10n.priority,
      children: priorityChildren,
    ),
    _MenuSub(
      leading: Icon(LucideIcons.userRound, size: 16, color: _hintColor(context)),
      label: l10n.assignee,
      children: assigneeChildren,
    ),
    _MenuSub(
      leading: Icon(LucideIcons.box, size: 16, color: _hintColor(context)),
      label: l10n.project,
      children: projectChildren,
    ),
    const _MenuDivider(),
    _MenuSub(
      leading: Icon(LucideIcons.gitCompareArrows, size: 16, color: _hintColor(context)),
      label: l10n.relateTo,
      children: relateChildren,
    ),
    const _MenuDivider(),
    _MenuAction(
      leading: Icon(LucideIcons.clipboard, size: 16, color: _hintColor(context)),
      label: l10n.copyId,
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: ticket.id));
        dismiss();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.ticketIdCopied)));
        }
      },
    ),
    const _MenuDivider(),
    _MenuAction(
      leading: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFD92D20)),
      label: l10n.delete,
      destructive: true,
      onTap: () async {
        dismiss();
        await _confirmDelete(context, ref, ticket, workspaceId);
      },
    ),
  ];
}

Color _hintColor(BuildContext context) =>
    (context.designSystem ?? DesignSystemTokens.light()).fgTertiary;

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Ticket ticket,
  String workspaceId,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showFDialog<bool>(
    context: context,
    builder: (ctx, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: Text(l10n.deleteTicket),
      body: Text(l10n.deleteTicketConfirm(ticket.title)),
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
      .read(ticketWorkflowServiceProvider)
      .deleteTicket(ticket.id, workspaceId: workspaceId);
  // If the deleted ticket is the one open in the detail pane, navigate away.
  if (context.mounted &&
      ref.read(selectedTicketIdProvider) == ticket.id) {
    ref.read(selectedTicketIdProvider.notifier).select(null);
    context.go(ticketsRoute);
  }
}

// ── Overlay widget ───────────────────────────────────────────────────────────

/// Width of a menu panel. Submenus flip to the other side when there isn't
/// room for two panels side by side.
const double _panelWidth = 232;

class _ContextMenuOverlay extends StatefulWidget {
  const _ContextMenuOverlay({
    required this.position,
    required this.entries,
    required this.onDismiss,
  });

  final Offset position;
  final List<_MenuEntry> entries;
  final VoidCallback onDismiss;

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay> {
  _MenuSub? _openSub;
  Rect? _openAnchor;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _openSubmenu(_MenuSub sub, Rect anchor) {
    if (_openSub == sub) {
      return;
    }
    setState(() {
      _openSub = sub;
      _openAnchor = anchor;
    });
  }

  void _closeSubmenu() {
    if (_openSub != null) {
      setState(() {
        _openSub = null;
        _openAnchor = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rootHeight = _estimateHeight(widget.entries);
    var left = widget.position.dx;
    var top = widget.position.dy;
    if (left + _panelWidth > size.width - 8) {
      left = size.width - _panelWidth - 8;
    }
    if (top + rootHeight > size.height - 8) {
      top = (size.height - rootHeight - 8).clamp(8.0, size.height);
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onDismiss();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          // Dismiss barrier.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              onSecondaryTap: widget.onDismiss,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: _Panel(
              entries: widget.entries,
              openSub: _openSub,
              onHoverSub: _openSubmenu,
              onHoverLeaf: _closeSubmenu,
            ),
          ),
          if (_openSub != null && _openAnchor != null)
            _buildSubmenu(size, _openSub!, _openAnchor!),
        ],
      ),
    );
  }

  Widget _buildSubmenu(Size size, _MenuSub sub, Rect anchor) {
    final subHeight = _estimateHeight(sub.children);
    var left = anchor.right - 4;
    if (left + _panelWidth > size.width - 8) {
      left = anchor.left - _panelWidth + 4;
    }
    var top = anchor.top - 4;
    if (top + subHeight > size.height - 8) {
      top = (size.height - subHeight - 8).clamp(8.0, size.height);
    }
    return Positioned(
      left: left,
      top: top,
      child: _Panel(
        entries: sub.children,
        openSub: null,
        onHoverSub: (_, _) {},
        onHoverLeaf: () {},
      ),
    );
  }

  double _estimateHeight(List<_MenuEntry> entries) {
    var h = 8.0; // vertical padding
    for (final e in entries) {
      h += e is _MenuDivider ? 9 : 33;
    }
    return h;
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.entries,
    required this.openSub,
    required this.onHoverSub,
    required this.onHoverLeaf,
  });

  final List<_MenuEntry> entries;
  final _MenuSub? openSub;
  final void Function(_MenuSub sub, Rect anchor) onHoverSub;
  final VoidCallback onHoverLeaf;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: _panelWidth,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: t.bgPrimary,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: t.borderSecondary),
          boxShadow: AppShadows.golden,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in entries)
              switch (entry) {
                _MenuDivider() => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(height: 1, color: t.borderSecondary),
                  ),
                final _MenuAction a => _Row(
                    leading: a.leading,
                    label: a.label,
                    selected: a.selected,
                    destructive: a.destructive,
                    onTap: a.onTap,
                    onHover: onHoverLeaf,
                  ),
                final _MenuSub s => _Row(
                    leading: s.leading,
                    label: s.label,
                    hasChildren: true,
                    highlighted: s == openSub,
                    onTap: () {},
                    onHoverWithBox: (rect) => onHoverSub(s, rect),
                  ),
              },
          ],
        ),
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.leading,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.destructive = false,
    this.hasChildren = false,
    this.highlighted = false,
    this.onHover,
    this.onHoverWithBox,
  });

  final Widget leading;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool destructive;
  final bool hasChildren;
  final bool highlighted;
  final VoidCallback? onHover;
  final void Function(Rect globalRect)? onHoverWithBox;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovered = false;

  void _emitHover() {
    widget.onHover?.call();
    final box = context.findRenderObject();
    if (box is RenderBox && widget.onHoverWithBox != null) {
      final topLeft = box.localToGlobal(Offset.zero);
      widget.onHoverWithBox!(topLeft & box.size);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final active = _hovered || widget.highlighted;
    final fg = widget.destructive ? t.fgErrorPrimary : t.textSecondary;
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _emitHover();
      },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? (widget.destructive
                    ? t.fgErrorPrimary.withValues(alpha: 0.10)
                    : t.bgPrimaryHover)
                : Colors.transparent,
            borderRadius: AppRadii.brSm,
          ),
          child: Row(
            children: [
              SizedBox(width: 20, child: Center(child: widget.leading)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: widget.destructive ? fg : t.textPrimary,
                  ),
                ),
              ),
              if (widget.selected)
                Icon(LucideIcons.check, size: 15, color: t.fgBrandPrimary),
              if (widget.hasChildren)
                Icon(LucideIcons.chevronRight, size: 15, color: t.fgQuaternary),
            ],
          ),
        ),
      ),
    );
  }
}
