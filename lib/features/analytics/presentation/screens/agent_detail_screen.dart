import 'package:control_center/features/analytics/presentation/widgets/stat_cards/streak_flame.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Agent detail screen.
class AgentDetailScreen extends ConsumerWidget {
  /// Creates a new [AgentDetailScreen].
  const AgentDetailScreen({super.key, required this.agentId});

  /// Identifier of the agent to display.
  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scorecard = ref.watch(agentScorecardProvider(agentId));
    final streaks = ref.watch(agentStreaksProvider(agentId));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(scorecard.value?.agentName ?? l10n.agent)),

      body: scorecard.when(
        data: (card) {
          if (card == null) {
            return Center(child: Text(l10n.noData));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _XpBar(totalXp: card.totalXp, level: card.level, levelProgress: card.levelProgress, theme: theme),
              const SizedBox(height: 16),
              Text(l10n.stats, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),

              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(label: l10n.totalRunsLabel, value: '${card.totalRuns}'),
                  _StatChip(label: l10n.erroredLabel, value: '${card.totalErrored}'),
                  _StatChip(label: l10n.successRate, value: '${(card.successRate * 100).round()}%'),
                  _StatChip(label: l10n.avgDuration, value: '${card.avgRunDurationMs ~/ 1000}s'),
                  _StatChip(label: l10n.prsCreatedLabel, value: '${card.totalPrsCreated}'),
                  _StatChip(label: 'PRs merged', value: '${card.totalPrsMerged}'),
                  _StatChip(label: l10n.reviewsLabel, value: '${card.totalReviews}'),
                  _StatChip(label: l10n.blockingLabel, value: '${card.totalBlockingComments}'),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.streaksLabel, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              streaks.when(
                data: (s) => Row(
                  children: s.map((st) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: StreakFlame(count: st.currentCount, label: st.streakType, isActive: st.currentCount > 0),
                  )).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(l10n.failedWithError('$e')),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.failedWithError('$e'))),
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.totalXp, required this.level, required this.levelProgress, required this.theme});

  final int totalXp;
  final int level;
  final double levelProgress;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(l10n.levelLabel(level), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('$totalXp XP', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: levelProgress,
                minHeight: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text('$label: $value', style: theme.textTheme.bodySmall),
      visualDensity: VisualDensity.compact,
    );
  }
}
