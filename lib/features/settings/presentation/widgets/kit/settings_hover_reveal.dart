import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Shows [child] only while its row is hovered or focused.
///
/// On a client with no mouse there is no hover to wait for, so the child stays
/// visible: touch must never lose an action to this. Hidden means transparent,
/// not absent, so Tab still lands on the child, which then keeps itself
/// visible, and a screen reader still finds it.
///
/// "No mouse" can't be read off `mouseIsConnected` alone: a desktop engine
/// removes the pointer whenever the app loses focus, which would flash every
/// action on the page. So a mouse, once seen, counts for the whole session, and
/// a desktop counts from the start.
class SettingsHoverReveal extends StatefulWidget {
  /// Creates a [SettingsHoverReveal].
  const SettingsHoverReveal({
    super.key,
    required this.active,
    required this.child,
  });

  /// Whether the row is hovered or focused.
  final bool active;

  /// The row's actions.
  final Widget child;

  static bool _mouseSeen = false;

  /// Forgets any mouse seen so far, so tests don't leak into each other.
  @visibleForTesting
  static void debugForgetMouse() => _mouseSeen = false;

  static bool get _canHover {
    if (RendererBinding.instance.mouseTracker.mouseIsConnected) {
      _mouseSeen = true;
    }
    return _mouseSeen ||
        switch (defaultTargetPlatform) {
          TargetPlatform.macOS ||
          TargetPlatform.linux ||
          TargetPlatform.windows => true,
          TargetPlatform.android ||
          TargetPlatform.fuchsia ||
          TargetPlatform.iOS => false,
        };
  }

  @override
  State<SettingsHoverReveal> createState() => _SettingsHoverRevealState();
}

class _SettingsHoverRevealState extends State<SettingsHoverReveal> {
  bool _focusWithin = false;

  @override
  Widget build(BuildContext context) {
    final tracker = RendererBinding.instance.mouseTracker;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focusWithin = focused),
      child: ListenableBuilder(
        listenable: tracker,
        builder: (context, child) => AnimatedOpacity(
          opacity:
              widget.active || _focusWithin || !SettingsHoverReveal._canHover
              ? 1
              : 0,
          duration: CcMotion.fast,
          alwaysIncludeSemantics: true,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
