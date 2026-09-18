import 'package:flutter/widgets.dart';

import 'package:control_center/l10n/app_localizations.dart';

/// One locale variant the app ships, as a BCP 47 `language-COUNTRY` pair.
///
/// The registry is the single enumeration of what the language picker offers,
/// what `MaterialApp.supportedLocales` admits and what the persisted
/// `app_locale` preference stores — adding a variant (fr-BE, en-GB, …) is
/// appending an entry here, plus an `app_<lang>_<country>.arb` only once that
/// variant's translations actually diverge (a sparse variant ARB is legal:
/// keys missing from it fall back to the language's base ARB at generation
/// time).
class AppLocaleVariant {
  /// Creates a variant from its ISO codes and its self-named picker label.
  const AppLocaleVariant(this.languageCode, this.countryCode, this.nativeLabel);

  /// ISO 639-1 language code (`'fr'`). Every language here must have a base
  /// ARB (`app_fr.arb`); `test/l10n/app_locales_test.dart` pins the two sets
  /// together so a registry entry without an ARB (or the reverse) fails.
  final String languageCode;

  /// ISO 3166-1 alpha-2 country code (`'FR'`).
  final String countryCode;

  /// Self-named picker label, country included: `Français (France)`.
  ///
  /// Deliberately NOT localized: each language names itself (and its country)
  /// so the entry is findable by speakers of every language — the same
  /// convention every OS language list uses. Values are identical across
  /// locales, which is why this is a constant and not an l10n key.
  final String nativeLabel;

  /// The region-qualified [Locale] used for `MaterialApp.locale` and the
  /// picker's option values.
  Locale get locale =>
      Locale.fromSubtags(languageCode: languageCode, countryCode: countryCode);

  /// BCP 47 tag as persisted in the `app_locale` preference (`'fr-FR'`).
  String get tag => '$languageCode-$countryCode';

  @override
  String toString() => tag;
}

/// Every locale variant the app ships, ordered A–Z by BCP 47 tag.
/// Chinese ships two (Hans `zh-CN` + a full Hant translation in
/// `app_zh_TW.arb`). Further country variants are appended here as they
/// ship.
const kAppLocaleVariants = <AppLocaleVariant>[
  AppLocaleVariant('ar', 'SA', 'العربية (السعودية)'),
  AppLocaleVariant('cs', 'CZ', 'Čeština (Česko)'),
  AppLocaleVariant('de', 'DE', 'Deutsch (Deutschland)'),
  AppLocaleVariant('el', 'GR', 'Ελληνικά (Ελλάδα)'),
  AppLocaleVariant('en', 'GB', 'English (United Kingdom)'),
  AppLocaleVariant('en', 'US', 'English (United States)'),
  AppLocaleVariant('es', 'ES', 'Español (España)'),
  AppLocaleVariant('es', 'MX', 'Español (México)'),
  AppLocaleVariant('fa', 'IR', 'فارسی (ایران)'),
  AppLocaleVariant('fr', 'CA', 'Français (Canada)'),
  AppLocaleVariant('fr', 'FR', 'Français (France)'),
  AppLocaleVariant('he', 'IL', 'עברית (ישראל)'),
  AppLocaleVariant('hu', 'HU', 'Magyar (Magyarország)'),
  AppLocaleVariant('id', 'ID', 'Bahasa Indonesia (Indonesia)'),
  AppLocaleVariant('it', 'IT', 'Italiano (Italia)'),
  AppLocaleVariant('ja', 'JP', '日本語（日本）'),
  AppLocaleVariant('ko', 'KR', '한국어（대한민국）'),
  AppLocaleVariant('ms', 'MY', 'Bahasa Melayu (Malaysia)'),
  AppLocaleVariant('nb', 'NO', 'Norsk bokmål (Norge)'),
  AppLocaleVariant('nl', 'NL', 'Nederlands (Nederland)'),
  AppLocaleVariant('pl', 'PL', 'Polski (Polska)'),
  AppLocaleVariant('pt', 'BR', 'Português (Brasil)'),
  AppLocaleVariant('pt', 'PT', 'Português (Portugal)'),
  AppLocaleVariant('ro', 'RO', 'Română (România)'),
  AppLocaleVariant('ru', 'RU', 'Русский (Россия)'),
  AppLocaleVariant('sv', 'SE', 'Svenska (Sverige)'),
  AppLocaleVariant('th', 'TH', 'ไทย (ประเทศไทย)'),
  AppLocaleVariant('tr', 'TR', 'Türkçe (Türkiye)'),
  AppLocaleVariant('uk', 'UA', 'Українська (Україна)'),
  AppLocaleVariant('ur', 'PK', 'اردو (پاکستان)'),
  AppLocaleVariant('vi', 'VN', 'Tiếng Việt (Việt Nam)'),
  AppLocaleVariant('zh', 'CN', '中文（简体）'),
  AppLocaleVariant('zh', 'HK', '中文（香港）'),
  AppLocaleVariant('zh', 'TW', '中文（繁體）'),
];

/// Locales for `MaterialApp.supportedLocales`: the language-only locales
/// generated from the ARBs first (what a system locale resolves against),
/// then the region-qualified variants (what the picker and the persisted
/// preference pin exactly).
final kSupportedAppLocales = <Locale>[
  ...AppLocalizations.supportedLocales,
  ...kAppLocaleVariants.map((variant) => variant.locale),
];

/// Parses a persisted `app_locale` value into a registry variant.
///
/// Only the canonical BCP 47 tag (`fr-FR`) is accepted. Anything else —
/// a bare language (`fr`), an underscore form, an unshipped country —
/// resolves to `null` (follow system) rather than guessing.
AppLocaleVariant? parsePersistedLocale(String raw) {
  final tag = raw.trim();
  if (tag.isEmpty) {
    return null;
  }
  for (final variant in kAppLocaleVariants) {
    if (variant.tag == tag) {
      return variant;
    }
  }
  return null;
}

/// Serializes a [Locale] to its BCP 47 tag for persistence.
String formatLocaleTag(Locale locale) {
  final country = locale.countryCode;
  return country == null || country.isEmpty
      ? locale.languageCode
      : '${locale.languageCode}-$country';
}

/// Whether a typed language-picker query hits this option.
///
/// Matches the visible label, the language code, the country code and the
/// BCP 47 tag so `fr`, `FR`, `fr-FR` and `Français` all find France.
bool localePickerQueryMatches({
  required String query,
  required String label,
  required Locale locale,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return true;
  }
  if (label.toLowerCase().contains(q)) {
    return true;
  }
  if (locale.languageCode.toLowerCase().contains(q)) {
    return true;
  }
  final country = locale.countryCode;
  if (country != null && country.toLowerCase().contains(q)) {
    return true;
  }
  return formatLocaleTag(locale).toLowerCase().contains(q);
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

/// [MaterialApp.localeResolutionCallback] that applies
/// [remapTranslationLocale] then Flutter's default matching.
Locale? resolveAppLocale(Locale? locale, Iterable<Locale> supportedLocales) {
  final requested = locale == null
      ? const <Locale>[]
      : <Locale>[remapTranslationLocale(locale)];
  return basicLocaleListResolution(requested, supportedLocales);
}
