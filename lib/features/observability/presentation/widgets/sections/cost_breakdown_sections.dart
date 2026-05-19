import 'dart:math' as math;

import 'package:cc_domain/features/observability/domain/token_axis_aggregator.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/insights_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cost and token breakdown sections for the Insights tab. Every section
/// reads [insightsTokenAggregationProvider] (range + facet filtered) and
/// renders a single [ObsSection] card without owning any scrolling — the
/// parent tab composes and scrolls them.

/// "Cost by role" — three labeled meters splitting cost across main /
/// subagents / advisor, plus a total row and a one-line summary caption.
class CostByRoleSection extends ConsumerWidget {
  /// Creates a [CostByRoleSection].
  const CostByRoleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(insightsTokenAggregationProvider).byRole;
    final totalCents = role.totalCostCents;
    final denom = math.max(1, totalCents);

    return ObsSection(
      title: l10n.obsCostByRoleTitle,
      subtitle: l10n.obsCostByRoleSubtitle,
      icon: AppIcons.gem,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ObsBar(
            label: l10n.obsRoleMain,
            fraction: role.main.costCents / denom,
            valueLabel: fmtCents(role.main.costCents),
            tone: ObsTone.brand,
          ),
          ObsBar(
            label: l10n.obsRoleSubagents,
            fraction: role.sub.costCents / denom,
            valueLabel: fmtCents(role.sub.costCents),
            tone: ObsTone.neutral,
          ),
          ObsBar(
            label: l10n.obsRoleAdvisor,
            fraction: role.advisor.costCents / denom,
            valueLabel: fmtCents(role.advisor.costCents),
            tone: ObsTone.neutral,
          ),
          const SizedBox(height: AppSpacing.xs),
          const CcDivider(),
          const SizedBox(height: AppSpacing.xs),
          ObsKeyValue(
            label: l10n.obsTotal,
            value: fmtCents(totalCents),
            valueTone: ObsTone.brand,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.obsRoleCaption(
              fmtCents(role.main.costCents),
              fmtCents(role.sub.costCents),
              fmtCents(role.advisor.costCents),
            ),
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// "Token model (5 axes)" — input / output / reasoning / cache read / cache
/// write counts plus a total, with a note on cache-read discounting.
class TokenModelSection extends ConsumerWidget {
  /// Creates a [TokenModelSection].
  const TokenModelSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final totals = ref.watch(insightsTokenAggregationProvider).totals;

    return ObsSection(
      title: l10n.obsTokenModelTitle,
      subtitle: l10n.obsTokenModelSubtitle,
      icon: AppIcons.zap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ObsKeyValue(label: l10n.obsAxisInput, value: fmtTokens(totals.input)),
          ObsKeyValue(
            label: l10n.obsAxisOutput,
            value: fmtTokens(totals.output),
          ),
          ObsKeyValue(
            label: l10n.obsAxisReasoning,
            value: fmtTokens(totals.reasoning),
          ),
          ObsKeyValue(
            label: l10n.obsAxisCacheRead,
            value: fmtTokens(totals.cacheRead),
          ),
          ObsKeyValue(
            label: l10n.obsAxisCacheWrite,
            value: fmtTokens(totals.cacheWrite),
          ),
          const SizedBox(height: AppSpacing.xs),
          const CcDivider(),
          const SizedBox(height: AppSpacing.xs),
          ObsKeyValue(
            label: l10n.obsTotalTokens,
            value: fmtTokens(totals.total),
            valueTone: ObsTone.brand,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.info, size: 12, color: t.fgTertiary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.obsCacheDiscountNote,
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "By model" — one card per [ModelUsage] (already sorted by cost desc):
/// model name, run count, the five token axes, cost, and a cost-share meter
/// against the overall total. Empty input shows a muted line.
class ByModelSection extends ConsumerWidget {
  /// Creates a [ByModelSection].
  const ByModelSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final agg = ref.watch(insightsTokenAggregationProvider);
    final models = agg.byModel;

    return ObsSection(
      title: l10n.obsByModelTitle,
      subtitle: l10n.obsByModelSubtitle,
      icon: AppIcons.network,
      child: models.isEmpty
          ? Text(
              l10n.obsNoModelUsage,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < models.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  _ByModelRow(
                    usage: models[i],
                    totalCostCents: agg.totals.costCents,
                  ),
                ],
              ],
            ),
    );
  }
}

/// A single model's usage: name + run count header, token-axis rows, and a
/// cost-share meter against the overall total.
class _ByModelRow extends StatelessWidget {
  const _ByModelRow({required this.usage, required this.totalCostCents});

  final ModelUsage usage;
  final int totalCostCents;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final tokens = usage.tokens;
    final costShare = totalCostCents > 0
        ? tokens.costCents / totalCostCents
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: t.bgTertiary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: t.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.bot, size: 14, color: t.fgSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  usage.model,
                  style: CcTypography.body.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                l10n.obsRunCount(usage.runs),
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ObsKeyValue(label: l10n.obsAxisInput, value: fmtTokens(tokens.input)),
          ObsKeyValue(
            label: l10n.obsAxisOutput,
            value: fmtTokens(tokens.output),
          ),
          ObsKeyValue(
            label: l10n.obsAxisReasoning,
            value: fmtTokens(tokens.reasoning),
          ),
          ObsKeyValue(
            label: l10n.obsAxisCacheRead,
            value: fmtTokens(tokens.cacheRead),
          ),
          ObsKeyValue(
            label: l10n.obsAxisCacheWrite,
            value: fmtTokens(tokens.cacheWrite),
          ),
          ObsKeyValue(
            label: l10n.obsColCost,
            value: fmtCents(tokens.costCents),
            valueTone: ObsTone.brand,
          ),
          const SizedBox(height: AppSpacing.sm),
          ObsBar(
            label: l10n.obsCostShare,
            fraction: costShare,
            valueLabel: fmtPercent(costShare),
          ),
        ],
      ),
    );
  }
}

/// "Per-run" — the median per-run token count alongside the aggregated run
/// count.
class PerRunSection extends ConsumerWidget {
  /// Creates a [PerRunSection].
  const PerRunSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final agg = ref.watch(insightsTokenAggregationProvider);

    return ObsSection(
      title: l10n.obsPerRunTitle,
      subtitle: l10n.obsPerRunSubtitle,
      icon: AppIcons.gauge,
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        children: [
          ObsStatTile(
            label: l10n.obsMedianRunTokens,
            value: fmtTokens(agg.medianRunTokens.round()),
            sub: l10n.obsMedianRunTokensSub,
            icon: AppIcons.zap,
          ),
          ObsStatTile(
            label: l10n.obsColRuns,
            value: fmtCount(agg.runCount),
            sub: l10n.obsRunsInWorkspace,
            icon: AppIcons.bot,
          ),
        ],
      ),
    );
  }
}
