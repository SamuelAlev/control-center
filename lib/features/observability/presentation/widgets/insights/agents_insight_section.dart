import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/insights_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The per-agent Insights table: cost-sorted rows with drill-down — tapping a
/// row toggles that agent in the run filters, narrowing every other surface.
class AgentsInsightSection extends ConsumerWidget {
  /// Creates an [AgentsInsightSection].
  const AgentsInsightSection({
    super.key,
    required this.showAll,
    required this.onToggleShowAll,
  });

  /// Whether the full roster is shown (vs the top 10).
  final bool showAll;

  /// Toggles [showAll].
  final VoidCallback onToggleShowAll;

  static const _cap = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rows = ref.watch(insightsPerAgentProvider);
    final selected = ref.watch(obsRunFiltersProvider).agentIds;

    final shown = showAll ? rows : rows.take(_cap).toList();

    return ObsSection(
      title: l10n.obsAgentsTitle,
      icon: AppIcons.bot,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(l10n: l10n),
          for (final row in shown)
            _AgentInsightTile(
              row: row,
              selected: selected.contains(row.agentId),
              onTap: () => ref
                  .read(obsRunFiltersProvider.notifier)
                  .toggleAgent(row.agentId),
            ),
          if (rows.length > _cap)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  onPressed: onToggleShowAll,
                  child: Text(
                    showAll
                        ? l10n.obsShowFewerAgents
                        : l10n.obsShowAllAgents(rows.length),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final style = CcTypography.caption.copyWith(color: t.textQuaternary);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(l10n.obsColAgent, style: style)),
          _NumHeader(label: l10n.obsColRuns, style: style, width: 48),
          _NumHeader(label: l10n.obsColErrors, style: style, width: 56),
          _NumHeader(label: l10n.obsColCost, style: style, width: 72),
          _NumHeader(label: l10n.obsColAvgLatency, style: style, width: 84),
          _NumHeader(label: l10n.obsColLastActive, style: style, width: 88),
        ],
      ),
    );
  }
}

class _NumHeader extends StatelessWidget {
  const _NumHeader({
    required this.label,
    required this.style,
    required this.width,
  });

  final String label;
  final TextStyle style;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(label, style: style, textAlign: TextAlign.right),
    );
  }
}

class _AgentInsightTile extends StatelessWidget {
  const _AgentInsightTile({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  final AgentInsightRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final numStyle = CcTypography.monoNum.copyWith(color: t.textPrimary);

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
        semanticLabel: row.displayName,
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
                Expanded(
                  child: Text(
                    row.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                numCell(fmtCount(row.runs), 48),
                numCell(fmtCount(row.errors), 56),
                numCell(fmtCents(row.costCents), 72),
                numCell(
                  row.avgDurationMs == null
                      ? '—'
                      : fmtDuration(row.avgDurationMs!.round()),
                  84,
                ),
                SizedBox(
                  width: 88,
                  child: Text(
                    formatRelativeTime(context, row.lastActive),
                    style: CcTypography.caption.copyWith(color: t.textTertiary),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
