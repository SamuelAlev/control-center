import 'package:control_center/features/analytics/domain/entities/achievement.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.achievement,
    required this.icon,
    required this.label,
    this.isUnlocked = false,
  });

  final Achievement? achievement;
  final IconData icon;
  final String label;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isUnlocked
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.2);

    return Tooltip(
      message: achievement != null
          ? 'Unlocked ${achievement!.unlockedAt.toString().substring(0, 10)}'
          : label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Map<String, BadgeDef> badgeDefinitions(AppLocalizations l10n) => <String, BadgeDef>{
  'first_run': const BadgeDef(LucideIcons.play, 'First run'),
  'first_pr': const BadgeDef(LucideIcons.gitPullRequest, 'First PR'),
  'first_merge': const BadgeDef(LucideIcons.rocket, 'First merge'),
  'first_review': BadgeDef(LucideIcons.messageSquareText, l10n.firstReviewBadge),
  'centurion': BadgeDef(LucideIcons.medal, l10n.centurionBadge),
  'pr_machine': BadgeDef(LucideIcons.factory, l10n.prMachineBadge),
  'merge_master': BadgeDef(LucideIcons.gitMerge, l10n.mergeMasterBadge),
  'sharpshooter': BadgeDef(LucideIcons.crosshair, l10n.sharpshooterBadge),
  'hot_streak': BadgeDef(LucideIcons.flame, l10n.hotStreakBadge),
  'all_star': BadgeDef(LucideIcons.sparkles, l10n.allStarBadge),
  'flawless': BadgeDef(LucideIcons.wand, l10n.flawlessBadge),
  'perfectionist': BadgeDef(LucideIcons.gem, l10n.perfectionistBadge),
};

class BadgeDef {
  const BadgeDef(this.icon, this.label);
  final IconData icon;
  final String label;
}
