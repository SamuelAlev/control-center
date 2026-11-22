import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_review_prompt.dart'
    show goalReviewObjectiveCriterion;
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/plan_goal/goal_contract_view.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// The last verification of a goal's claim: when it ran, what the agent
/// claimed, each check's result (with the tail of its output), the
/// reviewer's verdict per criterion and its concerns, and who verified it:
/// another agent, the goal's own agent, or a person who closed it.
/// The claim, the evidence, the output and the concerns are data.
class GoalVerificationView extends StatelessWidget {
  const GoalVerificationView({
    super.key,
    required this.goal,
    required this.agentName,
  });

  final AgentGoalRun goal;

  /// The display name of an agent id, or null when unknown.
  final String? Function(String agentId) agentName;

  @override
  Widget build(BuildContext context) {
    final v = goal.verification;
    if (v == null) return const SizedBox.shrink();
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final verdict = v.verdict;
    final secondary = CcTypography.bodySm.copyWith(color: t.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        goalSectionHeading(
          context,
          l.goalLastCheck(v.round, workTime(context, v.at)),
        ),
        if (v.claimSummary.trim().isNotEmpty) ...[
          Text(l.goalClaim, style: secondary),
          const SizedBox(height: 4),
          WorkQuote(v.claimSummary, maxLines: 8),
          const SizedBox(height: 10),
        ],
        for (final check in v.checks)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CheckResult(result: check),
          ),
        if (verdict != null) ...[
          Text(
            switch (verdict.verdict) {
              GoalVerdictOutcome.pass => l.goalVerdictPass,
              GoalVerdictOutcome.fail => l.goalVerdictFail,
              GoalVerdictOutcome.cannotVerify => l.goalVerdictCannotVerify,
            },
            style: CcTypography.bodySm.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          for (final item in verdict.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VerdictItem(item: item),
            ),
          if (verdict.concerns.isNotEmpty) ...[
            Text(l.goalConcerns, style: secondary),
            const SizedBox(height: 4),
            for (final concern in verdict.concerns)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: WorkQuote(concern),
              ),
          ],
        ],
        const SizedBox(height: 4),
        Text(_verifiedBy(l, v), style: secondary),
      ],
    );
  }

  String _verifiedBy(AppLocalizations l, GoalVerification v) {
    if (v.approvedByUserId != null) return l.goalClosedByPerson;
    final reviewer = v.reviewerAgentId;
    if (reviewer == null || reviewer == goal.agentId) {
      return l.goalVerifiedBySelf;
    }
    return l.goalVerifiedBy(agentName(reviewer) ?? reviewer);
  }
}

class _CheckResult extends StatelessWidget {
  const _CheckResult({required this.result});

  final GoalCheckResult result;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final (label, icon, color) = result.passed
        ? (l.goalCheckPassed, AppIcons.circleCheck, t.textSuccessPrimary)
        : result.broken
        ? (l.goalCheckBroken, AppIcons.triangleAlert, t.textErrorPrimary)
        : result.timedOut
        ? (l.goalCheckTimedOut, AppIcons.clock, t.textErrorPrimary)
        : result.skippedUnchanged
        ? (l.goalCheckNotRerun, AppIcons.circleDashed, t.textSecondary)
        : (
            l.goalCheckFailed(result.exitCode ?? -1),
            AppIcons.circleX,
            t.textErrorPrimary,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkCode(result.run),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: CcTypography.caption.copyWith(color: color)),
          ],
        ),
        if (!result.passed && result.outputTail.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          ColoredBox(
            color: t.surface,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: WorkCode(result.outputTail.trim(), maxLines: 12),
            ),
          ),
        ],
      ],
    );
  }
}

class _VerdictItem extends StatelessWidget {
  const _VerdictItem({required this.item});

  final GoalVerdictItem item;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final (label, variant) = switch (item.state) {
      GoalCriterionState.met => (l.goalCriterionMet, CcBadgeVariant.success),
      GoalCriterionState.unmet => (l.goalCriterionUnmet, CcBadgeVariant.danger),
      GoalCriterionState.cannotTell => (
        l.goalCriterionCannotTell,
        CcBadgeVariant.neutral,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcBadge(label: label, variant: variant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                // A goal with no criteria is judged as one item on its
                // objective: say so instead of the server's English.
                item.criterion == goalReviewObjectiveCriterion
                    ? l.goalVerdictObjective
                    : inertText(item.criterion),
                style: CcTypography.bodySm.copyWith(color: t.textPrimary),
              ),
            ),
          ],
        ),
        if (item.evidence.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: WorkQuote(item.evidence, maxLines: 6),
          ),
      ],
    );
  }
}
