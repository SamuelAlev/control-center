import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// The semantic intent of a [CcBadge].
enum CcBadgeVariant {
  /// Quiet, default state — secondary fill, tertiary text.
  neutral,

  /// Brand-tinted.
  brand,

  /// Positive / completed.
  success,

  /// Caution.
  warning,

  /// Error / blocking.
  danger,

  /// Informational — uses the brand tint with a distinct shape cue.
  info,
}

/// A small status pill — a soft-tinted capsule carrying a short label and an
/// optional leading [icon].
///
/// Status is conveyed by tint *and* the label text (and shape cue), never color
/// alone, per the accessibility bar in DESIGN.md.
class CcBadge extends StatelessWidget {
  /// Creates a [CcBadge] from a text [label].
  const CcBadge({
    super.key,
    required this.label,
    this.variant = CcBadgeVariant.neutral,
    this.icon,
  });

  /// The badge's text.
  final String label;

  /// The semantic variant driving the tint.
  final CcBadgeVariant variant;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final colors = _resolve(t);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: colors.fg),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: CcTypography.label.copyWith(color: colors.fg),
            ),
          ],
        ),
      ),
    );
  }

  _BadgeColors _resolve(DesignSystemTokens t) {
    switch (variant) {
      case CcBadgeVariant.neutral:
        return _BadgeColors(bg: t.bgSecondary, fg: t.textTertiary);
      case CcBadgeVariant.brand:
        return _BadgeColors(bg: t.bgBrandPrimary, fg: t.textBrandPrimary);
      case CcBadgeVariant.success:
        return _BadgeColors(bg: t.successSoft, fg: t.success);
      case CcBadgeVariant.warning:
        return _BadgeColors(bg: t.warnSoft, fg: t.warn);
      case CcBadgeVariant.danger:
        return _BadgeColors(bg: t.dangerSoft, fg: t.danger);
      case CcBadgeVariant.info:
        return _BadgeColors(bg: t.accentSoft, fg: t.accent);
    }
  }
}

class _BadgeColors {
  const _BadgeColors({required this.bg, required this.fg});

  final Color bg;
  final Color fg;
}
