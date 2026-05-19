import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
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
/// A soft-tinted box with a matching hairline border, a leading status glyph,
/// a [title], an optional [description], an optional [action], and an optional
/// close control. Intent reads from the glyph, tint, and copy together — never
/// color alone (DESIGN.md accessibility bar). When [icon] is null a glyph
/// matching [variant] is used so the status marker is always present. Announced
/// to assistive tech as a live region. Uses the 2px control radius
/// (`AppRadii.brSm`).
class CcAlert extends StatelessWidget {
  /// Creates a [CcAlert] with a text [title].
  const CcAlert({
    super.key,
    required this.title,
    this.description,
    this.variant = CcAlertVariant.info,
    this.icon,
    this.action,
    this.onClose,
  });

  /// The banner's headline text.
  final String title;

  /// Optional supporting body below the title.
  final Widget? description;

  /// The semantic variant driving the tint and default glyph role.
  final CcAlertVariant variant;

  /// Leading status glyph. When null, a glyph matching [variant] is used so the
  /// status marker is always present (color is never the only signal).
  final IconData? icon;

  /// Optional actionable control rendered below the body ("actionable
  /// inline notification"). Callers pass a widget (typically a ghost
  /// [CcButton]).
  final Widget? action;

  /// Optional close handler. When set, a close (×) control renders at the
  /// top-right; inline notifications persist until the user dismisses them.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final colors = _resolve(t);
    final statusIcon = icon ?? _defaultIcon(variant);

    return Semantics(
      container: true,
      liveRegion: true,
      label: title,
      child: DecoratedBox(
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
              Icon(statusIcon, size: 16, color: colors.fg),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: CcTypography.bodySm.copyWith(
                              color: t.textPrimary,
                            ),
                          ),
                        ),
                        if (onClose != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _AlertCloseButton(
                            onClose: onClose!,
                            color: t.textTertiary,
                          ),
                        ],
                      ],
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
                    if (action != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      DefaultTextStyle.merge(
                        style: CcTypography.bodySm.copyWith(
                          color: t.textPrimary,
                        ),
                        child: action!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _defaultIcon(CcAlertVariant v) {
    switch (v) {
      case CcAlertVariant.info:
        return CcIcons.info;
      case CcAlertVariant.success:
        return CcIcons.circleCheck;
      case CcAlertVariant.warning:
        return CcIcons.triangleAlert;
      case CcAlertVariant.danger:
        return CcIcons.circleX;
    }
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
        return _AlertColors(bg: t.warnSoft, border: t.warn, fg: t.warn);
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

/// The small dismiss control for an inline [CcAlert].
class _AlertCloseButton extends StatelessWidget {
  const _AlertCloseButton({required this.onClose, required this.color});

  final VoidCallback onClose;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CcTappable(
      onPressed: onClose,
      semanticLabel: 'Close',
      borderRadius: AppRadii.brSm,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            CcIcons.x,
            size: 14,
            color: hovered ? color : color.withValues(alpha: 0.8),
          ),
        );
      },
    );
  }
}
