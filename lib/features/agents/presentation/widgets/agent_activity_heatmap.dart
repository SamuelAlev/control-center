import 'package:cc_domain/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/charts/activity_heatmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A 6-month activity heatmap for a single agent, fed by analytics daily
/// stats. Shared between the agent hover card and the roster detail panel so
/// agent "activity over time" reads identically in both places.
class AgentActivityHeatmap extends ConsumerWidget {
  /// Creates an [AgentActivityHeatmap].
  const AgentActivityHeatmap({super.key, required this.agentId, this.cellSize = 10});

  /// The agent whose activity to show.
  final String agentId;

  /// Size of each day cell in logical pixels.
  final double cellSize;

  static const _weeks = 26;

  static const _paletteLight = [
    DesignSystemPalette.gray100,
    DesignSystemPalette.brand100,
    DesignSystemPalette.brand300,
    DesignSystemPalette.brand500,
    DesignSystemPalette.brand600,
  ];

  static const _paletteDark = [
    DesignSystemPalette.gray800,
    DesignSystemPalette.brand950,
    DesignSystemPalette.brand700,
    DesignSystemPalette.brand500,
    DesignSystemPalette.brand400,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: _weeks * 7));
    final stats = ref
            .watch(
              dailyStatsByDateRangeProvider((
                agentId: agentId,
                start: start,
                end: today,
              )),
            )
            .asData
            ?.value ??
        const <AgentDailyStats>[];

    final data = <DateTime, ActivityCell>{};
    var totalRuns = 0;
    for (final s in stats) {
      final key = DateTime(s.date.year, s.date.month, s.date.day);
      data[key] = ActivityCell(
        runsCompleted: s.runsCompleted,
        runsErrored: s.runsErrored,
        prsCreated: s.prsCreated,
        prsMerged: s.prsMerged,
        reviewsCompleted: s.reviewsCompleted,
        blockingComments: s.blockingComments,
      );
      totalRuns += s.runsCompleted + s.runsErrored;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ActivityHeatmap(
            data: data,
            weeks: _weeks,
            cellSize: cellSize,
            cellGap: 2,
            cellRadius: 2,
            showLegend: false,
            palette: isDark ? _paletteDark : _paletteLight,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.runsInLastSixMonths(_formatNumber(totalRuns)),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: tokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k < 10 ? 1 : 0)}k';
    }
    return n.toString();
  }
}
