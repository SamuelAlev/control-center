import 'package:control_center/features/analytics/domain/entities/leaderboard_entry.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Leaderboard widget.
class LeaderboardWidget extends StatelessWidget {
  /// Creates a new [LeaderboardWidget].
  const LeaderboardWidget({
    super.key,
    required this.entries,
    required this.selectedWindow,
    required this.onWindowChanged,
  });

  /// Leaderboard entries to display.
  final List<LeaderboardEntry> entries;
  /// Currently selected time window.
  final String selectedWindow;
  /// Callback when the time window changes.
  final ValueChanged<String> onWindowChanged;

  /// Available time window options.
  static const windows = ['Today', '7d', '30d', 'All'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final maxScore = entries.isEmpty ? 1 : entries.first.score;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.leaderboardLabelShort, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'Today', label: Text(l10n.todayLabel, style: const TextStyle(fontSize: 12))),
                    const ButtonSegment(value: '7d', label: Text('7d', style: TextStyle(fontSize: 12))),
                    const ButtonSegment(value: '30d', label: Text('30d', style: TextStyle(fontSize: 12))),
                    ButtonSegment(value: 'All', label: Text(l10n.allTimeLabel, style: const TextStyle(fontSize: 12))),
                  ],
                  selected: {selectedWindow},
                  onSelectionChanged: (s) => onWindowChanged(s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Center(child: Text(l10n.noData))
            else
              ...entries.map((e) => _LeaderboardRow(entry: e, maxScore: maxScore, theme: theme)),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.maxScore, required this.theme});

  final LeaderboardEntry entry;
  final int maxScore;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ratio = maxScore > 0 ? entry.score / maxScore : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#${entry.rank}', style: theme.textTheme.bodySmall)),
          SizedBox(width: 100, child: Text(entry.agentName, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 48, child: Text('${entry.score} pts', style: theme.textTheme.bodySmall, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
