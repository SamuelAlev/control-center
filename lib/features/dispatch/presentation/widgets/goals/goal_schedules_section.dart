import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/schedule_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The goal's schedules and watches (each opens its page) and the wakes
/// pending for it in its conversation, earliest first.
class GoalSchedulesSection extends ConsumerWidget {
  /// Creates the section.
  const GoalSchedulesSection({super.key, required this.goal});

  /// The goal.
  final AgentGoalRun goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final rules = [
      for (final r
          in ref.watch(workspaceWakeRulesProvider(goal.workspaceId)).value ??
              const <WakeRuleView>[])
        if (r.goalId == goal.id) r,
    ];
    final wakes = [
      for (final w
          in ref
                  .watch(
                    conversationWakesProvider((
                      workspaceId: goal.workspaceId,
                      conversationId: goal.conversationId,
                    )),
                  )
                  .value ??
              const <WakeView>[])
        if (w.goalId == goal.id) w,
    ];
    final label = workSectionLabelStyle(ds);
    final body = CcTypography.bodySm.copyWith(color: ds.textSecondary);
    return WorkSection(
      title: l10n.goalSectionSchedules,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rules.isEmpty && wakes.isEmpty)
            Text(l10n.goalNoSchedules, style: body),
          for (final r in rules)
            CcTappable(
              onPressed: () =>
                  context.go(scheduleRoute(goal.workspaceId, r.id)),
              semanticLabel: l10n.workFeedOpenSchedule,
              builder: (context, states) => ColoredBox(
                color: states.contains(WidgetState.hovered)
                    ? ds.bgPrimaryHover
                    : const Color(0x00000000),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: AppSpacing.xs,
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    scheduleTriggerSentence(context, r) ?? r.trigger,
                    style: body.copyWith(color: ds.textPrimary),
                  ),
                ),
              ),
            ),
          if (wakes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.goalPendingWakes, style: label),
            for (final w in wakes)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        inertText(w.headline, singleLine: true),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: body,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    WorkTime(
                      at: w.notBefore,
                      text: workTimeLabel(context, w.notBefore),
                      style: label,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
