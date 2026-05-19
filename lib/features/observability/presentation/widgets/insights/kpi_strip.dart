import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/insights_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Insights KPI strip: seven headline tiles over the filtered runs, each
/// carrying a vs-previous-period delta when one can be computed (hidden for
/// "All time" and for zero-denominator previous windows).
class InsightsKpiStrip extends ConsumerWidget {
  /// Creates an [InsightsKpiStrip].
  const InsightsKpiStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final metrics = ref.watch(insightsMetricsProvider);
    final previous = ref.watch(insightsPreviousMetricsProvider);
    final range = ref.watch(obsTimeRangeProvider);
    final showDeltas = range != ObsTimeRange.all;

    return Wrap(
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.lg,
      children: [
        _KpiTile(
          label: l10n.obsKpiTotalRuns,
          value: fmtCount(metrics.totalRuns),
          icon: AppIcons.gauge,
          delta: showDeltas
              ? _delta(l10n, metrics.totalRuns, previous.totalRuns)
              : null,
        ),
        _KpiTile(
          label: l10n.obsKpiTotalCost,
          value: fmtCents(metrics.totalCostCents),
          tone: ObsTone.brand,
          icon: AppIcons.zap,
          delta: showDeltas
              ? _delta(l10n, metrics.totalCostCents, previous.totalCostCents)
              : null,
        ),
        _KpiTile(
          label: l10n.obsKpiErrorRate,
          value: fmtPercent(metrics.errorRate),
          tone: metrics.errorRate > 0.1 ? ObsTone.danger : ObsTone.neutral,
          icon: AppIcons.triangleAlert,
          delta: showDeltas
              ? _delta(
                  l10n,
                  metrics.errorRate,
                  previous.errorRate,
                  increasedTone: ObsTone.danger,
                )
              : null,
        ),
        _KpiTile(
          label: l10n.obsKpiCacheRate,
          value: fmtPercent(metrics.cacheRate),
          tone: ObsTone.success,
          icon: AppIcons.brain,
          delta: showDeltas
              ? _delta(
                  l10n,
                  metrics.cacheRate,
                  previous.cacheRate,
                  increasedTone: ObsTone.success,
                )
              : null,
        ),
        _KpiTile(
          label: l10n.obsKpiTokensPerSec,
          value: metrics.tokensPerSecond.toStringAsFixed(1),
          icon: AppIcons.activity,
          delta: showDeltas
              ? _delta(l10n, metrics.tokensPerSecond, previous.tokensPerSecond)
              : null,
        ),
        _KpiTile(
          label: l10n.obsKpiAvgLatency,
          value: fmtDuration(metrics.avgDurationMs.round()),
          icon: AppIcons.clock,
          delta: showDeltas
              ? _delta(l10n, metrics.avgDurationMs, previous.avgDurationMs)
              : null,
        ),
        _KpiTile(
          label: l10n.obsKpiTtft,
          value: fmtDuration(metrics.avgTtftMs.round()),
          icon: AppIcons.clock,
          delta: showDeltas
              ? _delta(l10n, metrics.avgTtftMs, previous.avgTtftMs)
              : null,
        ),
      ],
    );
  }

  /// The relative change between periods, formatted `+12%` / `−4%`; null when
  /// the previous-period denominator is zero (no meaningful baseline).
  static ({String text, ObsTone tone})? _delta(
    AppLocalizations l10n,
    num current,
    num previous, {
    ObsTone increasedTone = ObsTone.neutral,
  }) {
    if (previous == 0) {
      return null;
    }
    final pct = (((current - previous) / previous) * 100).round();
    final text = l10n.obsDeltaVsPrevious('${pct < 0 ? '−' : '+'}${pct.abs()}%');
    final tone = pct > 0 ? increasedTone : ObsTone.neutral;
    return (text: text, tone: tone);
  }
}

/// One headline tile plus its optional colored delta line.
class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    this.tone = ObsTone.neutral,
    this.icon,
    this.delta,
  });

  final String label;
  final String value;
  final ObsTone tone;
  final IconData? icon;
  final ({String text, ObsTone tone})? delta;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ObsStatTile(label: label, value: value, tone: tone, icon: icon),
        if (delta != null)
          Text(
            delta!.text,
            style: CcTypography.caption.copyWith(
              color: delta!.tone == ObsTone.neutral
                  ? t.textQuaternary
                  : obsToneColor(t, delta!.tone),
            ),
          ),
      ],
    );
  }
}
