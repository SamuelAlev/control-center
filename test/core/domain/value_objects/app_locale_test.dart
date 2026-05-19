import 'package:control_center/core/domain/value_objects/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocale', () {
    test('constructor sets languageCode', () {
      const locale = AppLocale('fr');
      expect(locale.languageCode, 'fr');
    });

    group('displayName', () {
      test('returns correct name for known locales', () {
        const cases = <String, String>{
          'fr': 'French',
          'es': 'Spanish',
          'it': 'Italian',
          'de': 'German',
          'pt': 'Portuguese',
          'nl': 'Dutch',
        };
        for (final entry in cases.entries) {
          expect(AppLocale(entry.key).displayName, entry.value, reason: entry.key);
        }
      });

      test('returns null for unknown locale', () {
        expect(const AppLocale('xx').displayName, isNull);
      });

      test('returns null for en (not in the map)', () {
        expect(const AppLocale('en').displayName, isNull);
      });
    });

    group('isEnglish', () {
      test('returns true for en', () {
        expect(const AppLocale('en').isEnglish, isTrue);
      });

      test('returns false for other codes', () {
        expect(const AppLocale('fr').isEnglish, isFalse);
        expect(const AppLocale('de').isEnglish, isFalse);
      });
    });

    group('hasLocalization', () {
      test('returns true for codes in the map', () {
        for (final code in ['fr', 'es', 'it', 'de', 'pt', 'nl']) {
          expect(AppLocale(code).hasLocalization, isTrue, reason: code);
        }
      });

      test('returns false for en', () {
        expect(const AppLocale('en').hasLocalization, isFalse);
      });

      test('returns false for unknown codes', () {
        expect(const AppLocale('xx').hasLocalization, isFalse);
        expect(const AppLocale('ja').hasLocalization, isFalse);
      });
    });

    group('== and hashCode', () {
      test('same languageCode equals', () {
        expect(const AppLocale('fr'), equals(const AppLocale('fr')));
      });

      test('different languageCode not equal', () {
        expect(const AppLocale('fr'), isNot(equals(const AppLocale('de'))));
      });

      test('hashCode consistency', () {
        const a = AppLocale('es');
        const b = AppLocale('es');
        expect(a.hashCode, b.hashCode);
      });

      test('const constructor works', () {
        const a = AppLocale('en');
        const b = AppLocale('en');
        expect(identical(a, b), isTrue);
      });
    });
  });
}
