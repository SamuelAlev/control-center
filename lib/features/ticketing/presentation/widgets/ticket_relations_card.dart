import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_link.dart';
import 'package:control_center/features/ticketing/presentation/widgets/project_visuals.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_picker_dialog.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The order relation groups are listed in the relations card.
const _relationOrder = [
  TicketRelationKind.subIssueOf,
  TicketRelationKind.parentOf,
  TicketRelationKind.blockedBy,
  TicketRelationKind.blocking,
  TicketRelationKind.relatedTo,
  TicketRelationKind.duplicateOf,
  TicketRelationKind.duplicatedBy,
];

/// The relation kinds offered when adding a relation (the picker is opened
/// after choosing the kind). `duplicatedBy` is omitted — it is the inverse of
/// `duplicateOf` and set from the other ticket.
const _addableKinds = [
  TicketRelationKind.subIssueOf,
  TicketRelationKind.parentOf,
  TicketRelationKind.relatedTo,
  TicketRelationKind.blockedBy,
  TicketRelationKind.blocking,
  TicketRelationKind.duplicateOf,
];

/// A card listing the ticket's dependencies and tree links (parent,
/// sub-issues, blocked by / blocking / related / duplicate), each clickable to
/// open the linked ticket, with hover-to-remove and an add control.
class TicketRelationsCard extends ConsumerWidget {
  /// Creates a [TicketRelationsCard].
  const TicketRelationsCard({
    super.key,
    required this.ticket,
    required this.workspaceId,
  });

  /// The subject ticket.
  final Ticket ticket;

  /// The owning workspace.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    final tickets = ref.watch(workspaceTicketsProvider(workspaceId)).asData
            ?.value ??
        const <Ticket>[];
    final byId = {for (final tk in tickets) tk.id: tk};
    final links = ref
            .watch(ticketLinksProvider(
                (workspaceId: workspaceId, ticketId: ticket.id)))
            .asData
            ?.value ??
        const <TicketLink>[];

    // Group resolved (kind → list of other tickets).
    final grouped = <TicketRelationKind, List<Ticket>>{};
    void add(TicketRelationKind kind, String? otherId) {
      final other = otherId == null ? null : byId[otherId];
      if (other == null) {
        return;
      }
      grouped.putIfAbsent(kind, () => []).add(other);
    }

    if (ticket.parentTicketId != null) {
      add(TicketRelationKind.subIssueOf, ticket.parentTicketId);
    }
    for (final tk in tickets) {
      if (tk.parentTicketId == ticket.id) {
        add(TicketRelationKind.parentOf, tk.id);
      }
    }
    for (final link in links) {
      final view = link.relationFor(ticket.id);
      if (view != null) {
        add(view.kind, view.otherTicketId);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: t.borderSecondary),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.relations,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: t.textTertiary,
                  ),
                ),
              ),
              _AddRelationButton(ticket: ticket, workspaceId: workspaceId),
            ],
          ),
          if (grouped.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                l10n.noMatchingTickets,
                style: TextStyle(fontSize: 13, color: t.textQuaternary),
              ),
            )
          else
            for (final kind in _relationOrder)
              if (grouped[kind] != null)
                _RelationGroup(
                  kind: kind,
                  tickets: grouped[kind]!,
                  subjectTicket: ticket,
                  workspaceId: workspaceId,
                ),
        ],
      ),
    );
  }
}

class _RelationGroup extends ConsumerWidget {
  const _RelationGroup({
    required this.kind,
    required this.tickets,
    required this.subjectTicket,
    required this.workspaceId,
  });

  final TicketRelationKind kind;
  final List<Ticket> tickets;
  final Ticket subjectTicket;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(ticketRelationIcon(kind), size: 13, color: t.fgQuaternary),
              const SizedBox(width: 6),
              Text(
                ticketRelationGroupLabel(l10n, kind),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: t.textQuaternary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final other in tickets)
            _RelationRow(
              other: other,
              onRemove: () => _remove(ref, other),
            ),
        ],
      ),
    );
  }

  void _remove(WidgetRef ref, Ticket other) {
    final workflow = ref.read(ticketWorkflowServiceProvider);
    final linkService = ref.read(ticketLinkServiceProvider);
    switch (kind) {
      case TicketRelationKind.subIssueOf:
        workflow.clearParent(subjectTicket.id, workspaceId: workspaceId);
      case TicketRelationKind.parentOf:
        workflow.clearParent(other.id, workspaceId: workspaceId);
      default:
        linkService.removeRelation(
          workspaceId: workspaceId,
          subjectTicketId: subjectTicket.id,
          otherTicketId: other.id,
          kind: kind,
        );
    }
  }
}

class _RelationRow extends StatefulWidget {
  const _RelationRow({required this.other, required this.onRemove});

  final Ticket other;
  final VoidCallback onRemove;

  @override
  State<_RelationRow> createState() => _RelationRowState();
}

class _RelationRowState extends State<_RelationRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go(ticketDetailRoute(widget.other.id)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              TicketStatusDot(status: widget.other.status),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.other.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: t.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_hovered)
                CcTappable(
                  onPressed: widget.onRemove,
                  builder: (context, states) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(LucideIcons.x, size: 14, color: t.fgQuaternary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddRelationButton extends ConsumerStatefulWidget {
  const _AddRelationButton({required this.ticket, required this.workspaceId});

  final Ticket ticket;
  final String workspaceId;

  @override
  ConsumerState<_AddRelationButton> createState() => _AddRelationButtonState();
}

class _AddRelationButtonState extends ConsumerState<_AddRelationButton> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndApply(TicketRelationKind kind) async {
    _controller.hide();
    final l10n = AppLocalizations.of(context);
    // Exclude self + already-related tickets in this kind would need the link
    // set; excluding self is enough (idempotent links, cycle-guarded parents).
    final otherId = await showTicketPickerDialog(
      context,
      workspaceId: widget.workspaceId,
      title: ticketRelationMenuLabel(l10n, kind),
      excludeTicketIds: {widget.ticket.id},
    );
    if (otherId == null || !mounted) {
      return;
    }
    final workflow = ref.read(ticketWorkflowServiceProvider);
    final linkService = ref.read(ticketLinkServiceProvider);
    try {
      switch (kind) {
        case TicketRelationKind.subIssueOf:
          await workflow.setParent(widget.ticket.id, otherId,
              workspaceId: widget.workspaceId);
        case TicketRelationKind.parentOf:
          await workflow.setParent(otherId, widget.ticket.id,
              workspaceId: widget.workspaceId);
        default:
          await linkService.addRelation(
            workspaceId: widget.workspaceId,
            subjectTicketId: widget.ticket.id,
            otherTicketId: otherId,
            kind: kind,
          );
      }
    } on ArgumentError catch (e) {
      if (mounted) {
        CcToastScope.of(context)
            .show('${e.message}', variant: CcToastVariant.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final card = CcCardTokens.panel(t);
    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      target: CcTappable(
        onPressed: _controller.toggle,
        builder: (context, states) => Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(LucideIcons.plus, size: 16, color: t.fgTertiary),
        ),
      ),
      overlayBuilder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: card.bg,
            borderRadius: AppRadii.brLg,
            border: Border.all(color: card.border),
            boxShadow: CcElevation.floating,
          ),
          child: ClipRRect(
            borderRadius: AppRadii.brLg,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final kind in _addableKinds)
                    CcTile(
                      leadingIcon: ticketRelationIcon(kind),
                      title: ticketRelationMenuLabel(l10n, kind),
                      onTap: () => _pickAndApply(kind),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
