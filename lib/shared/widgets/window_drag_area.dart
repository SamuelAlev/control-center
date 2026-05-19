import 'package:control_center/shared/widgets/window_drag_action_io.dart'
    if (dart.library.js_interop) 'package:control_center/shared/widgets/window_drag_action_web.dart';
import 'package:flutter/widgets.dart';

/// Lets the user move the native OS window by pressing anywhere on [child] and
/// dragging — used by the custom title bar, the sidebar's traffic-light strip,
/// and the floating HUD windows.
///
/// Replaces `window_manager`'s `DragToMoveArea`. On pan start it kicks off the
/// platform's window-move loop on the focused window via the [startWindowDrag]
/// seam (nativeapi on desktop, a no-op on web). Like the old widget it sits
/// *inside* any pointer
/// [Listener]-based gestures (e.g. the meeting toolbar's hold-to-stop), which
/// keep receiving events because a raw [Listener] does not compete in the
/// gesture arena — the pan only wins once it crosses the slop threshold.
class WindowDragArea extends StatelessWidget {
  /// Creates a [WindowDragArea] wrapping [child].
  const WindowDragArea({super.key, required this.child});

  /// The draggable content (fills the area that initiates the window move).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => startWindowDrag(),
      child: child,
    );
  }
}
