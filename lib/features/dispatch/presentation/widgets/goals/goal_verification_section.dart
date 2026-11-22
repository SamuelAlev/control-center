import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_review_prompt.dart'
    show goalReviewObjectiveCriterion;
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/transcript/tool_body.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How a goal was last verified: the agent's claim and its evidence per
/// criterion, each check's exit code and output tail (in a code view), the
/// reviewer's verdict per criterion (for a goal with no criteria, one row
/// about the objective) and its concerns, and who reviewed it
/// (another agent, the agent itself, or a person who approved it). The
/// server keeps the last round only; earlier rounds are counted, not shown.
class GoalVerificationSection extends ConsumerWidget {
  /// Creates the section.
  const GoalVerificationSection({super.key, required this.goal});

  /// The goal.
  final AgentGoalRun goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final v = goal.verification;
    final label = workSectionLabelStyle(ds);
    final body = CcTypography.bodySm.copyWith(color: ds.textSecondary);
    if (v == null) {
      return WorkSection(
        title: l10n.goalSectionVerification,
        child: Text(l10n.goalNotVerifiedYet, style: body),
      );
    }
    final codeFont = ref.watch(codeFontFamilyProvider);
    final verdict = v.verdict;
    // With no criteria the review judges the objective as its one item.
    final noCriteria = goal.contract?.criteria.isEmpty ?? true;
    String criterion(String raw) =>
        noCriteria && raw.trim() == goalReviewObjectiveCriterion
        ? l10n.goalCardObjective
        : inertText(raw, singleLine: true);
    return WorkSection(
      title: l10n.goalSectionVerification,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkTime(
            at: v.at,
            text: l10n.goalVerificationRound(
              v.round,
              goal.verificationRounds < v.round
                  ? v.round
                  : goal.verificationRounds,
              workTimeLabel(context, v.at),
            ),
            style: label,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.goalVerificationClaim, style: label),
          Text(inertText(v.claimSummary), style: body),
          for (final e in v.claimEvidence) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(criterion(e.criterion), style: label),
            Text(inertText(e.evidence), style: body),
          ],
          if (v.checks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.goalContractChecks, style: label),
            for (final r in v.checks) ...[
              const SizedBox(height: AppSpacing.xs),
              GoalCheckResultLine(result: r),
              if (r.outputTail.trim().isNotEmpty)
                // RTL carve-out: command output is a log; the code view lays
                // it out left to right in every locale.
                buildLabeledToolBlock(
                  context,
                  label: l10n.goalCheckOutputTail,
                  body: r.outputTail,
                  codeFont: codeFont,
                  tokens: ds,
                ),
            ],
          ],
          const SizedBox(height: AppSpacing.md),
          Text(l10n.goalVerificationReview, style: label),
          if (verdict == null)
            Text(l10n.goalVerificationNoVerdict, style: body)
          else ...[
            Text(switch (verdict.verdict) {
              GoalVerdictOutcome.pass => l10n.goalCardVerdictPass,
              GoalVerdictOutcome.fail => l10n.goalCardVerdictFail,
              GoalVerdictOutcome.cannotVerify =>
                l10n.goalCardVerdictCannotVerify,
            }, style: body),
            for (final item in verdict.items)
              _VerdictItemLine(
                item: item,
                criterion: criterion(item.criterion),
              ),
            if (verdict.concerns.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.goalCardConcerns, style: label),
              for (final c in verdict.concerns) Text(inertText(c), style: body),
            ],
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(_reviewer(ref, l10n, v), style: body),
        ],
      ),
    );
  }

  String _reviewer(WidgetRef ref, AppLocalizations l10n, GoalVerification v) {
    if (v.approvedByUserId != null) {
      return l10n.goalCardClosedByPerson;
    }
    final reviewer = v.reviewerAgentId;
    if (reviewer == null || reviewer == goal.agentId) {
      return l10n.goalCardVerifiedBySelf;
    }
    final name =
        ref.watch(
          workAgentNameProvider((
            workspaceId: goal.workspaceId,
            agentId: reviewer,
          )),
        ) ??
        l10n.workAgentUnknown;
    return l10n.goalCardVerifiedBy(name);
  }
}

/// One check's last result: passed, failed with its exit code, timed out,
/// not rerun (unchanged), or broken; the command in code style.
class GoalCheckResultLine extends StatelessWidget {
  /// Creates the line.
  const GoalCheckResultLine({super.key, required this.result});

  /// The result.
  final GoalCheckResult result;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final r = result;
    final (IconData icon, Color color, String text) = switch (r) {
      GoalCheckResult(broken: true) => (
        AppIcons.triangleAlert,
        ds.warn,
        l10n.goalCardCheckBroken,
      ),
      GoalCheckResult(skippedUnchanged: true) => (
        AppIcons.circleCheck,
        ds.textTertiary,
        l10n.goalCardCheckNotRerun,
      ),
      GoalCheckResult(timedOut: true) => (
        AppIcons.clock,
        ds.danger,
        l10n.goalCardCheckTimedOut,
      ),
      GoalCheckResult(exitCode: 0) => (
        AppIcons.circleCheck,
        ds.success,
        l10n.goalCheckExitCode(0),
      ),
      GoalCheckResult(:final exitCode) => (
        AppIcons.circleX,
        ds.danger,
        exitCode == null
            ? l10n.goalCardCheckNotRun
            : l10n.goalCardCheckFailed(exitCode),
      ),
    };
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: WorkCode(r.run)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: CcTypography.caption.copyWith(color: ds.textSecondary),
        ),
      ],
    );
  }
}

class _VerdictItemLine extends StatelessWidget {
  const _VerdictItemLine({required this.item, required this.criterion});

  final GoalVerdictItem item;

  /// The criterion as shown: inert text, or the objective in words.
  final String criterion;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final (IconData icon, Color color, String state) = switch (item.state) {
      GoalCriterionState.met => (
        AppIcons.circleCheck,
        ds.success,
        l10n.goalCardCriterionMet,
      ),
      GoalCriterionState.unmet => (
        AppIcons.circleX,
        ds.danger,
        l10n.goalCardCriterionUnmet,
      ),
      GoalCriterionState.cannotTell => (
        AppIcons.circleHelp,
        ds.warn,
        l10n.goalCardCriterionCannotTell,
      ),
    };
    final style = CcTypography.caption.copyWith(color: ds.textSecondary);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.goalVerdictItem(criterion, state),
                  style: style.copyWith(color: ds.textPrimary),
                ),
                if (item.evidence.trim().isNotEmpty)
                  Text(inertText(item.evidence), style: style),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
