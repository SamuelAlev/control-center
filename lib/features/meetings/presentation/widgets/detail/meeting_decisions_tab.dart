import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_detail_row_widgets.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_edit_dialogs.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Decisions tab: a numbered list of the decisions the agent extracted,
/// each editable/deletable, with a footer row to add a custom decision. Each
/// decision's first sentence reads as a heading, the remainder as body.
class MeetingDecisionsTab extends ConsumerWidget {
  /// Creates a [MeetingDecisionsTab].
  const MeetingDecisionsTab({
    super.key,
    required this.meeting,
    required this.decisions,
  });

  /// The meeting these decisions belong to.
  final Meeting meeting;

  /// The persisted decisions, in order.
  final List<MeetingDecision> decisions;

  Future<void> _add(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return showCcDialog<void>(
      context: context,
      builder: (_) => MeetingTextFieldDialog(
        title: l10n.meetingAddDecision,
        label: l10n.meetingDecisionContentLabel,
        hint: l10n.meetingDecisionContentHint,
        submitLabel: l10n.add,
        multiline: true,
        onSubmit: (value) {
          ref
              .read(meetingRecorderControllerProvider.notifier)
              .addDecision(meeting.id, content: value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    if (decisions.isEmpty) {
      return SectionCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Column(
            children: [
              Text(
                l10n.meetingDecisionsEmpty,
                style: TextStyle(color: ds.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                onPressed: () => _add(context, ref),
                icon: AppIcons.plus,
                child: Text(l10n.meetingAddDecision),
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
            for (var i = 0; i < decisions.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: ds.borderSecondary),
              _DecisionRow(index: i, meeting: meeting, decision: decisions[i]),
            ],
            Divider(height: 1, thickness: 1, color: ds.borderSecondary),
            MeetingAddRow(
              label: l10n.meetingAddDecision,
              onTap: () => _add(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionRow extends ConsumerWidget {
  const _DecisionRow({
    required this.index,
    required this.meeting,
    required this.decision,
  });

  final int index;
  final Meeting meeting;
  final MeetingDecision decision;

  Future<void> _edit(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return showCcDialog<void>(
      context: context,
      builder: (_) => MeetingTextFieldDialog(
        title: l10n.meetingEditDecision,
        label: l10n.meetingDecisionContentLabel,
        hint: l10n.meetingDecisionContentHint,
        submitLabel: l10n.save,
        multiline: true,
        initialValue: decision.content,
        onSubmit: (value) {
          ref
              .read(meetingRecorderControllerProvider.notifier)
              .updateDecision(decision.id, content: value);
        },
      ),
    );
  }

  void _delete(WidgetRef ref) {
    ref
        .read(meetingRecorderControllerProvider.notifier)
        .deleteDecision(decision.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final (heading, body) = _split(decision.content);
    final number = (index + 1).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              number,
              style: meetingMono(context, fontSize: 14, color: ds.accent),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: ds.fg,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: TextStyle(fontSize: 13, height: 1.5, color: ds.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          MeetingRowIconButton(
            icon: AppIcons.pencil,
            tooltip: l10n.meetingEditDecision,
            onTap: () => _edit(context, ref),
          ),
          MeetingRowIconButton(
            icon: AppIcons.trash2,
            tooltip: l10n.meetingDeleteDecision,
            onTap: () => _delete(ref),
          ),
        ],
      ),
    );
  }

  /// Splits a decision into a heading (first sentence) and an optional body.
  static (String, String?) _split(String text) {
    final match = RegExp(r'^(.+?[.!?])\s+(.+)$', dotAll: true).firstMatch(text);
    if (match != null) {
      final head = match.group(1)!.trim();
      final rest = match.group(2)!.trim();
      // Only split when the heading is a reasonable, short lead.
      if (head.length <= 120 && rest.isNotEmpty) {
        return (head, rest);
      }
    }
    return (text, null);
  }
}
