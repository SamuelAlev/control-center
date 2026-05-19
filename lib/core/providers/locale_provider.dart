import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Riverpod provider for the current locale override.
///
/// `null` means "follow system"; a non-null [Locale] forces that locale.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

/// Persistent locale preference backed by [SharedPreferences].
class LocaleNotifier extends Notifier<Locale?> {
  late SharedPreferences _prefs;

  @override
  Locale? build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final saved = _prefs.getString(localeKey);
    if (saved == null) return null;
    return _localeFromString(saved);
  }

  /// Sets the locale override. Pass `null` to follow the system default.
  void setLocale(Locale? locale) {
    if (locale == null) {
      _prefs.remove(localeKey);
    } else {
      _prefs.setString(localeKey, _localeToString(locale));
    }
    state = locale;
  }

  /// Serializes a [Locale] as `'languageCode'` or `'languageCode_countryCode'`.
  static String _localeToString(Locale l) {
    final country = l.countryCode;
    return country != null && country.isNotEmpty
        ? '${l.languageCode}_$country'
        : l.languageCode;
  }

  /// Deserializes a persisted locale string.
  static Locale? _localeFromString(String s) {
    final parts = s.split('_');
    if (parts.length == 2) return Locale(parts[0], parts[1]);
    if (parts.length == 1) return Locale(parts[0]);
    return null;
  }
}
