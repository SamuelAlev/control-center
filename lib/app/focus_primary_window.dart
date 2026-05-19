/// Platform seam for bringing the primary app window to the front.
///
/// On the VM this delegates to the `nativeapi`-backed window chrome
/// (`focus_primary_window_io.dart` → `window_chrome.dart`); on web it is a no-op
/// (`focus_primary_window_web.dart`). Importing `window_chrome.dart` directly
/// would pull `nativeapi` (dart:ffi) into the web graph, so the web-reachable
/// focus-mode notifier imports this seam instead.
library;

export 'focus_primary_window_io.dart'
    if (dart.library.js_interop) 'focus_primary_window_web.dart';
