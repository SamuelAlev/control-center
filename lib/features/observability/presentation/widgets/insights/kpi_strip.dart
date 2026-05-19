import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/insights_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Insights KPI strip: seven headline figures over the filtered runs, each
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

    /// The delta line for one metric, or a no-op when deltas are hidden.
    ({String? text, ObsTone tone}) delta(
      num current,
      num prev, {
      ObsTone increasedTone = ObsTone.neutral,
    }) {
      if (!showDeltas) {
        return (text: null, tone: ObsTone.neutral);
      }
      return _delta(l10n, current, prev, increasedTone: increasedTone);
    }

    final runs = delta(metrics.totalRuns, previous.totalRuns);
    final cost = delta(metrics.totalCostCents, previous.totalCostCents);
    final errorRate = delta(
      metrics.errorRate,
      previous.errorRate,
      increasedTone: ObsTone.danger,
    );
    final cacheRate = delta(
      metrics.cacheRate,
      previous.cacheRate,
      increasedTone: ObsTone.success,
    );
    final throughput = delta(metrics.tokensPerSecond, previous.tokensPerSecond);
    final latency = delta(metrics.avgDurationMs, previous.avgDurationMs);
    final ttft = delta(metrics.avgTtftMs, previous.avgTtftMs);

    return ObsStatStrip(
      entries: [
        ObsStatStripEntry(
          label: l10n.obsKpiTotalRuns,
          value: fmtCount(metrics.totalRuns),
          detail: runs.text,
          detailTone: runs.tone,
        ),
        ObsStatStripEntry(
          label: l10n.obsKpiTotalCost,
          value: fmtCents(metrics.totalCostCents),
          tone: ObsTone.brand,
          detail: cost.text,
          detailTone: cost.tone,
        ),
        ObsStatStripEntry(
          label: l10n.obsKpiErrorRate,
          value: fmtPercent(metrics.errorRate),
          tone: metrics.errorRate > 0.1 ? ObsTone.danger : ObsTone.neutral,
          detail: errorRate.text,
          detailTone: errorRate.tone,
        ),
        ObsStatStripEntry(
          label: l10n.obsKpiCacheRate,
          value: fmtPercent(metrics.cacheRate),
          tone: ObsTone.success,
          detail: cacheRate.text,
          detailTone: cacheRate.tone,
        ),
        ObsStatStripEntry(
          label: l10n.obsKpiTokensPerSec,
          value: metrics.tokensPerSecond.toStringAsFixed(1),
          detail: throughput.text,
          detailTone: throughput.tone,
        ),
        ObsStatStripEntry(
          label: l10n.obsKpiAvgLatency,
          value: fmtDuration(metrics.avgDurationMs.round()),
          detail: latency.text,
          detailTone: latency.tone,
        ),
        ObsStatStripEntry(
          label: l10n.obsKpiTtft,
          value: fmtDuration(metrics.avgTtftMs.round()),
          detail: ttft.text,
          detailTone: ttft.tone,
        ),
      ],
    );
  }

  /// The relative change between periods, formatted `+12%` / `−4%`; a null
  /// text when the previous-period denominator is zero (no meaningful
  /// baseline).
  static ({String? text, ObsTone tone}) _delta(
    AppLocalizations l10n,
    num current,
    num previous, {
    ObsTone increasedTone = ObsTone.neutral,
  }) {
    if (previous == 0) {
      return (text: null, tone: ObsTone.neutral);
    }
    final pct = (((current - previous) / previous) * 100).round();
    return (
      text: l10n.obsDeltaVsPrevious('${pct < 0 ? '−' : '+'}${pct.abs()}%'),
      tone: pct > 0 ? increasedTone : ObsTone.neutral,
    );
  }
}
