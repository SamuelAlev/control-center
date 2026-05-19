import 'dart:ui' show Offset;

import 'package:nativeapi/nativeapi.dart'
    show DisplayManager, WindowManager;

/// Kicks off the platform's native window-move loop on the focused window.
///
/// The desktop implementation of the [startWindowDrag] seam — isolates the
/// `nativeapi` dependency to the `dart:io` half so the web build never links it.
void startWindowDrag() => WindowManager.instance.getCurrent()?.startDragging();

/// Toggles the focused window between maximized and its previous size.
///
/// The desktop implementation of the [toggleWindowMaximize] seam — mirrors the
/// native double-click-title-bar-to-zoom behaviour that a borderless window
/// otherwise loses.
void toggleWindowMaximize() {
  final window = WindowManager.instance.getCurrent();
  if (window == null) {
    return;
  }
  if (window.isMaximized) {
    window.unmaximize();
  } else {
    window.maximize();
  }
}

/// The cursor's current position in screen coordinates — top-left origin, y
/// growing downwards, logical points; the same space `Window.position` and
/// [moveWindowTo] use, and the same orientation as Flutter's window-local
/// coordinates, so a grab offset subtracts unconverted.
///
/// The desktop implementation of the [windowCursorPosition] seam. Deliberately
/// NOT the pointer-event stream: event positions are window-local, measured
/// against an origin a manual move keeps changing, so events still in flight
/// when a move lands report stale coordinates. The OS's live cursor state
/// (`NSEvent.mouseLocation`, `GetCursorPos`, GDK) has no such pipelining.
Offset windowCursorPosition() => DisplayManager.instance.getCursorPosition();

/// Sub-point tolerance for "the window is already there" in [moveWindowTo]:
/// anything smaller is not a user-visible position change.
const double _moveEpsilon = 0.01;

/// Places the focused window's top-left at [topLeft] (screen coordinates).
///
/// The desktop implementation of the [moveWindowTo] seam — the app moving its
/// own window, for the primary window, which is deliberately NOT movable by
/// the system (see `styleWindowOnShow`). An absolute set, never a
/// read-modify-write over the live position: recomputing the target from
/// fresh cursor state on every update is what keeps an update that lands
/// late, twice or not at all from accumulating error. A target within
/// [_moveEpsilon] of the current position is skipped — a no-op
/// `setFrameOrigin` still costs a window-server round trip.
void moveWindowTo(Offset topLeft) {
  final window = WindowManager.instance.getCurrent();
  if (window == null) {
    return;
  }
  if ((window.position - topLeft).distance <= _moveEpsilon) {
    return;
  }
  window.position = topLeft;
}
