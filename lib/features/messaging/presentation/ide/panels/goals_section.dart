import 'package:cc_data/cc_data.dart' show RpcAgentGoalRunRepository;
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/todos/providers/goal_run_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The conversation's durable supervised goals ([AgentGoalRun]). Hidden
/// entirely when the conversation has none — the section only appears once a
/// `/goal` or `/loop` is standing.
class GoalsSection extends ConsumerWidget {
  /// Creates a [GoalsSection].
  const GoalsSection({
    super.key,
    required this.channelId,
    required this.workspaceId,
  });

  /// The conversation whose goals are shown.
  final String channelId;

  /// The active workspace.
  final String workspaceId;

  /// Terminal goals stay visible for a glance at what just finished, capped so
  /// history never crowds out the live goals.
  static const visibleTerminalGoals = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final goalsAsync = ref.watch(conversationAgentGoalRunsProvider(channelId));
    final goals = goalsAsync.asData?.value ?? const <AgentGoalRun>[];
    if (goals.isEmpty) {
      return const SizedBox.shrink();
    }

    final live = goals.where((g) => !g.status.isTerminal).toList();
    final terminal = goals.where((g) => g.status.isTerminal).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final visible = [...live, ...terminal.take(visibleTerminalGoals)];

    return CollapsibleSidebarSection(
      icon: AppIcons.target,
      label: l10n.generalSectionGoals,
      count: live.isEmpty ? null : '${live.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final goal in visible)
            GoalRunRow(
              key: ValueKey(goal.id),
              goal: goal,
              workspaceId: workspaceId,
            ),
        ],
      ),
    );
  }
}

/// One durable goal: kind glyph + objective + status chip, with a
/// run/cost-budget secondary line while the goal is still live and
/// pause/resume/stop controls on the rows that can take them.
class GoalRunRow extends ConsumerWidget {
  /// Creates a [GoalRunRow].
  const GoalRunRow({super.key, required this.goal, required this.workspaceId});

  /// The goal to render.
  final AgentGoalRun goal;

  /// The active workspace.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final terminal = goal.status.isTerminal;
    final deadlineAt = goal.deadlineAt;
    final deadline = deadlineAt == null
        ? null
        : '${DateFormat.MMMEd(locale).format(deadlineAt.toLocal())} · '
              '${DateFormat.Hm(locale).format(deadlineAt.toLocal())}';
    final maxRuns = goal.maxRuns;

    return CcTooltip(
      message:
          '${goal.userText}'
          '${deadline == null ? '' : '\n${l10n.goalRunDeadline(deadline)}'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  goal.kind == AgentGoalKind.loop
                      ? AppIcons.repeat
                      : AppIcons.target,
                  size: 14,
                  color: terminal ? t.textQuaternary : t.fgBrandPrimary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    goal.userText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: terminal ? t.textTertiary : t.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                GoalRunStatusBadge(status: goal.status),
                ..._controls(ref, l10n, t),
              ],
            ),
            if (!terminal)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.sm + 14,
                  top: 2,
                ),
                child: Text(
                  maxRuns == null
                      ? l10n.goalRunProgressNoCap(
                          goal.runCount,
                          _dollars(goal.costCents),
                          _dollars(goal.costCapCents),
                        )
                      : l10n.goalRunProgress(
                          goal.runCount,
                          maxRuns,
                          _dollars(goal.costCents),
                          _dollars(goal.costCapCents),
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: t.textTertiary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// `$x.xx` from cents — budgets are priced in dollars.
  static String _dollars(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

  /// Pause/resume + stop on live goals; nothing once terminal — a finished
  /// goal takes no commands.
  List<Widget> _controls(
    WidgetRef ref,
    AppLocalizations l10n,
    DesignSystemTokens t,
  ) => switch (goal.status) {
    AgentGoalStatus.active => [
      const SizedBox(width: AppSpacing.xs),
      _control(
        label: l10n.goalRunPause,
        icon: AppIcons.pause,
        color: t.textTertiary,
        onTap: () => _act(ref, (repo) => repo.pauseGoal(workspaceId, goal.id)),
      ),
      _control(
        label: l10n.goalRunStop,
        icon: AppIcons.circleStop,
        color: t.textTertiary,
        onTap: () => _act(ref, (repo) => repo.cancelGoal(workspaceId, goal.id)),
      ),
    ],
    AgentGoalStatus.paused => [
      const SizedBox(width: AppSpacing.xs),
      _control(
        label: l10n.goalRunResume,
        icon: AppIcons.play,
        color: t.textTertiary,
        onTap: () => _act(ref, (repo) => repo.resumeGoal(workspaceId, goal.id)),
      ),
      _control(
        label: l10n.goalRunStop,
        icon: AppIcons.circleStop,
        color: t.textTertiary,
        onTap: () => _act(ref, (repo) => repo.cancelGoal(workspaceId, goal.id)),
      ),
    ],
    // Budget exhaustion is not completion: resume raises the cost cap and
    // the button says so — silently doubling an explicit `--budget` on one
    // unlabeled click is how a $2 goal becomes $4 without consent.
    AgentGoalStatus.budgetExhausted => [
      const SizedBox(width: AppSpacing.xs),
      _control(
        label: l10n.goalRunResumeRaise(_dollars(goal.costCapCents * 2)),
        icon: AppIcons.play,
        color: t.textTertiary,
        onTap: () => _act(
          ref,
          (repo) => repo.resumeGoal(
            workspaceId,
            goal.id,
            raiseCostCapCents: goal.costCapCents * 2,
          ),
        ),
      ),
      _control(
        label: l10n.goalRunStop,
        icon: AppIcons.circleStop,
        color: t.textTertiary,
        onTap: () => _act(ref, (repo) => repo.cancelGoal(workspaceId, goal.id)),
      ),
    ],
    _ => const [],
  };

  Widget _control({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => Semantics(
    button: true,
    label: label,
    child: CcTooltip(
      message: label,
      // CcTappable, cc_ui's ripple-free InkWell replacement: same pointer +
      // keyboard + focus-ring behaviour without pulling flutter/material.dart
      // into this file (see the vendor ratchet in
      // architecture_constraints_test.dart). Deliberately NOT CcIconButton —
      // its 32px box would nearly double these controls and this is a dense
      // sidebar row where the 14px glyph is the design.
      child: CcTappable(
        onPressed: onTap,
        borderRadius: AppRadii.brSm,
        builder: (context, states) => Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    ),
  );

  /// Fire-and-forget with a toast on failure: pause/resume/stop are
  /// instantaneous state changes the next watch tick reflects, so no
  /// optimistic local state is needed.
  Future<void> _act(
    WidgetRef ref,
    Future<void> Function(RpcAgentGoalRunRepository repo) action,
  ) async {
    final context = ref.context;
    try {
      await action(ref.read(agentGoalRunRepositoryProvider));
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show('$e', variant: CcToastVariant.danger);
      }
    }
  }
}

/// The goal's lifecycle chip — a distinct label AND icon per status (never
/// colour alone), per the accessibility bar.
class GoalRunStatusBadge extends StatelessWidget {
  /// Creates a [GoalRunStatusBadge].
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
