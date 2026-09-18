import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Locale variants the phone client offers, as BCP 47 `language-COUNTRY`
/// tags ordered A–Z. Mirrors desktop `kAppLocaleVariants` so a shared
/// `app_locale` preference resolves on both clients.
///
/// Native names stay in their own language — deliberately not localized.
const List<({String code, String label})> kRemoteLanguages = [
  (code: 'ar-SA', label: 'العربية (السعودية)'),
  (code: 'cs-CZ', label: 'Čeština (Česko)'),
  (code: 'de-DE', label: 'Deutsch (Deutschland)'),
  (code: 'el-GR', label: 'Ελληνικά (Ελλάδα)'),
  (code: 'en-GB', label: 'English (United Kingdom)'),
  (code: 'en-US', label: 'English (United States)'),
  (code: 'es-ES', label: 'Español (España)'),
  (code: 'es-MX', label: 'Español (México)'),
  (code: 'fa-IR', label: 'فارسی (ایران)'),
  (code: 'fr-CA', label: 'Français (Canada)'),
  (code: 'fr-FR', label: 'Français (France)'),
  (code: 'he-IL', label: 'עברית (ישראל)'),
  (code: 'hu-HU', label: 'Magyar (Magyarország)'),
  (code: 'id-ID', label: 'Bahasa Indonesia (Indonesia)'),
  (code: 'it-IT', label: 'Italiano (Italia)'),
  (code: 'ja-JP', label: '日本語（日本）'),
  (code: 'ko-KR', label: '한국어（대한민국）'),
  (code: 'ms-MY', label: 'Bahasa Melayu (Malaysia)'),
  (code: 'nb-NO', label: 'Norsk bokmål (Norge)'),
  (code: 'nl-NL', label: 'Nederlands (Nederland)'),
  (code: 'pl-PL', label: 'Polski (Polska)'),
  (code: 'pt-BR', label: 'Português (Brasil)'),
  (code: 'pt-PT', label: 'Português (Portugal)'),
  (code: 'ro-RO', label: 'Română (România)'),
  (code: 'ru-RU', label: 'Русский (Россия)'),
  (code: 'sv-SE', label: 'Svenska (Sverige)'),
  (code: 'th-TH', label: 'ไทย (ประเทศไทย)'),
  (code: 'tr-TR', label: 'Türkçe (Türkiye)'),
  (code: 'uk-UA', label: 'Українська (Україна)'),
  (code: 'ur-PK', label: 'اردو (پاکستان)'),
  (code: 'vi-VN', label: 'Tiếng Việt (Việt Nam)'),
  (code: 'zh-CN', label: '中文（简体）'),
  (code: 'zh-HK', label: '中文（香港）'),
  (code: 'zh-TW', label: '中文（繁體）'),
];

/// Parses a BCP 47 tag (`de-DE`) into a [Locale]. `Locale('de-DE')` would
/// treat the whole string as a language code.
Locale localeFromBcp47(String tag) {
  final parts = tag.split('-');
  return parts.length == 1
      ? Locale(parts.first)
      : Locale(parts.first, parts.last);
}

/// Locales for `WidgetsApp.supportedLocales`: generated ARB locales first
/// (what a system locale resolves against), then every region-qualified
/// picker variant so a persisted `cs-CZ` stays `cs-CZ` instead of collapsing
/// to language-only `cs`.
final kSupportedRemoteLocales = <Locale>[
  ...AppLocalizations.supportedLocales,
  ...kRemoteLanguages.map((lang) => localeFromBcp47(lang.code)),
];

/// Accepts only a shipped picker tag (`fr-FR`). Bare languages (`fr`) and
/// any other form resolve to `null` (follow system).
String? canonicalRemoteLocaleTag(String? raw) {
  if (raw == null) {
    return null;
  }
  final tag = raw.trim();
  if (tag.isEmpty) {
    return null;
  }
  for (final lang in kRemoteLanguages) {
    if (lang.code == tag) {
      return tag;
    }
  }
  return null;
}

/// Maps a requested locale onto the locale whose ARB should actually load.
///
/// Hong Kong Chinese is Traditional. Flutter gen-l10n emits `zh_HK` as a
/// sparse subclass of Simplified `zh`, so missing keys would render
/// Simplified. Resolve `zh-HK` onto `zh-TW` (full Traditional) instead.
Locale remapTranslationLocale(Locale locale) {
  if (locale.languageCode == 'zh' && locale.countryCode == 'HK') {
    return const Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW');
  }
  return locale;
}

/// [WidgetsApp.localeResolutionCallback] that applies
/// [remapTranslationLocale] then Flutter's default matching.
Locale? resolveRemoteLocale(Locale? locale, Iterable<Locale> supportedLocales) {
  final requested = locale == null
      ? const <Locale>[]
      : <Locale>[remapTranslationLocale(locale)];
  return basicLocaleListResolution(requested, supportedLocales);
}
