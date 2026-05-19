import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/analytics_shared.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/charts/activity_heatmap.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ActivityHeatmapCard extends ConsumerStatefulWidget {
  const ActivityHeatmapCard({super.key});

  static const _weeks = 26;

  @override
  ConsumerState<ActivityHeatmapCard> createState() => _ActivityHeatmapCardState();
}

class _ActivityHeatmapCardState extends ConsumerState<ActivityHeatmapCard> {
  late final DateTime _today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final start = _today.subtract(const Duration(days: ActivityHeatmapCard._weeks * 7));
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(allDailyStatsByDateRangeProvider((
      start: start,
      end: _today,
    )));

    return SectionCard(
      label: l10n.activityLabel,
      title: Text(l10n.runsAcrossAllAgents),
      subtitle: Text(l10n.lastMonths(ActivityHeatmapCard._weeks ~/ 4)),
      trailing: _ActivityTotal(stats: stats),
      child: stats.when(
        loading: () => const SizedBox(
          height: 140,
          child: Center(child: FCircularProgress()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(l10n.failedWithError('$e'))),
        ),
        data: (rows) {
          final byDay = <DateTime, _ActivityAccum>{};
          for (final r in rows) {
            final d = DateTime(r.date.year, r.date.month, r.date.day);
            (byDay[d] ??= _ActivityAccum()).add(r);
          }
          if (byDay.values.every((a) => a.toCell().isEmpty)) {
            return const SectionEmpty(
              icon: LucideIcons.calendarDays,
              message: 'No runs recorded yet',
            );
          }
          final cells = <DateTime, ActivityCell>{
            for (final e in byDay.entries) e.key: e.value.toCell(),
          };
          return ActivityHeatmap(data: cells, weeks: ActivityHeatmapCard._weeks);
        },
      ),
    );
  }
}

class _ActivityTotal extends StatelessWidget {
  const _ActivityTotal({required this.stats});
  final AsyncValue<List<AgentDailyStats>> stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final tokens = context.designSystem;
    final theme = FTheme.of(context);
    final muted = tokens?.textTertiary ?? theme.colors.mutedForeground;
    final fg = tokens?.textPrimary ?? theme.colors.foreground;
    final total = stats.maybeWhen(
      data: (rows) => rows.fold<int>(
        0,
        (sum, r) => sum + r.runsCompleted + r.runsErrored,
      ),
      orElse: () => 0,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          compactInt(total),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: fg,
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          l10n.runs.toLowerCase(),
          style: TextStyle(fontSize: 12, height: 1.4, color: muted),
        ),
      ],
    );
  }
}

class _ActivityAccum {
  int runsCompleted = 0;
  int runsErrored = 0;
  int prsCreated = 0;
  int prsMerged = 0;
  int reviewsCompleted = 0;
  int blockingComments = 0;

  void add(AgentDailyStats r) {
    runsCompleted += r.runsCompleted;
    runsErrored += r.runsErrored;
    prsCreated += r.prsCreated;
    prsMerged += r.prsMerged;
    reviewsCompleted += r.reviewsCompleted;
    blockingComments += r.blockingComments;
  }

  ActivityCell toCell() => ActivityCell(
        runsCompleted: runsCompleted,
        runsErrored: runsErrored,
        prsCreated: prsCreated,
        prsMerged: prsMerged,
        reviewsCompleted: reviewsCompleted,
        blockingComments: blockingComments,
      );
}
