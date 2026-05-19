/// Web stub for the desktop updater seam. The auto_updater plugin (Sparkle 2
/// / WinSparkle) only exists on macOS + Windows desktop builds; this stub
/// keeps every shared call site compiling (and honest: unsupported means
/// unsupported, never a silent pretend-update).
library;

/// Whether this platform has a native in-app updater backend (never here).
bool get desktopUpdaterSupported => false;

/// Arms the (absent) updater — a no-op off-desktop.
Future<void> initDesktopUpdater() async {}

/// Runs a (nonexistent) update check — a no-op off-desktop.
Future<void> desktopCheckForUpdates({bool background = false}) async {}

/// Registers outcome handlers that will never fire off-desktop.
void setDesktopUpdaterHandlers({
  void Function(String? version, String? notes)? onAvailable,
  void Function()? onNotAvailable,
  void Function(String message)? onError,
}) {}
