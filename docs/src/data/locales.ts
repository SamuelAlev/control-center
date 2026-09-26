/** Same order and native labels as `kAppLocaleVariants` in the app. */
export const siteLocales = [
  { id: 'ar-SA', name: 'العربية (السعودية)', path: '/ar-SA/' },
  { id: 'cs-CZ', name: 'Čeština (Česko)', path: '/cs-CZ/' },
  { id: 'de-DE', name: 'Deutsch (Deutschland)', path: '/de-DE/' },
  { id: 'el-GR', name: 'Ελληνικά (Ελλάδα)', path: '/el-GR/' },
  { id: 'en-GB', name: 'English (United Kingdom)', path: '/en-GB/' },
  { id: 'en-US', name: 'English (United States)', path: '/' },
  { id: 'es-ES', name: 'Español (España)', path: '/es-ES/' },
  { id: 'es-MX', name: 'Español (México)', path: '/es-MX/' },
  { id: 'fa-IR', name: 'فارسی (ایران)', path: '/fa-IR/' },
  { id: 'fr-CA', name: 'Français (Canada)', path: '/fr-CA/' },
  { id: 'fr-FR', name: 'Français (France)', path: '/fr-FR/' },
  { id: 'he-IL', name: 'עברית (ישראל)', path: '/he-IL/' },
  { id: 'hu-HU', name: 'Magyar (Magyarország)', path: '/hu-HU/' },
  { id: 'id-ID', name: 'Bahasa Indonesia (Indonesia)', path: '/id-ID/' },
  { id: 'it-IT', name: 'Italiano (Italia)', path: '/it-IT/' },
  { id: 'ja-JP', name: '日本語（日本）', path: '/ja-JP/' },
  { id: 'ko-KR', name: '한국어（대한민국）', path: '/ko-KR/' },
  { id: 'ms-MY', name: 'Bahasa Melayu (Malaysia)', path: '/ms-MY/' },
  { id: 'nb-NO', name: 'Norsk bokmål (Norge)', path: '/nb-NO/' },
  { id: 'nl-NL', name: 'Nederlands (Nederland)', path: '/nl-NL/' },
  { id: 'pl-PL', name: 'Polski (Polska)', path: '/pl-PL/' },
  { id: 'pt-BR', name: 'Português (Brasil)', path: '/pt-BR/' },
  { id: 'pt-PT', name: 'Português (Portugal)', path: '/pt-PT/' },
  { id: 'ro-RO', name: 'Română (România)', path: '/ro-RO/' },
  { id: 'ru-RU', name: 'Русский (Россия)', path: '/ru-RU/' },
  { id: 'sv-SE', name: 'Svenska (Sverige)', path: '/sv-SE/' },
  { id: 'th-TH', name: 'ไทย (ประเทศไทย)', path: '/th-TH/' },
  { id: 'tr-TR', name: 'Türkçe (Türkiye)', path: '/tr-TR/' },
  { id: 'uk-UA', name: 'Українська (Україна)', path: '/uk-UA/' },
  { id: 'ur-PK', name: 'اردو (پاکستان)', path: '/ur-PK/' },
  { id: 'vi-VN', name: 'Tiếng Việt (Việt Nam)', path: '/vi-VN/' },
  { id: 'zh-CN', name: '中文（简体）', path: '/zh-CN/' },
  { id: 'zh-HK', name: '中文（香港）', path: '/zh-HK/' },
  { id: 'zh-TW', name: '中文（繁體）', path: '/zh-TW/' },
] as const;

export type SiteLocale = (typeof siteLocales)[number]['id'];

/** An explicit picker choice, including English's otherwise unprefixed URL. */
export const localeChoiceParameter = 'lang';

/**
 * Locales that also advertise the bare language code (`en`, `fr`, `zh`).
 * One code, one URL: regional pages keep only their full BCP 47 tag.
 */
export const siteLanguageDefaults = new Set<SiteLocale>([
  'ar-SA',
  'cs-CZ',
  'de-DE',
  'el-GR',
  'en-US',
  'es-ES',
  'fa-IR',
  'fr-FR',
  'he-IL',
  'hu-HU',
  'id-ID',
  'it-IT',
  'ja-JP',
  'ko-KR',
  'ms-MY',
  'nb-NO',
  'nl-NL',
  'pl-PL',
  'pt-BR',
  'ro-RO',
  'ru-RU',
  'sv-SE',
  'th-TH',
  'tr-TR',
  'uk-UA',
  'ur-PK',
  'vi-VN',
  'zh-CN',
]);

export const siteRtl = new Set<SiteLocale>(['ar-SA', 'fa-IR', 'he-IL', 'ur-PK']);

export const landingPath = (locale: SiteLocale) => (locale === 'en-US' ? '/' : `/${locale}/`);

/** Match stored preferences only against the supported BCP-47 identifiers. */
export function isSiteLocale(value: unknown): value is SiteLocale {
  return siteLocales.some(locale => locale.id === value);
}

/** Resolve the site's canonical BCP-47 locale from either surface's URL. */
export function localeFromPath(pathname: string): SiteLocale {
  const prefix = pathname.split('/')[1]?.toLowerCase();
  return siteLocales.find(locale => locale.id.toLowerCase() === prefix)?.id ?? 'en-US';
}

export function unlocalizedPath(pathname: string): string {
  const prefix = pathname.split('/')[1]?.toLowerCase();
  if (!siteLocales.some(locale => locale.id.toLowerCase() === prefix)) return pathname;
  const end = pathname.indexOf('/', 1);
  return end === -1 ? '/' : pathname.slice(end);
}

/** Only the landing page and manual are translated destinations. */
export function localizePath(pathname: string, locale: SiteLocale): string {
  const path = unlocalizedPath(pathname);
  if (path === '/') return landingPath(locale);
  if (path === '/manual' || path.startsWith('/manual/')) {
    return (locale === 'en-US' ? '' : '/' + locale) + path;
  }
  return pathname;
}

export const manualPath = (locale: SiteLocale) => localizePath('/manual/', locale);
