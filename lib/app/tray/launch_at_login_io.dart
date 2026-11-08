// The login launch, as the operating system records it.
//
// - macOS: the app itself as an `SMAppService` main-app login item. It is
//   launched without arguments; the runner recognises the launch from its
//   Apple Event instead (see `resolveLaunchContext`). The user can switch it
//   off in System Settings → General → Login Items, and a newly registered
//   item may need their approval there first.
// - Windows: an `HKCU\…\Run` value (or the Startup folder for a packaged
//   build). Task Manager's Startup apps can disable it.
// - Linux: an XDG autostart entry. An AppImage registers the image file
//   (`$APPIMAGE`), not the binary inside its temporary mount.
//
// Read fresh every time rather than cached: all of the above can change
// outside the app.

import 'dart:io';

import 'package:control_center/app/tray/launch_context.dart';
import 'package:control_center/core/desktop/desktop_shell.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:nativeapi/nativeapi.dart' as na;

/// What the operating system reports now for the login launch.
LaunchAtLoginState readLaunchAtLoginRegistration() {
  final registration = _openRegistration();
  if (registration == null) {
    return LaunchAtLoginState.unsupported;
  }
  try {
    return registration.isEnabled
        ? LaunchAtLoginState.enabled
        : LaunchAtLoginState.disabled;
  } finally {
    registration.dispose();
  }
}

/// Registers or removes the login launch; true when the system now reports
/// the requested state.
bool writeLaunchAtLoginRegistration({required bool enabled}) {
  final registration = _openRegistration();
  if (registration == null) {
    return false;
  }
  try {
    final done = enabled ? registration.enable() : registration.disable();
    if (!done) {
      AppLog.w(
        'tray',
        'launch at login: ${enabled ? 'enable' : 'disable'} refused',
      );
    }
    return registration.isEnabled == enabled;
  } finally {
    registration.dispose();
  }
}

na.LaunchAtLogin? _openRegistration() {
  try {
    if (!na.LaunchAtLogin.isSupported()) {
      return null;
    }
    final registration = na.LaunchAtLogin.create();
    if (registration == null) {
      return null;
    }
    if (!Platform.isMacOS) {
      // macOS starts the bundle and passes nothing, so it gets no program:
      // setting one there would only be recorded, never used.
      final program =
          Platform.environment['APPIMAGE'] ?? Platform.resolvedExecutable;
      registration.setProgram(program, const [launchedAtLoginArgument]);
    }
    registration.setDisplayName('Control Center');
    return registration;
  } on Object catch (e) {
    AppLog.w('tray', 'launch at login unavailable: $e');
    return null;
  }
}
