import 'package:cc_domain/features/observability/domain/observability_metrics.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/insights_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';

/// The Insights activity chart: one stacked rod per bucket — successful runs
/// in [ObsTone.neutral] with errors stacked on top in [ObsTone.danger] — so
/// volume and failure share one axis. Legend always rendered (never
/// status-by-color-alone).
class ObsActivityChart extends StatelessWidget {
  /// Creates an [ObsActivityChart].
  const ObsActivityChart({
    super.key,
    required this.buckets,
    required this.kind,
    this.height = 180,
  });

  /// The bucketed series, ascending by [TimeBucket.bucketStart].
  final List<TimeBucket> buckets;

  /// The bucket granularity (drives the x-axis labels).
  final ObsBucketKind kind;

  /// Plot height (legend adds to this).
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final runsColor = obsToneColor(t, ObsTone.neutral);
    final errorsColor = obsToneColor(t, ObsTone.danger);
    final labels = _bucketLabels(buckets, kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: _activitySummary(l10n, labels),
          child: SizedBox(
            height: height,
            child: BarChart(
              duration: Duration.zero,
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: _grid(t),
                borderData: FlBorderData(show: false),
                titlesData: _titles(labels, t),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => t.bgPrimary,
                    tooltipBorder: BorderSide(color: t.borderPrimary),
                    tooltipBorderRadius: AppRadii.brMd,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final bucket = buckets[groupIndex];
                      return BarTooltipItem(
                        '${labels[groupIndex]}\n'
                        '${fmtCount(bucket.runs)} ${l10n.obsLegendRuns} · '
                        '${fmtCount(bucket.errors)} ${l10n.obsLegendErrors}',
                        CcTypography.caption.copyWith(color: t.textPrimary),
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < buckets.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: buckets[i].runs.toDouble(),
                          width: _rodWidth(buckets.length),
                          borderRadius: BorderRadius.zero,
                          rodStackItems: [
                            BarChartRodStackItem(
                              0,
                              (buckets[i].runs - buckets[i].errors).toDouble(),
                              runsColor,
                            ),
                            BarChartRodStackItem(
                              (buckets[i].runs - buckets[i].errors).toDouble(),
                              buckets[i].runs.toDouble(),
                              errorsColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ObsChartLegend(
          entries: [
            ObsLegendEntry(label: l10n.obsLegendRuns, color: runsColor),
            ObsLegendEntry(label: l10n.obsLegendErrors, color: errorsColor),
          ],
        ),
      ],
    );
  }

  String _activitySummary(AppLocalizations l10n, List<String> labels) {
    final parts = <String>['${l10n.obsChartActivity} chart'];
    for (var i = 0; i < buckets.length; i++) {
      parts.add(
        '${labels[i]}: ${buckets[i].runs} ${l10n.obsLegendRuns}, '
        '${buckets[i].errors} ${l10n.obsLegendErrors}',
      );
    }
    return parts.join('. ');
  }
}

/// The Insights cost chart: a single flat line of per-bucket spend in
/// [ObsTone.brand] with an accent-soft fill — the screen's one orange element
/// besides the selected-tab underline.
class ObsCostChart extends StatelessWidget {
  /// Creates an [ObsCostChart].
  const ObsCostChart({
    super.key,
    required this.buckets,
    required this.kind,
    this.height = 180,
  });

  /// The bucketed series, ascending by [TimeBucket.bucketStart].
  final List<TimeBucket> buckets;

  /// The bucket granularity (drives the x-axis labels).
  final ObsBucketKind kind;

  /// Plot height (legend adds to this).
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final lineColor = obsToneColor(t, ObsTone.brand);
    final labels = _bucketLabels(buckets, kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: _costSummary(l10n, labels),
          child: SizedBox(
            height: height,
            child: LineChart(
              duration: Duration.zero,
              LineChartData(
                gridData: _grid(t),
                borderData: FlBorderData(show: false),
                titlesData: _titles(labels, t),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => t.bgPrimary,
                    tooltipBorder: BorderSide(color: t.borderPrimary),
                    tooltipBorderRadius: AppRadii.brMd,
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          '${labels[spot.x.toInt()]}\n'
                          '${fmtCents((spot.y * 100).round())}',
                          CcTypography.caption.copyWith(color: t.textPrimary),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: false,
                    color: lineColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: t.accentSoft),
                    spots: [
                      for (var i = 0; i < buckets.length; i++)
                        FlSpot(i.toDouble(), buckets[i].costCents / 100.0),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ObsChartLegend(
          entries: [ObsLegendEntry(label: l10n.obsColCost, color: lineColor)],
        ),
      ],
    );
  }

  String _costSummary(AppLocalizations l10n, List<String> labels) {
    final parts = <String>['${l10n.obsChartCost} chart'];
    for (var i = 0; i < buckets.length; i++) {
      parts.add('${labels[i]}: ${fmtCents(buckets[i].costCents)}');
    }
    return parts.join('. ');
  }
}

/// The x-axis label per bucket, driven by granularity.
List<String> _bucketLabels(List<TimeBucket> buckets, ObsBucketKind kind) => [
  for (final bucket in buckets)
    switch (kind) {
      ObsBucketKind.hour => fmtHourBucket(bucket.bucketStart),
      ObsBucketKind.day => fmtDayBucket(bucket.bucketStart),
      ObsBucketKind.week => fmtWeekBucket(bucket.bucketStart),
    },
];

double _rodWidth(int bucketCount) {
  if (bucketCount > 40) {
    return 6;
  }
  if (bucketCount > 20) {
    return 10;
  }
  return 14;
}

FlGridData _grid(DesignSystemTokens t) => FlGridData(
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) =>
      FlLine(color: t.borderSecondary, strokeWidth: 1),
);

FlTitlesData _titles(List<String> categories, DesignSystemTokens t) {
  final style = CcTypography.caption.copyWith(
    color: t.textTertiary,
    fontSize: 10,
  );
  // At most ~6 x labels, whatever the bucket count.
  final stride = (categories.length / 6).ceil().clamp(1, 1000);
  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        getTitlesWidget: (value, _) => Text(
          fmtCount(value.round()),
          style: style,
          textAlign: TextAlign.right,
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        // One tick per bucket. Left to fl_chart the line chart picks a
        // pixel-derived interval and hands back FRACTIONAL x values, which
        // `value.round()` then collapses into the same label repeated across
        // the axis.
        interval: 1,
        getTitlesWidget: (value, _) {
          final i = value.round();
          if (i < 0 || i >= categories.length || i % stride != 0) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              categories[i],
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    ),
  );
}
