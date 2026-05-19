import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider for the current theme mode.
final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

/// Theme notifier.
class ThemeNotifier extends Notifier<ThemeMode> {
  late AppPreferences _prefs;

  @override
  ThemeMode build() {
    _prefs = ref.watch(appPreferencesProvider);
    final saved = _prefs.getString(themeModeKey);
    return AppTheme.modeFromString(saved);
  }

  /// Sets the application theme mode and persists it.
  void setThemeMode(ThemeMode mode) {
    _prefs.setString(themeModeKey, mode.name);
    state = mode;
  }
}
