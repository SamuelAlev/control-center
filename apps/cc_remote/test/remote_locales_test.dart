import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kRemoteLanguages', () {
    test('every entry is a language-COUNTRY BCP 47 tag', () {
      final tag = RegExp(r'^[a-z]{2}-[A-Z]{2}$');
      for (final lang in kRemoteLanguages) {
        expect(lang.code, matches(tag), reason: lang.code);
        expect(localeFromBcp47(lang.code).countryCode, isNotNull);
      }
    });

    test('tags are unique and sorted A–Z', () {
      final tags = kRemoteLanguages.map((lang) => lang.code).toList();
      expect(tags.toSet().length, tags.length);
      expect(tags, List<String>.from(tags)..sort());
    });

    test('every variant language has a generated ARB locale', () {
      final generated = AppLocalizations.supportedLocales
          .map((locale) => locale.languageCode)
          .toSet();
      for (final lang in kRemoteLanguages) {
        expect(
          generated,
          contains(localeFromBcp47(lang.code).languageCode),
          reason: '${lang.code} has no app_<lang>.arb',
        );
      }
    });

    test('every generated language has a picker variant', () {
      final registered = kRemoteLanguages
          .map((lang) => localeFromBcp47(lang.code).languageCode)
          .toSet();
      for (final locale in AppLocalizations.supportedLocales) {
        expect(
          registered,
          contains(locale.languageCode),
          reason: 'app_${locale.languageCode}.arb is unreachable from the picker',
        );
      }
    });
  });

  group('kSupportedRemoteLocales', () {
    test('contains every region-qualified picker locale', () {
      for (final lang in kRemoteLanguages) {
        expect(
          kSupportedRemoteLocales,
          contains(localeFromBcp47(lang.code)),
          reason: '${lang.code} would collapse to language-only',
        );
      }
    });
  });

  group('canonicalRemoteLocaleTag', () {
    test('accepts only shipped tags', () {
      expect(canonicalRemoteLocaleTag('cs-CZ'), 'cs-CZ');
      expect(canonicalRemoteLocaleTag('fa-IR'), 'fa-IR');
      expect(canonicalRemoteLocaleTag('ur-PK'), 'ur-PK');
      expect(canonicalRemoteLocaleTag('zh-HK'), 'zh-HK');
      expect(canonicalRemoteLocaleTag('cs'), isNull);
      expect(canonicalRemoteLocaleTag('fr-CH'), isNull);
    });
  });

  group('resolveRemoteLocale', () {
    test('keeps a region-qualified pin', () {
      expect(
        resolveRemoteLocale(const Locale('cs', 'CZ'), kSupportedRemoteLocales),
        const Locale('cs', 'CZ'),
      );
      expect(
        resolveRemoteLocale(const Locale('de', 'DE'), kSupportedRemoteLocales),
        const Locale('de', 'DE'),
      );
    });

    test('maps zh-HK onto Traditional zh-TW', () {
      expect(
        remapTranslationLocale(const Locale('zh', 'HK')),
        const Locale('zh', 'TW'),
      );
      expect(
        resolveRemoteLocale(const Locale('zh', 'HK'), kSupportedRemoteLocales),
        const Locale('zh', 'TW'),
      );
    });
  });
}
