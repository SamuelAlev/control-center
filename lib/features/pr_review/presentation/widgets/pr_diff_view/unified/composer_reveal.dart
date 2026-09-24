/// @docImport 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_measurement.dart';
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_measurement.dart' show HeightReporter;
import 'package:flutter/widgets.dart';

/// Grows an inline comment composer out of the diff row it is anchored to.
///
/// The child is laid out at its full height on every frame so a
/// [HeightReporter] above or below can measure the settled size. What changes
/// is the visible slice: the box opens downward and the text fades in ahead of
/// the height, so the field is readable before the motion finishes.
///
/// Reduced motion skips the travel and keeps a short opacity fade. At rest the
/// clip is dropped so the composer's shadow can extend past the card.
class ComposerReveal extends StatelessWidget {
  /// Creates a reveal driven by [animation] (0 collapsed, 1 settled).
  const ComposerReveal({
    super.key,
    required this.animation,
    required this.reducedMotion,
    required this.child,
  });

  /// Curved reveal progress. 0 is closed, 1 is fully open.
  final Animation<double> animation;

  /// When true, the box is full size immediately and only the opacity moves.
  final bool reducedMotion;

  /// The composer, measured at its natural height.
  final Widget child;

  static const Interval _fade = Interval(0, 0.62, curve: CcMotion.standard);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0);
        if (t >= 1) {
          return child!;
        }
        final opacity = reducedMotion ? t : _fade.transform(t);
        final revealed = Opacity(opacity: opacity, child: child);
        if (reducedMotion) {
          return revealed;
        }
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: t,
            child: revealed,
          ),
        );
      },
      child: child,
    );
  }
}
