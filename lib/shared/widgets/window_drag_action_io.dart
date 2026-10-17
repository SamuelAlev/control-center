// WindowScope supplies per-view identity for Flutter's experimental windows.
// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:ui' show Offset;

import 'package:flutter/src/widgets/_window.dart' show WindowScope;
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:nativeapi_flutter/nativeapi_flutter.dart'
    show DisplayManager, OffsetToNative, PointToOffset, Window;
import 'package:nativeapi_flutter/windowing.dart' show nativeWindowOf;

/// Kicks off the native window-move loop for the window containing [context].
///
/// The desktop implementation of the [startWindowDrag] seam — isolates the
/// `nativeapi` dependency to the `dart:io` half so the web build never links it.
void startWindowDrag(BuildContext context) {
  final window = _windowOf(context);
  if (window == null) {
    return;
  }
  try {
    window.startDragging();
  } finally {
    window.dispose();
  }
}

/// Toggles the window containing [context] between maximized and its prior size.
///
/// The desktop implementation of the [toggleWindowMaximize] seam — mirrors the
/// native double-click-title-bar-to-zoom behaviour that a borderless window
/// otherwise loses.
void toggleWindowMaximize(BuildContext context) {
  final window = _windowOf(context);
  if (window == null) {
    return;
  }
  try {
    if (window.isMaximized) {
      window.unmaximize();
    } else {
      window.maximize();
    }
  } finally {
    window.dispose();
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
Offset windowCursorPosition() =>
    DisplayManager.instance.getCursorPosition().toOffset();

/// Sub-point tolerance for "the window is already there" in [moveWindowTo]:
/// anything smaller is not a user-visible position change.
const double _moveEpsilon = 0.01;

/// Places the window containing [context] at [topLeft] (screen coordinates).
///
/// The desktop implementation of the [moveWindowTo] seam — the app moving its
/// own window, for the primary window, which is deliberately NOT movable by
/// the system (see `styleWindowOnShow`). An absolute set, never a
/// read-modify-write over the live position: recomputing the target from
/// fresh cursor state on every update is what keeps an update that lands
/// late, twice or not at all from accumulating error. A target within
/// [_moveEpsilon] of the current position is skipped — a no-op
/// `setFrameOrigin` still costs a window-server round trip.
void moveWindowTo(BuildContext context, Offset topLeft) {
  final window = _windowOf(context);
  if (window == null) {
    return;
  }
  try {
    if ((window.position.toOffset() - topLeft).distance <= _moveEpsilon) {
      return;
    }
    window.position = topLeft.toNative();
  } finally {
    window.dispose();
  }
}

Window? _windowOf(BuildContext context) {
  // HUDs deliberately cannot take keyboard focus. The current/focused window
  // is therefore not the window receiving their pointer gestures.
  final controller = WindowScope.maybeOf(context);
  return controller == null ? null : nativeWindowOf(controller);
}
