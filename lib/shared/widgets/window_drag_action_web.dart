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
