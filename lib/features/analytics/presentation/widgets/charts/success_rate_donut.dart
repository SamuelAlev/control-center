import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Success rate donut.
class SuccessRateDonut extends StatelessWidget {
  /// Creates a new [SuccessRateDonut].
  const SuccessRateDonut({
    super.key,
    required this.successCount,
    required this.errorCount,
  });

  /// Number of successful runs.
  final int successCount;
  /// Number of errored runs.
  final int errorCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final total = successCount + errorCount;
    final rate = total > 0 ? (successCount / total * 100).round() : 0;

    return SizedBox(
      height: 180,
      width: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: successCount.toDouble(),
                  color: tokens?.fgSuccessPrimary ?? theme.colorScheme.primary,
                  radius: 30,
                  title: '',
                ),
                PieChartSectionData(
                  value: errorCount.toDouble(),
                  color: tokens?.fgErrorSecondary ?? theme.colorScheme.error,
                  radius: 30,
                  title: '',
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 50,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$rate%', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(l10n.successLabelShort, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
