import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_edit_dialogs.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What "done" means for a goal: its criteria, its checks (where each runs
/// and its timeout), its boundaries and stop conditions, and who checks it.
/// Both can change only while the goal is paused, and only by whoever may
/// resume it (the server's `can_resume`); otherwise the controls say why
/// they are unavailable. With no contract it also says there is no machine
/// check.
class GoalContractSection extends ConsumerWidget {
  /// Creates the section.
  const GoalContractSection({
    super.key,
    required this.goal,
    required this.canChange,
  });

  /// The goal.
  final AgentGoalRun goal;

  /// Whether this viewer may change its contract and checker
  /// ([GoalRunView.canResume]).
  final bool canChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final paused = goal.status == AgentGoalStatus.paused;
    final open = paused || goal.status == AgentGoalStatus.active;
    final contract = goal.contract;
    final label = workSectionLabelStyle(ds);
    final body = CcTypography.bodySm.copyWith(color: ds.textSecondary);
    final checker = goal.checkerAgentId;
    final checkerName = checker == null
        ? null
        : ref.watch(
                workAgentNameProvider((
                  workspaceId: goal.workspaceId,
                  agentId: checker,
                )),
              ) ??
              l10n.workAgentUnknown;
    final hint = !canChange
        ? l10n.goalRefusalNotYours
        : paused
        ? null
        : l10n.goalContractPauseFirst;
    final editable = paused && canChange;
    return WorkSection(
      title: l10n.goalSectionContract,
      actions: [
        if (open) ...[
          WorkTip(
            message: hint,
            child: CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: AppIcons.pencil,
              onPressed: editable
                  ? () => showGoalContractDialog(context, goal)
                  : null,
              child: Text(l10n.goalContractEdit),
            ),
          ),
          WorkTip(
            message: hint,
            child: CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: editable
                  ? () => showGoalCheckerDialog(context, goal)
                  : null,
              child: Text(l10n.goalCheckerChange),
            ),
          ),
        ],
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (open && !paused && canChange) ...[
            Text(l10n.goalContractPauseFirst, style: label),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (contract == null || _empty(contract)) ...[
            Text(l10n.goalContractNone, style: body),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.goalContractChecks, style: label),
            Text(l10n.goalCardNoMachineCheck, style: body),
          ] else ...[
            if (contract.criteria.isNotEmpty) ...[
              Text(l10n.goalContractDoneMeans, style: label),
              for (final c in contract.criteria)
                _Bullet(text: inertText(c), style: body),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(l10n.goalContractChecks, style: label),
            if (contract.checks.isEmpty)
              Text(l10n.goalCardNoMachineCheck, style: body)
            else
              for (final check in contract.checks) _CheckLine(check: check),
            if (contract.boundaries case final b?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.goalContractBoundaries, style: label),
              Text(inertText(b), style: body),
            ],
            if (contract.stopWhen case final s?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.goalContractStopWhen, style: label),
              Text(inertText(s), style: body),
            ],
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            checkerName == null
                ? l10n.goalCheckerSelf
                : l10n.goalCheckerIs(checkerName),
            style: body,
          ),
        ],
      ),
    );
  }

  static bool _empty(GoalContract c) =>
      c.criteria.isEmpty &&
      c.checks.isEmpty &&
      c.boundaries == null &&
      c.stopWhen == null;
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 2, end: AppSpacing.xs),
          child: Icon(
            AppIcons.square,
            size: 10,
            color: context.ds.textTertiary,
          ),
        ),
        Expanded(child: Text(text, style: style)),
      ],
    ),
  );
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.check});

  final GoalCheck check;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = CcTypography.caption.copyWith(color: context.ds.textTertiary);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 2),
      child: Row(
        children: [
          Flexible(child: WorkCode(check.run)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            check.where == GoalCheckLocation.environment
                ? l10n.goalCheckEnvironmentTask(check.timeoutSeconds)
                : l10n.goalCheckWorktree(check.timeoutSeconds),
            style: style,
          ),
        ],
      ),
    );
  }
}
