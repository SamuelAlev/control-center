import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:control_center/core/theme/app_text_styles.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';

/// Draws an [ArtifactChartBlock] — the app's first generic, data-driven chart.
///
/// Every other chart in the app is a bespoke widget bound to one DTO with
/// `theme.colorScheme.primary` inlined, which cannot distinguish two
/// series. This one takes a spec and produces a chart and takes its series
/// colors from the shared `chartCategorical` ramp.
///
/// Series identity is always carried by a labelled legend as well as by color,
/// so the chart stays readable for a color-blind operator and in a screenshot
/// (never status-by-color-alone).
class ArtifactChart extends StatelessWidget {
  /// Creates an [ArtifactChart].
  const ArtifactChart({super.key, required this.block, this.height = 220});

  /// The chart to draw.
  final ArtifactChartBlock block;

  /// Plot height. The legend and title add to this.
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    final series = block.series.where((s) => s.points.isNotEmpty).toList();
    if (series.isEmpty) {
      return const SizedBox.shrink();
    }
    final ramp = tokens.chartCategorical;
    Color colorAt(int i) => ramp[i % ramp.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.title != null && block.title!.isNotEmpty) ...[
          Text(
            block.title!,
            style: AppTextStyles.labelLarge(
              tokens,
            ).copyWith(color: tokens.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          label: _semanticSummary(),
          child: SizedBox(
            height: height,
            child: switch (block.chartKind) {
              ArtifactChartKind.bar => _bar(series, colorAt, tokens),
              ArtifactChartKind.line => _line(series, colorAt, tokens),
              ArtifactChartKind.pie => _pie(series.first, colorAt, tokens),
            },
          ),
        ),
        const SizedBox(height: 10),
        _Legend(
          entries: block.chartKind == ArtifactChartKind.pie
              // A pie's slices are its categories, so the legend keys the x
              // labels rather than the series names.
              ? [
                  for (var i = 0; i < series.first.points.length; i++)
                    (label: series.first.points[i].x, color: colorAt(i)),
                ]
              : [
                  for (var i = 0; i < series.length; i++)
                    (label: series[i].label, color: colorAt(i)),
                ],
        ),
        if (block.yLabel != null && block.yLabel!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              block.yLabel!,
              style: AppTextStyles.labelSmall(
                tokens,
              ).copyWith(color: tokens.textTertiary),
            ),
          ),
      ],
    );
  }

  /// A screen-reader alternative: charts are pictures, so the numbers have to be
  /// available as text too.
  String _semanticSummary() {
    final parts = <String>[
      '${block.chartKind.name} chart',
      if (block.title != null && block.title!.isNotEmpty) block.title!,
    ];
    for (final s in block.series) {
      final points = s.points.map((p) => '${p.x}: ${_fmt(p.y)}').join(', ');
      parts.add('${s.label} — $points');
    }
    return parts.join('. ');
  }

  /// The union of x values across series, in first-seen order, so grouped bars
  /// and multi-series lines share one axis.
  List<String> _categories(List<ArtifactSeries> series) {
    final seen = <String>[];
    for (final s in series) {
      for (final p in s.points) {
        if (!seen.contains(p.x)) {
          seen.add(p.x);
        }
      }
    }
    return seen;
  }

  Widget _bar(
    List<ArtifactSeries> series,
    Color Function(int) colorAt,
    DesignSystemTokens tokens,
  ) {
    final categories = _categories(series);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: _grid(tokens),
        borderData: FlBorderData(show: false),
        titlesData: _titles(categories, tokens),
        barGroups: [
          for (var c = 0; c < categories.length; c++)
            BarChartGroupData(
              x: c,
              barRods: [
                for (var i = 0; i < series.length; i++)
                  BarChartRodData(
                    toY: _valueFor(series[i], categories[c]),
                    color: colorAt(i),
                    width: series.length > 2 ? 8 : 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _line(
    List<ArtifactSeries> series,
    Color Function(int) colorAt,
    DesignSystemTokens tokens,
  ) {
    final categories = _categories(series);
    return LineChart(
      LineChartData(
        gridData: _grid(tokens),
        borderData: FlBorderData(show: false),
        titlesData: _titles(categories, tokens),
        lineBarsData: [
          for (var i = 0; i < series.length; i++)
            LineChartBarData(
              isCurved: false,
              color: colorAt(i),
              barWidth: 2,
              dotData: FlDotData(show: categories.length <= 20),
              spots: [
                for (var c = 0; c < categories.length; c++)
                  if (_hasValue(series[i], categories[c]))
                    FlSpot(c.toDouble(), _valueFor(series[i], categories[c])),
              ],
            ),
        ],
      ),
    );
  }

  Widget _pie(
    ArtifactSeries series,
    Color Function(int) colorAt,
    DesignSystemTokens tokens,
  ) {
    final total = series.points.fold<double>(0, (a, p) => a + p.y.abs());
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 36,
        sections: [
          for (var i = 0; i < series.points.length; i++)
            PieChartSectionData(
              value: series.points[i].y.abs(),
              color: colorAt(i),
              radius: 52,
              // A slice label only fits when the slice is big enough; below
              // that the legend carries it.
              showTitle: total > 0 && series.points[i].y.abs() / total > 0.08,
              title: total > 0
                  ? '${((series.points[i].y.abs() / total) * 100).round()}%'
                  : '',
              titleStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: tokens.bgPrimary,
              ),
            ),
        ],
      ),
    );
  }

  FlGridData _grid(DesignSystemTokens tokens) => FlGridData(
    drawVerticalLine: false,
    getDrawingHorizontalLine: (_) =>
        FlLine(color: tokens.borderSecondary, strokeWidth: 1),
  );

  FlTitlesData _titles(List<String> categories, DesignSystemTokens tokens) {
    final style = AppTextStyles.labelSmall(
      tokens,
    ).copyWith(color: tokens.textTertiary, fontSize: 10);
    // With many categories, printing every label turns the axis into mush;
    // thin them to a readable count instead.
    final stride = (categories.length / 8).ceil().clamp(1, 1000);
    return FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, _) =>
              Text(_fmt(value), style: style, textAlign: TextAlign.right),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (value, _) {
            final i = value.round();
            if (i < 0 || i >= categories.length || i % stride != 0) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
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

  bool _hasValue(ArtifactSeries s, String x) => s.points.any((p) => p.x == x);

  double _valueFor(ArtifactSeries s, String x) {
    for (final p in s.points) {
      if (p.x == x) {
        return p.y;
      }
    }
    return 0;
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e6) {
      return v.round().toString();
    }
    return v.toStringAsFixed(1);
  }
}

/// Series/category key. Always rendered — the chart never relies on color alone.
class _Legend extends StatelessWidget {
  const _Legend({required this.entries});

  final List<({String label, Color color})> entries;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final e in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: e.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                e.label,
                style: AppTextStyles.labelSmall(
                  tokens,
                ).copyWith(color: tokens.textSecondary),
              ),
            ],
          ),
      ],
    );
  }
}
