import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider for the current locale override.
///
/// `null` means "follow system"; a non-null [Locale] forces that locale.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

/// Persistent locale preference backed by [AppPreferences].
///
/// The stored value is a BCP 47 tag (`fr-FR`) naming a [kAppLocaleVariants]
/// entry. Anything else is treated as unset (follow system).
class LocaleNotifier extends Notifier<Locale?> {
  late AppPreferences _prefs;

  @override
  Locale? build() {
    _prefs = ref.watch(appPreferencesProvider);
    final saved = _prefs.getString(localeKey);
    if (saved == null) {
      return null;
    }
    return parsePersistedLocale(saved)?.locale;
  }

  /// Sets the locale override. Pass `null` to follow the system default.
  ///
  /// Only a shipped BCP 47 tag (`fr-FR`) is persisted. A bare language
  /// (`fr`) or any other unrecognised value is treated as follow-system.
  void setLocale(Locale? locale) {
    if (locale == null) {
      _prefs.remove(localeKey);
      state = null;
      return;
    }
    final variant = parsePersistedLocale(formatLocaleTag(locale));
    if (variant == null) {
      _prefs.remove(localeKey);
      state = null;
      return;
    }
    _prefs.setString(localeKey, variant.tag);
    state = variant.locale;
  }
}
