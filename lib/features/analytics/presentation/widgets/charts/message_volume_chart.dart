import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Message volume chart.
class MessageVolumeChart extends StatelessWidget {
  /// Creates a new [MessageVolumeChart].
  const MessageVolumeChart({super.key, required this.data});

  /// Volume points to render.
  final List<VolumePoint> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: data.map((d) => FlSpot(d.day.toDouble(), d.count.toDouble())).toList(),
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              interval: (data.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= data.length) {
                  return const SizedBox.shrink();
                }
                return Text(data[i].label, style: theme.textTheme.bodySmall);
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

/// Volume point.
class VolumePoint {
  /// Creates a new [VolumePoint].
  const VolumePoint({required this.day, required this.label, required this.count});
  /// Day index.
  final int day;
  /// Display label for the point.
  final String label;
  /// Message count for the day.
  final int count;
}
