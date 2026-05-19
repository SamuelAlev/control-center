import 'package:cc_domain/features/observability/domain/usage_stats.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';

/// The model-usage split: a donut of tokens per model with the window total in
/// the hole, beside a legend naming every slice with its figure and share.
///
/// The legend carries the numbers, so the split survives grayscale and
/// color-blind viewing — the ring is the summary, not the source.
class UsageModelDonut extends StatelessWidget {
  /// Creates a [UsageModelDonut].
  const UsageModelDonut({super.key, required this.slices});

  /// The per-model slices, already sorted by tokens descending.
  final List<UsageModelSlice> slices;

  /// Below this width the legend moves under the ring.
  static const double _stackBelow = 560;

  /// Diameter of the donut, including its hole.
  static const double _diameter = 200;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    if (slices.isEmpty) {
      return CcEmptyState(
        icon: AppIcons.chartColumn,
        message: l10n.obsUsageNoActivity,
      );
    }

    final ramp = t.chartCategorical;
    Color colorAt(int i) => ramp[i % ramp.length];
    var total = 0;
    for (final slice in slices) {
      total += slice.tokens;
    }

    final ring = SizedBox(
      width: _diameter,
      height: _diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            duration: Duration.zero,
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: _diameter / 2 - 28,
              startDegreeOffset: -90,
              sections: [
                for (var i = 0; i < slices.length; i++)
                  PieChartSectionData(
                    value: slices[i].tokens.toDouble(),
                    color: colorAt(i),
                    radius: 28,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fmtTokens(total),
                style: CcTypography.title.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.obsUsageTokensLabel,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );

    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < slices.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _SliceRow(slice: slices[i], color: colorAt(i)),
        ],
      ],
    );

    return Semantics(
      label: _summary(l10n, total),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _stackBelow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(child: ring),
                const SizedBox(height: AppSpacing.lg),
                legend,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ring,
              const SizedBox(width: AppSpacing.xl),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }

  String _summary(AppLocalizations l10n, int total) {
    final parts = <String>[
      '${l10n.obsUsageModelUsage}: ${fmtTokens(total)} ${l10n.obsUsageTokensLabel}',
    ];
    for (final slice in slices) {
      parts.add(
        '${_label(l10n, slice.model)}: ${fmtTokens(slice.tokens)}, '
        '${fmtPercent(slice.share)}',
      );
    }
    return parts.join('. ');
  }

  static String _label(AppLocalizations l10n, String model) =>
      model == UsageStatsCalculator.otherModels
      ? l10n.obsUsageOtherModels
      : model;
}

/// One legend row: swatch, model name, token figure and share.
class _SliceRow extends StatelessWidget {
  const _SliceRow({required this.slice, required this.color});

  final UsageModelSlice slice;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(width: 9, height: 9, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                UsageModelDonut._label(l10n, slice.model),
                style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                fmtTokens(slice.tokens),
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          fmtPercent(slice.share),
          style: CcTypography.monoNum.copyWith(color: t.textSecondary),
        ),
      ],
    );
  }
}
