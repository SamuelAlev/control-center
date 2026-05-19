/// Platform seam for "is the operator actually looking at this app right now".
///
/// On the VM this asks the native windowing layer
/// (`app_window_focused_io.dart` → `nativeapi`); on web it answers "yes"
/// (`app_window_focused_web.dart`). Importing `nativeapi` directly would pull
/// dart:ffi into the web graph, so the notification path imports this seam
/// instead — the same reason `focus_primary_window.dart` exists.
///
/// The answer is polled at the moment it is needed rather than tracked: the
/// `nativeapi` window event handlers do not fire on macOS, so a listener-based
/// mirror of this state would silently latch at whatever it was when the app
/// started. A read costs one enumeration of a handful of windows and only
/// happens when a notification is about to be shown.
library;

export 'app_window_focused_io.dart'
    if (dart.library.js_interop) 'app_window_focused_web.dart';
