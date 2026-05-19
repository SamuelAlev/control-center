import 'package:nativeapi/nativeapi.dart' show WindowManager;

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
