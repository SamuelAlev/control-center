import 'package:cc_domain/features/observability/domain/goal_budget.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/goal_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Goal Mode budget section (PRD #6).
///
/// Shows the active workspace goal — its objective, lifecycle status and token
/// budget consumption — and lets the operator set or clear a goal. When the
/// goal crosses its wrap-up threshold, the steer notice is surfaced as a warning
/// banner. With no active goal, an empty state offers a "set a goal" action.
///
/// Non-scrolling: renders [ObsSection] cards; the parent tab owns the scroll
/// view.
class GoalSection extends ConsumerWidget {
  /// Creates a [GoalSection].
  const GoalSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(activeWorkspaceGoalProvider);
    if (goal == null) {
      return const _NoGoalState();
    }
    return _ActiveGoalView(goal: goal);
  }
}

/// Empty state shown when no goal is set for the active workspace.
class _NoGoalState extends ConsumerWidget {
  const _NoGoalState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return ObsSection(
      title: l10n.obsGoalNoActiveTitle,
      icon: AppIcons.gauge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.obsGoalNoActiveBody,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          CcButton(
            icon: AppIcons.gauge,
            onPressed: () => _showGoalDialog(context, ref),
            child: Text(l10n.obsGoalSetGoal),
          ),
        ],
      ),
    );
  }
}

/// The active goal panel: status chip, budget meter, elapsed time, optional
/// wrap-up banner and a clear action.
class _ActiveGoalView extends ConsumerWidget {
  const _ActiveGoalView({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shouldSteer = ref.watch(goalShouldSteerProvider);
    final budget = goal.tokenBudget;
    final fraction = goal.budgetFraction ?? 0;

    final children = <Widget>[
      Align(
        alignment: Alignment.centerLeft,
        child: CcBadge(
          label: _statusLabel(l10n, goal.status),
          variant: _statusVariant(goal.status),
          icon: _statusIcon(goal.status),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
    ];

    if (budget != null) {
      children.add(
        ObsBar(
          label: l10n.obsGoalTokenBudget,
          fraction: fraction,
          valueLabel: '${fmtTokens(goal.tokensUsed)} / ${fmtTokens(budget)}',
          tone: _budgetTone(fraction),
          detail: l10n.obsGoalTokensLeft(fmtTokens(goal.remainingTokens ?? 0)),
        ),
      );
    } else {
      children.add(
        ObsKeyValue(
          label: l10n.obsGoalTokensUsed,
          value: l10n.obsGoalTokensUsedNoBudget(fmtTokens(goal.tokensUsed)),
        ),
      );
    }

    children.add(
      ObsKeyValue(
        label: l10n.obsGoalElapsed,
        value: fmtDuration(goal.timeUsedSeconds * 1000),
      ),
    );

    if (shouldSteer) {
      children.add(const SizedBox(height: AppSpacing.md));
      children.add(_SteerBanner(notice: goalSteerNotice(goal)));
    }

    children.add(const SizedBox(height: AppSpacing.lg));
    children.add(
      Align(
        alignment: Alignment.centerLeft,
        child: CcButton(
          variant: CcButtonVariant.secondary,
          icon: AppIcons.ban,
          onPressed: () =>
              ref.read(workspaceGoalControllerProvider.notifier).clear(),
          child: Text(l10n.obsGoalClear),
        ),
      ),
    );

    return ObsSection(
      title: goal.objective.isEmpty
          ? l10n.obsGoalFallbackTitle
          : goal.objective,
      icon: AppIcons.gauge,
      subtitle: l10n.obsGoalSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  ObsTone _budgetTone(double fraction) {
    if (fraction >= 1) {
      return ObsTone.danger;
    }
    if (fraction >= 0.88) {
      return ObsTone.warning;
    }
    return ObsTone.brand;
  }

  String _statusLabel(AppLocalizations l10n, GoalStatus status) =>
      switch (status) {
        GoalStatus.active => l10n.obsGoalStatusActive,
        GoalStatus.paused => l10n.obsGoalStatusPaused,
        GoalStatus.budgetLimited => l10n.obsGoalStatusBudgetLimited,
        GoalStatus.complete => l10n.obsGoalStatusComplete,
        GoalStatus.dropped => l10n.obsGoalStatusDropped,
      };

  CcBadgeVariant _statusVariant(GoalStatus status) => switch (status) {
    GoalStatus.active => CcBadgeVariant.brand,
    GoalStatus.budgetLimited => CcBadgeVariant.warning,
    GoalStatus.complete => CcBadgeVariant.success,
    GoalStatus.paused => CcBadgeVariant.neutral,
    GoalStatus.dropped => CcBadgeVariant.neutral,
  };

  IconData _statusIcon(GoalStatus status) => switch (status) {
    GoalStatus.active => AppIcons.zap,
    GoalStatus.budgetLimited => AppIcons.gauge,
    GoalStatus.complete => AppIcons.circleCheck,
    GoalStatus.paused => AppIcons.gauge,
    GoalStatus.dropped => AppIcons.ban,
  };
}

/// A warning-toned banner carrying the goal wrap-up steer notice.
class _SteerBanner extends StatelessWidget {
  const _SteerBanner({required this.notice});

  final String notice;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final tone = obsToneColor(t, ObsTone.warning);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgTertiary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ObsStatusDot(tone: ObsTone.warning, size: 8),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.obsGoalWrapUp,
                    style: CcTypography.label.copyWith(
                      color: t.textWarningPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    notice,
                    style: CcTypography.caption.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the "set a goal" dialog and starts the goal on confirm.
void _showGoalDialog(BuildContext context, WidgetRef ref) {
  showCcDialog<void>(
    context: context,
    builder: (dialogContext) => _GoalDialog(
      onSubmit: (objective, tokenBudget) {
        ref
            .read(workspaceGoalControllerProvider.notifier)
            .setGoal(objective: objective, tokenBudget: tokenBudget);
      },
    ),
  );
}

/// Dialog form collecting an objective and an optional token budget.
class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.onSubmit});

  final void Function(String objective, int? tokenBudget) onSubmit;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _objectiveController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _objectiveEmpty = true;

  @override
  void initState() {
    super.initState();
    _objectiveController.addListener(_onObjectiveChanged);
  }

  void _onObjectiveChanged() {
    final empty = _objectiveController.text.trim().isEmpty;
    if (empty != _objectiveEmpty) {
      setState(() => _objectiveEmpty = empty);
    }
  }

  @override
  void dispose() {
    _objectiveController
      ..removeListener(_onObjectiveChanged)
      ..dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _submit() {
    final objective = _objectiveController.text.trim();
    if (objective.isEmpty) {
      return;
    }
    final raw = _budgetController.text.trim().replaceAll(',', '');
    final budget = raw.isEmpty ? null : int.tryParse(raw);
    widget.onSubmit(objective, budget);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: l10n.obsGoalSetGoal,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.obsGoalObjectiveLabel,
            style: CcTypography.label.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          CcTextField(
            controller: _objectiveController,
            autofocus: true,
            keyboardType: TextInputType.multiline,
            hintText: 'e.g. ship the PR review redesign',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.obsGoalBudgetLabel,
            style: CcTypography.label.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          CcTextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hintText: '100000',
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          icon: AppIcons.gauge,
          onPressed: _objectiveEmpty ? null : _submit,
          child: Text(l10n.obsGoalSetAction),
        ),
      ],
    );
  }
}
