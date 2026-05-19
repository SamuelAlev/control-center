import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Agent activity chart.
class AgentActivityChart extends StatelessWidget {
  /// Creates a new [AgentActivityChart].
  const AgentActivityChart({
    super.key,
    required this.data,
  });

  /// Daily activity bars to render.
  final List<ActivityBarData> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.fold(0.0, (max, e) => e.runs > max ? e.runs.toDouble() : max) + 2,
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.runs.toDouble(),
                  color: theme.colorScheme.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data[value.toInt()].label,
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
                reservedSize: 20,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

/// Activity bar data.
class ActivityBarData {
  /// Creates a new [ActivityBarData].
  const ActivityBarData({required this.label, required this.runs});
  /// Label for the bar (e.g., day abbreviation).
  final String label;
  /// Number of runs represented by the bar.
  final int runs;
}
