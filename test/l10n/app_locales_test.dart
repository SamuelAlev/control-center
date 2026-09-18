import 'dart:io';

import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kAppLocaleVariants', () {
    test('every variant language has a base ARB locale', () {
      final generated = AppLocalizations.supportedLocales
          .map((locale) => locale.languageCode)
          .toSet();
      for (final variant in kAppLocaleVariants) {
        expect(
          generated,
          contains(variant.languageCode),
          reason:
              '${variant.tag} names a language with no app_<lang>.arb — the '
              'picker would offer a locale that never resolves.',
        );
      }
    });

    test('Arabic and Hebrew ship as generated locales', () {
      final generated = AppLocalizations.supportedLocales
          .map((locale) => locale.languageCode)
          .toSet();
      expect(generated, containsAll(['ar', 'he']));
    });

    test('every generated language has a picker variant', () {
      final registered = kAppLocaleVariants
          .map((variant) => variant.languageCode)
          .toSet();
      for (final locale in AppLocalizations.supportedLocales) {
        expect(
          registered,
          contains(locale.languageCode),
          reason:
              'app_${locale.languageCode}.arb has no kAppLocaleVariants entry '
              '— that translation is unreachable from the picker.',
        );
      }
    });

    test('tags are unique and sorted A–Z', () {
      final tags = kAppLocaleVariants.map((variant) => variant.tag).toList();
      expect(tags.toSet().length, tags.length);
      expect(tags, List<String>.from(tags)..sort());
    });

    test('native labels name language and country', () {
      for (final variant in kAppLocaleVariants) {
        // ASCII or fullwidth parentheses — CJK labels use the latter.
        expect(
          variant.nativeLabel.contains('(') ||
              variant.nativeLabel.contains('（'),
          isTrue,
          reason: '${variant.tag} label lacks a country qualifier',
        );
        expect(
          variant.nativeLabel.endsWith(')') ||
              variant.nativeLabel.endsWith('）'),
          isTrue,
        );
      }
    });

    test('locale is the region-qualified pair', () {
      const locale = Locale('fr', 'FR');
      expect(kAppLocaleVariants.any((v) => v.locale == locale), isTrue);
    });

    test('supportedLocales includes every country-qualified variant', () {
      for (final variant in kAppLocaleVariants) {
        expect(
          kSupportedAppLocales,
          contains(variant.locale),
          reason: '${variant.tag} would collapse to language-only',
        );
      }
    });

    test('desktop and remote pickers ship the same BCP 47 tags', () {
      final desktop = kAppLocaleVariants.map((v) => v.tag).toList();
      final remoteFile = File('apps/cc_remote/lib/l10n/remote_locales.dart');
      expect(
        remoteFile.existsSync(),
        isTrue,
        reason: 'run this suite from the repo root',
      );
      final remote = RegExp(r"code: '([a-z]{2}-[A-Z]{2})'")
          .allMatches(remoteFile.readAsStringSync())
          .map((match) => match[1]!)
          .toList();
      expect(remote, desktop);
    });
  });

  group('parsePersistedLocale', () {
    test('parses the canonical BCP 47 form', () {
      expect(parsePersistedLocale('fr-FR')?.tag, 'fr-FR');
      expect(parsePersistedLocale('en-US')?.tag, 'en-US');
      expect(parsePersistedLocale('zh-CN')?.tag, 'zh-CN');
      expect(parsePersistedLocale('zh-TW')?.tag, 'zh-TW');
    });

    test('two variants of one language do not collapse', () {
      expect(parsePersistedLocale('zh-TW')?.tag, 'zh-TW');
      expect(parsePersistedLocale('zh-CN')?.tag, 'zh-CN');
    });

    test('anything other than an exact shipped tag is follow-system', () {
      expect(parsePersistedLocale('zh'), isNull);
      expect(parsePersistedLocale('nl'), isNull);
      expect(parsePersistedLocale('pt_BR'), isNull);
      expect(parsePersistedLocale('fr-CH'), isNull);
      expect(parsePersistedLocale('en_gb'), isNull);
      expect(parsePersistedLocale('zz'), isNull);
      expect(parsePersistedLocale('zz-ZZ'), isNull);
      expect(parsePersistedLocale('system'), isNull);
      expect(parsePersistedLocale(''), isNull);
      expect(parsePersistedLocale('fr-FR-x-formal'), isNull);
    });
  });

  group('localePickerQueryMatches', () {
    const france = Locale.fromSubtags(languageCode: 'fr', countryCode: 'FR');

    test('empty query matches every option', () {
      expect(
        localePickerQueryMatches(
          query: '  ',
          label: 'Français (France)',
          locale: france,
        ),
        isTrue,
      );
    });

    test('matches native label, language code, country and BCP 47 tag', () {
      const label = 'Français (France)';
      expect(
        localePickerQueryMatches(query: 'fran', label: label, locale: france),
        isTrue,
      );
      expect(
        localePickerQueryMatches(query: 'FR', label: label, locale: france),
        isTrue,
      );
      expect(
        localePickerQueryMatches(query: 'fr-fr', label: label, locale: france),
        isTrue,
      );
      expect(
        localePickerQueryMatches(
          query: 'Deutsch',
          label: label,
          locale: france,
        ),
        isFalse,
      );
    });

    test('matches the follow-system option by its localized label', () {
      expect(
        localePickerQueryMatches(
          query: 'sys',
          label: 'System',
          locale: const Locale('system'),
        ),
        isTrue,
      );
    });
  });

  group('formatLocaleTag', () {
    test('serializes region-qualified locales as BCP 47', () {
      expect(formatLocaleTag(const Locale('pt', 'BR')), 'pt-BR');
    });

    test('serializes language-only locales bare', () {
      expect(formatLocaleTag(const Locale('de')), 'de');
    });

    test('round-trips through parsePersistedLocale', () {
      for (final variant in kAppLocaleVariants) {
        expect(
          parsePersistedLocale(formatLocaleTag(variant.locale)),
          same(variant),
        );
      }
    });
  });

  group('resolveAppLocale', () {
    test('maps zh-HK onto Traditional zh-TW', () {
      expect(
        remapTranslationLocale(const Locale('zh', 'HK')),
        const Locale('zh', 'TW'),
      );
      expect(
        resolveAppLocale(const Locale('zh', 'HK'), kSupportedAppLocales),
        const Locale('zh', 'TW'),
      );
    });

    test('keeps a region-qualified pin', () {
      expect(
        resolveAppLocale(const Locale('cs', 'CZ'), kSupportedAppLocales),
        const Locale('cs', 'CZ'),
      );
      expect(
        resolveAppLocale(const Locale('fa', 'IR'), kSupportedAppLocales),
        const Locale('fa', 'IR'),
      );
      expect(
        resolveAppLocale(const Locale('ur', 'PK'), kSupportedAppLocales),
        const Locale('ur', 'PK'),
      );
    });

    test('keeps zh-CN as Simplified and zh-TW as Traditional', () {
      expect(
        remapTranslationLocale(const Locale('zh', 'CN')),
        const Locale('zh', 'CN'),
      );
      expect(
        resolveAppLocale(const Locale('zh', 'CN'), kSupportedAppLocales),
        const Locale('zh', 'CN'),
      );
      expect(
        resolveAppLocale(const Locale('zh', 'TW'), kSupportedAppLocales),
        const Locale('zh', 'TW'),
      );
    });
  });
}
