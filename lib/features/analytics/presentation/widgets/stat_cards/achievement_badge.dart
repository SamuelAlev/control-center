import 'package:cc_domain/features/analytics/domain/entities/achievement.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';

/// A stat card showing an achievement badge icon with an unlock indicator.
/// The badge renders in a muted state when locked and in primary color when
/// unlocked.
class AchievementBadge extends StatelessWidget {
/// Constructs the badge with an optional [Achievement] record, icon, label,
/// and unlock state.
  const AchievementBadge({
    super.key,
    required this.achievement,
    required this.icon,
    required this.label,
    this.isUnlocked = false,
  });

/// The achievement record, if unlocked; `null` when locked.
  final Achievement? achievement;
/// Icon representing the achievement category.
  final IconData icon;
/// Short label for the badge.
  final String label;
/// Whether the achievement has been unlocked by the current user.
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

/// Returns a map of badge keys to their definitions, resolved with
/// localized labels from [AppLocalizations].
Map<String, BadgeDef> badgeDefinitions(AppLocalizations l10n) => <String, BadgeDef>{
  'first_run': const BadgeDef(AppIcons.play, 'First run'),
  'first_pr': const BadgeDef(AppIcons.gitPullRequest, 'First PR'),
  'first_merge': const BadgeDef(AppIcons.rocket, 'First merge'),
  'first_review': BadgeDef(AppIcons.messageSquareText, l10n.firstReviewBadge),
  'centurion': BadgeDef(AppIcons.medal, l10n.centurionBadge),
  'pr_machine': BadgeDef(AppIcons.factory, l10n.prMachineBadge),
  'merge_master': BadgeDef(AppIcons.gitMerge, l10n.mergeMasterBadge),
  'sharpshooter': BadgeDef(AppIcons.crosshair, l10n.sharpshooterBadge),
  'hot_streak': BadgeDef(AppIcons.flame, l10n.hotStreakBadge),
  'all_star': BadgeDef(AppIcons.sparkles, l10n.allStarBadge),
  'flawless': BadgeDef(AppIcons.wand, l10n.flawlessBadge),
  'perfectionist': BadgeDef(AppIcons.gem, l10n.perfectionistBadge),
};

/// A simple data class pairing an icon with a label for badge rendering.
class BadgeDef {
/// Creates a badge definition with an icon and label.
  const BadgeDef(this.icon, this.label);
/// The icon representing this badge.
  final IconData icon;
/// The display label for this badge.
  final String label;
}
