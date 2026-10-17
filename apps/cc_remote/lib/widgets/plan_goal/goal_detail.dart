import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
import 'package:cc_remote/widgets/plan_goal/confirm_operation.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

String phoneGoalStatus(AppLocalizations l10n, AgentGoalStatus status) =>
    switch (status) {
      AgentGoalStatus.active => l10n.mobileGoalActive,
      AgentGoalStatus.paused => l10n.mobileGoalPaused,
      AgentGoalStatus.completed => l10n.mobileGoalCompleted,
      AgentGoalStatus.failed => l10n.mobileGoalFailed,
      AgentGoalStatus.cancelled => l10n.mobileGoalCancelled,
      AgentGoalStatus.budgetExhausted => l10n.mobileGoalBudgetExhausted,
    };

/// Durable supervisor state and only the controls the current status accepts.
class PhoneGoalDetail extends ConsumerStatefulWidget {
  const PhoneGoalDetail({
    super.key,
    required this.goal,
    required this.workspaceId,
  });
  final AgentGoalRun goal;
  final String workspaceId;

  @override
  ConsumerState<PhoneGoalDetail> createState() => _PhoneGoalDetailState();
}

class _PhoneGoalDetailState extends ConsumerState<PhoneGoalDetail> {
  bool _busy = false;
  String? _error;

  bool get _canAct =>
      ref.read(activeWorkspaceIdProvider).value == widget.workspaceId &&
      (ref.read(workspaceRoleProvider).value?.canWrite ?? false);

  Future<void> _act(
    Future<void> Function(RpcAgentGoalRunRepository) action,
  ) async {
    if (_busy || !_canAct) return;
    final client = ref.read(rpcClientProvider).value;
    if (client == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_canAct) return;
      await action(RpcAgentGoalRunRepository(client));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmOperation(
      context,
      title: l10n.mobileGoalStop,
      description: l10n.mobileGoalStopConfirm,
      action: l10n.mobileGoalStop,
      destructive: true,
    );
    if (ok && mounted) {
      await _act((r) => r.cancelGoal(widget.workspaceId, widget.goal.id));
    }
  }

  Future<void> _resumeRaising(int newCap) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmOperation(
      context,
      title: l10n.mobileGoalRaiseBudget,
      description: l10n.mobileGoalRaiseConfirm(
        planMoney(context, widget.goal.costCapCents),
        planMoney(context, newCap),
      ),
      action: l10n.mobileGoalRaiseBudget,
    );
    if (ok && mounted) {
      await _act(
        (r) => r.resumeGoal(
          widget.workspaceId,
          widget.goal.id,
          raiseCostCapCents: newCap,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final g = widget.goal;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat.decimalPattern(locale);
    final writable = ref.watch(workspaceRoleProvider).value?.canWrite ?? false;
    final budgetOnly =
        g.status == AgentGoalStatus.budgetExhausted &&
        g.costCents >= g.costCapCents &&
        !g.deadlinePassed(DateTime.now()) &&
        (g.maxRuns == null || g.runCount < g.maxRuns!);
    final nextCap = g.costCapCents > g.costCents
        ? g.costCapCents * 2
        : (g.costCents + 1) * 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          g.userText,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: CcBadge(
            label: phoneGoalStatus(l10n, g.status),
            variant: g.status == AgentGoalStatus.failed
                ? CcBadgeVariant.danger
                : g.status == AgentGoalStatus.active
                ? CcBadgeVariant.success
                : CcBadgeVariant.neutral,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.mobileGoalKind(
            g.kind == AgentGoalKind.loop
                ? l10n.mobileGoalLoop
                : l10n.mobileGoalGoal,
          ),
          style: TextStyle(color: t.textSecondary),
        ),
        Text(
          l10n.mobileGoalProgress(
            number.format(g.runCount),
            g.maxRuns == null
                ? l10n.mobileGoalNoRunLimit
                : number.format(g.maxRuns!),
            planMoney(context, g.costCents),
            planMoney(context, g.costCapCents),
          ),
          style: TextStyle(fontSize: 14, color: t.textSecondary),
        ),
        if (g.deadlineAt != null)
          Text(
            l10n.mobileGoalDeadline(
              '${shortDate(context, g.deadlineAt!)} ${clockTime(context, g.deadlineAt!)}',
            ),
            style: TextStyle(color: t.textSecondary),
          ),
        if (g.consecutiveFailures > 0)
          Text(
            l10n.mobileGoalFailures(number.format(g.consecutiveFailures)),
            style: TextStyle(color: t.danger),
          ),
        if (g.summary?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Text(
            l10n.mobileGoalSummary,
            style: TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary),
          ),
          PhoneMarkdown(data: g.summary!),
        ],
        if (g.status == AgentGoalStatus.failed && g.summary?.isNotEmpty != true)
          Text(
            l10n.mobileGoalFailedDescription,
            style: TextStyle(color: t.danger),
          ),
        if (g.status == AgentGoalStatus.budgetExhausted && !budgetOnly)
          Text(
            l10n.mobileGoalBudgetWall,
            style: TextStyle(color: t.textSecondary),
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: t.danger)),
        ],
        if (writable && g.status == AgentGoalStatus.active) ...[
          const SizedBox(height: 20),
          CcButton(
            fullWidth: true,
            size: CcButtonSize.lg,
            loading: _busy,
            variant: CcButtonVariant.secondary,
            onPressed: _busy
                ? null
                : () => _act((r) => r.pauseGoal(widget.workspaceId, g.id)),
            child: Text(l10n.mobileGoalPause),
          ),
        ],
        if (writable && g.status == AgentGoalStatus.paused) ...[
          const SizedBox(height: 20),
          CcButton(
            fullWidth: true,
            size: CcButtonSize.lg,
            loading: _busy,
            onPressed: _busy
                ? null
                : () => _act((r) => r.resumeGoal(widget.workspaceId, g.id)),
            child: Text(l10n.mobileGoalResume),
          ),
        ],
        if (writable && budgetOnly) ...[
          const SizedBox(height: 20),
          CcButton(
            fullWidth: true,
            size: CcButtonSize.lg,
            loading: _busy,
            onPressed: _busy ? null : () => _resumeRaising(nextCap),
            child: Text(l10n.mobileGoalRaiseTo(planMoney(context, nextCap))),
          ),
        ],
        if (writable &&
            (g.status == AgentGoalStatus.active ||
                g.status == AgentGoalStatus.paused)) ...[
          const SizedBox(height: 8),
          CcButton(
            fullWidth: true,
            size: CcButtonSize.lg,
            variant: CcButtonVariant.destructive,
            onPressed: _busy ? null : _stop,
            child: Text(l10n.mobileGoalStop),
          ),
        ],
        if (g.spaceId.isNotEmpty) ...[
          const SizedBox(height: 16),
          CcButton(
            fullWidth: true,
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            icon: AppIcons.arrowRight,
            onPressed: () => context.push(
              remoteSpaceLocation(
                workspaceId: widget.workspaceId,
                spaceId: g.spaceId,
                conversationId: g.conversationId,
              ),
            ),
            child: Text(l10n.mobileGoalOpenConversation),
          ),
        ],
      ],
    );
  }
}
