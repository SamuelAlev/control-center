import 'dart:async';
import 'dart:io';
import 'dart:ui' show AppExitType;

import 'package:control_center/app/tray/launch_at_login_io.dart';
import 'package:control_center/app/tray/launch_context.dart';
import 'package:control_center/app/tray/linux_tray_host_probe.dart';
import 'package:control_center/app/tray/main_window_visibility.dart';
import 'package:control_center/app/tray/tray_icon_host.dart';
import 'package:control_center/core/desktop/desktop_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;

/// The desktop process's [DesktopShell], over nativeapi and the runners.
///
/// One per process: the tray icon and the main window outlive every session
/// container, so a server switch hands the new container this same shell.
class NativeDesktopShell implements DesktopShell {
  NativeDesktopShell._() {
    if (Platform.isLinux && _tray.supported) {
      unawaited(probeLinuxTrayHost().then((state) => _trayHost.value = state));
    }
  }

  /// The process-wide instance.
  static final NativeDesktopShell instance = NativeDesktopShell._();

  final TrayIconHost _tray = TrayIconHost.instance;
  final MainWindowVisibility _window = MainWindowVisibility.instance;
  late final ValueNotifier<TrayHostState> _trayHost = ValueNotifier(
    _tray.supported ? TrayHostState.available : TrayHostState.unsupported,
  );

  @override
  bool get traySupported => _tray.supported;

  @override
  ValueListenable<TrayHostState> get trayHost => _trayHost;

  @override
  void setTrayIcon(TrayIconSpec spec, List<TrayMenuEntry> menu) =>
      _tray.show(spec, menu);

  @override
  void removeTrayIcon() => _tray.remove();

  @override
  Stream<TrayPointerEvent> get trayEvents => _tray.events;

  @override
  Stream<String> get trayMenuSelections => _tray.selections;

  @override
  ValueListenable<bool> get mainWindowHidden => _window.hidden;

  @override
  void hideMainWindow() => _window.hide();

  @override
  void revealMainWindow() => _window.reveal();

  @override
  set closeInterceptor(bool Function()? interceptor) =>
      _window.closeInterceptor = interceptor;

  @override
  void quit() {
    // The same exit the window's close took before close-to-tray: every
    // `onExitRequested` handler runs, the bundled server shuts down cleanly.
    unawaited(WidgetsBinding.instance.exitApplication(AppExitType.cancelable));
  }

  @override
  bool get launchedAtLogin => wasLaunchedAtLogin;

  @override
  LaunchAtLoginState readLaunchAtLogin() => readLaunchAtLoginRegistration();

  @override
  bool setLaunchAtLogin({required bool enabled}) =>
      writeLaunchAtLoginRegistration(enabled: enabled);
}
