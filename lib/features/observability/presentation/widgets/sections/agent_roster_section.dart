import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maps an [AgentStatus] to its roster tone.
ObsTone obsAgentStatusTone(AgentStatus status) => switch (status) {
  AgentStatus.running => ObsTone.success,
  AgentStatus.idle => ObsTone.neutral,
  AgentStatus.parked => ObsTone.warning,
  AgentStatus.aborted => ObsTone.danger,
};

int _sortKey(AgentRef a) => switch (a.status) {
  AgentStatus.running => 0,
  AgentStatus.idle => 1,
  AgentStatus.parked => 2,
  AgentStatus.aborted => 3,
};

/// Sorts the roster: running, idle, parked, aborted; ties by lastActivity
/// descending.
List<AgentRef> sortObsRoster(List<AgentRef> roster) {
  final sorted = [...roster]
    ..sort((a, b) {
      final byStatus = _sortKey(a).compareTo(_sortKey(b));
      if (byStatus != 0) {
        return byStatus;
      }
      return b.lastActivity.compareTo(a.lastActivity);
    });
  return sorted;
}

/// The agent roster section — one row per agent with status, current
/// activity, tokens, cost, and a kill control. Selection and drawer docking
/// are owned by the parent tab; this widget never scrolls.
class AgentRosterSection extends ConsumerWidget {
  /// Creates an [AgentRosterSection].
  const AgentRosterSection({
    super.key,
    required this.roster,
    required this.latestRunByAgent,
    required this.activeRunByAgent,
    required this.selectedAgentId,
    required this.onSelectAgent,
  });

  /// The roster rows, already sorted via [sortObsRoster].
  final List<AgentRef> roster;

  /// Latest run per agent id, for the token/cost stats.
  final Map<String, AgentRunLog> latestRunByAgent;

  /// Newest uncompleted run per agent id, for the kill pid.
  final Map<String, AgentRunLog> activeRunByAgent;

  /// The currently selected agent id, if any.
  final String? selectedAgentId;

  /// Row-tap callback; toggle semantics are handled by the caller.
  final ValueChanged<String?> onSelectAgent;

  Future<void> _kill(WidgetRef ref, int pid) async {
    await ref.read(processControlPortProvider).kill(pid);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ObsSection(
      title: l10n.obsAgentsTitle,
      icon: AppIcons.bot,
      child: Column(
        children: [
          for (final agent in roster)
            _AgentRow(
              agent: agent,
              latestRun: latestRunByAgent[agent.id],
              selected: agent.id == selectedAgentId,
              onTap: () => onSelectAgent(agent.id),
              onKill: activeRunByAgent[agent.id]?.pid == null
                  ? null
                  : () => _kill(ref, activeRunByAgent[agent.id]!.pid!),
              tone: obsAgentStatusTone(agent.status),
            ),
        ],
      ),
    );
  }
}

class _AgentRow extends StatelessWidget {
  const _AgentRow({
    required this.agent,
    required this.latestRun,
    required this.selected,
    required this.onTap,
    required this.onKill,
    required this.tone,
  });

  final AgentRef agent;
  final AgentRunLog? latestRun;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onKill;
  final ObsTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final cost = latestRun?.cost;
    final running = agent.status == AgentStatus.running;
    final activity = running && (agent.activity?.isNotEmpty ?? false)
        ? '${agent.activity} · ${relTime(agent.lastActivity)}'
        : switch (agent.status) {
            AgentStatus.idle => l10n.obsAgentStatusIdle,
            AgentStatus.parked => l10n.obsAgentStatusParked,
            AgentStatus.aborted => l10n.obsAgentStatusAborted,
            AgentStatus.running => l10n.obsStatusRunning,
          };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: CcTappable(
        onPressed: onTap,
        borderRadius: AppRadii.brLg,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: hovered || selected ? t.bgSecondary : t.bgPrimary,
              borderRadius: AppRadii.brLg,
              border: Border.all(
                color: selected ? t.borderBrand : t.borderPrimary,
              ),
            ),
            child: Row(
              children: [
                ObsStatusDot(tone: tone),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 160,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          agent.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CcTypography.body.copyWith(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (agent.kind != AgentKind.main) ...[
                        const SizedBox(width: AppSpacing.xs),
                        CcBadge(
                          label: agent.kind == AgentKind.advisor
                              ? l10n.obsRoleAdvisor
                              : l10n.obsAgentKindSub,
                          variant: agent.kind == AgentKind.advisor
                              ? CcBadgeVariant.neutral
                              : CcBadgeVariant.brand,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    activity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(
                      color: t.textSecondary,
                      fontFeatures: const [],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _stat(
                  context,
                  fmtTokens(cost?.totalTokens ?? 0),
                  l10n.obsRosterTokensLabel,
                ),
                const SizedBox(width: AppSpacing.lg),
                _stat(
                  context,
                  fmtCents(cost?.estimatedCostCents ?? 0),
                  l10n.obsStatCost,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (onKill != null)
                  CcIconButton(
                    icon: AppIcons.circleStop,
                    onPressed: onKill,
                    tooltip: l10n.obsKillAgent,
                  )
                else
                  const SizedBox(width: 28),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: CcTypography.monoNum.copyWith(color: t.textPrimary)),
        Text(
          label,
          style: CcTypography.caption.copyWith(color: t.textQuaternary),
        ),
      ],
    );
  }
}
