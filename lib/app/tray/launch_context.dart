import 'dart:io';

import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/services.dart';

/// The argument the Windows and Linux login entries start the app with.
///
/// Those platforms cannot otherwise tell a login launch from the operator
/// opening the app, and only the first may start hidden. The runners know it
/// too: a login launch that finds the app already running must not raise its
/// window (`windows/runner/main.cpp`, `linux/runner/my_application.cc`).
const String launchedAtLoginArgument = '--launched-at-login';

bool _launchedAtLogin = false;

/// Whether the login launch started this process (see
/// [resolveLaunchContext]).
bool get wasLaunchedAtLogin => _launchedAtLogin;

/// Resolves [wasLaunchedAtLogin] once, early in the desktop bootstrap.
///
/// [arguments] are the program's own (Dart `main`'s), which the Windows and
/// Linux runners forward. macOS cannot pass arguments to an SMAppService
/// login item, so there the runner reads the launch's Apple Event and
/// answers over the app channel.
Future<void> resolveLaunchContext(List<String> arguments) async {
  if (!Platform.isMacOS) {
    _launchedAtLogin = arguments.contains(launchedAtLoginArgument);
    return;
  }
  try {
    final context = await const MethodChannel(
      'com.controlcenter/app',
    ).invokeMapMethod<String, Object?>('launchContext');
    _launchedAtLogin = context?['launchedAtLogin'] == true;
  } on PlatformException catch (e) {
    AppLog.w('tray', 'launch context unavailable: ${e.message}');
  } on MissingPluginException {
    // An older runner without the method: an ordinary launch.
  }
}
