import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// The semantic intent of a [CcAlert].
enum CcAlertVariant {
  /// Neutral informational message — brand tint.
  info,

  /// Positive outcome.
  success,

  /// Caution.
  warning,

  /// Error / failure.
  danger,
}

/// An inline banner that surfaces a status message in flow.
///
/// A soft-tinted box with a matching hairline border, a leading status [icon],
/// a [title], and an optional [description]. Intent reads from the icon, tint,
/// and copy together — never color alone (DESIGN.md accessibility bar). Uses the
/// 2px control radius (`AppRadii.brSm`).
class CcAlert extends StatelessWidget {
  /// Creates a [CcAlert] with a text [title].
  const CcAlert({
    super.key,
    required this.title,
    this.description,
    this.variant = CcAlertVariant.info,
    this.icon,
  });

  /// The banner's headline text.
  final String title;

  /// Optional supporting body below the title.
  final Widget? description;

  /// The semantic variant driving the tint and default icon role.
  final CcAlertVariant variant;

  /// Leading icon; callers typically pass a lucide glyph matching [variant].
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final colors = _resolve(t);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: colors.fg),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    DefaultTextStyle.merge(
                      style: CcTypography.caption.copyWith(
                        color: t.textSecondary,
                      ),
                      child: description!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _AlertColors _resolve(DesignSystemTokens t) {
    switch (variant) {
      case CcAlertVariant.info:
        return _AlertColors(
          bg: t.accentSoft,
          border: t.borderBrand,
          fg: t.accent,
        );
      case CcAlertVariant.success:
        return _AlertColors(
          bg: t.successSoft,
          border: t.success,
          fg: t.success,
        );
      case CcAlertVariant.warning:
        return _AlertColors(
          bg: t.warnSoft,
          border: t.warn,
          fg: t.warn,
        );
      case CcAlertVariant.danger:
        return _AlertColors(
          bg: t.dangerSoft,
          border: t.borderError,
          fg: t.danger,
        );
    }
  }
}

class _AlertColors {
  const _AlertColors({
    required this.bg,
    required this.border,
    required this.fg,
  });

  final Color bg;
  final Color border;
  final Color fg;
}
