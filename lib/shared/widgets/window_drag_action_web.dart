import 'dart:ui' show Offset;

/// The web implementation of the [startWindowDrag] seam.
///
/// A browser tab is not a movable OS window, so dragging the title bar / sidebar
/// strip is a no-op here. Lives behind a conditional import so the web build
/// never links `nativeapi` (and the desktop window-move code never compiles in).
void startWindowDrag() {}

/// The web implementation of the [toggleWindowMaximize] seam.
///
/// A browser tab has no OS-level maximize state, so double-clicking the title
/// bar is a no-op here.
void toggleWindowMaximize() {}

/// The web implementation of the [windowCursorPosition] seam.
///
/// A browser tab cannot read the OS cursor outside the page, so this reports
/// a dummy position; the manual move that would consume it is itself a no-op
/// (see [moveWindowTo]).
Offset windowCursorPosition() => Offset.zero;

/// The web implementation of the [moveWindowTo] seam.
///
/// A browser tab has no frame to reposition, so a manual window move is a
/// no-op here.
void moveWindowTo(Offset topLeft) {}
