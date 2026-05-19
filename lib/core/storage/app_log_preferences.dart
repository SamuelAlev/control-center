import 'dart:async';

import 'package:control_center/core/constants/app_log_level.dart';
import 'package:control_center/core/providers/storage_providers.dart';

/// AppPreferences storage key for the app-wide log level.
const String _kLogLevelKey = 'app_log_level';

/// Read/write the user's app-wide log-level preference.
///
/// Wrapping `SharedPreferences` instead of hitting it directly keeps the
/// settings UI testable and avoids hard-coded keys outside this file.
class AppLogPreferences {
  /// Creates [AppLogPreferences] over the given `SharedPreferences` instance.
  AppLogPreferences(this._prefs);

  final AppPreferences _prefs;

  /// Currently selected app log level. Defaults to [AppLogLevel.none]
  /// on fresh installs (production-safe).
  AppLogLevel get logLevel =>
      AppLogLevel.fromName(_prefs.getString(_kLogLevelKey));

  /// Sets the app log level.
  Future<void> setLogLevel(AppLogLevel value) =>
      _prefs.setString(_kLogLevelKey, value.name);
}
