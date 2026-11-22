import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/features/dispatch/presentation/goal_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_list_row.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_record_states.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/features/messaging/providers/goal_card_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Every goal of the workspace the viewer may see: those waiting for review
/// first, then the open ones, then the ended ones, newest first in each.
class GoalsList extends ConsumerWidget {
  /// Creates the list.
  const GoalsList({super.key, required this.workspaceId});

  /// The workspace.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return WorkListStates<GoalRunView>(
      value: ref.watch(workspaceGoalRunsProvider(workspaceId)),
      emptyIcon: AppIcons.target,
      empty: l10n.goalsEmpty,
      emptyDescription: l10n.goalsEmptyHint,
      builder: (goals) {
        final review = [
          for (final v in goals)
            if (goalIsOpen(v.goal) && v.goal.hold == GoalHold.needsReview) v,
        ];
        final open = [
          for (final v in goals)
            if (goalIsOpen(v.goal) && v.goal.hold != GoalHold.needsReview) v,
        ];
        final ended = [
          for (final v in goals)
            if (!goalIsOpen(v.goal)) v,
        ];
        return ListView(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          children: [
            for (final (label, group) in [
              (l10n.goalsGroupReview, review),
              (l10n.goalsGroupOpen, open),
              (l10n.goalsGroupEnded, ended),
            ])
              if (group.isNotEmpty) ...[
                WorkListGroupHeading(label: label, count: group.length),
                for (var i = 0; i < group.length; i++)
                  GoalRow(view: group[i], first: i == 0),
              ],
          ],
        );
      },
    );
  }
}

/// One goal in the list: its status, objective, agent, segments and money.
class GoalRow extends ConsumerWidget {
  /// Creates the row.
  const GoalRow({super.key, required this.view, this.first = false});

  /// The goal.
  final GoalRunView view;

  /// Whether this is the first row of its group.
  final bool first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final goal = view.goal;
    final agent =
        ref.watch(
          workAgentNameProvider((
            workspaceId: goal.workspaceId,
            agentId: goal.agentId,
          )),
        ) ??
        l10n.workAgentUnknown;
    return WorkListRow(
      first: first,
      tag: CcStatusTag(
        label: goalStatusLabel(l10n, goal.status),
        tone: goalStatusTone(goal.status),
      ),
      title: inertText(goal.userText, singleLine: true),
      meta: [
        [
          agent,
          if (goal.maxRuns == null)
            l10n.goalCardSegmentsNoCap(goal.runCount)
          else
            l10n.goalCardSegments(goal.runCount, goal.maxRuns!),
          l10n.goalCardMoney(
            fmtMicros(goal.costMicros, decimals: 2, locale: locale),
            fmtMicros(goal.costCapMicros, decimals: 2, locale: locale),
          ),
        ].join(' · '),
        ?goalListLine(context, goal),
      ],
      trailing: AppTimestamp.relative(
        goal.updatedAt,
        style: CcTypography.caption.copyWith(color: ds.textTertiary),
      ),
      onPressed: () => context.go(goalRoute(goal.workspaceId, goal.id)),
    );
  }
}
