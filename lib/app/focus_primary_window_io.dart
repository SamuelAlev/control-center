import 'package:control_center/app/window_chrome.dart' as chrome;

/// Desktop: brings the primary application window to the front (show + focus)
/// via the native windowing layer (`nativeapi`). Used when returning from a HUD
/// (expanding the focus pill, stopping a recording).
void focusPrimaryWindow() => chrome.focusPrimaryWindow();
