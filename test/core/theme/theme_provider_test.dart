// ignore_for_file: avoid_dynamic_calls

import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      final prefs = AppPreferences.inMemory({});
      container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
    });

    test('build returns system mode when no pref is set', () {
      final mode = container.read(themeModeProvider);
      expect(mode, ThemeMode.system);
    });

    test('build returns light mode when saved preference is light', () async {
      final prefs = AppPreferences.inMemory({themeModeKey: 'light'});
      final lightContainer = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(lightContainer.dispose);

      final mode = lightContainer.read(themeModeProvider);
      expect(mode, ThemeMode.light);
    });

    test('build returns dark mode when saved preference is dark', () async {
      final prefs = AppPreferences.inMemory({themeModeKey: 'dark'});
      final darkContainer = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(darkContainer.dispose);

      final mode = darkContainer.read(themeModeProvider);
      expect(mode, ThemeMode.dark);
    });

    test(
      'build returns system mode when saved preference is unknown',
      () async {
        final prefs = AppPreferences.inMemory({themeModeKey: 'invalid'});
        final container2 = ProviderContainer(
          overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container2.dispose);

        final mode = container2.read(themeModeProvider);
        expect(mode, ThemeMode.system);
      },
    );

    test('setThemeMode switches from light to dark', () async {
      final prefs = AppPreferences.inMemory({themeModeKey: 'light'});
      final toggleContainer = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(toggleContainer.dispose);

      expect(toggleContainer.read(themeModeProvider), ThemeMode.light);

      toggleContainer
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(toggleContainer.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.getString(themeModeKey), 'dark');
    });

    test('setThemeMode switches from dark to light', () async {
      final prefs = AppPreferences.inMemory({themeModeKey: 'dark'});
      final toggleContainer = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(toggleContainer.dispose);

      expect(toggleContainer.read(themeModeProvider), ThemeMode.dark);

      toggleContainer
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);

      expect(toggleContainer.read(themeModeProvider), ThemeMode.light);
      expect(prefs.getString(themeModeKey), 'light');
    });

    test('setThemeMode to system from light', () {
      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('setThemeMode persists the new value', () {
      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);

      final saved = container.read(appPreferencesProvider);
      expect(saved.getString(themeModeKey), 'dark');
    });
  });
}
