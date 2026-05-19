/// Native implementation of the desktop updater seam over the auto_updater
/// plugin: Sparkle 2 on macOS, WinSparkle on Windows. Updates the WHOLE app
/// bundle (UI + embedded cc_server + natives) — never the binary alone.
///
/// Two dev-only escape hatches (never set in release builds):
///  * `CC_APPCAST_URL` (dart-define or env) overrides the feed URL — the
///    local harness at `tool/fake_update_server.dart` uses it to serve a
///    signed fake update from 127.0.0.1 and exercise the REAL Sparkle flow.
///  * `CC_FAKE_UPDATE` (dart-define or env) replaces the native updater with
///    a simulated one (`available` / `none` / `error`) so the controller,
///    the About row, and the macOS menu item can be exercised with no
///    Sparkle, keys, or server at all.
library;

import 'dart:async';
import 'dart:io';

import 'package:auto_updater/auto_updater.dart' as au;
import 'package:control_center/core/update/desktop_update_config.dart';

/// Whether this platform has a native in-app updater backend.
bool get desktopUpdaterSupported => Platform.isMacOS || Platform.isWindows;

const String _kFeedUrlDefine = String.fromEnvironment('CC_APPCAST_URL');
const String _kFakeDefine = String.fromEnvironment('CC_FAKE_UPDATE');

/// The dev escape hatches resolve dart-define first, then process env
/// (`flutter run` inherits the shell env, so both work with one command).
String? get _feedOverride => _kFeedUrlDefine.isNotEmpty
    ? _kFeedUrlDefine
    : Platform.environment['CC_APPCAST_URL'];

/// `available` (default), `none`, or `error`; null = real updater.
String? get _fakeMode {
  const fromDefine = _kFakeDefine;
  final raw = fromDefine.isNotEmpty
      ? fromDefine
      : Platform.environment['CC_FAKE_UPDATE'];
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return switch (raw) {
    'none' || 'error' => raw,
    _ => 'available',
  };
}

/// Called with the new version (and release notes text when the appcast
/// carries it) after a check finds an update.
void Function(String? version, String? notes)? _onAvailable;

/// Called when a check completes with no update.
void Function()? _onNotAvailable;

/// Called when the updater reports an error (feed unreachable, signature
/// rejected, download failed).
void Function(String message)? _onError;

final _Listener _listener = _Listener();

/// Arms the updater: sets the platform's appcast feed URL and takes over the
/// check cadence (Sparkle's own scheduler is disabled — our controller decides
/// WHEN a check is safe to prompt, per the drain rule).
Future<void> initDesktopUpdater() async {
  if (!desktopUpdaterSupported || _fakeMode != null) {
    return;
  }
  final override = _feedOverride;
  await au.autoUpdater.setFeedURL(
    override ?? (Platform.isWindows ? kWindowsAppcastUrl : kMacAppcastUrl),
  );
  await au.autoUpdater.setScheduledCheckInterval(0);
  au.autoUpdater.addListener(_listener);
}

/// Interactive (UI) or background check. `background: true` only probes and
/// reports through the handlers; `background: false` shows the updater's own
/// prompt with release notes and the confirm/install flow.
Future<void> desktopCheckForUpdates({bool background = false}) async {
  if (!desktopUpdaterSupported) {
    return;
  }
  final fake = _fakeMode;
  if (fake != null) {
    // Simulated outcome after a short, network-plausible delay. The
    // foreground/background distinction collapses in fake mode (there is no
    // native prompt) — both fire the same handler, which is exactly what the
    // controller + About row consume.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    switch (fake) {
      case 'available':
        _onAvailable?.call(
          '999.0.0',
          'This is a fake update (CC_FAKE_UPDATE=available). No Sparkle, no '
              'server — the controller, the About row, and the app-menu item are '
              'being exercised.',
        );
      case 'none':
        _onNotAvailable?.call();
      case 'error':
        _onError?.call('CC_FAKE_UPDATE=error: simulated failure');
    }
    return;
  }
  await au.autoUpdater.checkForUpdates(inBackground: background);
}

/// Registers the outcome handlers (available / not-available / error) the
/// native updater events forward to.
void setDesktopUpdaterHandlers({
  void Function(String? version, String? notes)? onAvailable,
  void Function()? onNotAvailable,
  void Function(String message)? onError,
}) {
  _onAvailable = onAvailable;
  _onNotAvailable = onNotAvailable;
  _onError = onError;
}

class _Listener implements au.UpdaterListener {
  @override
  void onUpdaterCheckingForUpdate(au.Appcast? appcast) {}

  @override
  void onUpdaterUpdateAvailable(au.AppcastItem? item) {
    _onAvailable?.call(item?.versionString, item?.itemDescription);
  }

  @override
  void onUpdaterUpdateNotAvailable(au.UpdaterError? error) {
    _onNotAvailable?.call();
  }

  @override
  void onUpdaterError(au.UpdaterError? error) {
    _onError?.call(error?.message ?? 'unknown updater error');
  }

  @override
  void onUpdaterUpdateDownloaded(au.AppcastItem? item) {}

  @override
  void onUpdaterBeforeQuitForUpdate(au.AppcastItem? item) {}
}
