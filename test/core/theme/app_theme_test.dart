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

    group('light theme', () {
      test('returns a ThemeData with system font', () {
        final theme = AppTheme.light(appFontFamily: 'Arial');
        expect(theme, isA<ThemeData>());
      });

      test('does not attach tokens as a Material ThemeExtension', () {
        // Tokens are delivered via CcTheme (an InheritedWidget), not as a
        // Material ThemeExtension. The light tokens come from CcThemeData.
        final theme = AppTheme.light(appFontFamily: 'Arial');
        expect(theme.extension<DesignSystemTokens>(), isNull);
        expect(CcThemeData.light().tokens.bgPrimary, isNotNull);
      });
    });

    group('dark theme', () {
      test('returns a ThemeData with system font', () {
        final theme = AppTheme.dark(appFontFamily: 'Arial');
        expect(theme, isA<ThemeData>());
      });

      test('does not attach tokens as a Material ThemeExtension', () {
        final theme = AppTheme.dark(appFontFamily: 'Arial');
        expect(theme.extension<DesignSystemTokens>(), isNull);
        expect(CcThemeData.dark().tokens.bgPrimary, isNotNull);
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
