import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/insights_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The granular run log: the newest 50 filtered runs. Tapping a row docks the
/// run's transcript drawer in the tab.
class RunLogSection extends ConsumerWidget {
  /// Creates a [RunLogSection].
  const RunLogSection({
    super.key,
    required this.selectedRunId,
    required this.onSelectRun,
  });

  /// The run whose drawer is docked, if any.
  final String? selectedRunId;

  /// Selects a run (docks its transcript drawer).
  final ValueChanged<AgentRunLog> onSelectRun;

  static const _cap = 50;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final runs = ref.watch(filteredRunLogsProvider);
    final options = ref.watch(insightsFilterOptionsProvider);
    final agentNames = {for (final a in options.agents) a.value: a.label};

    final shown = runs.take(_cap).toList();

    return ObsSection(
      title: l10n.obsRunsTitle,
      icon: AppIcons.scrollText,
      child: shown.isEmpty
          ? Text(
              l10n.obsNoRunsInRange,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RunHeader(l10n: l10n),
                for (final run in shown)
                  _RunRow(
                    run: run,
                    agentName: agentNames[run.agentId] ?? run.agentId,
                    selected: run.id == selectedRunId,
                    onTap: () => onSelectRun(run),
                  ),
              ],
            ),
    );
  }
}

class _RunHeader extends StatelessWidget {
  const _RunHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final style = CcTypography.caption.copyWith(color: t.textQuaternary);

    Widget cell(String label, double width) => SizedBox(
      width: width,
      child: Text(label, style: style, textAlign: TextAlign.right, maxLines: 1),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(width: 76, child: Text(l10n.obsColTime, style: style)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.obsColAgent, style: style)),
          SizedBox(width: 96, child: Text(l10n.obsColStatus, style: style)),
          Expanded(child: Text(l10n.obsColModel, style: style)),
          cell(l10n.obsColDuration, 64),
          cell(l10n.obsColTokens, 56),
          cell(l10n.obsColCost, 64),
        ],
      ),
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({
    required this.run,
    required this.agentName,
    required this.selected,
    required this.onTap,
  });

  final AgentRunLog run;
  final String agentName;
  final bool selected;
  final VoidCallback onTap;

  static ObsTone _statusTone(RunStatus status) => switch (status) {
    RunStatus.completed => ObsTone.success,
    RunStatus.error => ObsTone.danger,
    RunStatus.running => ObsTone.brand,
    RunStatus.pending => ObsTone.neutral,
  };

  static String _statusLabel(AppLocalizations l10n, RunStatus status) =>
      switch (status) {
        RunStatus.pending => l10n.obsStatusPending,
        RunStatus.running => l10n.obsStatusRunning,
        RunStatus.completed => l10n.obsStatusCompleted,
        RunStatus.error => l10n.obsStatusError,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final numStyle = CcTypography.monoNum.copyWith(color: t.textPrimary);
    final cost = run.cost;

    Widget numCell(String text, double width) => SizedBox(
      width: width,
      child: Text(
        text,
        style: numStyle,
        textAlign: TextAlign.right,
        maxLines: 1,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      child: CcTappable(
        semanticLabel: agentName,
        borderRadius: AppRadii.brMd,
        onPressed: onTap,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected || hovered ? t.bgSecondary : t.bgPrimary,
              borderRadius: AppRadii.brMd,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: AppTimestamp.relative(
                    run.startedAt,
                    style: CcTypography.caption.copyWith(color: t.textTertiary),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    agentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: Row(
                    children: [
                      ObsStatusDot(tone: _statusTone(run.status), size: 6),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          _statusLabel(l10n, run.status),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CcTypography.caption.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    run.modelId ?? run.adapter ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                  ),
                ),
                numCell(
                  cost.durationMs == null ? '—' : fmtDuration(cost.durationMs!),
                  64,
                ),
                numCell(fmtTokens(cost.totalTokens), 56),
                numCell(fmtCents(cost.estimatedCostCents), 64),
              ],
            ),
          );
        },
      ),
    );
  }
}
