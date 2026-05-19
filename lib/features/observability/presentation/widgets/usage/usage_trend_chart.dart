import 'dart:math' as math;

import 'package:cc_domain/features/observability/domain/usage_stats.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// A y-axis rounded to human steps: the gridline spacing and the ceiling the
/// plot is scaled to.
///
/// Without this the axis ends exactly at the data peak and fl_chart labels
/// both that peak and its own interval steps, so a run of 25.5M draws "25.5M"
/// on top of "25M". Snapping the ceiling UP to a whole step means every label
/// is a round number and the top one is the ceiling itself.
@immutable
class _TokenAxis {
  const _TokenAxis({required this.step, required this.max});

  /// Builds an axis covering zero through `peak`. A peak of zero still yields
  /// a usable axis, so an idle window renders a flat baseline rather than
  /// collapsing to nothing.
  factory _TokenAxis.forPeak(int peak) {
    if (peak <= 0) {
      return const _TokenAxis(step: 1, max: 1);
    }
    final rough = peak / _targetLines;
    final magnitude = math
        .pow(10, (math.log(rough) / math.ln10).floor())
        .toDouble();
    final normalized = rough / magnitude;
    final double multiple;
    if (normalized <= 1) {
      multiple = 1;
    } else if (normalized <= 2) {
      multiple = 2;
    } else if (normalized <= 5) {
      multiple = 5;
    } else {
      multiple = 10;
    }
    // Never step below a whole token: a fractional step would round two
    // adjacent labels to the same integer and print "0" twice.
    final step = math.max(1.0, multiple * magnitude);
    return _TokenAxis(step: step, max: (peak / step).ceil() * step);
  }

  /// Roughly this many gridlines, before rounding to a nice step.
  static const int _targetLines = 4;

  /// Spacing between gridlines, a 1/2/5×10ⁿ value.
  final double step;

  /// The plot ceiling: the data peak rounded up to a whole [step].
  final double max;
}

/// The daily token trend: one line per model over the selected window, drawn
/// from dense zero-filled series so a quiet day reads as a dip rather than as
/// a straight segment between the days on either side of it.
///
/// The lines are splined with overshoot prevention on, so bursty token usage
/// reads as rounded peaks over a flat baseline instead of as a saw blade —
/// and never dips below zero on the way down from a spike.
///
/// Series colors come from the design system's categorical ramp and are always
/// named in the legend.
class UsageTrendChart extends StatelessWidget {
  /// Creates a [UsageTrendChart].
  const UsageTrendChart({super.key, required this.series, this.height = 220});

  /// The per-model series; every entry shares one dense day axis.
  final List<UsageTrendSeries> series;

  /// Plot height (the legend adds to this).
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    final plotted = [
      for (final s in series)
        if (s.points.isNotEmpty) s,
    ];
    if (plotted.isEmpty) {
      return CcEmptyState(
        icon: AppIcons.chartColumn,
        message: l10n.obsUsageNoActivity,
      );
    }

    final ramp = t.chartCategorical;
    Color colorAt(int i) => ramp[i % ramp.length];
    final days = plotted.first.points;
    final labelFormat = DateFormat.MMMd(locale);
    final labels = [for (final day in days) labelFormat.format(day.day)];

    var peak = 0;
    for (final entry in plotted) {
      for (final point in entry.points) {
        if (point.tokens > peak) {
          peak = point.tokens;
        }
      }
    }
    final axis = _TokenAxis.forPeak(peak);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: _summary(l10n, plotted, labels),
          excludeSemantics: true,
          child: SizedBox(
            height: height,
            child: LineChart(
              duration: Duration.zero,
              LineChartData(
                minY: 0,
                maxY: axis.max,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: axis.step,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: t.borderSecondary, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: _titles(labels, axis, t),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => t.bgPrimary,
                    tooltipBorder: BorderSide(color: t.borderPrimary),
                    tooltipBorderRadius: AppRadii.brMd,
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          '${_modelLabel(l10n, plotted[spot.barIndex].model)}\n'
                          '${labels[spot.x.toInt()]} · '
                          '${fmtTokens(spot.y.round())}',
                          CcTypography.caption.copyWith(color: t.textPrimary),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  for (var i = 0; i < plotted.length; i++)
                    LineChartBarData(
                      isCurved: true,
                      // Without this a spike to a daily peak and back swings
                      // the spline well below the baseline on the way down —
                      // a visible dip into negative tokens. It flattens the
                      // vertical tangent at peaks and along quiet runs, which
                      // is also what keeps a zero stretch reading as a
                      // straight baseline rather than a gentle wave.
                      preventCurveOverShooting: true,
                      isStrokeJoinRound: true,
                      isStrokeCapRound: true,
                      color: colorAt(i),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      spots: [
                        for (var d = 0; d < plotted[i].points.length; d++)
                          FlSpot(
                            d.toDouble(),
                            plotted[i].points[d].tokens.toDouble(),
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
            for (var i = 0; i < plotted.length; i++)
              ObsLegendEntry(
                label: _modelLabel(l10n, plotted[i].model),
                color: colorAt(i),
                detail: fmtTokens(
                  plotted[i].points.fold(0, (sum, p) => sum + p.tokens),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// The display name for a series, translating the overflow bucket.
  static String _modelLabel(AppLocalizations l10n, String model) =>
      model == UsageStatsCalculator.otherModels
      ? l10n.obsUsageOtherModels
      : model;

  String _summary(
    AppLocalizations l10n,
    List<UsageTrendSeries> plotted,
    List<String> labels,
  ) {
    final parts = <String>[l10n.obsUsageTrendTitle];
    for (final s in plotted) {
      final total = s.points.fold(0, (sum, p) => sum + p.tokens);
      parts.add('${_modelLabel(l10n, s.model)}: ${fmtTokens(total)}');
    }
    if (labels.isNotEmpty) {
      parts.add('${labels.first} – ${labels.last}');
    }
    return parts.join('. ');
  }

  FlTitlesData _titles(
    List<String> labels,
    _TokenAxis axis,
    DesignSystemTokens t,
  ) {
    final style = CcTypography.caption.copyWith(
      color: t.textTertiary,
      fontSize: 10,
    );
    // At most ~6 x labels, whatever the window length.
    final stride = (labels.length / 6).ceil().clamp(1, 1000);
    return FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          // Pinned to the same round step as the gridlines. Left to itself
          // fl_chart also emits a title at the DATA max, which lands a
          // hair above the top gridline — "25.5M" printed over "25M".
          interval: axis.step,
          getTitlesWidget: (value, meta) {
            // The axis maximum is drawn by the grid as a bare line; labelling
            // it too would collide with nothing here, but a value that is not
            // an exact step multiple still slips through on some ranges.
            if (value % axis.step != 0) {
              return const SizedBox.shrink();
            }
            return Text(
              fmtTokens(value.round()),
              style: style,
              textAlign: TextAlign.right,
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (value, _) {
            final i = value.round();
            if (i < 0 || i >= labels.length || i % stride != 0) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                labels[i],
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
}
