import 'dart:developer' as developer;

import 'package:control_center/core/constants/app_log_level.dart';
import 'package:control_center/core/storage/app_log_preferences.dart' show AppLogPreferences;
import 'package:flutter/foundation.dart';

/// Static, app-wide logger. Level is set once at startup from
/// [AppLogPreferences] and can be changed at runtime via [init].
///
/// Use the shorthand methods when the call site knows the severity:
///
/// ```dart
/// AppLog.e('Tag', 'message', error, stackTrace); // error
/// AppLog.w('Tag', 'message');                     // warning
/// AppLog.i('Tag', 'message');                     // info
/// AppLog.d('Tag', 'message');                     // debug
/// AppLog.v('Tag', 'message');                     // verbose
/// ```
class AppLog {
  AppLog._();

  static AppLogLevel _level = kDebugMode ? AppLogLevel.debug : AppLogLevel.none;

  /// Current effective log level.
  static AppLogLevel get level => _level;

  /// Re-initialise the effective log level. Called once at app startup
  /// from the Riverpod provider and again whenever the user changes it
  /// in General Settings.
  static void init(AppLogLevel level) {
    _level = level;
  }

  /// Returns `true` when [messageLevel] is loud enough to be emitted.
  static bool _shouldLog(AppLogLevel messageLevel) {
    if (_level == AppLogLevel.none) {
      return false;
    }
    return messageLevel.index <= _level.index;
  }

  /// Log an error with an optional exception and stack trace.
  static void e(String tag, String message, [Object? error, StackTrace? st]) {
    if (!_shouldLog(AppLogLevel.error)) {
      return;
    }
    _emit('E', tag, message, error: error, stackTrace: st);
  }

  /// Log a warning.
  static void w(String tag, String message) {
    if (!_shouldLog(AppLogLevel.warning)) {
      return;
    }
    _emit('W', tag, message);
  }

  /// Log general information.
  static void i(String tag, String message) {
    if (!_shouldLog(AppLogLevel.info)) {
      return;
    }
    _emit('I', tag, message);
  }

  /// Log debug details.
  static void d(String tag, String message) {
    if (!_shouldLog(AppLogLevel.debug)) {
      return;
    }
    _emit('D', tag, message);
  }

  /// Log verbose / noisy diagnostics.
  static void v(String tag, String message) {
    if (!_shouldLog(AppLogLevel.verbose)) {
      return;
    }
    _emit('V', tag, message);
  }

  static void _emit(
    String severity,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer();
    buffer.write('[$severity]');
    buffer.write('[$tag] ');
    buffer.write(message);
    if (error != null) {
      buffer.write(' | $error');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }

    final line = buffer.toString();

    // Structured sink: shows up in the DevTools "Logging" view.
    developer.log(
      line,
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );

    // Console sink: developer.log does NOT print to the `flutter run` /
    // terminal stdout, so mirror to debugPrint when a level is active. This is
    // already gated by the per-method _shouldLog check that calls _emit.
    debugPrint(line);
  }
}

/// Adapts [AppLog] to the `NativeLog` sink expected by `package:cc_natives`.
///
/// Routes error-bearing calls to [AppLog.e] and info-only calls to [AppLog.i],
/// so the natives' diagnostics flow through the app logger without
/// `cc_natives` depending on it.
void ccNativesLog(
  String tag,
  String message, [
  Object? error,
  StackTrace? stackTrace,
]) {
  if (error != null) {
    AppLog.e(tag, message, error, stackTrace);
  } else {
    AppLog.i(tag, message);
  }
}
