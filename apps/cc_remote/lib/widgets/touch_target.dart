import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// The phone accessibility floor for a tap target, from DESIGN.md
/// ("keyboard-first *and* touch-ergonomic (≥44px targets on phone)").
///
/// 44 is the number both platform HIGs converge on: it is roughly the width of
/// an adult fingertip, so anything smaller is a target you aim at rather than
/// press.
const double kMinTouchTarget = 44;

/// An icon button whose HIT AREA is never smaller than [kMinTouchTarget],
/// regardless of how small the icon it draws is.
///
/// Every icon-only control in this app was hand-rolled as
/// `CcTappable(builder: … Padding(all: 8) … Icon(size: 18))`, which is a 34pt
/// target — a tenth of an inch below the floor, in the back button of five
/// different screens. Padding alone cannot fix it without changing how the
/// chrome LOOKS, so the size lives here instead: the icon keeps its visual
/// size and inset, and the touch area is grown around it. That split is the
/// whole point — an accessible target and a dense-looking header are not in
/// conflict, they just need different boxes.
class PhoneIconButton extends StatelessWidget {
  /// Creates a [PhoneIconButton] drawing [icon].
  const PhoneIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.color,
    this.iconSize = 20,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  /// The glyph to draw.
  final IconData icon;

  /// Accessibility label — required, because an icon-only control has no
  /// other name.
  final String semanticLabel;

  /// Tap handler; null disables the button.
  final VoidCallback? onPressed;

  /// Icon color; defaults to the secondary foreground token.
  final Color? color;

  /// Visual icon size. Independent of the tap target.
  final double iconSize;

  /// Focus-ring radius.
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      borderRadius: borderRadius,
      builder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kMinTouchTarget,
          minHeight: kMinTouchTarget,
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Icon(icon, size: iconSize, color: color ?? tokens.fgSecondary),
        ),
      ),
    );
  }
}
