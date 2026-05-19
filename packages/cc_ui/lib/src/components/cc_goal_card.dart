import 'package:cc_ui/src/components/cc_badge.dart';
import 'package:cc_ui/src/components/cc_progress_bar.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// Lifecycle status of a goal. Drives the status badge tone on a [CcGoalCard].
enum CcGoalStatus {
  /// Actively being pursued.
  active,

  /// Reached its objective.
  complete,

  /// Stopped because the token budget ran out.
  budgetLimited,

  /// Temporarily set aside.
  paused,

  /// Abandoned.
  dropped,
}

/// Compact count label: `999`, `1.5K`, `25K`, `1.5M`, `2B`.
String formatCompactCount(num n) {
  if (n < 1000) return '${n.round()}';
  String scaled(double v) {
    final s = v < 10 ? v.toStringAsFixed(1) : '${v.round()}';
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  if (n < 1000000) return '${scaled(n / 1000)}K';
  if (n < 1000000000) return '${scaled(n / 1000000)}M';
  return '${scaled(n / 1000000000)}B';
}

/// Coarse duration label from a [Duration]: `45s`, `12m`, `3h`, `2d`.
String formatCoarseDuration(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  if (s < 60) return '${s}s';
  final m = (s / 60).round();
  if (m < 60) return '${m}m';
  final h = (m / 60).round();
  if (h < 48) return '${h}h';
  return '${(h / 24).round()}d';
}

/// A goal card: an [objective], a status badge, an optional token-budget
/// progress bar and optional elapsed time — the structured "what is this run
/// trying to achieve and how far through its budget is it" surface for CC's
/// plan/review/orchestrate modes.
class CcGoalCard extends StatelessWidget {
  /// Creates a [CcGoalCard].
  const CcGoalCard({
    super.key,
    required this.objective,
    required this.status,
    required this.statusLabel,
    this.tokensUsed,
    this.tokenBudget,
    this.elapsed,
    this.tokensLabel,
    this.elapsedLabel,
  });

  /// The objective text.
  final String objective;

  /// Lifecycle status driving the badge tone.
  final CcGoalStatus status;

  /// Localized status label shown in the badge.
  final String statusLabel;

  /// Tokens consumed so far, if tracked.
  final int? tokensUsed;

  /// The token budget ceiling, if any.
  final int? tokenBudget;

  /// Elapsed wall-clock, if tracked.
  final Duration? elapsed;

  /// Localized "Tokens" caption (defaults to "Tokens").
  final String? tokensLabel;

  /// Localized "Elapsed" caption (defaults to "Elapsed").
  final String? elapsedLabel;

  CcBadgeVariant get _badgeVariant => switch (status) {
    CcGoalStatus.complete => CcBadgeVariant.success,
    CcGoalStatus.budgetLimited => CcBadgeVariant.warning,
    CcGoalStatus.active => CcBadgeVariant.info,
    CcGoalStatus.paused || CcGoalStatus.dropped => CcBadgeVariant.neutral,
  };

  String _tokensLine() {
    final used = formatCompactCount(tokensUsed ?? 0);
    if (tokenBudget == null) return '$used tokens';
    final left = (tokenBudget! - (tokensUsed ?? 0)).clamp(0, tokenBudget!);
    return '$used / ${formatCompactCount(tokenBudget!)} tokens '
        '(${formatCompactCount(left)} left)';
  }

  double? get _budgetFraction {
    if (tokenBudget == null || tokenBudget == 0) return null;
    return ((tokensUsed ?? 0) / tokenBudget!).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final showTokens = tokensUsed != null || tokenBudget != null;

    return Container(
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: t.borderSecondary),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  objective,
                  style: CcTypography.title.copyWith(color: t.textPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CcBadge(label: statusLabel, variant: _badgeVariant),
            ],
          ),
          if (showTokens) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              (tokensLabel ?? 'Tokens').toUpperCase(),
              style: CcTypography.caption.copyWith(
                color: t.textQuaternary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            CcProgressBar(value: _budgetFraction, semanticLabel: _tokensLine()),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _tokensLine(),
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
          ],
          if (elapsed != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${elapsedLabel ?? 'Elapsed'} · ${formatCoarseDuration(elapsed!)}',
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
