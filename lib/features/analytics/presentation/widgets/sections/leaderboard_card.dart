import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/analytics_shared.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A card displaying a leaderboard of agents ranked by score, with
/// selectable time windows.
class LeaderboardCard extends ConsumerWidget {
/// Creates the leaderboard card widget.
  const LeaderboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(leaderboardWindowProvider);
    final entries = ref.watch(leaderboardProvider);
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      label: l10n.leaderboardLabel,
      trailing: _WindowToggle(currentLabel: window.label, onSelect: (label) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        late LeaderboardWindow next;
        switch (label) {
          case 'Today':
            next = LeaderboardWindow(today, now, 'Today');
          case '7d':
            next = LeaderboardWindow(today.subtract(const Duration(days: 6)), now, '7d');
          case '30d':
            next = LeaderboardWindow(today.subtract(const Duration(days: 29)), now, '30d');
          case 'All':
          default:
            next = LeaderboardWindow(DateTime.fromMillisecondsSinceEpoch(0), now, 'All');
        }
        ref.read(leaderboardWindowProvider.notifier).setWindow(next);
      }),
      child: entries.when(
        loading: () => const SizedBox(
          height: 140,
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(l10n.failedWithError('$e'))),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const SectionEmpty(
              icon: LucideIcons.trendingUp,
              message: 'No activity in this window yet',
            );
          }
          final top = rows.take(5).toList();
          final maxScore = top.first.score == 0 ? 1 : top.first.score;
          return Column(
            children: [
              for (var i = 0; i < top.length; i++) ...[
                _LeaderboardRow(
                  rank: top[i].rank,
                  name: top[i].agentName,
                  score: top[i].score,
                  ratio: top[i].score / maxScore,
                  agentId: top[i].agentId,
                ),
                if (i < top.length - 1) const SizedBox(height: 6),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _WindowToggle extends StatelessWidget {
  const _WindowToggle({required this.currentLabel, required this.onSelect});
  final String currentLabel;
  final ValueChanged<String> onSelect;

  static const _options = ['Today', '7d', '30d', 'All'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final muted = tokens.textTertiary;
    final l10n = AppLocalizations.of(context);
    final fg = tokens.textPrimary;
    final activeBg = tokens.bgTertiary;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in _options)
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => onSelect(o),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: o == currentLabel ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _windowLabel(o, l10n),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: o == currentLabel ? fg : muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _windowLabel(String key, AppLocalizations l10n) {
  switch (key) {
    case 'Today':
      return l10n.todayLabel;
    case 'All':
      return l10n.allTimeLabel;
    default:
      return key;
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.name,
    required this.score,
    required this.ratio,
    required this.agentId,
  });

  final int rank;
  final String name;
  final int score;
  final double ratio;
  final String agentId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final accent = Theme.of(context).colorScheme.primary;
    final muted = tokens.textTertiary;
    final fg = tokens.textPrimary;
    final rankBadge = switch (rank) {
      1 => const Color(0xFFE5B100),
      2 => const Color(0xFF9CA3AF),
      3 => const Color(0xFFB97A56),
      _ => muted,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => context.go(analyticsAgentRoute(agentId)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: rankBadge,
                ),
              ),
            ),
            const SizedBox(width: 6),
            AgentAvatar(name: name, size: 22, color: accent),
            const SizedBox(width: 10),
            SizedBox(
              width: 96,
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: tokens.bgTertiary,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              child: Text(
                compactInt(score),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
