import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/features/dispatch/presentation/schedule_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedule_create_dialog.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_list_row.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_record_states.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The page-header action that creates a person's schedule.
class NewScheduleButton extends StatelessWidget {
  /// Creates the button.
  const NewScheduleButton({super.key, required this.workspaceId});

  /// The workspace.
  final String workspaceId;

  @override
  Widget build(BuildContext context) => CcButton(
    size: CcButtonSize.sm,
    icon: AppIcons.plus,
    onPressed: () => showScheduleCreateDialog(context, workspaceId),
    child: Text(AppLocalizations.of(context).scheduleNew),
  );
}

/// The settings card listing every schedule and watch of the workspace the
/// viewer may read, grouped active, paused, ended. It sizes to its rows and
/// scrolls with the page; the page header carries [NewScheduleButton].
class SchedulesList extends ConsumerWidget {
  /// Creates the list.
  const SchedulesList({super.key, required this.workspaceId});

  /// The workspace.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(workspaceWakeRulesProvider(workspaceId));
    return SectionCard(
      label: l10n.schedulesTitle,
      count: rules.value?.length,
      padding: EdgeInsets.zero,
      headerPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        14,
        AppSpacing.lg,
        0,
      ),
      // A row insets its own text by `sm`, so this lines the text up with the
      // card's label and leaves the hover wash a margin from the card's edge.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: WorkListStates<WakeRuleView>(
          value: rules,
          emptyIcon: AppIcons.clock,
          empty: l10n.schedulesEmpty,
          emptyDescription: l10n.schedulesEmptyHint,
          builder: (rules) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final status in WakeRuleStatus.values)
                if (rules.where((r) => r.status == status).toList()
                    case final group when group.isNotEmpty) ...[
                  WorkListGroupHeading(
                    label: scheduleStatusLabel(l10n, status),
                    count: group.length,
                  ),
                  for (var i = 0; i < group.length; i++)
                    ScheduleRow(rule: group[i], first: i == 0),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One schedule in the list: the trigger in words (a cron's next three fire
/// times in the viewer's zone), agent and conversation, owner, runs and
/// skips, money of its cap, expiry, and its next fire at the end.
class ScheduleRow extends ConsumerWidget {
  /// Creates the row.
  const ScheduleRow({super.key, required this.rule, this.first = false});

  /// The schedule.
  final WakeRuleView rule;

  /// Whether this is the first row of its group.
  final bool first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final ws = rule.workspaceId;
    final locale = Localizations.localeOf(context).toString();
    final agent =
        ref.watch(
          workAgentNameProvider((workspaceId: ws, agentId: rule.agentId)),
        ) ??
        l10n.workAgentUnknown;
    final where = ref.watch(
      workConversationLabelProvider((
        workspaceId: ws,
        spaceId: rule.spaceId,
        conversationId: rule.conversationId,
      )),
    );
    final owner = rule.ownerUserId == null
        ? null
        : ref.watch(
            workMemberNameProvider((
              workspaceId: ws,
              userId: rule.ownerUserId!,
            )),
          );
    final trigger = ruleTrigger(rule);
    final fires = trigger is Cron && rule.status == WakeRuleStatus.active
        ? upcomingFires(rule, DateTime.now().toUtc())
        : const <DateTime>[];
    final next = rule.nextFireAt;
    return WorkListRow(
      first: first,
      tag: CcStatusTag(
        label: scheduleStatusLabel(l10n, rule.status),
        tone: scheduleStatusTone(rule.status),
      ),
      title: scheduleTriggerSentence(context, rule) ?? rule.trigger,
      meta: [
        [
          agent,
          ?where,
          if (owner != null) l10n.scheduleOwnedBy(owner),
        ].join(' · '),
        [
          l10n.scheduleRunsSkips(rule.runCount, rule.skipCount),
          l10n.goalCardMoney(
            fmtMicros(rule.costMicros, decimals: 2, locale: locale),
            fmtMicros(rule.costCapMicros, decimals: 2, locale: locale),
          ),
          if (rule.status != WakeRuleStatus.ended)
            l10n.scheduleExpires(workTimeLabel(context, rule.expiresAt)),
        ].join(' · '),
        if (fires.isNotEmpty)
          l10n.scheduleNextFires(
            fires.map((f) => workTimeLabel(context, f)).join(' · '),
          ),
      ],
      trailing: next == null || rule.status != WakeRuleStatus.active
          ? null
          : AppTimestamp.relative(
              next,
              style: CcTypography.caption.copyWith(color: ds.textTertiary),
            ),
      onPressed: () => context.go(scheduleRoute(ws, rule.id)),
    );
  }
}
