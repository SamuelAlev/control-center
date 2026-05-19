import 'package:control_center/core/theme/app_theme.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    group('modeFromString', () {
      test('returns ThemeMode.light for "light"', () {
        expect(AppTheme.modeFromString('light'), ThemeMode.light);
      });

      test('returns ThemeMode.dark for "dark"', () {
        expect(AppTheme.modeFromString('dark'), ThemeMode.dark);
      });

      test('returns ThemeMode.system for null', () {
        expect(AppTheme.modeFromString(null), ThemeMode.system);
      });

      test('returns ThemeMode.system for unknown value', () {
        expect(AppTheme.modeFromString('unknown'), ThemeMode.system);
      });

      test('returns ThemeMode.system for empty string', () {
        expect(AppTheme.modeFromString(''), ThemeMode.system);
      });

      test('returns ThemeMode.system for "system"', () {
        expect(AppTheme.modeFromString('system'), ThemeMode.system);
      });

      test('case sensitive - "Light" returns system', () {
        expect(AppTheme.modeFromString('Light'), ThemeMode.system);
      });
    });

    group('FTheme statics', () {
      // A non-Google family avoids google_fonts' runtime loading, which needs
      // an initialized binding (the same reason the light/dark theme tests
      // below use 'Arial'). Production always runs with the binding ready.
      test('lightFTheme is non-null', () {
        expect(AppTheme.lightFTheme(appFontFamily: 'Arial'), isNotNull);
      });

      test('darkFTheme is non-null', () {
        expect(AppTheme.darkFTheme(appFontFamily: 'Arial'), isNotNull);
      });
    });

    group('light theme', () {
      test('returns a ThemeData with system font', () {
        final theme = AppTheme.light(appFontFamily: 'Arial');
        expect(theme, isA<ThemeData>());
      });

      test('registers DesignSystemTokens extension', () {
        final theme = AppTheme.light(appFontFamily: 'Arial');
        expect(theme.extension<DesignSystemTokens>(), isNotNull);
      });
    });

    group('dark theme', () {
      test('returns a ThemeData with system font', () {
        final theme = AppTheme.dark(appFontFamily: 'Arial');
        expect(theme, isA<ThemeData>());
      });

      test('registers DesignSystemTokens extension', () {
        final theme = AppTheme.dark(appFontFamily: 'Arial');
        expect(theme.extension<DesignSystemTokens>(), isNotNull);
      });
    });

    group('font handling', () {
      test('light theme with fallback font works', () {
        final theme = AppTheme.light(appFontFamily: 'SystemFont');
        expect(theme, isA<ThemeData>());
      });

      test('dark theme with fallback font works', () {
        final theme = AppTheme.dark(appFontFamily: 'SystemFont');
        expect(theme, isA<ThemeData>());
      });
    });
  });
}
