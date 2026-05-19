import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_detail_row_widgets.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_edit_dialogs.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Action items tab: each persisted action item with a checkbox (its
/// `done` state is stored on the row), an owner line, edit/delete affordances,
/// and a "Create ticket" action that files a real ticket and links it back to
/// the item. A footer row adds a custom action item the agent didn't extract.
class MeetingActionItemsTab extends ConsumerWidget {
  /// Creates a [MeetingActionItemsTab].
  const MeetingActionItemsTab({
    super.key,
    required this.meeting,
    required this.actionItems,
  });

  /// The meeting these action items belong to.
  final Meeting meeting;

  /// The persisted action items.
  final List<MeetingActionItem> actionItems;

  Future<void> _add(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return showCcDialog<void>(
      context: context,
      builder: (_) => MeetingActionItemDialog(
        title: l10n.meetingAddActionItem,
        submitLabel: l10n.add,
        onSubmit: (content, owner) {
          ref.read(meetingRecorderControllerProvider.notifier).addActionItem(
                meeting.id,
                content: content,
                owner: owner,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    if (actionItems.isEmpty) {
      return SectionCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Column(
            children: [
              Text(
                l10n.meetingActionItemsEmpty,
                style: TextStyle(color: ds.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                onPressed: () => _add(context, ref),
                icon: LucideIcons.plus,
                child: Text(l10n.meetingAddActionItem),
              ),
            ],
          ),
        ),
      );
    }
    return SectionCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < actionItems.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: ds.borderSecondary),
              _ActionItemRow(meeting: meeting, item: actionItems[i]),
            ],
            Divider(height: 1, thickness: 1, color: ds.borderSecondary),
            MeetingAddRow(
              label: l10n.meetingAddActionItem,
              onTap: () => _add(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItemRow extends ConsumerWidget {
  const _ActionItemRow({required this.meeting, required this.item});

  final Meeting meeting;
  final MeetingActionItem item;

  Future<void> _createTicket(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    try {
      final ticket = await ref.read(ticketWorkflowServiceProvider).createTicket(
            workspaceId: meeting.workspaceId,
            title: item.content,
            description: 'From meeting: ${meeting.title}',
          );
      final key = ticket.externalKey ?? ticket.id;
      await ref.read(meetingRepositoryProvider).setActionItemTicket(
            workspaceId: meeting.workspaceId,
            id: item.id,
            ticketId: key,
          );
      final shown = key.split('-').first.toUpperCase();
      toaster.show(
        l10n.meetingTicketCreated(shown),
        variant: CcToastVariant.success,
      );
    } on Object {
      toaster.show(l10n.meetingTicketFailed, variant: CcToastVariant.danger);
    }
  }

  Future<void> _toggleDone(WidgetRef ref) async {
    await ref.read(meetingRepositoryProvider).setActionItemDone(
          workspaceId: meeting.workspaceId,
          id: item.id,
          done: !item.done,
        );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return showCcDialog<void>(
      context: context,
      builder: (_) => MeetingActionItemDialog(
        title: l10n.meetingEditActionItem,
        submitLabel: l10n.save,
        initialContent: item.content,
        initialOwner: item.owner,
        onSubmit: (content, owner) {
          ref.read(meetingRecorderControllerProvider.notifier).updateActionItem(
                item.id,
                content: content,
                owner: owner,
              );
        },
      ),
    );
  }

  void _delete(WidgetRef ref) {
    ref.read(meetingRecorderControllerProvider.notifier).deleteActionItem(item.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final done = item.done;
    final ticket = item.ticketId;
    final owner = item.owner;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Checkbox(done: done, onTap: () => _toggleDone(ref)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: done ? ds.muted : ds.fg,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(LucideIcons.user, size: 12, color: ds.muted),
                    const SizedBox(width: 5),
                    Text(
                      owner != null && owner.isNotEmpty
                          ? owner
                          : l10n.meetingActionItemFrom,
                      style: meetingMono(context, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (ticket != null && ticket.isNotEmpty)
            _TicketTag(label: ticket.split('-').first.toUpperCase())
          else
            CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: () => _createTicket(context, ref),
              icon: LucideIcons.plus,
              child: Text(l10n.meetingCreateTicket),
            ),
          const SizedBox(width: AppSpacing.xs),
          MeetingRowIconButton(
            icon: LucideIcons.pencil,
            tooltip: l10n.meetingEditActionItem,
            onTap: () => _edit(context, ref),
          ),
          MeetingRowIconButton(
            icon: LucideIcons.trash2,
            tooltip: l10n.meetingDeleteActionItem,
            onTap: () => _delete(ref),
          ),
        ],
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brSm,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: done ? ds.success : ds.panel,
            borderRadius: AppRadii.brSm,
            border: Border.all(
              color: done ? ds.success : ds.fg.withValues(alpha: 0.3),
            ),
          ),
          child: done
              ? Icon(LucideIcons.check, size: 12, color: ds.panel)
              : null,
        ),
      ),
    );
  }
}

class _TicketTag extends StatelessWidget {
  const _TicketTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: context.mSuccessSoft,
        borderRadius: AppRadii.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.ticket, size: 12, color: context.mSuccess),
          const SizedBox(width: 5),
          Text(label, style: meetingMono(context, fontSize: 11, color: context.mSuccess)),
        ],
      ),
    );
  }
}
