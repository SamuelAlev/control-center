import 'dart:math' as math;

import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_kind_text.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';

/// What a live goal is doing now, and why it holds when it does: one
/// sentence for the hold (waiting, verifying, at a usage limit, needing a
/// person, paused by a person, waiting for review), then the hold detail.
class GoalStatusLine extends StatelessWidget {
  /// Creates the line.
  const GoalStatusLine({super.key, required this.goal});

  /// The goal.
  final AgentGoalRun goal;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final until = goal.holdUntil;
    final time = until == null ? null : workTimeLabel(context, until);
    final (IconData icon, String sentence) = switch (goal.hold) {
      GoalHold.waiting => (
        AppIcons.clock,
        // The server sends when the doubling fallback looks again; the
        // goal may wake sooner, when what it waits on arrives.
        time == null ? l10n.goalCardWaiting : l10n.goalCardWaitingNext(time),
      ),
      GoalHold.verifying => (AppIcons.scanSearch, l10n.goalCardVerifying),
      GoalHold.limit => (
        AppIcons.gauge,
        time == null ? l10n.goalCardLimit : l10n.goalCardLimitUntil(time),
      ),
      GoalHold.person => (AppIcons.user, l10n.goalCardPerson),
      GoalHold.byPerson => (AppIcons.pause, l10n.goalCardByPerson),
      GoalHold.needsReview => (AppIcons.eye, l10n.goalCardNeedsReview),
      null => (
        AppIcons.loaderCircle,
        goal.status == AgentGoalStatus.active
            ? l10n.goalCardWorking(math.max(goal.runCount, 1))
            : '',
      ),
    };
    final detail = goal.holdDetail;
    final style = CcTypography.caption.copyWith(color: ds.textSecondary);
    final lines = <Widget>[
      if (sentence.isNotEmpty)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 1),
              child: Icon(icon, size: 12, color: ds.textTertiary),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: until == null
                  ? Text(sentence, style: style)
                  : WorkTime(at: until, text: sentence, style: style),
            ),
          ],
        ),
      if (detail != null && detail.isNotEmpty) _HoldDetail(detail: detail),
    ];
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 14 + AppSpacing.xs,
        top: 3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: lines,
      ),
    );
  }
}

class _HoldDetail extends StatelessWidget {
  const _HoldDetail({required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final read = goalHoldDetailSentence(l10n, detail);
    final style = CcTypography.caption.copyWith(color: ds.textTertiary);
    final sentence = read.sentence;
    final code = read.code;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 12 + AppSpacing.xs,
        top: 1,
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(sentence ?? l10n.wakeKindUnknown, style: style),
          if (read.followUp != null) Text(read.followUp!, style: style),
          if (code != null) WorkCode(code),
        ],
      ),
    );
  }
}

/// What a live goal has spent of its caps: segments of the run cap, money of
/// the cost cap (with a thin meter) and time left before its deadline.
class GoalBudgetLine extends StatelessWidget {
  /// Creates the line.
  const GoalBudgetLine({super.key, required this.goal});

  /// The goal.
  final AgentGoalRun goal;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final maxRuns = goal.maxRuns;
    final deadline = goal.deadlineAt;
    final parts = <String>[
      if (maxRuns == null)
        l10n.goalCardSegmentsNoCap(goal.runCount)
      else
        l10n.goalCardSegments(goal.runCount, maxRuns),
      l10n.goalCardMoney(
        fmtMicros(goal.costMicros, decimals: 2),
        fmtMicros(goal.costCapMicros, decimals: 2),
      ),
      if (deadline != null)
        deadline.isAfter(DateTime.now())
            ? l10n.goalCardTimeLeft(
                workDurationLabel(deadline.difference(DateTime.now())),
              )
            : l10n.goalCardOverdue,
    ];
    final fraction = goal.costCapMicros <= 0
        ? 0.0
        : (goal.costMicros / goal.costCapMicros).clamp(0.0, 1.0);
    final text = Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CcTypography.caption.copyWith(color: ds.textTertiary),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 14 + AppSpacing.xs,
        top: 3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (deadline == null)
            text
          else
            AppTimestamp(dateTime: deadline, child: text),
          const SizedBox(height: 3),
          CcProgressBar(
            value: fraction,
            height: 2,
            color: fraction >= 0.8 ? ds.warn : ds.textTertiary,
            trackColor: ds.borderSecondary,
            semanticLabel: l10n.goalCardMoney(
              fmtMicros(goal.costMicros, decimals: 2),
              fmtMicros(goal.costCapMicros, decimals: 2),
            ),
          ),
        ],
      ),
    );
  }
}
