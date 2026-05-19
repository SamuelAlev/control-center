import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_status.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/agents/providers/conversation_run_tree_provider.dart';
import 'package:control_center/features/agents/providers/run_activity_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/paused_runs_provider.dart';
import 'package:control_center/features/observability/presentation/widgets/run_activity_stats.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The header of a run-activity tab: who ran, its live status, its metrics and
/// the run-scoped controls (pause/resume, stop) that only make sense here.
class AgentActivityHeader extends ConsumerWidget {
  /// Creates an [AgentActivityHeader].
  const AgentActivityHeader({
    super.key,
    required this.workspaceId,
    required this.channelId,
    required this.runId,
    required this.agentId,
    required this.run,
    this.fallbackLabel,
  });

  /// The workspace the run belongs to.
  final String workspaceId;

  /// The conversation the run belongs to.
  final String channelId;

  /// The run being shown.
  final String runId;

  /// The agent that executed the run (often the literal `subagent` for an
  /// ephemeral child — see [_agentLabel]).
  final String agentId;

  /// The run's log row, or null when it is not (or no longer) resolvable.
  final AgentRunLog? run;

  /// Tab label to show before the run row resolves, or after it is gone.
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final toolCount = ref.watch(
      runToolCountProvider((workspaceId: workspaceId, runId: runId)),
    );
    final isActive = run?.isActive ?? false;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AgentStatusBadge(
                state: run == null ? AgentLiveState.idle : runLiveState(run!),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                    Text(
                      _agentLabel(ref, l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.caption.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive) ..._controls(context, ref, l10n),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          RunActivityStatBar(
            cost: run?.cost,
            toolCount: toolCount,
            childCostCents: run?.childCostCents ?? 0,
          ),
        ],
      ),
    );
  }

  /// The run's own summary, else the label the tab was opened with.
  String _title(AppLocalizations l10n) {
    final summary = run?.summary?.trim();
    if (summary != null && summary.isNotEmpty) {
      return summary;
    }
    final fallback = fallbackLabel?.trim();
    return (fallback == null || fallback.isEmpty)
        ? l10n.ideAgentActivity
        : fallback;
  }

  /// The agent's display name.
  ///
  /// An ephemeral subagent carries its PARENT's agent id (or the literal
  /// `subagent`), so the agents lookup usually misses — without the parent
  /// fallback the header would read "subagent" as if that were a name.
  String _agentLabel(WidgetRef ref, AppLocalizations l10n) {
    final agents =
        ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
        const <Agent>[];
    final byId = {for (final a in agents) a.id: a};

    String? nameOf(String? id) {
      final agent = id == null ? null : byId[id];
      if (agent == null) {
        return null;
      }
      final name = agent.name.trim();
      if (name.isNotEmpty) {
        return name;
      }
      final title = agent.title.trim();
      return title.isEmpty ? null : title;
    }

    final own = nameOf(agentId);
    if (run?.role != AgentRunRole.sub) {
      return own ?? agentId;
    }
    // A subagent reads as "Subagent of <parent>": resolve the parent through the
    // conversation's own run set rather than a second query.
    final parentId = run?.parentRunId;
    final parent = parentId == null
        ? null
        : ref
              .watch(
                runInConversationProvider((
                  workspaceId: workspaceId,
                  channelId: channelId,
                  runId: parentId,
                )),
              )
              .asData
              ?.value;
    final parentName = nameOf(parent?.agentId) ?? own;
    return parentName == null
        ? l10n.ideAgentActivity
        : l10n.agentActivitySubagentOf(parentName);
  }

  List<Widget> _controls(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final paused = ref.watch(pausedRunsProvider).contains(runId);
    return [
      CcIconButton(
        icon: paused ? AppIcons.play : AppIcons.pause,
        tooltip: paused ? l10n.resumeAgent : l10n.pauseAgent,
        onPressed: () => _togglePause(ref, context, paused: paused),
      ),
      CcIconButton(
        icon: AppIcons.circleStop,
        tooltip: l10n.stopAgentRun,
        onPressed: () => _stop(context, ref, l10n),
      ),
    ];
  }

  /// Pauses or resumes the run at a turn boundary. Optimistically flips the
  /// affordance; the server is the authority, so a run it refuses (an external
  /// CLI, or one already finished) surfaces a toast and stays un-paused.
  Future<void> _togglePause(
    WidgetRef ref,
    BuildContext context, {
    required bool paused,
  }) async {
    final port = ref.read(messagingServiceProvider);
    final notifier = ref.read(pausedRunsProvider.notifier);
    final toast = CcToastScope.of(context);
    final cannotPause = AppLocalizations.of(context).agentCannotPause;
    if (paused) {
      notifier.markResumed(runId);
      await port.resumeRun(runId);
      return;
    }
    if (await port.pauseRun(runId)) {
      notifier.markPaused(runId);
    } else {
      toast.show(cannotPause, variant: CcToastVariant.neutral);
    }
  }

  Future<void> _stop(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final port = ref.read(messagingServiceProvider);
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.stopAgentRun,
      message: l10n.stopAgentRunConfirm,
      confirmLabel: l10n.stopAgentRun,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (confirmed) {
      await port.stopRun(ref.requireWorkspaceId(), runId);
    }
  }
}
