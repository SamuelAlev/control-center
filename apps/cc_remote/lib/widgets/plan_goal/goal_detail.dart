import 'package:cc_domain/cc_domain.dart' show AgentDto;
import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/plan_goal/goal_actions.dart';
import 'package:cc_remote/widgets/plan_goal/goal_contract_view.dart';
import 'package:cc_remote/widgets/plan_goal/goal_hold_line.dart';
import 'package:cc_remote/widgets/plan_goal/goal_verification_view.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

String phoneGoalStatus(AppLocalizations l10n, AgentGoalStatus status) =>
    switch (status) {
      AgentGoalStatus.active => l10n.mobileGoalActive,
      AgentGoalStatus.paused => l10n.mobileGoalPaused,
      AgentGoalStatus.completed => l10n.mobileGoalCompleted,
      AgentGoalStatus.failed => l10n.mobileGoalFailed,
      AgentGoalStatus.cancelled => l10n.mobileGoalCancelled,
      AgentGoalStatus.budgetExhausted => l10n.mobileGoalBudgetExhausted,
    };

CcBadgeVariant phoneGoalStatusVariant(AgentGoalStatus status) =>
    switch (status) {
      AgentGoalStatus.active ||
      AgentGoalStatus.completed => CcBadgeVariant.success,
      AgentGoalStatus.failed => CcBadgeVariant.danger,
      _ => CcBadgeVariant.neutral,
    };

/// One goal: its objective and status, the hold in words (who must act and
/// what happens next), segments, money and deadline, what done means, the
/// last verification and who verified it, and the controls its state and
/// this viewer allow. The objective, summary and every verification text
/// are the agent's or person's words and render as plain text.
class PhoneGoalDetail extends ConsumerWidget {
  const PhoneGoalDetail({
    super.key,
    required this.view,
    required this.workspaceId,
  });

  final GoalRunView view;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final g = view.goal;
    final agents = ref.watch(agentsProvider).value ?? const <AgentDto>[];
    String? agentName(String id) =>
        agents.where((a) => a.id == id).firstOrNull?.name;
    final secondary = CcTypography.bodySm.copyWith(color: t.textSecondary);
    final maxRuns = g.maxRuns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          inertText(g.userText),
          style: CcTypography.title.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CcBadge(
              label: phoneGoalStatus(l, g.status),
              variant: phoneGoalStatusVariant(g.status),
            ),
            if (agentName(g.agentId) case final name?)
              Text(name, style: secondary),
          ],
        ),
        const SizedBox(height: 12),
        GoalHoldLine(goal: g),
        const SizedBox(height: 12),
        Text(
          maxRuns == null
              ? l.goalSegmentsNoCap(g.runCount)
              : l.goalSegments(g.runCount, maxRuns),
          style: secondary,
        ),
        Text(
          l.goalMoney(
            planMoney(context, g.costMicros),
            planMoney(context, g.costCapMicros),
          ),
          style: secondary,
        ),
        if (g.deadlineAt case final deadline?)
          Text(l.goalDeadline(workTime(context, deadline)), style: secondary),
        if (g.consecutiveFailures > 0)
          Text(
            l.mobileGoalFailures(
              NumberFormat.decimalPattern(
                Localizations.localeOf(context).toLanguageTag(),
              ).format(g.consecutiveFailures),
            ),
            style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
          ),
        if (g.pipeline != null) Text(l.goalPipelineStep, style: secondary),
        if (g.status == AgentGoalStatus.failed &&
            (g.summary?.trim().isEmpty ?? true))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.mobileGoalFailedDescription,
              style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
            ),
          ),
        if (g.summary case final summary? when summary.trim().isNotEmpty) ...[
          goalSectionHeading(context, l.goalSummaryHeading),
          WorkQuote(summary),
        ],
        GoalContractView(contract: g.contract),
        GoalVerificationView(goal: g, agentName: agentName),
        const SizedBox(height: 12),
        GoalActions(view: view, workspaceId: workspaceId),
        if (g.spaceId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: CcButton(
              fullWidth: true,
              size: CcButtonSize.lg,
              variant: CcButtonVariant.secondary,
              icon: AppIcons.arrowRight,
              onPressed: () => context.push(
                remoteSpaceLocation(
                  workspaceId: workspaceId,
                  spaceId: g.spaceId,
                  conversationId: g.conversationId,
                ),
              ),
              child: Text(l.mobileGoalOpenConversation),
            ),
          ),
      ],
    );
  }
}
