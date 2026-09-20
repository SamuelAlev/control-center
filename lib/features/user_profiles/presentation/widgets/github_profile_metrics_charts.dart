part of 'github_profile_metrics_panel.dart';

class _LedgerFact {
  const _LedgerFact(this.label, this.value);

  final String label;
  final String value;
}

class _OutcomeLedger extends StatelessWidget {
  const _OutcomeLedger({required this.facts});

  final List<_LedgerFact> facts;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? facts.length
            : constraints.maxWidth >= 720
            ? 4
            : 2;
        final width = constraints.maxWidth / columns;
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.borderSecondary)),
          ),
          child: Wrap(
            children: [
              for (var index = 0; index < facts.length; index++)
                SizedBox(
                  width: width,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: BorderDirectional(
                        start: index % columns == 0
                            ? BorderSide.none
                            : BorderSide(color: t.borderSecondary),
                        top: index < columns
                            ? BorderSide.none
                            : BorderSide(color: t.borderSecondary),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facts[index].value,
                            maxLines: 1,
                            style: CcFonts.code(
                              textStyle: CcTypography.body.copyWith(
                                color: t.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            facts[index].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CcTypography.caption.copyWith(
                              color: t.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ChartsGrid extends StatelessWidget {
  const _ChartsGrid({
    required this.distribution,
    required this.size,
    required this.trend,
    required this.rhythm,
  });

  final Widget distribution;
  final Widget size;
  final Widget trend;
  final Widget rhythm;

  static const _rowHeight = 220.0;
  static const _twoColMinWidth = 640.0;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final charts = [distribution, size, trend, rhythm];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= _twoColMinWidth ? 2 : 1;
        final rows = (charts.length / columns).ceil();
        Widget hairline({required bool vertical}) => SizedBox(
          width: vertical ? 1 : null,
          height: vertical ? null : 1,
          child: ColoredBox(color: t.borderSecondary),
        );

        return SizedBox(
          height: rows * _rowHeight + (rows - 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var row = 0; row < rows; row++) ...[
                if (row > 0) hairline(vertical: false),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < columns; col++) ...[
                        if (col > 0) hairline(vertical: true),
                        Expanded(child: charts[row * columns + col]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ChartPane extends StatelessWidget {
  const _ChartPane({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: CcTypography.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: CcTypography.semiboldWeight,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: CcFonts.code(
                        textStyle: CcTypography.caption.copyWith(
                          color: t.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  trailing!,
                  style: CcFonts.code(
                    textStyle: CcTypography.bodySm.copyWith(
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MergeDistributionChart extends StatelessWidget {
  const _MergeDistributionChart({
    required this.counts,
    required this.medianBucket,
    required this.median,
    required this.p90,
  });

  final List<int> counts;
  final int? medianBucket;
  final String median;
  final String p90;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ChartPane(
      title: l10n.profileTimeToMerge,
      subtitle: l10n.profilePercentiles(median, p90),
      child: _BucketHistogram(
        labels: _mergeBucketLabels(l10n),
        counts: counts,
        medianBucket: medianBucket,
      ),
    );
  }
}

class _PrSizeChart extends StatelessWidget {
  const _PrSizeChart({
    required this.counts,
    required this.medianBucket,
    required this.median,
    required this.p90,
  });

  final List<int> counts;
  final int? medianBucket;
  final String median;
  final String p90;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return _ChartPane(
      title: l10n.profilePrSize,
      subtitle: l10n.profilePercentiles(median, p90),
      child: _BucketHistogram(
        labels: _sizeBucketLabels(locale),
        counts: counts,
        medianBucket: medianBucket,
      ),
    );
  }
}

class _BucketHistogram extends StatelessWidget {
  const _BucketHistogram({
    required this.labels,
    required this.counts,
    required this.medianBucket,
  });

  final List<String> labels;
  final List<int> counts;
  final int? medianBucket;

  @override
  Widget build(BuildContext context) {
    final total = counts.fold<int>(0, (sum, value) => sum + value);
    final maxCount = counts.fold<int>(0, math.max);
    final semantics = [
      for (var index = 0; index < counts.length; index++)
        '${labels[index]}: ${counts[index]}',
    ].join('. ');

    return Semantics(
      container: true,
      label: semantics,
      child: Directionality(
        // RTL carve-out: histogram axes and numeric ranges are a chart
        // canvas, so start/end remain physical across locales.
        textDirection: ui.TextDirection.ltr,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var index = 0; index < counts.length; index++)
              _HistogramBar(
                label: labels[index],
                count: counts[index],
                percent: total == 0
                    ? '—'
                    : '${(counts[index] * 100 / total).round()}%',
                fraction: maxCount == 0 ? 0 : counts[index] / maxCount,
                emphasized: medianBucket == index,
              ),
          ],
        ),
      ),
    );
  }
}

class _HistogramBar extends StatefulWidget {
  const _HistogramBar({
    required this.label,
    required this.count,
    required this.percent,
    required this.fraction,
    required this.emphasized,
  });

  final String label;
  final int count;
  final String percent;
  final double fraction;
  final bool emphasized;

  @override
  State<_HistogramBar> createState() => _HistogramBarState();
}

class _HistogramBarState extends State<_HistogramBar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fill = _hovered
        ? t.accent
        : widget.emphasized
        ? t.fgPrimary
        : t.muted;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: CcTooltip(
        showDelay: CcMotion.fast,
        placement: CcTooltipPlacement.top,
        message: '${widget.label} · ${widget.count} (${widget.percent})',
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcFonts.code(
                  textStyle: CcTypography.caption.copyWith(
                    color: widget.emphasized || _hovered
                        ? t.textPrimary
                        : t.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 12,
                child: ColoredBox(
                  color: t.bgTertiary,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: widget.fraction,
                      heightFactor: 1,
                      child: ColoredBox(color: fill),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 24,
              child: Text(
                '${widget.count}',
                textAlign: TextAlign.end,
                style: CcFonts.code(
                  textStyle: CcTypography.caption.copyWith(
                    color: widget.count == 0 ? t.textTertiary : t.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 38,
              child: Text(
                widget.percent,
                textAlign: TextAlign.end,
                style: CcFonts.code(
                  textStyle: CcTypography.caption.copyWith(
                    color: t.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MergeTrendChart extends StatelessWidget {
  const _MergeTrendChart({required this.points});

  final List<_WeeklyMedian> points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final latest = points.isEmpty ? '—' : _duration(l10n, points.last.hours);
    final semantics = [
      for (final point in points)
        '${DateFormat.yMMMd(locale).format(point.weekStart)}: ${_duration(l10n, point.hours)}',
    ].join('. ');

    return _ChartPane(
      title: l10n.profileMergeTimeTrend,
      subtitle: l10n.profileWeeklyMedian,
      trailing: latest,
      child: Semantics(
        container: true,
        label: semantics,
        child: Directionality(
          // RTL carve-out: time-series axes stay LTR in every locale.
          textDirection: ui.TextDirection.ltr,
          child: points.isEmpty
              ? Center(
                  child: Text(
                    '—',
                    style: CcFonts.code(
                      textStyle: CcTypography.title.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                  ),
                )
              : _trendPlot(locale, t, l10n),
        ),
      ),
    );
  }

  Widget _trendPlot(
    String locale,
    DesignSystemTokens t,
    AppLocalizations l10n,
  ) {
    final values = [for (final point in points) _logMinutes(point.hours)];
    final axis = _LogDurationAxis.fromValues(values);
    final last = points.length - 1;
    final stride = math.max(1, (points.length / 3).ceil());
    final sample = (axis.maxY - axis.minY) / 80;
    final axisStyle = CcFonts.code(
      textStyle: CcTypography.caption.copyWith(
        color: t.textSecondary,
        fontSize: 9,
      ),
    );

    Widget? tickTitle(double value, TitleMeta meta) {
      for (final tick in axis.ticks) {
        if ((value - tick).abs() <= sample / 2) {
          return SideTitleWidget(
            meta: meta,
            space: 4,
            child: SizedBox(
              width: 52,
              child: Text(
                _duration(l10n, math.exp(tick) / 60),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: axisStyle,
              ),
            ),
          );
        }
      }
      return null;
    }

    return ChartHoverHost(
      plotPadding: _trendPlotPadding,
      pointCount: points.length,
      maxY: axis.maxY - axis.minY,
      seriesColors: [t.accent],
      seriesValuesAt: (index) => [values[index] - axis.minY],
      flyoutBuilder: (index) {
        final point = points[index];
        return Text(
          '${DateFormat.yMMMd(locale).format(point.weekStart)}\n'
          '${_duration(l10n, point.hours)}',
        );
      },
      child: LineChart(
        duration: Duration.zero,
        LineChartData(
          minX: 0,
          maxX: math.max(1, last).toDouble(),
          minY: axis.minY,
          maxY: axis.maxY,
          clipData: const FlClipData.all(),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          extraLinesData: ExtraLinesData(
            extraLinesOnTop: false,
            horizontalLines: [
              for (final tick in axis.ticks)
                HorizontalLine(
                  y: tick,
                  color: t.borderSecondary,
                  strokeWidth: 1,
                ),
            ],
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                interval: sample,
                minIncluded: false,
                maxIncluded: false,
                getTitlesWidget: (value, meta) =>
                    tickTitle(value, meta) ?? const SizedBox.shrink(),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index > last) {
                    return const SizedBox.shrink();
                  }
                  final isEdge = index == 0 || index == last;
                  final isStride = index % stride == 0;
                  if (!isEdge && (!isStride || last - index < stride)) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    fitInside: SideTitleFitInsideData.fromTitleMeta(
                      meta,
                      distanceFromEdge: 0,
                    ),
                    child: Text(
                      DateFormat.MMMd(locale).format(points[index].weekStart),
                      maxLines: 1,
                      style: axisStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var index = 0; index < values.length; index++)
                  FlSpot(index.toDouble(), values[index]),
              ],
              isCurved: false,
              isStepLineChart: points.length > 1,
              color: t.accent,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 2.5,
                      color: t.accent,
                      strokeWidth: 0,
                    ),
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpeningRhythmChart extends StatelessWidget {
  const _OpeningRhythmChart({required this.counts});

  final List<List<int>> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final peak = counts.expand((row) => row).fold<int>(0, math.max);
    final dayLabels = [
      for (var index = 0; index < 7; index++)
        DateFormat.E(locale).format(DateTime(2024, 1, 1 + index)),
    ];
    final semantics = [
      for (var day = 0; day < 7; day++)
        '${dayLabels[day]}: ${counts[day].fold<int>(0, (sum, value) => sum + value)}',
    ].join('. ');

    return _ChartPane(
      title: l10n.prsCreated,
      subtitle: l10n.profilePrOpeningPattern,
      child: Semantics(
        container: true,
        label: semantics,
        child: Directionality(
          // RTL carve-out: weekday × hour is a chart canvas with a physical
          // midnight-to-evening axis.
          textDirection: ui.TextDirection.ltr,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dayWidth = 36.0;
              const totalWidth = 24.0;
              const gap = 3.0;
              final cellWidth = math.max(
                8.0,
                (constraints.maxWidth - dayWidth - totalWidth - gap * 9) / 8,
              );
              final hourStyle = CcFonts.code(
                textStyle: CcTypography.caption.copyWith(
                  color: t.textSecondary,
                  fontSize: 9,
                ),
              );
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: dayWidth + gap),
                      for (var hour = 0; hour < 24; hour += 3) ...[
                        SizedBox(
                          width: cellWidth,
                          child: Text(
                            NumberFormat('00', locale).format(hour),
                            textAlign: TextAlign.center,
                            style: hourStyle,
                          ),
                        ),
                        const SizedBox(width: gap),
                      ],
                    ],
                  ),
                  for (var day = 0; day < 7; day++)
                    Row(
                      children: [
                        SizedBox(
                          width: dayWidth,
                          child: Text(
                            dayLabels[day],
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: hourStyle,
                          ),
                        ),
                        const SizedBox(width: gap),
                        for (var bucket = 0; bucket < 8; bucket++) ...[
                          _HeatCell(
                            width: cellWidth,
                            color: _heatColor(t, counts[day][bucket], peak),
                            tooltip:
                                '${dayLabels[day]} · '
                                '${NumberFormat('00', locale).format(bucket * 3)}–'
                                '${NumberFormat('00', locale).format(bucket * 3 + 3)} · '
                                '${counts[day][bucket]}',
                          ),
                          const SizedBox(width: gap),
                        ],
                        SizedBox(
                          width: totalWidth,
                          child: Text(
                            '${counts[day].fold<int>(0, (sum, value) => sum + value)}',
                            textAlign: TextAlign.end,
                            style: hourStyle.copyWith(color: t.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  _HeatLegend(peak: peak),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Color _heatColor(DesignSystemTokens t, int value, int peak) {
    if (value == 0 || peak == 0) {
      return t.bgTertiary;
    }
    final fraction = value / peak;
    return Color.lerp(t.surface, t.fg, 0.22 + fraction * 0.62)!;
  }
}

class _HeatCell extends StatefulWidget {
  const _HeatCell({
    required this.width,
    required this.color,
    required this.tooltip,
  });

  final double width;
  final Color color;
  final String tooltip;

  @override
  State<_HeatCell> createState() => _HeatCellState();
}

class _HeatCellState extends State<_HeatCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTooltip(
      showDelay: CcMotion.fast,
      placement: CcTooltipPlacement.top,
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: SizedBox(
          width: widget.width,
          height: 15,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color,
              border: _hovered
                  ? Border.all(color: t.textPrimary, width: 1)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend({required this.peak});

  final int peak;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final values = peak <= 1
        ? const [0, 1]
        : peak <= 4
        ? [0, 1, peak]
        : [0, 1, (peak / 2).ceil(), peak];
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final value in values) ...[
          SizedBox.square(
            dimension: 9,
            child: ColoredBox(
              color: value == 0
                  ? t.bgTertiary
                  : Color.lerp(
                      t.surface,
                      t.fg,
                      0.22 + (value / math.max(1, peak)) * 0.62,
                    )!,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$value',
            style: CcFonts.code(
              textStyle: CcTypography.caption.copyWith(
                color: t.textSecondary,
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    Widget block({required double height, double? width}) => SizedBox(
      width: width,
      height: height,
      child: ColoredBox(color: t.bgTertiary),
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var index = 0; index < 4; index++) ...[
                if (index > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: block(height: 48)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(child: block(height: 176)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileChartData {
  const _ProfileChartData({
    required this.mergeBuckets,
    required this.sizeBuckets,
    required this.weeklyMergeMedians,
    required this.openedByWeekdayAndHour,
  });

  factory _ProfileChartData.fromActivity(GitHubProfileActivity activity) {
    final mergeBuckets = List<int>.filled(8, 0);
    final sizeBuckets = List<int>.filled(8, 0);
    final mergesByWeek = <DateTime, List<double>>{};
    final opened = List.generate(7, (_) => List<int>.filled(8, 0));

    for (final group in activity.repos) {
      for (final pr in group.prs) {
        sizeBuckets[_sizeBucketIndex(pr.additions + pr.deletions)]++;
        final createdAt = pr.createdAt?.toLocal();
        if (createdAt != null) {
          opened[createdAt.weekday - 1][createdAt.hour ~/ 3]++;
        }
        final mergedAt = pr.mergedAt?.toLocal();
        if (createdAt == null ||
            mergedAt == null ||
            !mergedAt.isAfter(createdAt)) {
          continue;
        }
        final hours = mergedAt.difference(createdAt).inMinutes / 60;
        mergeBuckets[_mergeBucketIndex(hours)]++;
        final weekStart = DateTime(
          mergedAt.year,
          mergedAt.month,
          mergedAt.day - (mergedAt.weekday - 1),
        );
        (mergesByWeek[weekStart] ??= <double>[]).add(hours);
      }
    }

    final weeks = mergesByWeek.keys.toList()..sort();
    final trend = [
      for (final week in weeks)
        _WeeklyMedian(week, _median(mergesByWeek[week]!)),
    ];
    final visibleTrend = trend.length <= 8
        ? trend
        : trend.sublist(trend.length - 8);

    return _ProfileChartData(
      mergeBuckets: mergeBuckets,
      sizeBuckets: sizeBuckets,
      weeklyMergeMedians: visibleTrend,
      openedByWeekdayAndHour: opened,
    );
  }

  final List<int> mergeBuckets;
  final List<int> sizeBuckets;
  final List<_WeeklyMedian> weeklyMergeMedians;
  final List<List<int>> openedByWeekdayAndHour;
}

class _WeeklyMedian {
  const _WeeklyMedian(this.weekStart, this.hours);

  final DateTime weekStart;
  final double hours;
}

/// Must match [_MergeTrendChart] titles: left reservedSize 56, bottom 28.
///
/// RTL carve-out: fl_chart lays axes on the physical left/bottom.
const _trendPlotPadding = EdgeInsets.only(left: 56, bottom: 28);

double _logMinutes(double hours) => math.log(math.max(1, hours * 60));

const _niceDurationMinutes = <int>[
  1,
  2,
  5,
  10,
  15,
  20,
  30,
  45,
  60,
  90,
  120,
  180,
  240,
  360,
  480,
  720,
  1080,
  1440,
  2160,
  2880,
  4320,
  5760,
  10080,
  20160,
  43200,
  86400,
];

class _LogDurationAxis {
  const _LogDurationAxis({
    required this.minY,
    required this.maxY,
    required this.ticks,
  });

  factory _LogDurationAxis.fromValues(List<double> values) {
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    var span = maxY - minY;
    if (span < 0.8) {
      final mid = (minY + maxY) / 2;
      minY = mid - 0.4;
      maxY = mid + 0.4;
      span = maxY - minY;
    }
    minY -= span * 0.1;
    maxY += span * 0.1;

    final candidates = [
      for (final minutes in _niceDurationMinutes) math.log(minutes.toDouble()),
    ].where((y) => y >= minY && y <= maxY).toList();
    final ticks = _pickDurationTicks(candidates, minY: minY, maxY: maxY);
    return _LogDurationAxis(
      minY: math.min(minY, ticks.first),
      maxY: math.max(maxY, ticks.last),
      ticks: ticks,
    );
  }

  final double minY;
  final double maxY;
  final List<double> ticks;
}

List<double> _pickDurationTicks(
  List<double> candidates, {
  required double minY,
  required double maxY,
}) {
  const target = 5;
  if (candidates.length >= 3) {
    if (candidates.length <= target) {
      return candidates;
    }
    final picked = <double>[candidates.first];
    for (var i = 1; i < target - 1; i++) {
      final index = ((candidates.length - 1) * i / (target - 1)).round();
      final value = candidates[index];
      if ((value - picked.last).abs() > 1e-9) {
        picked.add(value);
      }
    }
    if ((candidates.last - picked.last).abs() > 1e-9) {
      picked.add(candidates.last);
    }
    return picked;
  }
  return [
    for (var i = 0; i < target; i++) minY + (maxY - minY) * i / (target - 1),
  ];
}

const _sizeBucketLimits = [10, 30, 100, 500, 1000, 5000, 10000];

int _mergeBucketIndex(double hours) {
  if (hours < 1) {
    return 0;
  }
  if (hours < 4) {
    return 1;
  }
  if (hours < 8) {
    return 2;
  }
  if (hours < 24) {
    return 3;
  }
  if (hours < 48) {
    return 4;
  }
  if (hours < 96) {
    return 5;
  }
  if (hours < 168) {
    return 6;
  }
  return 7;
}

int _sizeBucketIndex(num lines) {
  final value = lines < 0 ? 0 : lines;
  for (var i = 0; i < _sizeBucketLimits.length; i++) {
    if (value < _sizeBucketLimits[i]) {
      return i;
    }
  }
  return _sizeBucketLimits.length;
}

List<String> _mergeBucketLabels(AppLocalizations l10n) => [
  '< ${_duration(l10n, 1)}',
  '${_duration(l10n, 1)}–${_duration(l10n, 4)}',
  '${_duration(l10n, 4)}–${_duration(l10n, 8)}',
  '${_duration(l10n, 8)}–${_duration(l10n, 24)}',
  '${_duration(l10n, 24)}–${_duration(l10n, 48)}',
  '${_duration(l10n, 48)}–${_duration(l10n, 96)}',
  '${_duration(l10n, 96)}–${_duration(l10n, 168)}',
  '> ${_duration(l10n, 168)}',
];

List<String> _sizeBucketLabels(String locale) {
  final compact = NumberFormat.compact(locale: locale);
  String n(int value) => value < 1000 ? '$value' : compact.format(value);
  return [
    '< ${n(10)}',
    '${n(10)}–${n(29)}',
    '${n(30)}–${n(99)}',
    '${n(100)}–${n(499)}',
    '${n(500)}–${n(999)}',
    '${n(1000)}–${n(5000)}',
    '${n(5000)}–${n(10000)}',
    '≥ ${n(10000)}',
  ];
}

double _median(List<double> values) {
  final sorted = values.toList()..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[middle];
  }
  return (sorted[middle - 1] + sorted[middle]) / 2;
}

String _percent(String locale, double? value) {
  if (value == null) {
    return '—';
  }
  return '${NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 0).format(value)}%';
}

String _lines(AppLocalizations l10n, NumberFormat compact, double? value) {
  if (value == null) {
    return '—';
  }
  return l10n.profileLinesChanged(compact.format(value.round()));
}

String _duration(AppLocalizations l10n, double? hours) {
  if (hours == null) {
    return '—';
  }
  final roundedMinutes = (hours * 60).round();
  if (roundedMinutes < 60) {
    return l10n.profileDurationMinutes(roundedMinutes);
  }
  final roundedHours = (roundedMinutes / 60).round();
  if (roundedHours < 24) {
    return l10n.profileDurationHours(roundedHours);
  }
  return l10n.profileDurationDaysHours(
    roundedHours ~/ 24,
    roundedHours.remainder(24),
  );
}
