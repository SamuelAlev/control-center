import 'package:cc_domain/features/observability/domain/usage_stats.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/presentation/widgets/usage/usage_activity_grid_view.dart';
import 'package:control_center/features/observability/presentation/widgets/usage/usage_model_donut.dart';
import 'package:control_center/features/observability/presentation/widgets/usage/usage_summary_strip.dart';
import 'package:control_center/features/observability/presentation/widgets/usage/usage_trend_chart.dart';
import 'package:control_center/features/observability/providers/usage_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Usage tab (first): lifetime headline figures, a trailing-year token
/// activity calendar, and — over a shorter picked window — the per-model daily
/// trend and the model split.
///
/// The two windows are deliberately different. The strip and the calendar
/// answer "how much, ever, and how consistently"; the trend and the donut
/// answer "what am I spending tokens on lately", which is a question about a
/// few weeks, not a year.
class UsageTab extends ConsumerWidget {
  /// Creates a [UsageTab].
  const UsageTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(usageActivityModeProvider);
    final range = ref.watch(usageTrendRangeProvider);
    final grid = ref.watch(usageActivityGridProvider);
    final series = ref.watch(usageTrendSeriesProvider);
    final slices = ref.watch(usageModelSlicesProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const UsageSummaryStrip(),
        const SizedBox(height: AppSpacing.lg),
        ObsSection(
          title: l10n.obsUsageTokenActivity,
          icon: AppIcons.activity,
          trailing: CcSegmentedToggle<UsageActivityMode>(
            value: mode,
            semanticLabel: l10n.obsUsageActivityModeLabel,
            onChanged: (next) =>
                ref.read(usageActivityModeProvider.notifier).setMode(next),
            segments: [
              CcSegment(
                value: UsageActivityMode.daily,
                label: l10n.obsUsageModeDaily,
              ),
              CcSegment(
                value: UsageActivityMode.weekly,
                label: l10n.obsUsageModeWeekly,
              ),
              CcSegment(
                value: UsageActivityMode.cumulative,
                label: l10n.obsUsageModeCumulative,
              ),
            ],
          ),
          child: UsageActivityGridView(grid: grid),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.obsUsageTimeRange,
                style: CcTypography.body.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CcSegmentedToggle<UsageTrendRange>(
              value: range,
              semanticLabel: l10n.obsUsageTimeRange,
              onChanged: (next) =>
                  ref.read(usageTrendRangeProvider.notifier).setRange(next),
              segments: [
                CcSegment(
                  value: UsageTrendRange.last7d,
                  label: l10n.obsRangeLast7d,
                ),
                CcSegment(
                  value: UsageTrendRange.last30d,
                  label: l10n.obsRangeLast30d,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ObsSection(
          title: l10n.obsUsageTrendTitle,
          icon: AppIcons.chartColumn,
          child: UsageTrendChart(series: series),
        ),
        const SizedBox(height: AppSpacing.lg),
        ObsSection(
          title: l10n.obsUsageModelUsage,
          icon: AppIcons.network,
          child: UsageModelDonut(slices: slices),
        ),
      ],
    );
  }
}
