import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A compact bordered chip — the cc_ui replacement for Material's `Chip`.
///
/// Renders a [label] with an optional [leadingIcon] in a flat, hairline-bordered
/// box. Setting [onDeleted] adds a trailing delete affordance (an `x` button).
/// [onTap] makes the whole chip tappable; [selected] swaps the resting border
/// and fill for the accent treatment so a chosen filter/tag reads at a glance.
class CcChip extends StatelessWidget {
  /// Creates a [CcChip].
  const CcChip({
    super.key,
    required this.label,
    this.leadingIcon,
    this.onTap,
    this.onDeleted,
    this.selected = false,
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

  /// The icon used for the delete affordance. Defaults to a small `x` glyph
  /// drawn without depending on an icon font; pass an [IconData] to override.
  final IconData? deleteIcon;

  /// Whether the chip is in the selected state.
  final bool selected;

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
    final fg = selected ? t.accent : t.textSecondary;
    final border = selected ? t.borderBrand : t.borderSecondary;

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
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w400,
              color: fg,
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: AppSpacing.xs),
            _DeleteButton(
              icon: deleteIcon,
              color: fg,
              onPressed: onDeleted!,
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

    if (onTap == null) {
      return _buildBody(t, selected ? t.accentSoft : t.surface);
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
  final VoidCallback onPressed;
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
                    fontWeight: FontWeight.w400,
                    color: color,
                  ),
                ),
        ),
      ),
    );
  }
}
