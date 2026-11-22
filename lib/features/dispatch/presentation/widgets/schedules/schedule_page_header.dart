import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/dispatch/presentation/schedule_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedule_extend_dialog.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_kind_text.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The top of a schedule's page: back, the trigger in words, its status (and
/// why it ended), the note its runs start from with whose words it is, and
/// the controls. Pause and delete are any member's; resume and extend are
/// the owner's (the server's `can_change`). A rule in a chain is extended
/// through the chain's first rule, which the header links to.
class SchedulePageHeader extends ConsumerWidget {
  /// Creates the header.
  const SchedulePageHeader({
    super.key,
    required this.rule,
    required this.onBack,
  });

  /// The schedule.
  final WakeRuleView rule;

  /// Leaves the page.
  final VoidCallback onBack;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ended = rule.status == WakeRuleStatus.ended;
    final ok = await showCcDialog<bool>(
      context: context,
      builder: (d) => CcDialog(
        title: ended ? l10n.scheduleRemoveTitle : l10n.scheduleDeleteTitle,
        content: Text(
          ended ? l10n.scheduleRemoveBody : l10n.scheduleDeleteBody,
        ),
        actions: [
          CcButton(
            variant: CcButtonVariant.ghost,
            onPressed: () => Navigator.of(d).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.of(d).pop(true),
            child: Text(ended ? l10n.scheduleRemove : l10n.scheduleDelete),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final done = await runDispatchAction(
        context,
        () => ref
            .read(wakeRuleScheduleRepositoryProvider)
            .delete(rule.workspaceId, rule.id),
      );
      if (done && ended && context.mounted) {
        onBack();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(wakeRuleScheduleRepositoryProvider);
    final ws = rule.workspaceId;
    final active = rule.status == WakeRuleStatus.active;
    final paused = rule.status == WakeRuleStatus.paused;
    final root = rule.rootRuleId;
    final chained = root != null && root != rule.id;
    final editor = rule.noteEditedByUserId == null
        ? null
        : ref.watch(
            workMemberNameProvider((
              workspaceId: ws,
              userId: rule.noteEditedByUserId!,
            )),
          );
    final caption = CcTypography.caption.copyWith(color: ds.textTertiary);
    final ownerOnly = rule.canChange ? null : l10n.scheduleOwnerOnly;
    final end = rule.endReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          icon: AppIcons.arrowLeft,
          onPressed: onBack,
          child: Text(l10n.schedulesBackToList),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                scheduleTriggerSentence(context, rule) ?? rule.trigger,
                style: CcTypography.body.copyWith(
                  color: ds.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            CcStatusTag(
              label: scheduleStatusLabel(l10n, rule.status),
              tone: scheduleStatusTone(rule.status),
            ),
          ],
        ),
        if (end != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          KindSentence(
            sentence: wakeRuleEndReasonSentence(l10n, end.wire),
            lead: l10n.wakeKindUnknown,
            kind: end.wire,
            style: caption,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          rule.noteAuthor == WakeRuleOrigin.agent
              ? l10n.scheduleNoteByAgent
              : editor != null
              ? l10n.scheduleNoteEditedBy(editor)
              : l10n.scheduleNoteByPerson,
          style: caption,
        ),
        const SizedBox(height: AppSpacing.xxs),
        // The note is data (an agent's or a person's words): plain text.
        Text(
          rule.note.trim().isEmpty ? l10n.scheduleNoNote : inertText(rule.note),
          style: CcTypography.bodySm.copyWith(color: ds.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (active)
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                icon: AppIcons.pause,
                onPressed: () =>
                    runDispatchAction(context, () => repo.pause(ws, rule.id)),
                child: Text(l10n.schedulePause),
              ),
            if (paused)
              WorkTip(
                message: ownerOnly,
                child: CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  icon: AppIcons.play,
                  onPressed: rule.canChange
                      ? () => runDispatchAction(
                          context,
                          () => repo.resume(ws, rule.id),
                        )
                      : null,
                  child: Text(l10n.scheduleResume),
                ),
              ),
            if ((active || paused) && !chained)
              WorkTip(
                message: ownerOnly,
                child: CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  icon: AppIcons.calendarClock,
                  onPressed: rule.canChange
                      ? () => showScheduleExtendDialog(context, rule)
                      : null,
                  child: Text(l10n.scheduleExtend),
                ),
              ),
            if (chained)
              CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                onPressed: () => context.go(scheduleRoute(ws, root)),
                child: Text(l10n.scheduleOpenChainRoot),
              ),
            CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              icon: AppIcons.trash2,
              onPressed: () => _delete(context, ref),
              child: Text(
                rule.status == WakeRuleStatus.ended
                    ? l10n.scheduleRemove
                    : l10n.scheduleDelete,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
