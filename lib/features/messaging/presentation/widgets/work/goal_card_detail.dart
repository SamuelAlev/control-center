import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_review_prompt.dart'
    show goalReviewObjectiveCriterion;
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/goal_tab.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The expanded half of a goal card: what done means (each criterion with
/// its last verdict), its checks with their last results, the last verdict
/// and its concerns, and who verified it. A goal with no machine check says
/// so and offers to add one on the goal's page.
class GoalCardDetail extends ConsumerWidget {
  /// Creates the detail.
  const GoalCardDetail({super.key, required this.goal});

  /// The goal.
  final AgentGoalRun goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final contract = goal.contract;
    final verification = goal.verification;
    final verdict = verification?.verdict;
    final criteria = contract?.criteria ?? const <String>[];
    // With no criteria the reviewer judges the objective as one item.
    final objective = criteria.isEmpty
        ? verdict?.items
              .where((i) => i.criterion.trim() == goalReviewObjectiveCriterion)
              .firstOrNull
        : null;
    final checks = contract?.checks ?? const <GoalCheck>[];
    final heading = CcTypography.label.copyWith(color: ds.textTertiary);
    final body = CcTypography.caption.copyWith(color: ds.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (criteria.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.goalCardDoneMeans, style: heading),
          for (final c in criteria)
            _CriterionRow(text: c, item: _itemFor(verdict, c)),
        ],
        if (objective != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.goalCardDoneMeans, style: heading),
          _CriterionRow(text: l10n.goalCardObjective, item: objective),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.goalCardChecks, style: heading),
        if (checks.isEmpty)
          Row(
            children: [
              Icon(AppIcons.circleHelp, size: 12, color: ds.textTertiary),
              const SizedBox(width: AppSpacing.xs),
              Text(l10n.goalCardNoMachineCheck, style: body),
              const SizedBox(width: AppSpacing.sm),
              CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                onPressed: () => openGoal(
                  context,
                  workspaceId: goal.workspaceId,
                  spaceId: goal.spaceId,
                  goalId: goal.id,
                  title: goal.userText,
                  openContractEditor: true,
                ),
                child: Text(l10n.goalCardAddCheck),
              ),
            ],
          )
        else
          for (final check in checks)
            _CheckRow(check: check, result: _resultFor(verification, check)),
        if (verdict != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(switch (verdict.verdict) {
            GoalVerdictOutcome.pass => l10n.goalCardVerdictPass,
            GoalVerdictOutcome.fail => l10n.goalCardVerdictFail,
            GoalVerdictOutcome.cannotVerify => l10n.goalCardVerdictCannotVerify,
          }, style: body),
          if (verdict.concerns.isNotEmpty) ...[
            Text(l10n.goalCardConcerns, style: heading),
            for (final c in verdict.concerns)
              Text(inertText(c), style: body, maxLines: 4),
          ],
        ],
        if (verification != null)
          _verifiedBy(context, ref, l10n, verification, body),
      ],
    );
  }

  Widget _verifiedBy(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    GoalVerification v,
    TextStyle style,
  ) {
    if (v.approvedByUserId != null) {
      return Text(l10n.goalCardClosedByPerson, style: style);
    }
    if (v.verdict == null) {
      return const SizedBox.shrink();
    }
    final reviewer = v.reviewerAgentId;
    if (reviewer == null || reviewer == goal.agentId) {
      return Text(l10n.goalCardVerifiedBySelf, style: style);
    }
    final name =
        ref.watch(
          workAgentNameProvider((
            workspaceId: goal.workspaceId,
            agentId: reviewer,
          )),
        ) ??
        l10n.workAgentUnknown;
    return Text(l10n.goalCardVerifiedBy(name), style: style);
  }

  static GoalVerdictItem? _itemFor(GoalVerdict? verdict, String criterion) {
    for (final item in verdict?.items ?? const <GoalVerdictItem>[]) {
      if (item.criterion.trim() == criterion.trim()) {
        return item;
      }
    }
    return null;
  }

  static GoalCheckResult? _resultFor(GoalVerification? v, GoalCheck check) {
    for (final r in v?.checks ?? const <GoalCheckResult>[]) {
      if (r.run == check.run && r.where == check.where) {
        return r;
      }
    }
    return null;
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.text, required this.item});

  final String text;
  final GoalVerdictItem? item;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final state = item?.state;
    final (IconData icon, Color color, String? label) = switch (state) {
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
      null => (AppIcons.square, ds.textQuaternary, null),
    };
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 1),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              inertText(text),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(
                color: context.ds.textSecondary,
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: CcTypography.caption.copyWith(color: ds.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check, required this.result});

  final GoalCheck check;
  final GoalCheckResult? result;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final r = result;
    final (IconData icon, Color color, String label) = switch (r) {
      null => (AppIcons.square, ds.textQuaternary, l10n.goalCardCheckNotRun),
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
        l10n.goalCardCheckPassed,
      ),
      GoalCheckResult(:final exitCode) => (
        AppIcons.circleX,
        ds.danger,
        l10n.goalCardCheckFailed(exitCode ?? -1),
      ),
    };
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: WorkCode(check.run)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: CcTypography.caption.copyWith(color: ds.textTertiary),
          ),
        ],
      ),
    );
  }
}
