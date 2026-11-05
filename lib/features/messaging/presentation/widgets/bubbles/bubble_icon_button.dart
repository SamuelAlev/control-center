import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A 22px icon action under a message: the hover rail's entries and the agent
/// turn's feedback thumbs. They all answer the pointer alike, with a ghost wash
/// behind a brightened glyph.
class BubbleIconButton extends StatelessWidget {
  /// Creates a [BubbleIconButton].
  const BubbleIconButton({
    required this.icon,
    required this.onTap,
    required this.tokens,
    super.key,
    this.tooltip,
    this.restColor,
    this.activeColor,
  });

  /// The glyph, drawn at 14px.
  final IconData icon;

  /// Tap handler.
  final VoidCallback onTap;

  /// The design tokens to paint with.
  final DesignSystemTokens tokens;

  /// Tooltip text, also used as the accessible name.
  final String? tooltip;

  /// Glyph color at rest; defaults to `fgTertiary`.
  final Color? restColor;

  /// When non-null the action is on: the glyph holds this color, hovered or
  /// not.
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final ghost = CcButtonTokens.ghost(tokens);
    final button = CcTappable(
      onPressed: onTap,
      borderRadius: AppRadii.brSm,
      semanticLabel: tooltip,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        return AnimatedContainer(
          duration: CcMotion.resolveFade(context, CcMotion.fast),
          curve: CcMotion.standard,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: pressed
                ? ghost.bgPressed
                : hovered
                ? ghost.bgHover
                : ghost.bg,
            borderRadius: AppRadii.brSm,
          ),
          child: Icon(
            icon,
            size: 14,
            color:
                activeColor ??
                (hovered ? tokens.fg : restColor ?? tokens.fgTertiary),
          ),
        );
      },
    );
    final label = tooltip;
    if (label == null) {
      return button;
    }
    return CcTooltip(message: label, child: button);
  }
}
