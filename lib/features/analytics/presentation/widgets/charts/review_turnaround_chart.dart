import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Review turnaround chart.
class ReviewTurnaroundChart extends StatelessWidget {
  /// Creates a new [ReviewTurnaroundChart].
  const ReviewTurnaroundChart({super.key, required this.data});

  /// Turnaround data points to render.
  final List<TurnaroundData> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.fold(0.0, (max, e) => e.hours > max ? e.hours : max) + 2,
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.hours,
                  color: theme.colorScheme.tertiary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length) {
                  return const SizedBox.shrink();
                }
                return Text(data[value.toInt()].label, style: theme.textTheme.bodySmall);
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

/// Turnaround data.
class TurnaroundData {
  /// Creates a new [TurnaroundData].
  const TurnaroundData({required this.label, required this.hours});
  /// Display label for the data point.
  final String label;
  /// Average turnaround time in hours.
  final double hours;
}
