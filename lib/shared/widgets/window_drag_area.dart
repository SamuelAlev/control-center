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

/// Semantic roles that mean "this pixel does something when you press it".
///
/// The cursor alone is not enough: a **disabled** control paints
/// [SystemMouseCursors.basic], which is indistinguishable from inert chrome, so
/// the title bar's greyed-out back button used to move the window on the
/// slightest wobble of a click. A control keeps its semantic role while
/// disabled, so the role is what the guard asks about — a button is a button
/// whether or not it currently accepts the press.
/// Whether [target] subscribed to the press itself.
///
/// The cursor and the semantic role between them catch every control that
/// *announces* itself. A bare `GestureDetector` or `Listener` announces
/// nothing: no `MouseRegion`, and for a raw `Listener` no semantics either.
/// That is not a hypothetical shape here — a popover/menu target is
/// deliberately built that way (the target stays inert as a control so the
/// popover owns the toggle), and the presence rail, the notification bell and
/// the usage pill in the title bar are all popovers. Under the old guard the
/// window happily dragged out from under them on the slightest wobble.
///
/// Subscribing to pointer-down, or announcing a tap/long-press/drag gesture,
/// is a claim on the press whatever the pixel looks like.
bool _handlesPress(RenderObject target) {
  if (target is RenderPointerListener) {
    return target.onPointerDown != null ||
        target.onPointerUp != null ||
        target.onPointerSignal != null;
  }
  if (target is RenderSemanticsGestureHandler) {
    return target.onTap != null ||
        target.onLongPress != null ||
        target.onHorizontalDragUpdate != null ||
        target.onVerticalDragUpdate != null;
  }
  return false;
}

bool _declaresPressableRole(SemanticsProperties p) =>
    (p.button ?? false) ||
    (p.link ?? false) ||
    (p.textField ?? false) ||
    (p.slider ?? false) ||
    p.checked != null ||
    p.toggled != null ||
    p.onTap != null ||
    p.onLongPress != null;

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
/// joins the arena it hit-tests the press point (through the child subtree, not
/// through this widget's own gesture plumbing) and asks three questions of the
/// path. Does anything on it resolve a cursor outside
/// [_dragThroughCursorKinds] the way `MouseTracker` would (a button, a
/// breadcrumb link, a text field, a resize handle)? Does anything declare a
/// pressable *semantic role* ([_declaresPressableRole]) — which is what catches
/// a control that is merely disabled? And does anything simply subscribe to the
/// press ([_handlesPress]) — which is what catches a bare `GestureDetector` or
/// `Listener`, the shape every popover/menu target in this app takes, since
/// those announce neither a cursor nor a role? Any one of the three rejects the
/// pointer outright, so the child's own tap still wins even if the press
/// wanders past the drag slop. Children therefore need no manual opt-out
/// wrapper and the same guard covers [enableDoubleClickMaximize] so
/// double-clicking a button never zooms the window.
///
/// **Only a press-and-drag moves the window.** Trackpad pan/zoom pointers are
/// refused wholesale ([_WindowMoveGestureRecognizer.isPointerPanZoomAllowed]):
/// they arrive from two-finger scrolling, never from a click, and they bypass
/// `isPointerAllowed` entirely — so without that refusal a scroll anywhere over
/// the title bar dragged the whole window, pressable child or not.
class WindowDragArea extends StatefulWidget {
  /// Creates a [WindowDragArea] wrapping [child].
  const WindowDragArea({
    super.key,
    required this.child,
    this.enableDoubleClickMaximize = false,
    this.moveWindowManually = false,
  });

  /// The draggable content (fills the area that initiates the window move).
  final Widget child;

  /// When true, a double-click on the drag area toggles the native window
  /// between maximized and its previous size — the standard title-bar zoom
  /// gesture a borderless window otherwise loses. Off by default so floating
  /// HUD windows (focus pill, meeting toolbar, mini player) stay unaffected.
  final bool enableDoubleClickMaximize;

  /// Whether this area repositions the window itself as the pointer moves,
  /// instead of relying on the platform's own drag loop.
  ///
  /// The primary window is `isMovable = false` (see `styleWindowOnShow`),
  /// because that is the only switch that stops macOS starting its own drag
  /// from the titlebar strip our title bar draws into — and it disables
  /// `performWindowDragWithEvent:` along with it. So the title bar moves the
  /// window itself. The floating HUDs have no titlebar to be dragged from and
  /// stay system-movable, which is the smoother path (it participates in space
  /// switching and snapping), so they leave this off.
  ///
  /// The move targets an absolute position, never an accumulation: each update
  /// reads the OS cursor's CURRENT screen position — not the pointer event's
  /// window-local position — and places the window so the grabbed pixel lands
  /// under it. Event positions are measured against the window's own origin, a
  /// frame this very code keeps moving; events still in flight when a move
  /// lands therefore report stale coordinates, and correcting from a stale
  /// event re-applied displacement the window had already absorbed while the
  /// next fresh event pulled it back — an oscillation whose amplitude grew
  /// with drag speed, i.e. the window shook. A target derived from cursor
  /// state is idempotent and monotone with the pointer, and when the system
  /// IS moving the window the grabbed pixel is already under the cursor, so
  /// the target equals the current position and nothing double-moves.
  final bool moveWindowManually;

  /// Test seam standing in for the native window-move loop, which cannot run
  /// under `flutter_tester` (there is no OS window to move). Null in
  /// production, where [startWindowDrag] is called directly.
  @visibleForTesting
  static VoidCallback? debugOnStartDrag;

  /// Test seam standing in for the native cursor read, which touches OS
  /// state `flutter_tester` has none of. Null in production, where
  /// [windowCursorPosition] is called directly.
  @visibleForTesting
  static Offset Function()? debugCursorPosition;

  /// Test seam standing in for the native window placement. See
  /// [debugOnStartDrag].
  @visibleForTesting
  static ValueChanged<Offset>? debugOnMoveTo;

  /// Test seam standing in for the native maximize toggle. See
  /// [debugOnStartDrag].
  @visibleForTesting
  static VoidCallback? debugOnToggleMaximize;

  @override
  State<WindowDragArea> createState() => _WindowDragAreaState();
}

class _WindowDragAreaState extends State<WindowDragArea> {
  /// Anchors the hit test to the child subtree, below this widget's own
  /// gesture plumbing.
  final GlobalKey _childKey = GlobalKey();

  /// Whether a press at [globalPosition] should move the window rather than be
  /// left to whatever sits under it.
  ///
  /// Walks the hit-test path from the topmost render object down. A
  /// [RenderMouseRegion] resolving a cursor outside [_dragThroughCursorKinds]
  /// vetoes the drag the way `MouseTracker` would resolve it, and so does any
  /// node declaring a pressable semantic role. An *allow-listed* cursor is
  /// deliberately NOT the last word: `basic` is what a disabled control paints,
  /// and `CcTappable` puts its `Semantics` wrapper above its `MouseRegion`, so
  /// the scan has to keep going to find the veto rather than stopping at the
  /// first opinionated cursor. With nothing on the whole path claiming the
  /// press, the pixel is inert and the window drag wins.
  bool _isDragAllowedAt(Offset globalPosition) {
    // Hit-test the CHILD, not this widget: our own `RawGestureDetector`
    // installs a pointer listener and a semantics gesture handler of its own,
    // and a hit test from here would find them first and read them as "someone
    // already claims this press" — vetoing every drag we exist to start.
    final box = _childKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return true;
    }
    final result = BoxHitTestResult();
    box.hitTest(result, position: box.globalToLocal(globalPosition));
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderObject && _handlesPress(target)) {
        return false;
      }
      if (target is SemanticsAnnotationsMixin &&
          _declaresPressableRole(target.properties)) {
        return false;
      }
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
      final dragThrough =
          cursor is SystemMouseCursor &&
          _dragThroughCursorKinds.contains(cursor.kind);
      if (!dragThrough) {
        return false;
      }
    }
    return true;
  }

  /// Where in the WINDOW the pointer grabbed it, recorded at drag start — the
  /// one moment a window-local measurement is trustworthy, because the window
  /// has not moved yet. Flutter's global coordinates are window coordinates on
  /// desktop (origin at the window's top-left), which for the hidden-titlebar
  /// primary window coincides with the frame origin `moveWindowTo` positions.
  Offset? _grabInWindow;

  void _startDrag(DragStartDetails details) {
    _grabInWindow = details.globalPosition;
    (WindowDragArea.debugOnStartDrag ?? startWindowDrag).call();
  }

  /// Places the window so the grabbed pixel sits under the cursor.
  ///
  /// The target is absolute — cursor screen position minus the grab offset —
  /// and is read from the OS's live cursor state rather than from [details]:
  /// pointer-event positions are window-local, i.e. measured against an origin
  /// this method itself keeps changing, so events still in flight when a move
  /// lands carry stale coordinates. Correcting from a stale event overshoots,
  /// the next fresh event pulls back, and a fast drag always has roughly one
  /// event of pipelining in flight — the window oscillated around the pointer
  /// with an amplitude that grew with drag speed. Deriving the target from
  /// cursor state instead makes every update idempotent and monotone with the
  /// pointer: a dropped, duplicated or coalesced update costs nothing, and a
  /// stationary cursor produces the target the window already sits at (which
  /// [moveWindowTo] skips outright).
  void _updateDrag(DragUpdateDetails details) {
    final grab = _grabInWindow;
    if (grab == null || !widget.moveWindowManually) {
      return;
    }
    final cursor =
        (WindowDragArea.debugCursorPosition ?? windowCursorPosition)();
    (WindowDragArea.debugOnMoveTo ?? moveWindowTo)(cursor - grab);
  }

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
              (recognizer) => recognizer
                ..onStart = _startDrag
                ..onUpdate = _updateDrag,
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
      child: KeyedSubtree(key: _childKey, child: widget.child),
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

  /// Refuses trackpad pan/zoom pointers, which reach a recognizer through
  /// `addPointerPanZoom` and never consult [isPointerAllowed]. Moving a window
  /// is a press-and-drag; a two-finger scroll over the title bar is not one.
  @override
  bool isPointerPanZoomAllowed(PointerPanZoomStartEvent event) => false;

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
