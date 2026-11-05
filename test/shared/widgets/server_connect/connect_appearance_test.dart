import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/theme_choice.dart';
import 'package:control_center/shared/widgets/server_connect/connect_appearance.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('follows the platform until a theme is pinned', () {
    final appearance = ConnectAppearance(AppPreferences.inMemory());
    expect(appearance.isDark(Brightness.dark), isTrue);
    expect(appearance.isDark(Brightness.light), isFalse);

    appearance.setTheme(ThemeChoice.light);
    expect(appearance.isDark(Brightness.dark), isFalse);

    appearance.setTheme(ThemeChoice.system);
    expect(appearance.isDark(Brightness.dark), isTrue);
  });

  test('writes the keys the connected app reads', () {
    final prefs = AppPreferences.inMemory();
    ConnectAppearance(prefs)
      ..setTheme(ThemeChoice.dark)
      ..setLocale(const Locale('fr', 'FR'));

    expect(prefs.getString(themeModeKey), 'dark');
    expect(prefs.getString(localeKey), 'fr-FR');
  });

  test('a null or unshipped locale follows the system again', () {
    final prefs = AppPreferences.inMemory();
    final appearance = ConnectAppearance(prefs)
      ..setLocale(const Locale('fr', 'FR'));
    expect(appearance.locale, const Locale('fr', 'FR'));

    appearance.setLocale(null);
    expect(appearance.locale, isNull);
    expect(prefs.getString(localeKey), isNull);

    appearance.setLocale(const Locale('xx'));
    expect(appearance.locale, isNull);
  });

  test('notifies so the surface re-themes', () {
    final appearance = ConnectAppearance(AppPreferences.inMemory());
    var notified = 0;
    appearance
      ..addListener(() => notified++)
      ..setTheme(ThemeChoice.dark)
      ..setLocale(null);
    expect(notified, 2);
  });
}
