import 'dart:io';

import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps the app fully active while a long-running background task — a meeting
/// recording — is in progress, so the OS does not throttle it when its window
/// loses focus.
///
/// On macOS, an unfocused/occluded app is subject to **App Nap**: the system
/// coalesces timers and slows the main run loop, which stalls Flutter
/// platform-channel delivery. The audio-capture plugins keep enqueuing PCM on
/// their real-time threads, but the buffered chunks are only handed to Dart in a
/// burst when the window is refocused — so transcription appears to "pause while
/// unfocused and catch up all at once" on focus. Holding an `NSProcessInfo`
/// activity assertion for the duration of the recording prevents App Nap (and
/// idle system sleep), keeping capture + transcription continuous in the
/// background.
///
/// Other platforms do not throttle background apps this way for our capture
/// path, so the guard is a no-op there.
abstract interface class BackgroundActivityGuard {
  /// Begins an activity assertion described by [reason]. Idempotent.
  Future<void> begin(String reason);

  /// Ends the activity assertion. Idempotent.
  Future<void> end();
}

/// A guard that does nothing — used on platforms without OS-level background
/// throttling of the capture path (Windows/Linux), and in tests.
class NoopBackgroundActivityGuard implements BackgroundActivityGuard {
  /// Creates a [NoopBackgroundActivityGuard].
  const NoopBackgroundActivityGuard();

  @override
  Future<void> begin(String reason) async {}

  @override
  Future<void> end() async {}
}

/// macOS guard that brackets the recording in an `NSProcessInfo.beginActivity` /
/// `endActivity` assertion via the app method channel (see `AppDelegate`).
class MacosBackgroundActivityGuard implements BackgroundActivityGuard {
  /// Creates a [MacosBackgroundActivityGuard] over the given method channel
  /// (the shared app method channel by default).
  const MacosBackgroundActivityGuard([
    this._channel = const MethodChannel('com.controlcenter/app'),
  ]);

  final MethodChannel _channel;

  @override
  Future<void> begin(String reason) =>
      _invoke('beginBackgroundActivity', {'reason': reason});

  @override
  Future<void> end() => _invoke('endBackgroundActivity', null);

  Future<void> _invoke(String method, Map<String, Object?>? args) async {
    try {
      await _channel.invokeMethod<void>(method, args);
      AppLog.i('BackgroundActivity', '$method ok');
    } on MissingPluginException {
      // An older native build without the handler — degrade gracefully; the
      // worst case is the pre-fix throttling behaviour. If you see this during a
      // recording, the macOS app was NOT rebuilt after the App Nap fix landed
      // (a hot restart does not recompile Swift) — do a full rebuild.
      AppLog.w(
        'BackgroundActivity',
        'native handler missing for $method — rebuild the macOS app '
            '(hot restart does not recompile Swift)',
      );
    } on PlatformException catch (e) {
      AppLog.w('BackgroundActivity', '$method failed: ${e.message}');
    }
  }
}

/// The platform-appropriate [BackgroundActivityGuard]: a real assertion on
/// macOS, a no-op elsewhere.
final backgroundActivityGuardProvider =
    Provider<BackgroundActivityGuard>((ref) {
  if (Platform.isMacOS) {
    return const MacosBackgroundActivityGuard();
  }
  return const NoopBackgroundActivityGuard();
});
