import 'package:control_center/core/desktop/desktop_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The process's [DesktopShell]: tray icon, hidden main window, launch at
/// login.
///
/// [UnsupportedDesktopShell] unless the desktop bootstrap overrides it with
/// the native shell, so web, tests and previews see a desktop with no tray.
/// The native shell outlives every session container (a server switch
/// rebuilds the container around the same tray icon and window).
final desktopShellProvider = Provider<DesktopShell>(
  (ref) => UnsupportedDesktopShell(),
);
