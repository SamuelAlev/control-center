import 'package:cc_domain/features/orchestration/domain/ports/orchestration_cap_raiser.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_budget_gate.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_label.dart';
import 'package:cc_domain/features/pipelines/domain/templates/goal_pursue_config.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/features/dispatch/presentation/goal_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/raise_cap_dialog.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/orchestration/providers/orchestration_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// What a run waits on beyond its own steps: each `goal.pursue` step's goal
/// (with its status and a link to the goal's page), and a hold on the
/// orchestration's budget (the reason, what was spent of the cap, and a
/// raise-cap action for a viewer the server allows (`can_raise_cap`); the
/// server resumes the run once the cap is raised).
/// Nothing when the run waits on neither.
class PipelineRunWorkNotices extends ConsumerWidget {
  /// Creates the notices for [run].
  const PipelineRunWorkNotices({super.key, required this.run});

  /// The run.
  final PipelineRun run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = run.state;
    final goals = [
      for (final e in state.entries)
        if (e.key.startsWith(kGoalPursueStateKeyPrefix) && e.value is String)
          (
            e.key.substring(kGoalPursueStateKeyPrefix.length),
            e.value as String,
          ),
    ];
    final hold = state[kBudgetHoldStateKey];
    if (goals.isEmpty && hold is! Map) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hold is Map) _BudgetHold(run: run, hold: hold),
          for (final (stepId, goalId) in goals)
            _GoalLink(run: run, stepId: stepId, goalId: goalId),
        ],
      ),
    );
  }
}

class _GoalLink extends ConsumerWidget {
  const _GoalLink({
    required this.run,
    required this.stepId,
    required this.goalId,
  });

  final PipelineRun run;
  final String stepId;
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final goal = ref
        .watch(goalRunViewProvider((workspaceId: run.workspaceId, id: goalId)))
        .value
        ?.goal;
    final label = renderStepLabel(
      run.templateSnapshot?.step(stepId)?.config.label,
      state: run.state,
      trigger: run.triggerPayload,
      fallback: stepId,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(AppIcons.target, size: 14, color: ds.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              l10n.pipelineRunGoalStep(label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.bodySm.copyWith(color: ds.textSecondary),
            ),
          ),
          if (goal != null) ...[
            CcStatusTag(
              label: goalStatusLabel(l10n, goal.status),
              tone: goalStatusTone(goal.status),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () => context.go(goalRoute(run.workspaceId, goalId)),
            child: Text(l10n.pipelineRunOpenGoal),
          ),
        ],
      ),
    );
  }
}

class _BudgetHold extends ConsumerWidget {
  const _BudgetHold({required this.run, required this.hold});

  final PipelineRun run;
  final Map<dynamic, dynamic> hold;

  Future<void> _raise(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final id = hold['orchestration_id'];
    if (id is! String) {
      return;
    }
    final raiser = ref.read(orchestrationCapRaiserProvider);
    final cap = await showRaiseCapDialog(
      context,
      title: l10n.pipelineRunRaiseCapTitle,
      capMicros: (hold['cap_micros'] as num?)?.toInt() ?? 0,
      spentMicros: (hold['spent_micros'] as num?)?.toInt() ?? 0,
      maxMicros: kOrchestrationCapMaxMicros,
      submit: (micros) => raiser.raiseCap(run.workspaceId, id, micros),
    );
    if (cap != null && context.mounted) {
      CcToastScope.maybeOf(context)?.show(l10n.pipelineRunCapRaised);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final reason = hold['reason'];
    String money(Object? v) =>
        fmtMicros((v as num?)?.toInt() ?? 0, decimals: 2, locale: locale);
    return CcAlert(
      variant: CcAlertVariant.warning,
      title: reason == kOrchestrationBudgetHoldReason
          ? l10n.pipelineRunHeldBudget
          : l10n.pipelineRunHeldOther('$reason'),
      description: Text(
        l10n.pipelineRunHeldSpent(
          money(hold['spent_micros']),
          money(hold['cap_micros']),
        ),
      ),
      // Only the run's requester (an admin for a bot run) may raise it; the
      // server says so per viewer.
      action: run.canRaiseCap == true && hold['orchestration_id'] is String
          ? CcButton(
              size: CcButtonSize.sm,
              icon: AppIcons.dollarSign,
              onPressed: () => _raise(context, ref),
              child: Text(l10n.pipelineRunRaiseCap),
            )
          : null,
    );
  }
}
