import 'package:control_center/shared/widgets/window_drag_action_io.dart'
    if (dart.library.js_interop) 'package:control_center/shared/widgets/window_drag_action_web.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// [SystemMouseCursor.kind]s a window drag is still allowed to start
/// underneath.
///
/// The resolved cursor is the cheapest honest signal for "this pixel already
/// does something on press": every pressable surface in the app announces
/// itself with one (`CcTappable` sets [SystemMouseCursors.click], text fields
/// set `text`, resize handles set the resize cursors), so the title bar can
/// stand down without every call site opting out by hand.
///
/// The drag-affordance cursors are the exception — a grip handle exists *to* be
/// dragged (the soundscape mini player's) — and the busy cursors say "wait",
/// not "press me", so both keep the window drag. Matching on `kind` rather than
/// on the cursor objects is what lets this be a `const` set: [SystemMouseCursor]
/// defines `==` over `kind`, which disqualifies it from a const collection.
const Set<String> _dragThroughCursorKinds = {
  'basic',
  'none',
  'grab',
  'grabbing',
  'move',
  'allScroll',
  'wait',
  'progress',
};

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
///
/// **Pressable children are excluded automatically.** Before the recognizer
/// joins the arena it hit-tests the press point and resolves the cursor the way
/// `MouseTracker` does; anything outside [_dragThroughCursorKinds] — a button, a
/// breadcrumb link, a text field, a resize handle — rejects the pointer
/// outright, so the child's own tap still wins even if the press wanders past
/// the drag slop. Children therefore need no manual opt-out wrapper and the
/// same guard covers [enableDoubleClickMaximize] so double-clicking a button
/// never zooms the window.
class WindowDragArea extends StatefulWidget {
  /// Creates a [WindowDragArea] wrapping [child].
  const WindowDragArea({
    super.key,
    required this.child,
    this.enableDoubleClickMaximize = false,
  });

  /// The draggable content (fills the area that initiates the window move).
  final Widget child;

  /// When true, a double-click on the drag area toggles the native window
  /// between maximized and its previous size — the standard title-bar zoom
  /// gesture a borderless window otherwise loses. Off by default so floating
  /// HUD windows (focus pill, meeting toolbar, mini player) stay unaffected.
  final bool enableDoubleClickMaximize;

  /// Test seam standing in for the native window-move loop, which cannot run
  /// under `flutter_tester` (there is no OS window to move). Null in
  /// production, where [startWindowDrag] is called directly.
  @visibleForTesting
  static VoidCallback? debugOnStartDrag;

  /// Test seam standing in for the native maximize toggle. See
  /// [debugOnStartDrag].
  @visibleForTesting
  static VoidCallback? debugOnToggleMaximize;

  @override
  State<WindowDragArea> createState() => _WindowDragAreaState();
}

class _WindowDragAreaState extends State<WindowDragArea> {
  /// Whether a press at [globalPosition] should move the window rather than be
  /// left to whatever sits under it.
  ///
  /// Mirrors `MouseTracker`'s resolution: walk the hit-test path from the
  /// topmost render object down and take the first [RenderMouseRegion] that
  /// does not defer. With no opinion anywhere in the path the pixel is inert,
  /// and the window drag wins.
  bool _isDragAllowedAt(Offset globalPosition) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return true;
    }
    final result = BoxHitTestResult();
    box.hitTest(result, position: box.globalToLocal(globalPosition));
    for (final entry in result.path) {
      final target = entry.target;
      if (target is! RenderMouseRegion) {
        continue;
      }
      final cursor = target.cursor;
      if (cursor == MouseCursor.defer) {
        continue;
      }
      // A cursor the framework does not name (a custom one, or the
      // `uncontrolled` marker a platform view installs) is a live surface of
      // its own — leave the press to it.
      return cursor is SystemMouseCursor &&
          _dragThroughCursorKinds.contains(cursor.kind);
    }
    return true;
  }

  void _startDrag() =>
      (WindowDragArea.debugOnStartDrag ?? startWindowDrag).call();

  void _toggleMaximize() =>
      (WindowDragArea.debugOnToggleMaximize ?? toggleWindowMaximize).call();

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        _WindowMoveGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<_WindowMoveGestureRecognizer>(
              () => _WindowMoveGestureRecognizer(
                isDragAllowedAt: _isDragAllowedAt,
                debugOwner: this,
              ),
              (recognizer) => recognizer.onStart = (_) => _startDrag(),
            ),
        if (widget.enableDoubleClickMaximize)
          _WindowZoomGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                _WindowZoomGestureRecognizer
              >(
                () => _WindowZoomGestureRecognizer(
                  isDragAllowedAt: _isDragAllowedAt,
                  debugOwner: this,
                ),
                (recognizer) => recognizer.onDoubleTap = _toggleMaximize,
              ),
      },
      child: widget.child,
    );
  }
}

/// A pan recognizer that declines pointers landing on pressable content.
///
/// Rejecting in [isPointerAllowed] (rather than no-op'ing in `onStart`) keeps
/// the recognizer out of the gesture arena entirely, so a button's tap still
/// resolves after a jittery press instead of losing to a drag that then does
/// nothing.
class _WindowMoveGestureRecognizer extends PanGestureRecognizer {
  _WindowMoveGestureRecognizer({
    required this.isDragAllowedAt,
    super.debugOwner,
  });

  final bool Function(Offset globalPosition) isDragAllowedAt;

  @override
  bool isPointerAllowed(PointerEvent event) =>
      super.isPointerAllowed(event) && isDragAllowedAt(event.position);

  @override
  String get debugDescription => 'window move';
}

/// The double-click-to-zoom counterpart of [_WindowMoveGestureRecognizer].
class _WindowZoomGestureRecognizer extends DoubleTapGestureRecognizer {
  _WindowZoomGestureRecognizer({
    required this.isDragAllowedAt,
    super.debugOwner,
  });

  final bool Function(Offset globalPosition) isDragAllowedAt;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      super.isPointerAllowed(event) && isDragAllowedAt(event.position);

  @override
  String get debugDescription => 'window zoom';
}
