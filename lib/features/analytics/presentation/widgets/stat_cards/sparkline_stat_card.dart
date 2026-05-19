import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Sparkline stat card.
class SparklineStatCard extends StatelessWidget {
  /// Creates a new [SparklineStatCard].
  const SparklineStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.spots,
    this.prefix,
    this.suffix,
    this.color,
    this.onTap,
  });

  /// Card title describing the stat.
  final String title;
  /// Current value displayed prominently.
  final String value;
  /// Sparkline data points.
  final List<double> spots;
  /// Optional widget shown before the title (e.g., an icon).
  final Widget? prefix;
  /// Optional suffix text shown after the value.
  final String? suffix;
  /// Custom color for the sparkline and value.
  final Color? color;
  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (prefix != null) ...[prefix!, const SizedBox(width: 6)],
                  Expanded(child: Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: c)),
                  if (suffix != null) ...[
                    const SizedBox(width: 2),
                    Text(suffix!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 24,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        color: c,
                        barWidth: 1.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: c.withValues(alpha: 0.1)),
                      ),
                    ],
                    titlesData: const FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
