import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;

import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/charts/chart_hover.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'github_profile_metrics_charts.dart';

/// Profile-level PR outcomes and delivery patterns.
///
/// Exact outcome counts lead as a compact ledger. The detailed GitHub sample
/// then powers four pr-stats-style views in a 2×2: merge-time distribution,
/// PR size, weekly median trend and local-time opening rhythm.
class GitHubProfileMetricsPanel extends StatelessWidget {
  /// Creates a profile metrics panel.
  const GitHubProfileMetricsPanel({super.key, required this.activity});

  /// Workspace-scoped profile activity.
  final AsyncValue<GitHubProfileActivity> activity;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.panel,
        border: Border.all(color: t.borderPrimary),
        borderRadius: AppRadii.brLg,
      ),
      child: activity.when(
        loading: () => const _MetricsSkeleton(),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CcAlert(
            variant: CcAlertVariant.danger,
            title: l10n.failedToLoad,
            description: Text(error.toString()),
          ),
        ),
        data: (value) => _MetricsBody(activity: value),
      ),
    );
  }
}

class _MetricsBody extends StatelessWidget {
  const _MetricsBody({required this.activity});

  final GitHubProfileActivity activity;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final compact = NumberFormat.compact(locale: locale);
    final metrics = activity.metrics;
    final data = _ProfileChartData.fromActivity(activity);
    final mergeRate = metrics.mergeRatePercent;
    final reviewCoverage = metrics.reviewCoveragePercent;

    final facts = <_LedgerFact>[
      _LedgerFact(l10n.prsCreated, compact.format(metrics.total)),
      _LedgerFact(l10n.openLabel, compact.format(metrics.open)),
      _LedgerFact(l10n.draft, compact.format(metrics.draft)),
      _LedgerFact(l10n.merged, compact.format(metrics.merged)),
      _LedgerFact(l10n.closed, compact.format(metrics.closed)),
      _LedgerFact(l10n.profileMergeRate, _percent(locale, mergeRate)),
      _LedgerFact(l10n.profileReviewCoverage, _percent(locale, reviewCoverage)),
      _LedgerFact(
        l10n.profileFirstReview,
        _duration(l10n, metrics.medianHoursToFirstReview),
      ),
    ];

    final medianLines = _lines(l10n, compact, metrics.medianLinesChanged);
    final p90Lines = _lines(l10n, compact, metrics.p90LinesChanged);
    final medianMerge = _duration(l10n, metrics.medianHoursToMerge);
    final p90Merge = _duration(l10n, metrics.p90HoursToMerge);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OutcomeLedger(facts: facts),
        _ChartsGrid(
          distribution: _MergeDistributionChart(
            counts: data.mergeBuckets,
            medianBucket: metrics.medianHoursToMerge == null
                ? null
                : _mergeBucketIndex(metrics.medianHoursToMerge!),
            median: medianMerge,
            p90: p90Merge,
          ),
          size: _PrSizeChart(
            counts: data.sizeBuckets,
            medianBucket: metrics.medianLinesChanged == null
                ? null
                : _sizeBucketIndex(metrics.medianLinesChanged!),
            median: medianLines,
            p90: p90Lines,
          ),
          trend: _MergeTrendChart(points: data.weeklyMergeMedians),
          rhythm: _OpeningRhythmChart(counts: data.openedByWeekdayAndHour),
        ),
        if (metrics.resultsTruncated)
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.bgSecondary,
              border: Border(top: BorderSide(color: t.borderSecondary)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(CcIcons.info, size: 14, color: t.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.profileMetricsTruncated,
                      style: CcTypography.caption.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
