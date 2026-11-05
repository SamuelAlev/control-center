import 'dart:async';

import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/theme_choice.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:flutter/widgets.dart';

/// Language and theme on the connect surfaces, before any server is chosen.
///
/// Writes the same keys as `localeProvider` and `themeModeProvider`, so a
/// choice made here is what the connected app opens with. Those providers
/// cannot serve here: they report to analytics, which reads telemetry config
/// from a server this client has not reached, and the surfaces deliberately
/// mount no provider container of their own.
class ConnectAppearance extends ChangeNotifier {
  /// Creates appearance state over [_prefs].
  ConnectAppearance(this._prefs);

  final AppPreferences _prefs;

  /// The saved language, or null to follow the system.
  Locale? get locale {
    final saved = _prefs.getString(localeKey);
    return saved == null ? null : parsePersistedLocale(saved)?.locale;
  }

  /// The saved theme choice.
  ThemeChoice get theme => switch (_prefs.getString(themeModeKey)) {
    'dark' => ThemeChoice.dark,
    'light' => ThemeChoice.light,
    _ => ThemeChoice.system,
  };

  /// Whether the dark theme applies, given the [platform] appearance.
  bool isDark(Brightness platform) => switch (theme) {
    ThemeChoice.dark => true,
    ThemeChoice.light => false,
    ThemeChoice.system => platform == Brightness.dark,
  };

  /// Saves [locale], or follows the system when it is null or not shipped.
  void setLocale(Locale? locale) {
    final variant = locale == null
        ? null
        : parsePersistedLocale(formatLocaleTag(locale));
    unawaited(
      variant == null
          ? _prefs.remove(localeKey)
          : _prefs.setString(localeKey, variant.tag),
    );
    notifyListeners();
  }

  /// Saves a theme [choice].
  void setTheme(ThemeChoice choice) {
    unawaited(
      choice == ThemeChoice.system
          ? _prefs.remove(themeModeKey)
          : _prefs.setString(themeModeKey, choice.name),
    );
    notifyListeners();
  }
}
