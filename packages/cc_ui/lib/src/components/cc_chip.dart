import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// Compact bordered chip (Material `Chip` replacement). Pick one interaction:
/// [onDeleted] (dismiss), [onPressed]+[selected] (toggle), or [onPressed] alone
/// (in-place disclose — not navigation). [disabled] mutes body and delete.
/// Long [label] truncates with tooltip.
///
/// The body and the delete button are separate, side-by-side controls inside
/// one bordered chip, so each is its own Tab stop and screen-reader node.
class CcChip extends StatefulWidget {
  /// Creates a [CcChip].
  const CcChip({
    super.key,
    required this.label,
    this.leadingIcon,
    this.onPressed,
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

  /// Tap handler for the chip body. When null the body is non-interactive
  /// (the delete button from [onDeleted] still is).
  final VoidCallback? onPressed;

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

  @override
  State<CcChip> createState() => _CcChipState();
}

class _CcChipState extends State<CcChip> {
  /// The body's interaction states; its press washes the whole chip.
  final WidgetStatesController _bodyStates = WidgetStatesController();
  bool _pressed = false;

  /// Whether the pointer is anywhere over the chip, delete button included.
  bool _hovered = false;

  bool get _interactive => widget.onPressed != null && !widget.disabled;

  @override
  void initState() {
    super.initState();
    _bodyStates.addListener(_onBodyStates);
  }

  @override
  void dispose() {
    _bodyStates
      ..removeListener(_onBodyStates)
      ..dispose();
    super.dispose();
  }

  // Only a press repaints the chip. The tappable also writes its disabled
  // state here while it builds, which must not rebuild this chip mid-build.
  void _onBodyStates() {
    final pressed = _bodyStates.value.contains(WidgetState.pressed);
    if (pressed != _pressed) {
      setState(() => _pressed = pressed);
    }
  }

  void _setHovered(bool hovered) {
    if (hovered != _hovered) {
      setState(() => _hovered = hovered);
    }
  }

  Color _background(DesignSystemTokens t) {
    final selected = widget.selected && !widget.disabled;
    if (_interactive) {
      if (_pressed) {
        return Color.alphaBlend(t.hoverStrong, t.surface);
      }
      if (_hovered && !selected) {
        return Color.alphaBlend(t.hover, t.surface);
      }
    }
    return selected ? t.accentSoft : t.surface;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final disabled = widget.disabled;
    final selected = widget.selected;
    final fg = disabled
        ? t.textDisabled
        : (selected ? t.accent : t.textSecondary);
    final border = disabled
        ? t.borderDisabled
        : (selected ? t.borderBrand : t.borderSecondary);
    final deletable = widget.onDeleted != null;

    Widget body = Padding(
      // With a delete button, its own 24px box supplies the gap after the
      // label and the trailing inset.
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.sm,
        AppSpacing.xs,
        deletable ? 0 : AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.leadingIcon != null) ...[
            Icon(widget.leadingIcon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: CcTruncatedText(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: CcTypography.regularWeight,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
    if (widget.onPressed != null) {
      final content = body;
      body = CcTappable(
        onPressed: disabled ? null : widget.onPressed,
        statesController: _bodyStates,
        borderRadius: AppRadii.brSm,
        semanticLabel: widget.semanticLabel,
        semanticSelected: selected ? true : null,
        builder: (context, states) => widget.semanticLabel == null
            ? content
            : ExcludeSemantics(child: content),
      );
    } else if (disabled && !deletable) {
      body = Semantics(container: true, enabled: false, child: body);
    }

    Widget chip = AnimatedContainer(
      duration: CcMotion.resolveFade(context, CcMotion.fast),
      curve: CcMotion.standard,
      decoration: BoxDecoration(
        color: _background(t),
        borderRadius: AppRadii.brSm,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: body),
          if (deletable)
            _DeleteButton(
              icon: widget.deleteIcon,
              color: fg,
              onPressed: disabled ? null : widget.onDeleted,
              label: widget.label,
            ),
        ],
      ),
    );
    if (_interactive) {
      chip = MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: chip,
      );
    }
    return chip;
  }
}

/// The trailing delete affordance for a [CcChip]: its own tappable beside the
/// body. The 24px box is the pointer target and the focus ring's box; the
/// glyph inside stays 16px.
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
      semanticLabel: context.ccStrings.remove(label),
      builder: (context, states) => SizedBox.square(
        // 4px gap after the label + the 16px glyph + 4px trailing inset: the
        // same footprint the glyph and its spacing always had.
        dimension: 24,
        child: Center(
          child: ExcludeSemantics(
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
      ),
    );
  }
}
