import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/goal_card_actions.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/goal_card_detail.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/goal_status_line.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_hover_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One durable goal in the conversation panel: objective, status, why it
/// holds, what it has spent of its caps, and (expanded) what done means, its
/// checks and the last verdict. Controls follow the server: Resume and every
/// budget raise only when this viewer's `can_resume` is true, Approve
/// completion only on a goal waiting for review.
class GoalCard extends ConsumerStatefulWidget {
  /// Creates the card.
  const GoalCard({super.key, required this.view});

  /// The goal as this viewer sees it.
  final GoalRunView view;

  @override
  ConsumerState<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends ConsumerState<GoalCard> {
  bool? _open;

  AgentGoalRun get _goal => widget.view.goal;

  bool get _wantsPerson =>
      _goal.hold == GoalHold.needsReview || _goal.hold == GoalHold.person;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final goal = _goal;
    final terminal = goal.status.isTerminal;
    final open = _open ?? (_wantsPerson && !terminal);
    final mayRaise =
        widget.view.canResume &&
        (goal.status == AgentGoalStatus.paused ||
            goal.status == AgentGoalStatus.budgetExhausted);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkHoverRow(
            actions: _actions(l10n),
            child: Row(
              children: [
                Icon(
                  AppIcons.target,
                  size: 14,
                  color: terminal ? ds.textQuaternary : ds.fgBrandPrimary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    inertText(goal.userText, singleLine: true),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(
                      color: terminal ? ds.textTertiary : ds.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                GoalRunStatusBadge(status: goal.status),
              ],
            ),
          ),
          if (!terminal) ...[
            GoalStatusLine(goal: goal),
            GoalBudgetLine(goal: goal),
            if (!widget.view.canResume &&
                (goal.status == AgentGoalStatus.paused ||
                    goal.status == AgentGoalStatus.budgetExhausted))
              _Indented(
                child: Text(
                  l10n.goalCardResumeNotYours,
                  style: CcTypography.caption.copyWith(color: ds.textTertiary),
                ),
              ),
          ],
          if (goal.hold == GoalHold.needsReview && !terminal)
            _Indented(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                // A goal in a pipeline is closed only by whoever started it
                // (`can_approve`); the server refuses anyone else.
                child: widget.view.canApprove
                    ? CcButton(
                        icon: AppIcons.circleCheck,
                        variant: CcButtonVariant.secondary,
                        size: CcButtonSize.sm,
                        onPressed: () => goalCardApprove(context, ref, goal),
                        child: Text(l10n.goalCardApprove),
                      )
                    : CcTooltip(
                        message: l10n.goalCardApproveNotYours,
                        child: CcButton(
                          icon: AppIcons.circleCheck,
                          variant: CcButtonVariant.secondary,
                          size: CcButtonSize.sm,
                          onPressed: null,
                          child: Text(l10n.goalCardApprove),
                        ),
                      ),
              ),
            ),
          if (mayRaise && goal.status == AgentGoalStatus.budgetExhausted)
            _Indented(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: CcButton(
                  icon: AppIcons.play,
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  onPressed: () => goalCardResume(
                    context,
                    ref,
                    goal,
                    raiseCostCapMicros: goal.costCapMicros * 2,
                  ),
                  child: Text(
                    l10n.goalRunResumeRaise(
                      fmtMicros(goal.costCapMicros * 2, decimals: 2),
                    ),
                  ),
                ),
              ),
            ),
          _Indented(
            child: CcTappable(
              onPressed: () => setState(() => _open = !open),
              semanticLabel: open
                  ? l10n.workFeedHideDetails
                  : l10n.workFeedShowDetails,
              builder: (context, states) => Row(
                children: [
                  Text(
                    open ? l10n.workFeedHideDetails : l10n.workFeedShowDetails,
                    style: CcTypography.caption.copyWith(
                      color: ds.textTertiary,
                    ),
                  ),
                  Icon(
                    open ? AppIcons.chevronUp : AppIcons.chevronDown,
                    size: 12,
                    color: ds.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          CcCollapsible(
            expanded: open,
            child: _Indented(child: GoalCardDetail(goal: goal)),
          ),
        ],
      ),
    );
  }

  /// Pause and stop on a live goal, Resume on a paused one the viewer may
  /// resume, Open on every goal.
  List<Widget> _actions(AppLocalizations l10n) {
    final goal = _goal;
    Widget button(IconData icon, String tip, VoidCallback onTap) =>
        CcIconButton(
          icon: icon,
          size: CcButtonSize.sm,
          tooltip: tip,
          onPressed: onTap,
        );
    return [
      if (goal.status == AgentGoalStatus.active)
        button(
          AppIcons.pause,
          l10n.goalRunPause,
          () => goalCardPause(context, ref, goal),
        ),
      if (goal.status == AgentGoalStatus.paused && widget.view.canResume)
        button(
          AppIcons.play,
          l10n.goalRunResume,
          () => goalCardResume(context, ref, goal),
        ),
      if (!goal.status.isTerminal)
        button(
          AppIcons.circleStop,
          l10n.goalRunStop,
          () => goalCardCancel(context, ref, goal),
        ),
      button(
        AppIcons.externalLink,
        l10n.goalCardOpen,
        () => context.go(goalRoute(goal.workspaceId, goal.id)),
      ),
    ];
  }
}

class _Indented extends StatelessWidget {
  const _Indented({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      start: 14 + AppSpacing.xs,
      top: 3,
    ),
    child: child,
  );
}

/// The goal's lifecycle chip: a distinct label and icon per status, never
/// colour alone.
class GoalRunStatusBadge extends StatelessWidget {
  /// Creates the chip.
  const GoalRunStatusBadge({super.key, required this.status});

  /// The goal's lifecycle status.
  final AgentGoalStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, variant, icon) = switch (status) {
      AgentGoalStatus.active => (
        l10n.goalRunStatusActive,
        CcBadgeVariant.brand,
        AppIcons.loaderCircle,
      ),
      AgentGoalStatus.paused => (
        l10n.goalRunStatusPaused,
        CcBadgeVariant.warning,
        AppIcons.pause,
      ),
      AgentGoalStatus.completed => (
        l10n.goalRunStatusCompleted,
        CcBadgeVariant.success,
        AppIcons.circleCheck,
      ),
      AgentGoalStatus.failed => (
        l10n.goalRunStatusFailed,
        CcBadgeVariant.danger,
        AppIcons.circleX,
      ),
      AgentGoalStatus.cancelled => (
        l10n.goalRunStatusCancelled,
        CcBadgeVariant.neutral,
        AppIcons.ban,
      ),
      AgentGoalStatus.budgetExhausted => (
        l10n.goalRunStatusBudgetExhausted,
        CcBadgeVariant.warning,
        AppIcons.clock,
      ),
    };
    return CcBadge(label: label, variant: variant, icon: icon);
  }
}
