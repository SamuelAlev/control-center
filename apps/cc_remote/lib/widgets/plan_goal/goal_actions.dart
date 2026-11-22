import 'dart:math' as math;

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show AgentDto;
import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/plan_goal/confirm_operation.dart';
import 'package:cc_remote/widgets/plan_goal/goal_contract_view.dart';
import 'package:cc_remote/widgets/plan_goal/goal_hold_line.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_remote/work_providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The controls a goal accepts in its state, for this viewer. Pause and
/// cancel are open to every member who sees the goal; resuming, raising the
/// budget and picking another checker are shown only when the server says
/// this viewer may resume it (`canResume`), with a sentence otherwise;
/// approving completion is offered only while the goal waits for review.
class GoalActions extends ConsumerStatefulWidget {
  const GoalActions({super.key, required this.view, required this.workspaceId});

  final GoalRunView view;
  final String workspaceId;

  @override
  ConsumerState<GoalActions> createState() => _GoalActionsState();
}

class _GoalActionsState extends ConsumerState<GoalActions> {
  bool _busy = false;
  Object? _error;
  String? _notice;

  bool get _canAct =>
      ref.read(activeWorkspaceIdProvider).value == widget.workspaceId &&
      (ref.read(workspaceRoleProvider).value?.canWrite ?? false);

  Future<void> _act(
    Future<void> Function(RpcAgentGoalRunRepository repo) action, {
    String? notice,
  }) async {
    final repo = ref.read(phoneGoalRunsRepositoryProvider);
    if (_busy || !_canAct || repo == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action(repo);
      if (mounted && notice != null) setState(() => _notice = notice);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmThen(
    String title,
    String body,
    String action,
    Future<void> Function(RpcAgentGoalRunRepository repo) run, {
    bool destructive = false,
  }) async {
    final ok = await confirmOperation(
      context,
      title: title,
      description: body,
      action: action,
      destructive: destructive,
    );
    if (ok && mounted) await _act(run);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final g = widget.view.goal;
    final mayResume = widget.view.canResume;
    ref.watch(activeWorkspaceIdProvider);
    final writable = ref.watch(workspaceRoleProvider).value?.canWrite ?? false;
    final paused = g.status == AgentGoalStatus.paused;
    final raisable = goalBudgetRaisable(g);
    final inReview = paused && g.hold == GoalHold.needsReview;
    final checkerGone =
        paused && (g.holdDetail ?? '').startsWith('checker_unavailable');
    // Double the larger of the cap and the spend: always above the spend
    // that tripped the cap, as the server requires.
    final nextCap = math.max(math.max(g.costCapMicros, g.costMicros), 1) * 2;
    Widget button(
      String label,
      VoidCallback onPressed, {
      CcButtonVariant variant = CcButtonVariant.secondary,
    }) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: CcButton(
        fullWidth: true,
        size: CcButtonSize.lg,
        variant: variant,
        onPressed: _busy ? null : onPressed,
        child: Text(label),
      ),
    );
    final ws = widget.workspaceId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: WorkFailureLine(error: _error!),
          ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _notice!,
              style: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
          ),
        if (writable) ...[
          // Approve completion only when the server says this viewer may
          // (a pipeline goal is its requester's); otherwise disabled, with
          // the not-yours sentence.
          if (inReview && widget.view.canApprove)
            button(
              l.goalApprove,
              () => _confirmThen(
                l.goalApproveTitle,
                l.goalApproveBody,
                l.goalApproveConfirm,
                (r) => r.approveCompletion(ws, g.id),
              ),
              variant: CcButtonVariant.primary,
            ),
          if (inReview && !widget.view.canApprove) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CcButton(
                fullWidth: true,
                size: CcButtonSize.lg,
                variant: CcButtonVariant.primary,
                onPressed: null,
                child: Text(l.goalApprove),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.goalRefusalNotYours,
                style: CcTypography.bodySm.copyWith(color: t.textSecondary),
              ),
            ),
          ],
          if (paused && mayResume)
            button(
              l.mobileGoalResume,
              () => _act((r) => r.resumeGoal(ws, g.id)),
              variant: inReview
                  ? CcButtonVariant.secondary
                  : CcButtonVariant.primary,
            ),
          if (raisable && mayResume)
            button(
              l.mobileGoalRaiseTo(planMoney(context, nextCap)),
              () => _confirmThen(
                l.mobileGoalRaiseBudget,
                l.mobileGoalRaiseConfirm(
                  planMoney(context, g.costCapMicros),
                  planMoney(context, nextCap),
                ),
                l.mobileGoalRaiseBudget,
                (r) => r.resumeGoal(ws, g.id, raiseCostCapMicros: nextCap),
              ),
              variant: CcButtonVariant.primary,
            ),
          if ((paused || raisable) && !mayResume)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l.goalResumeNotYours,
                style: CcTypography.bodySm.copyWith(color: t.textSecondary),
              ),
            ),
          if (checkerGone && mayResume) _checkerPicker(context, l),
          if (g.status == AgentGoalStatus.active)
            button(l.mobileGoalPause, () => _act((r) => r.pauseGoal(ws, g.id))),
          if (g.status == AgentGoalStatus.active || paused || raisable)
            button(
              l.mobileGoalStop,
              () => _confirmThen(
                l.mobileGoalStop,
                l.mobileGoalStopConfirm,
                l.mobileGoalStop,
                (r) => r.cancelGoal(ws, g.id),
                destructive: true,
              ),
              variant: CcButtonVariant.destructive,
            ),
        ],
      ],
    );
  }

  Widget _checkerPicker(BuildContext context, AppLocalizations l) {
    // Changing the checker is the requester's, as resuming is.
    if (!widget.view.canResume) return const SizedBox.shrink();
    final g = widget.view.goal;
    final agents = (ref.watch(agentsProvider).value ?? const <AgentDto>[])
        .where(
          (a) =>
              a.workspaceId == widget.workspaceId &&
              a.lifecycleStatus == 'active' &&
              a.id != g.agentId &&
              a.id != g.checkerAgentId,
        )
        .toList();
    if (agents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        goalSectionHeading(context, l.goalChooseChecker),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final agent in agents)
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.secondary,
                onPressed: _busy
                    ? null
                    : () => _act(
                        (r) => r.setChecker(widget.workspaceId, g.id, agent.id),
                        notice: l.goalCheckerSet(agent.name),
                      ),
                child: Text(agent.name),
              ),
          ],
        ),
      ],
    );
  }
}
