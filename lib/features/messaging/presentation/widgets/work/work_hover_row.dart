import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A row whose trailing actions show while it is hovered or holds focus.
///
/// With no mouse (touch) the actions always show: touch never loses an action
/// to hover. A mouse once seen counts for the session and a desktop counts
/// from the start, because a desktop engine drops the pointer whenever the
/// app loses focus. Hidden means transparent, so Tab still reaches an action
/// (which then shows the row's actions) and a screen reader still finds it.
class WorkHoverRow extends StatefulWidget {
  /// Creates the row.
  const WorkHoverRow({super.key, required this.child, required this.actions});

  /// The row's content.
  final Widget child;

  /// The trailing actions, revealed on hover or focus.
  final List<Widget> actions;

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
  State<WorkHoverRow> createState() => _WorkHoverRowState();
}

class _WorkHoverRowState extends State<WorkHoverRow> {
  bool _hovered = false;
  bool _focusWithin = false;

  @override
  Widget build(BuildContext context) {
    final tracker = RendererBinding.instance.mouseTracker;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
        children: [
          Expanded(child: widget.child),
          if (widget.actions.isNotEmpty)
            Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onFocusChange: (f) => setState(() => _focusWithin = f),
              child: ListenableBuilder(
                listenable: tracker,
                builder: (context, child) => AnimatedOpacity(
                  opacity: _hovered || _focusWithin || !WorkHoverRow._canHover
                      ? 1
                      : 0,
                  duration: CcMotion.fast,
                  alwaysIncludeSemantics: true,
                  child: child,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.actions,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
