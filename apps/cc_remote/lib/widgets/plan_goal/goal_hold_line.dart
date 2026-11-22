import 'dart:math' as math;

import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_remote/work_kind_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// What a live goal is doing, in words: who must act and what happens next.
/// Null for a goal that ended (its status says it all).
String? goalHoldSentence(BuildContext context, AgentGoalRun goal) {
  final l = AppLocalizations.of(context);
  // A goal at its budget is terminal for the supervisor, but a person may
  // still raise the budget and resume it.
  if (goal.status == AgentGoalStatus.budgetExhausted) return l.goalHoldBudget;
  if (goal.status.isTerminal) return null;
  final until = goal.holdUntil;
  final time = until == null ? null : workTime(context, until);
  return switch (goal.hold) {
    GoalHold.waiting =>
      time == null ? l.goalHoldWaiting : l.goalHoldWaitingUntil(time),
    GoalHold.verifying => l.goalHoldVerifying,
    GoalHold.limit =>
      time == null ? l.goalHoldLimit : l.goalHoldLimitUntil(time),
    GoalHold.person => l.goalHoldPerson,
    GoalHold.byPerson => l.goalHoldByPerson,
    GoalHold.needsReview => l.goalHoldNeedsReview,
    null =>
      goal.status == AgentGoalStatus.paused
          ? l.goalHoldByPerson
          : l.goalHoldWorking(math.max(goal.runCount, 1)),
  };
}

/// Whether a goal stopped at its budget offers a raise. The server decides
/// whether the raise is enough and refuses with a kind otherwise.
bool goalBudgetRaisable(AgentGoalRun goal) =>
    goal.status == AgentGoalStatus.budgetExhausted;

/// Whether the goal waits for a person to decide or answer.
bool goalNeedsPerson(AgentGoalRun goal) =>
    goalBudgetRaisable(goal) ||
    (!goal.status.isTerminal &&
        (goal.hold == GoalHold.needsReview || goal.hold == GoalHold.person));

/// The hold sentence with its glyph, the hold detail (a known detail as a
/// sentence; a command or an unknown detail in code style) and, at a usage
/// limit, how often it has parked.
class GoalHoldLine extends StatelessWidget {
  const GoalHoldLine({super.key, required this.goal, this.compact = false});

  final AgentGoalRun goal;

  /// One line, without the detail and the park count (list rows).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final sentence = goalHoldSentence(context, goal);
    if (sentence == null) return const SizedBox.shrink();
    final attention = goalNeedsPerson(goal);
    final icon = switch (goal.hold) {
      GoalHold.waiting || GoalHold.limit => AppIcons.clock,
      GoalHold.verifying => AppIcons.eye,
      GoalHold.person || GoalHold.needsReview => AppIcons.user,
      GoalHold.byPerson => AppIcons.circleSlash,
      null => attention ? AppIcons.user : AppIcons.loader,
    };
    final style = CcTypography.bodySm.copyWith(
      color: attention ? t.textPrimary : t.textSecondary,
      fontWeight: attention ? FontWeight.w600 : FontWeight.w400,
    );
    final detail = goal.holdDetail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Icon(
                icon,
                size: 14,
                color: attention ? t.accent : t.textTertiary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                sentence,
                maxLines: compact ? 2 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
                style: style,
              ),
            ),
          ],
        ),
        if (!compact && detail != null && detail.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 22, top: 4),
            // While waiting, the detail is the server's own summary of what
            // the goal is owed (English data), not a kind.
            child: goal.hold == GoalHold.waiting
                ? Text(
                    inertText(detail),
                    style: CcTypography.caption.copyWith(
                      color: t.textSecondary,
                    ),
                  )
                : _HoldDetail(detail: detail),
          ),
        if (!compact && goal.hold == GoalHold.limit && goal.parkCount > 0)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 22, top: 4),
            child: Text(
              l.goalHoldLimitParks(goal.parkCount, LimitPark.maxGoalParks),
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _HoldDetail extends StatelessWidget {
  const _HoldDetail({required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final read = goalHoldDetailText(l, detail);
    final style = CcTypography.bodySm.copyWith(color: t.textSecondary);
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(read.sentence ?? l.workKindUnknown, style: style),
        if (read.followUp != null) Text(read.followUp!, style: style),
        if (read.code != null) WorkCode(read.code!),
      ],
    );
  }
}
