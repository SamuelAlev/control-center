import 'package:flutter/widgets.dart';

/// Tracks whether the pointer is over [builder]'s subtree OR keyboard focus is
/// inside it, and rebuilds with that as `revealed`.
///
/// For the hover-revealed affordances on the PR page (edit pencils, remove
/// buttons, "View logs"): a control that only exists under the mouse cannot be
/// reached with Tab or by a screen reader. Keep the control mounted and
/// focusable at all times, and paint it with [HoverFocusReveal.fade] so it
/// shows on hover and the moment Tab lands on it.
class HoverFocusReveal extends StatefulWidget {
  /// Creates a [HoverFocusReveal].
  const HoverFocusReveal({super.key, required this.builder});

  /// Builds the region; `revealed` is true while hovered or focused within.
  final Widget Function(BuildContext context, bool revealed) builder;

  /// Paints [child] only while [revealed], keeping it hit-testable, focusable
  /// and in the semantics tree while transparent — it sits inside the hover
  /// region, so a pointer over it has already revealed it.
  static Widget fade({required bool revealed, required Widget child}) {
    return Opacity(
      opacity: revealed ? 1 : 0,
      alwaysIncludeSemantics: true,
      child: child,
    );
  }

  @override
  State<HoverFocusReveal> createState() => _HoverFocusRevealState();
}

class _HoverFocusRevealState extends State<HoverFocusReveal> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: widget.builder(context, _hovered || _focused),
      ),
    );
  }
}
