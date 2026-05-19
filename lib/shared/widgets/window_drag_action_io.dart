import 'package:nativeapi/nativeapi.dart' show WindowManager;

/// Kicks off the platform's native window-move loop on the focused window.
///
/// The desktop implementation of the [startWindowDrag] seam — isolates the
/// `nativeapi` dependency to the `dart:io` half so the web build never links it.
void startWindowDrag() => WindowManager.instance.getCurrent()?.startDragging();
