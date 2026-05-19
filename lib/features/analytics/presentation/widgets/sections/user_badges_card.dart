import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/analytics/domain/entities/user_badge.dart';
import 'package:control_center/features/analytics/presentation/utils/badge_icon_resolver.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A card showing the user's earned badges with tier medals and progress
/// indicators, supporting tap-to-detail dialogs.
class UserBadgesCard extends ConsumerWidget {
  /// Creates the badges card widget.
  const UserBadgesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(userBadgesProvider);
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      label: l10n.yourAchievements,
      title: Text(l10n.earnTiersDescription),
      subtitle: Text(l10n.tapBadgeToLevelUp),
      child: badges.when(
        loading: () =>
            const SizedBox(height: 120, child: Center(child: CcSpinner())),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(l10n.failedWithError('$e'))),
        ),
        data: (list) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 920
                  ? 5
                  : constraints.maxWidth >= 720
                  ? 4
                  : constraints.maxWidth >= 480
                  ? 3
                  : 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final b in list)
                    SizedBox(
                      width: (constraints.maxWidth - 12 * (cols - 1)) / cols,
                      child: _BadgeTile(badge: b),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});
  final UserBadge badge;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final tier = badge.tier;
    final isLocked = tier == BadgeTier.none;
    final tierColor = tier.color;
    final fg = tokens.textPrimary;
    final muted = tokens.textTertiary;
    final border = tokens.borderSecondary;
    final bg = tokens.bgSecondary;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showBadgeDetail(context, badge),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: tokens.bgPrimary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isLocked ? border : tierColor.withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _BadgeMedal(
                    iconName: badge.category.iconName,
                    tier: tier,
                    size: 40,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          badge.category.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLocked ? l10n.lockedLabel : tier.label,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: isLocked ? muted : tierColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: badge.progressToNext,
                  minHeight: 5,
                  backgroundColor: bg,
                  valueColor: AlwaysStoppedAnimation(
                    isLocked ? muted.withValues(alpha: 0.6) : tierColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _progressCopy(badge),
                style: TextStyle(fontSize: 12, color: muted, height: 1.45),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _progressCopy(UserBadge b) {
    final next = b.nextTier;
    if (next == null) {
      return 'Maxed out — Master tier earned.';
    }
    final remaining = b.countToNext;
    final unit = remaining == 1 ? b.category.unit : '${b.category.unit}s';
    return '$remaining more $unit to ${next.label}';
  }
}

class _BadgeMedal extends StatelessWidget {
  const _BadgeMedal({
    required this.iconName,
    required this.tier,
    required this.size,
  });

  final String iconName;
  final BadgeTier tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isLocked = tier == BadgeTier.none;
    final tierColor = tier.color;
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final lockedBg = tokens.bgTertiary;
    final lockedFg = tokens.textTertiary;

    final medal = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: isLocked
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tierColor.withValues(alpha: 0.28),
                  tierColor.withValues(alpha: 0.10),
                ],
              ),
        color: isLocked ? lockedBg : null,
        shape: BoxShape.circle,
        border: Border.all(
          color: isLocked
              ? tokens.borderSecondary
              : tierColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Icon(
        badgeIconData(iconName),
        size: size * 0.45,
        color: isLocked ? lockedFg : tierColor,
      ),
    );

    if (isLocked) {
      return medal;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          medal,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: tierColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tokens.bgPrimary, width: 1.2),
              ),
              child: Text(
                'L${tier.index0 + 1}',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: tokens.textWhite,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showBadgeDetail(BuildContext context, UserBadge badge) {
  return showCcDialog<void>(
    context: context,
    builder: (dialogCtx) => _BadgeDetailDialog(badge: badge),
  );
}

class _BadgeDetailDialog extends StatelessWidget {
  const _BadgeDetailDialog({required this.badge});
  final UserBadge badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final fg = tokens.textPrimary;
    final muted = tokens.textTertiary;
    final border = tokens.borderSecondary;
    final tier = badge.tier;
    final isLocked = tier == BadgeTier.none;
    final tierColor = tier.color;
    final next = badge.nextTier;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.bgPrimary,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: border, width: 1.0),
          boxShadow: AppShadows.golden,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.brLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: BoxDecoration(
                  gradient: isLocked
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tierColor.withValues(alpha: 0.10),
                            tierColor.withValues(alpha: 0.0),
                          ],
                        ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Column(
                  children: [
                    _BadgeMedal(
                      iconName: badge.category.iconName,
                      tier: tier,
                      size: 76,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      badge.category.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLocked ? l10n.notEarnedYet : l10n.tierLabel(tier.label),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isLocked ? muted : tierColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      badge.category.blurb,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: muted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const CcDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.progressLabel,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: muted,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${badge.count} ${badge.count == 1 ? badge.category.unit : '${badge.category.unit}s'}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: badge.progressToNext,
                        minHeight: 8,
                        backgroundColor: tokens.bgTertiary,
                        valueColor: AlwaysStoppedAnimation(
                          isLocked ? next!.color : tierColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (next == null)
                      Text(
                        'You\'ve reached the highest tier. Legend status.',
                        style: TextStyle(fontSize: 12, color: muted),
                      )
                    else
                      RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 12, color: muted),
                          children: [
                            TextSpan(
                              text: '${badge.countToNext} ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: fg,
                              ),
                            ),
                            TextSpan(
                              text: badge.countToNext == 1
                                  ? '${badge.category.unit} to '
                                  : '${badge.category.unit}s to ',
                            ),
                            TextSpan(
                              text: next.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: next.color,
                              ),
                            ),
                            const TextSpan(text: ' tier'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: Text(
                  'TIER LADDER',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: muted,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Column(
                  children: [
                    for (final t in const [
                      BadgeTier.beginner,
                      BadgeTier.intermediate,
                      BadgeTier.advanced,
                      BadgeTier.expert,
                      BadgeTier.master,
                    ])
                      _TierLadderRow(
                        tier: t,
                        threshold: badge.category.thresholdFor(t)!,
                        unit: badge.category.unit,
                        achieved:
                            badge.count >= badge.category.thresholdFor(t)!,
                        isCurrent: t == badge.tier,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '→ ${badge.category.action}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    CcButton(
                      variant: CcButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.close),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierLadderRow extends StatelessWidget {
  const _TierLadderRow({
    required this.tier,
    required this.threshold,
    required this.unit,
    required this.achieved,
    required this.isCurrent,
  });

  final BadgeTier tier;
  final int threshold;
  final String unit;
  final bool achieved;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final fg = tokens.textPrimary;
    final muted = tokens.textTertiary;
    final color = tier.color;
    final unitLabel = threshold == 1 ? unit : '${unit}s';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? color.withValues(alpha: 0.35) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            achieved ? LucideIcons.checkCheck : LucideIcons.circle,
            size: 16,
            color: achieved ? color : muted.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tier.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: achieved ? fg : muted,
              ),
            ),
          ),
          Text(
            '$threshold $unitLabel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: achieved ? color : muted,
            ),
          ),
        ],
      ),
    );
  }
}
