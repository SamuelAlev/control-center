import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A compact bordered chip — the cc_ui replacement for Material's `Chip`, and
/// the interactive tag of the design system.
///
/// Renders a [label] with an optional [leadingIcon] in a flat, hairline-bordered
/// box. The callbacks map to the tag interaction variants — pick one per chip
/// rather than stacking several behaviors on the same tag, which invites
/// accidental clicks:
///
/// * **Dismissible** — [onDeleted] adds a trailing `x` that removes the tag
///   (user-created labels, active filters).
/// * **Selectable** — [onTap] + [selected]: tapping anywhere toggles, and the
///   accent border/fill keeps the chosen state legible at a glance.
/// * **Operational** — [onTap] alone: tapping discloses related content in
///   place (a popover of overflow tags, a detail view). Never use a chip as a
///   link that navigates away from the current page — use a real link or
///   button for that.
///
/// Set [disabled] to render a muted, non-interactive chip (a "disabled"
/// tag state) — the body and any delete affordance both go inert. A long
/// [label] never wraps; it truncates with an ellipsis and discloses the full
/// text via tooltip.
class CcChip extends StatelessWidget {
  /// Creates a [CcChip].
  const CcChip({
    super.key,
    required this.label,
    this.leadingIcon,
    this.onTap,
    this.onDeleted,
    this.selected = false,
    this.disabled = false,
    this.deleteIcon,
    this.semanticLabel,
  });

  /// The chip's text.
  final String label;

  /// Optional leading icon.
  final IconData? leadingIcon;

  /// Tap handler for the whole chip. When null the chip is non-interactive
  /// (unless [onDeleted] provides its own button).
  final VoidCallback? onTap;

  /// When non-null, shows a trailing delete button that invokes this callback.
  final VoidCallback? onDeleted;

  /// Whether the chip is in the selected state.
  final bool selected;

  /// Whether the chip is disabled (muted, non-interactive).
  final bool disabled;

  /// The icon used for the delete affordance. Defaults to a small `x` glyph
  /// drawn without depending on an icon font; pass an [IconData] to override.
  final IconData? deleteIcon;

  /// Optional accessibility label override for the tappable chip.
  final String? semanticLabel;

  Color _background(DesignSystemTokens t, Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) {
      return Color.alphaBlend(t.hoverStrong, t.surface);
    }
    if (states.contains(WidgetState.hovered)) {
      return selected ? t.accentSoft : Color.alphaBlend(t.hover, t.surface);
    }
    return selected ? t.accentSoft : t.surface;
  }

  Widget _buildBody(DesignSystemTokens t, Color background) {
    final fg = disabled
        ? t.textDisabled
        : (selected ? t.accent : t.textSecondary);
    final border = disabled
        ? t.borderDisabled
        : (selected ? t.borderBrand : t.borderSecondary);

    return AnimatedContainer(
      duration: CcMotion.fast,
      curve: CcMotion.standard,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        onDeleted != null ? AppSpacing.xs : AppSpacing.sm,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: CcTruncatedText(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: CcTypography.regularWeight,
                color: fg,
              ),
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: AppSpacing.xs),
            _DeleteButton(
              icon: deleteIcon,
              color: fg,
              onPressed: disabled ? null : onDeleted!,
              label: label,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    // Disabled (or non-interactive) chips render a static body; the muted
    // colors come from [disabled] in [_buildBody].
    if (onTap == null || disabled) {
      return _buildBody(t, selected && !disabled ? t.accentSoft : t.surface);
    }

    return CcTappable(
      onPressed: onTap,
      borderRadius: AppRadii.brSm,
      semanticLabel: semanticLabel ?? label,
      builder: (context, states) => _buildBody(t, _background(t, states)),
    );
  }
}

/// The trailing delete affordance for a [CcChip] — its own tappable so the
/// `x` can be pressed independently of the chip body.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({
    required this.color,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brXs,
      semanticLabel: 'Remove $label',
      builder: (context, states) => SizedBox(
        width: 16,
        height: 16,
        child: Center(
          child: icon != null
              ? Icon(icon, size: 12, color: color)
              : Text(
                  '×', // multiplication sign — a clean x glyph.
                  style: TextStyle(
                    fontSize: 13,
                    height: 1,
                    fontWeight: CcTypography.regularWeight,
                    color: color,
                  ),
                ),
        ),
      ),
    );
  }
}
