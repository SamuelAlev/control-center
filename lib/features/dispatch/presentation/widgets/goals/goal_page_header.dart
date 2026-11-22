import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/dispatch/presentation/goal_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/raise_cap_dialog.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/goal_card_actions.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The top of a goal's page: back, the objective's first line, its status,
/// who pursues it and where, and the controls the viewer has (pause, resume,
/// stop, approve completion). Resume and raising the budget follow the
/// server's `can_resume`; approve shows only while the goal waits for
/// review, and asks first.
class GoalPageHeader extends ConsumerWidget {
  /// Creates the header.
  const GoalPageHeader({super.key, required this.view, required this.onBack});

  /// The goal as this viewer sees it.
  final GoalRunView view;

  /// Leaves the page.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final goal = view.goal;
    final ws = goal.workspaceId;
    final agent =
        ref.watch(
          workAgentNameProvider((workspaceId: ws, agentId: goal.agentId)),
        ) ??
        l10n.workAgentUnknown;
    final where = ref.watch(
      workConversationLabelProvider((
        workspaceId: ws,
        spaceId: goal.spaceId,
        conversationId: goal.conversationId,
      )),
    );
    final title = inertText(goal.userText, singleLine: true);
    final caption = CcTypography.caption.copyWith(color: ds.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          icon: AppIcons.arrowLeft,
          onPressed: onBack,
          child: Text(l10n.goalsBackToList),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.body.copyWith(
                  color: ds.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            CcStatusTag(
              label: goalStatusLabel(l10n, goal.status),
              tone: goalStatusTone(goal.status),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.goalPursuedBy(agent), style: caption),
            if (where != null)
              CcTappable(
                onPressed: () => context.go(
                  spaceRoute(
                    ws,
                    goal.spaceId,
                    tab: conversationTabKey(goal.conversationId),
                  ),
                ),
                semanticLabel: l10n.goalOpenConversation,
                builder: (context, states) => Text(
                  where,
                  style: caption.copyWith(
                    decoration: states.contains(WidgetState.hovered)
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ),
            AppTimestamp(
              dateTime: goal.createdAt,
              child: Text(
                l10n.goalStarted(workTimeLabel(context, goal.createdAt)),
                style: caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _GoalActions(view: view),
      ],
    );
  }
}

class _GoalActions extends ConsumerWidget {
  const _GoalActions({required this.view});

  final GoalRunView view;

  Future<void> _stop(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.goalStopTitle,
        content: Text(l10n.goalStopBody),
        actions: [
          CcButton(
            variant: CcButtonVariant.ghost,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.goalRunStop),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await goalCardCancel(context, ref, view.goal);
    }
  }

  Future<void> _raiseAndResume(BuildContext context, WidgetRef ref) async {
    final goal = view.goal;
    final cap = await showRaiseCapDialog(
      context,
      title: AppLocalizations.of(context).goalRaiseBudgetTitle,
      capMicros: goal.costCapMicros,
      spentMicros: goal.costMicros,
    );
    if (cap != null && context.mounted) {
      await runDispatchAction(
        context,
        () => ref
            .read(agentGoalRunRepositoryProvider)
            .resumeGoal(goal.workspaceId, goal.id, raiseCostCapMicros: cap),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final goal = view.goal;
    final paused = goal.status == AgentGoalStatus.paused;
    final active = goal.status == AgentGoalStatus.active;
    final outOfBudget = goal.status == AgentGoalStatus.budgetExhausted;
    final review = goal.hold == GoalHold.needsReview;
    final buttons = <Widget>[
      if (review)
        WorkTip(
          message: view.canApprove ? null : l10n.goalCardApproveNotYours,
          child: CcButton(
            size: CcButtonSize.sm,
            icon: AppIcons.circleCheck,
            onPressed: view.canApprove
                ? () => goalCardApprove(context, ref, goal)
                : null,
            child: Text(l10n.goalCardApprove),
          ),
        ),
      if (active)
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          icon: AppIcons.pause,
          onPressed: () => goalCardPause(context, ref, goal),
          child: Text(l10n.goalRunPause),
        ),
      if (paused || outOfBudget)
        WorkTip(
          message: view.canResume ? null : l10n.goalCardResumeNotYours,
          child: CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: AppIcons.play,
            onPressed: !view.canResume
                ? null
                : outOfBudget
                ? () => _raiseAndResume(context, ref)
                : () => goalCardResume(context, ref, goal),
            child: Text(
              outOfBudget ? l10n.goalRaiseBudgetAction : l10n.goalRunResume,
            ),
          ),
        ),
      if (paused && view.canResume)
        CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          icon: AppIcons.dollarSign,
          onPressed: () => _raiseAndResume(context, ref),
          child: Text(l10n.goalRaiseBudgetAction),
        ),
      if (goalIsOpen(goal))
        CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          icon: AppIcons.circleStop,
          onPressed: () => _stop(context, ref),
          child: Text(l10n.goalRunStop),
        ),
    ];
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: buttons,
    );
  }
}
