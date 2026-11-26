import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:flutter/widgets.dart';

/// The ghost hover and press wash an overlay trigger paints under an inert
/// target (a badge, a label), so the target reads as something to press.
///
/// The wash is painted over [child], not behind it: an opaque target (a chip
/// with a solid fill) would cover a wash underneath and show no feedback.
class CcTriggerWash extends StatelessWidget {
  /// Creates a [CcTriggerWash] for the trigger's current [states].
  const CcTriggerWash({super.key, required this.states, required this.child});

  /// The trigger's interaction states, from its tappable's builder.
  final Set<WidgetState> states;

  /// The inert target.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final pressed = states.contains(WidgetState.pressed);
    final hovered = states.contains(WidgetState.hovered);
    // Alpha-0 at rest (not transparent black) so the wash lerps only alpha,
    // the same way a ghost button does.
    final wash = pressed
        ? t.hoverStrong
        : hovered
        ? t.hover
        : t.hover.withValues(alpha: 0);
    return AnimatedContainer(
      duration: CcMotion.resolveFade(context, CcMotion.fast),
      curve: CcMotion.standard,
      foregroundDecoration: BoxDecoration(
        color: wash,
        borderRadius: AppRadii.brSm,
      ),
      child: child,
    );
  }
}
