import 'package:control_center/core/constants/app_log_level.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/app_log_preferences.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User preferences for the app-wide log level.
final appLogPreferencesProvider = Provider<AppLogPreferences>((ref) {
  return AppLogPreferences(ref.watch(appPreferencesProvider));
});

/// Wires the static [AppLog] level from the current preference value.
///
/// Override this in tests or call [AppLog.init] directly.
final appLogLevelProvider = Provider<AppLogLevel>((ref) {
  final prefs = ref.watch(appLogPreferencesProvider);
  final level = prefs.logLevel;
  AppLog.init(level);
  return level;
});
