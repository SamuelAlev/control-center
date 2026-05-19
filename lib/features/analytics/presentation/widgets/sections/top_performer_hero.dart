import 'package:cc_domain/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/analytics_shared.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A hero section highlighting the top-performing agent with sparkline
/// charts, level, and stats summary.
class TopPerformerHero extends ConsumerWidget {
/// Creates the top performer hero widget.
  const TopPerformerHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scorecards = ref.watch(allAgentScorecardsProvider);
    final l10n = AppLocalizations.of(context);

    return scorecards.when(
      loading: () => SectionCard(
        label: l10n.topPerformerLabel,
        child: const SizedBox(
          height: 168,
          child: Center(child: CcSpinner()),
        ),
      ),
      error: (e, _) => SectionCard(
        label: l10n.topPerformerLabel,
        child: SizedBox(
          height: 168,
          child: Center(child: Text(l10n.failedWithError('$e'))),
        ),
      ),
      data: (cards) {
        if (cards.isEmpty) {
          return SectionCard(
            label: l10n.topPerformerLabel,
            child: const _HeroEmpty(),
          );
        }
        final top = [...cards]..sort((a, b) => b.totalXp.compareTo(a.totalXp));
        return _HeroBody(top: top.first);
      },
    );
  }
}

class _HeroEmpty extends StatelessWidget {
  const _HeroEmpty();

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final muted = tokens.textTertiary;
    return SizedBox(
      height: 168,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.trophy, color: muted, size: 28),
            const SizedBox(height: 8),
            Text(
              'No agent activity yet',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBody extends ConsumerStatefulWidget {
  const _HeroBody({required this.top});

  final AgentScorecard top;

  @override
  ConsumerState<_HeroBody> createState() => _HeroBodyState();
}

class _HeroBodyState extends ConsumerState<_HeroBody> {
  late final DateTime _today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final bg = tokens.bgPrimary;
    final border = tokens.borderSecondary;
    final primary = tokens.textPrimary;
    final muted = tokens.textTertiary;
    final accent = Theme.of(context).colorScheme.primary;

    final start = _today.subtract(const Duration(days: 29));
    final spark = ref.watch(dailyStatsByDateRangeProvider((
      agentId: widget.top.agentId,
      start: start,
      end: _today,
    )));

    final successPct = (widget.top.successRate * 100).round();

    return Container(
      decoration: ShapeDecoration(
        color: bg,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: border, width: 1.0),
          borderRadius: AppRadii.brMd,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 168,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.1,
                    colors: [
                      accent.withValues(alpha: 0.08),
                      accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: LayoutBuilder(
              builder: (context, c) {
                final compact = c.maxWidth < 640;
                final header = Row(
                  children: [
                    _OverlineDot(color: accent),
                    const SizedBox(width: 8),
                    Text(
                      l10n.topPerformerLabel,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: muted,
                      ),
                    ),
                    const Spacer(),
                    Icon(AppIcons.trophy, size: 14, color: muted),
                  ],
                );

                final identity = Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AgentAvatar(name: widget.top.agentName, size: 56, color: accent),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.top.agentName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: primary,
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _LevelChip(level: widget.top.level, color: accent),
                              const SizedBox(width: 8),
                              Text(
                                '${compactInt(widget.top.totalXp)} XP',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 220,
                              child: LinearProgressIndicator(
                                value: widget.top.levelProgress.clamp(0, 1),
                                minHeight: 6,
                                backgroundColor: tokens.bgTertiary,
                                valueColor: AlwaysStoppedAnimation(accent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final stats = Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  children: [
                    _HeroStat(label: l10n.runs, value: '${widget.top.totalRuns}'),
                    _HeroStat(label: l10n.success, value: '$successPct%'),
                    _HeroStat(label: 'PRs merged', value: '${widget.top.totalPrsMerged}'),
                    _HeroStat(label: l10n.reviewsLabel, value: '${widget.top.totalReviews}'),
                  ],
                );

                final sparkline = SizedBox(
                  height: 56,
                  width: compact ? double.infinity : 220,
                  child: _Sparkline(
                    spots: _buildSpark(spark.value, 30, _today),
                    color: accent,
                  ),
                );

                final body = compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          identity,
                          const SizedBox(height: 16),
                          stats,
                          const SizedBox(height: 12),
                          Text(
                            'Last 30 days',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          sparkline,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                identity,
                                const SizedBox(height: 16),
                                stats,
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Last 30 days',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              sparkline,
                            ],
                          ),
                        ],
                      );

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                        onTap: () => context.go(
                          analyticsAgentRoute(
                            context.currentWorkspaceId!,
                            widget.top.agentId,
                          ),
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          header,
                          const SizedBox(height: 14),
                          body,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static List<double> _buildSpark(List<AgentDailyStats>? stats, int days, DateTime today) {
    if (stats == null || stats.isEmpty) {
      return List<double>.filled(days, 0);
    }
    final out = List<double>.filled(days, 0);
    for (final s in stats) {
      final day = DateTime(s.date.year, s.date.month, s.date.day);
      final delta = today.difference(day).inDays;
      final idx = days - 1 - delta;
      if (idx >= 0 && idx < days) {
        out[idx] += s.runsCompleted.toDouble();
      }
    }
    return out;
  }
}

class _OverlineDot extends StatelessWidget {
  const _OverlineDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level, required this.color});
  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        'LV $level',
        style: TextStyle(
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: tokens.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.spots, required this.color});
  final List<double> spots;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return const SizedBox.shrink();
    }
    final flSpots = spots
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: flSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: color,
            barWidth: 1.8,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
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
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}
