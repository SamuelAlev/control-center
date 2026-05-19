import 'package:cc_ui/src/components/cc_button.dart';
import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A square, icon-only button sharing the [CcButtonVariant] color matrix.
///
/// Flat and ripple-free like [CcButton]: hover/press are color washes and the
/// pressed state nudges the icon 1px down. Defaults to the [CcButtonVariant.ghost]
/// treatment — the quiet variant used for toolbar and inline affordances.
class CcIconButton extends StatelessWidget {
  /// Creates a [CcIconButton].
  const CcIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = CcButtonVariant.ghost,
    this.size = CcButtonSize.md,
    this.color,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The icon to render (16px) centered in the box.
  final IconData icon;

  /// Tap handler. When null the button is disabled.
  final VoidCallback? onPressed;

  /// The color treatment (defaults to ghost).
  final CcButtonVariant variant;

  /// The box size — md is a 36px box, sm a 32px box.
  final CcButtonSize size;

  /// Optional icon-color override (e.g. to signal an active state). Ignored
  /// when the button is disabled. When null the variant foreground is used.
  final Color? color;

  /// Optional tooltip text. When set, the button is wrapped in a [CcTooltip]
  /// that appears on hover dwell.
  final String? tooltip;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus on mount.
  final bool autofocus;

  /// Accessibility label.
  final String? semanticLabel;

  CcButtonTokens _tokens(DesignSystemTokens t) {
    switch (variant) {
      case CcButtonVariant.primary:
        return CcButtonTokens.primary(t);
      case CcButtonVariant.secondary:
        return CcButtonTokens.secondary(t);
      case CcButtonVariant.accent:
        return CcButtonTokens.accent(t);
      case CcButtonVariant.line:
        return CcButtonTokens.line(t);
      case CcButtonVariant.ghost:
        return CcButtonTokens.ghost(t);
      case CcButtonVariant.destructive:
        return CcButtonTokens.destructive(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final tokens = _tokens(t);
    final box = size == CcButtonSize.md ? 36.0 : 32.0;
    final disabled = onPressed == null;

    final Widget button = CcTappable(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      borderRadius: AppRadii.brSm,
      focusRingColor: t.focusRing,
      semanticLabel: semanticLabel,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);

        final Color bg;
        final Color fg;
        final Color border;
        if (disabled) {
          bg = tokens.bg.a == 0
              ? tokens.bg
              : t.bgDisabled;
          fg = t.textDisabled;
          border = tokens.border.a == 0
              ? tokens.border
              : t.borderDisabled;
        } else if (pressed) {
          bg = tokens.bgPressed;
          fg = tokens.fg;
          border = tokens.borderHover;
        } else if (hovered) {
          bg = tokens.bgHover;
          fg = tokens.fg;
          border = tokens.borderHover;
        } else {
          bg = tokens.bg;
          fg = tokens.fg;
          border = tokens.border;
        }

        final iconColor = disabled ? fg : (color ?? fg);
        Widget content = Center(child: Icon(icon, size: 16, color: iconColor));
        content = AnimatedContainer(
          duration: CcMotion.resolve(context, CcMotion.fast),
          curve: CcMotion.standard,
          width: box,
          height: box,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.brSm,
            border: Border.all(color: border, width: 1),
          ),
          child: content,
        );

        if (pressed && !disabled) {
          content = Transform.translate(
            offset: const Offset(0, 1),
            child: content,
          );
        }

        return content;
      },
    );

    if (tooltip == null) {
      return button;
    }
    return CcTooltip(message: tooltip!, child: button);
  }
}
