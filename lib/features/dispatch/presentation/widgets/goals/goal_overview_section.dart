import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/features/dispatch/presentation/goal_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/goal_status_line.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Where a goal stands: what it does now and why it holds (the shared
/// [GoalStatusLine]), what happens next, the segments, money and deadline it
/// has used of its caps, how many segments in a row made no progress, and
/// the objective in full.
class GoalOverviewSection extends StatelessWidget {
  /// Creates the section.
  const GoalOverviewSection({super.key, required this.goal});

  /// The goal.
  final AgentGoalRun goal;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final next = goalNextSentence(context, goal);
    final deadline = goal.deadlineAt;
    final now = DateTime.now();
    final body = CcTypography.bodySm.copyWith(color: ds.textSecondary);
    return WorkSection(
      title: l10n.goalSectionNow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoalStatusLine(goal: goal),
          if (next != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(next, style: body),
          ],
          const SizedBox(height: AppSpacing.md),
          WorkFactGrid(
            facts: [
              (
                l10n.goalFactSegments,
                goal.maxRuns == null
                    ? l10n.goalCardSegmentsNoCap(goal.runCount)
                    : l10n.goalCardSegments(goal.runCount, goal.maxRuns!),
              ),
              (
                l10n.goalFactMoney,
                l10n.goalCardMoney(
                  fmtMicros(goal.costMicros, decimals: 2, locale: locale),
                  fmtMicros(goal.costCapMicros, decimals: 2, locale: locale),
                ),
              ),
              (
                l10n.goalFactDeadline,
                deadline == null
                    ? l10n.goalNoDeadline
                    : deadline.isAfter(now)
                    ? l10n.goalDeadlineWithLeft(
                        workTimeLabel(context, deadline),
                        workDurationLabel(deadline.difference(now)),
                      )
                    : l10n.goalCardOverdue,
              ),
              if (goal.noProgressStreak > 0)
                (
                  l10n.goalFactNoProgress,
                  l10n.goalNoProgressCount(goal.noProgressStreak),
                ),
            ],
            timestamps: {l10n.goalFactDeadline: ?deadline},
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.goalObjective, style: workSectionLabelStyle(ds)),
          const SizedBox(height: AppSpacing.xxs),
          // Agent and person text is data: plain text, never markdown.
          Text(inertText(goal.userText), style: body),
        ],
      ),
    );
  }
}
