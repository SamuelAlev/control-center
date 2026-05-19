import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FontSelection', () {
    test('creates with default source', () {
      const selection = FontSelection(family: 'Inter');
      expect(selection.family, 'Inter');
      expect(selection.source, FontSource.google);
      expect(selection.filePath, isNull);
    });

    test('creates with system source', () {
      const selection = FontSelection(
        family: 'Custom Font',
        source: FontSource.system,
        filePath: '/fonts/custom.ttf',
      );
      expect(selection.source, FontSource.system);
      expect(selection.filePath, '/fonts/custom.ttf');
    });

    test('copyWith returns new instance', () {
      const original = FontSelection(family: 'Inter');
      final modified = original.copyWith(family: 'Roboto');
      expect(modified.family, 'Roboto');
      expect(original.family, 'Inter');
    });

    test('copyWith modifies source', () {
      const original = FontSelection(family: 'Inter');
      final modified = original.copyWith(source: FontSource.system);
      expect(modified.source, FontSource.system);
      expect(original.source, FontSource.google);
    });

    test('copyWith modifies filePath', () {
      const original = FontSelection(family: 'Inter');
      final modified = original.copyWith(filePath: '/path/to/font.ttf');
      expect(modified.filePath, '/path/to/font.ttf');
      expect(original.filePath, isNull);
    });

    test('copyWith no changes returns equal instance', () {
      const original = FontSelection(family: 'Inter');
      final modified = original.copyWith();
      expect(original, equals(modified));
    });

    test('equality works correctly', () {
      const a = FontSelection(family: 'Inter');
      const b = FontSelection(family: 'Inter');
      const c = FontSelection(family: 'Roboto');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('equality checks source', () {
      const a = FontSelection(family: 'Inter', source: FontSource.google);
      const b = FontSelection(family: 'Inter', source: FontSource.system);
      expect(a, isNot(equals(b)));
    });

    test('equality checks filePath', () {
      const a = FontSelection(family: 'Inter', filePath: '/a.ttf');
      const b = FontSelection(family: 'Inter', filePath: '/b.ttf');
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent', () {
      const a = FontSelection(family: 'Inter');
      const b = FontSelection(family: 'Inter');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs for different families', () {
      const a = FontSelection(family: 'Inter');
      const b = FontSelection(family: 'Roboto');
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('FontSettings', () {
    test('creates with defaults', () {
      const settings = FontSettings();
      expect(settings.appFontSelection.family, AppFonts.uiFamily);
      expect(settings.codeFontSelection.family, AppFonts.codeFamily);
    });

    test('creates with custom fonts', () {
      const settings = FontSettings(
        appFontSelection: FontSelection(family: 'Inter'),
        codeFontSelection: FontSelection(family: 'Fira Code'),
      );
      expect(settings.appFontSelection.family, 'Inter');
      expect(settings.codeFontSelection.family, 'Fira Code');
    });

    test('copyWith modifies app font', () {
      const original = FontSettings();
      final modified = original.copyWith(
        appFontSelection: const FontSelection(family: 'Inter'),
      );
      expect(modified.appFontSelection.family, 'Inter');
      expect(modified.codeFontSelection.family, AppFonts.codeFamily);
    });

    test('copyWith modifies code font', () {
      const original = FontSettings();
      final modified = original.copyWith(
        codeFontSelection: const FontSelection(family: 'Fira Code'),
      );
      expect(modified.appFontSelection.family, AppFonts.uiFamily);
      expect(modified.codeFontSelection.family, 'Fira Code');
    });

    test('copyWith modifies both fonts', () {
      const original = FontSettings();
      final modified = original.copyWith(
        appFontSelection: const FontSelection(family: 'Inter'),
        codeFontSelection: const FontSelection(family: 'Fira Code'),
      );
      expect(modified.appFontSelection.family, 'Inter');
      expect(modified.codeFontSelection.family, 'Fira Code');
    });

    test('copyWith no changes returns equal instance', () {
      const original = FontSettings();
      final modified = original.copyWith();
      expect(original, equals(modified));
    });

    test('equality works correctly', () {
      const a = FontSettings();
      const b = FontSettings();
      const c = FontSettings(appFontSelection: FontSelection(family: 'Inter'));
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('equality considers code font', () {
      const a = FontSettings();
      const b = FontSettings(codeFontSelection: FontSelection(family: 'Consolas'));
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent', () {
      const a = FontSettings();
      const b = FontSettings();
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs for different settings', () {
      const a = FontSettings();
      const b = FontSettings(appFontSelection: FontSelection(family: 'Inter'));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('FontSource', () {
    test('has two values', () {
      expect(FontSource.values.length, 2);
      expect(FontSource.values, contains(FontSource.google));
      expect(FontSource.values, contains(FontSource.system));
    });

    test('name returns correct string', () {
      expect(FontSource.google.name, 'google');
      expect(FontSource.system.name, 'system');
    });
  });

  group('fontSettingsProvider', () {
    test('is a valid NotifierProvider', () {
      expect(fontSettingsProvider, isA<NotifierProvider>());
    });
  });

  group('codeFontFamilyProvider', () {
    test('is a valid Provider', () {
      expect(codeFontFamilyProvider, isA<Provider<String>>());
    });
  });

  group('fontsReadyProvider', () {
    test('is a valid FutureProvider', () {
      expect(fontsReadyProvider, isA<FutureProvider>());
    });
  });

  group('FontSettingsNotifier', () {
    test('build returns default settings', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final settings = container.read(fontSettingsProvider);
      expect(settings.appFontSelection.family, AppFonts.uiFamily);
      expect(settings.codeFontSelection.family, AppFonts.codeFamily);
      expect(settings.appFontSelection.source, FontSource.google);
      expect(settings.codeFontSelection.source, FontSource.google);
    });

    test('build loads app font from prefs', () async {
      final prefs = AppPreferences.inMemory({
        'app_font_family': 'Inter',
        'app_font_source': 'google',
      });
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final settings = container.read(fontSettingsProvider);
      expect(settings.appFontSelection.family, 'Inter');
    });

    test('build loads code font from prefs', () async {
      final prefs = AppPreferences.inMemory({
        'code_font_family': 'Fira Code',
        'code_font_source': 'google',
      });
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final settings = container.read(fontSettingsProvider);
      expect(settings.codeFontSelection.family, 'Fira Code');
    });

    test('loadSystemFont returns immediately for google font', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(fontSettingsProvider.notifier);
      await notifier.loadSystemFont(
        const FontSelection(family: 'Inter', source: FontSource.google),
      );
    });

    test('loadSystemFont returns immediately for system font with null path', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(fontSettingsProvider.notifier);
      await notifier.loadSystemFont(
        const FontSelection(family: 'Custom', source: FontSource.system),
      );
    });

    test('isGoogleFont returns true for known fonts', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(fontSettingsProvider.notifier);
      expect(notifier.isGoogleFont('Inter'), isTrue);
      expect(notifier.isGoogleFont('Roboto'), isTrue);
    });

    test('isGoogleFont returns false for unknown fonts', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(fontSettingsProvider.notifier);
      expect(notifier.isGoogleFont('UnknownFontXYZ'), isFalse);
    });

    test('setAppFont updates state', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(fontSettingsProvider.notifier);
      await notifier.setAppFont(
        const FontSelection(family: 'Inter', source: FontSource.google),
      );
      final settings = container.read(fontSettingsProvider);
      expect(settings.appFontSelection.family, 'Inter');
    });

    test('setCodeFont updates state', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(fontSettingsProvider.notifier);
      await notifier.setCodeFont(
        const FontSelection(family: 'Fira Code', source: FontSource.google),
      );
      final settings = container.read(fontSettingsProvider);
      expect(settings.codeFontSelection.family, 'Fira Code');
    });
  });
}
