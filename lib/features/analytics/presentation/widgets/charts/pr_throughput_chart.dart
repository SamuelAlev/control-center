import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Pr throughput chart.
class PrThroughputChart extends StatelessWidget {
  /// Creates a new [PrThroughputChart].
  const PrThroughputChart({
    super.key,
    required this.spots,
  });

  /// Weekly throughput data points.
  final List<ThroughputSpot> spots;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final createdSpots = spots.map((s) => FlSpot(s.week.toDouble(), s.created.toDouble())).toList();
    final mergedSpots = spots.map((s) => FlSpot(s.week.toDouble(), s.merged.toDouble())).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: createdSpots,
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 2,
              dotData: const FlDotData(show: true),
            ),
            LineChartBarData(
              spots: mergedSpots,
              isCurved: true,
              color: tokens?.fgSuccessPrimary ?? theme.colorScheme.primary,
              barWidth: 2,
              dotData: const FlDotData(show: true),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= spots.length) {
                  return const SizedBox.shrink();
                }
                return Text(spots[value.toInt()].label, style: theme.textTheme.bodySmall);
              },
              reservedSize: 20,
            )),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

/// Throughput spot.
class ThroughputSpot {
  /// Creates a new [ThroughputSpot].
  const ThroughputSpot({required this.week, required this.label, required this.created, required this.merged});
  /// Week index.
  final int week;
  /// Display label for the week.
  final String label;
  /// PRs created during the week.
  final int created;
  /// PRs merged during the week.
  final int merged;
}
