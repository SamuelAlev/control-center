// The windowing controllers' native handles live in Flutter's experimental,
// @internal windowing library (see app_windows.dart). Contained here.
// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/src/widgets/_window.dart' show WindowController;
import 'package:flutter/src/widgets/_window_linux.dart'
    show BaseWindowControllerLinux;
import 'package:flutter/src/widgets/_window_macos.dart'
    show BaseWindowControllerMacOS;
import 'package:flutter/src/widgets/_window_win32.dart'
    show BaseWindowControllerWin32;
import 'package:nativeapi_flutter/nativeapi_flutter.dart'
    as nativeapi
    show Window;

/// [controller]'s platform window (NSWindow, HWND, GtkWindow) as a fresh
/// `nativeapi.Window` the caller disposes, or null once it is destroyed.
///
/// The handle, not a title lookup: Windows enumerates only visible windows,
/// and the window this is asked for may be hidden in the tray.
nativeapi.Window? nativeWindowOf(WindowController controller) {
  try {
    final handle = switch (controller) {
      final BaseWindowControllerMacOS c => c.windowHandle,
      final BaseWindowControllerWin32 c => c.windowHandle,
      final BaseWindowControllerLinux c => c.windowHandle,
      _ => null,
    };
    return handle == null
        ? null
        : nativeapi.Window.createWithNativeWindow(handle);
  } on Object catch (e) {
    // A destroyed controller throws on its handle.
    AppLog.d('windowing', 'no native window for controller: $e');
    return null;
  }
}

/// Shows [controller]'s window now, in front and focused, rather than on the
/// engine's first frame — which never comes while frames are disabled, as
/// they are whenever this app has no visible window.
void showNativeWindowNow(WindowController controller) {
  final window = nativeWindowOf(controller);
  if (window == null) {
    return;
  }
  try {
    window
      ..show()
      ..focus();
  } finally {
    window.dispose();
  }
}
