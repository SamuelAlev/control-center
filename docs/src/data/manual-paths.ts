/**
 * Translated manual URLs, as pure functions over a {@link ManualRoutes} table.
 *
 * Each locale's manual mirrors the English file names
 * (`src/content/docs/<locale>/manual/…` beside `src/content/docs/manual/…`) and
 * sets the page's translated URL as its `slug` frontmatter. The table comes from
 * those pages: the content collection at build time (`manual-routes.ts`), the
 * files for the checker and sitemap (`scripts/manual-i18n.ts`), and the build's
 * `/manual-routes.json` in the Worker.
 *
 * Server-only: the browser keeps the prefix-only helpers in `locales.ts`, and
 * the Worker redirects the prefixed English paths those produce
 * (`manualRedirect`).
 */
import { landingPath, siteLocales, type SiteLocale } from './locales.ts';

/** Locale → English page id (`manual/guides/create-agent`) → translated path, no locale prefix or slashes. */
export type ManualRoutes = Readonly<Record<string, Readonly<Record<string, string>>>>;
export type TranslatedLocale = Exclude<SiteLocale, 'en-US'>;

export const translatedLocales = siteLocales
  .map(({ id }) => id)
  .filter((id): id is TranslatedLocale => id !== 'en-US');

const MANUAL = 'manual';

/** True for an English manual id or section (`manual`, `manual/guides/create-agent`). */
export function isManualId(id: string): boolean {
  return id === MANUAL || id.startsWith(MANUAL + '/');
}

/**
 * Where a docs file is the locale copy of an English manual page:
 * `fr-FR/manual/guides/create-agent.mdx` (relative to `src/content/docs`) →
 * `{ locale: 'fr-FR', id: 'manual/guides/create-agent' }`.
 */
export function localeManualPage(relativeFile: string): { locale: TranslatedLocale; id: string } | undefined {
  const [prefix, ...rest] = relativeFile.split('/');
  const locale = translatedLocales.find(candidate => candidate === prefix);
  const id = rest.join('/').replace(/\.mdx?$/, '').replace(/\/index$/, '');
  return locale && isManualId(id) ? { locale, id } : undefined;
}

/** Builds the table from each locale page's English id and translated `slug` (`fr-FR/manuel/…`). */
export function manualRoutesFrom(pages: Iterable<{ locale: string; id: string; slug: string }>): ManualRoutes {
  const routes: Record<string, Record<string, string>> = {};
  for (const { locale, id, slug } of pages) {
    if (!slug.startsWith(locale + '/')) continue;
    (routes[locale] ??= {})[id] = slug.slice(locale.length + 1).normalize('NFC');
  }
  return routes;
}

/** The translated path of English manual page [id] in [locale], or undefined when that page has none. */
export function translateManualId(id: string, locale: SiteLocale, routes: ManualRoutes): string | undefined {
  return locale === 'en-US' ? id : routes[locale]?.[id];
}

const reverseTables = new WeakMap<ManualRoutes, Map<string, Map<string, string>>>();

/** The English manual id served at translated [path] in [locale], if any. */
export function manualIdFromTranslated(path: string, locale: string, routes: ManualRoutes): string | undefined {
  let tables = reverseTables.get(routes);
  if (!tables) reverseTables.set(routes, (tables = new Map()));
  let reverse = tables.get(locale);
  if (!reverse) {
    reverse = new Map(Object.entries(routes[locale] ?? {}).map(([id, translated]) => [translated, id]));
    tables.set(locale, reverse);
  }
  return reverse.get(path);
}

function decodePath(pathname: string): string {
  try {
    return decodeURI(pathname).normalize('NFC');
  } catch {
    return pathname;
  }
}

const trimSlashes = (path: string) => path.replace(/^\/+|\/+$/g, '');

function splitLocale(path: string): { locale: SiteLocale; rest: string } {
  const prefix = path.split('/')[1]?.toLowerCase();
  const locale = translatedLocales.find(candidate => candidate.toLowerCase() === prefix);
  if (!locale) return { locale: 'en-US', rest: path };
  const end = path.indexOf('/', 1);
  return { locale, rest: end === -1 ? '/' : path.slice(end) };
}

/** English id for a path under [locale]: its own slugs, the prefixed English ones, then any other locale's. */
function resolveManualId(inner: string, locale: TranslatedLocale, routes: ManualRoutes): string | undefined {
  const own = manualIdFromTranslated(inner, locale, routes);
  if (own) return own;
  if (isManualId(inner)) return inner;
  for (const other of translatedLocales) {
    if (other === locale) continue;
    const id = manualIdFromTranslated(inner, other, routes);
    if (id) return id;
  }
  return undefined;
}

/**
 * The English site path of [pathname]: the locale prefix removed and translated
 * manual slugs resolved back to English ids. Accepts percent-encoded paths.
 */
export function unlocalizeSitePath(pathname: string, routes: ManualRoutes): string {
  const path = decodePath(pathname);
  const { locale, rest } = splitLocale(path);
  if (locale === 'en-US') return path;
  const inner = trimSlashes(rest);
  if (!inner) return '/';
  const id = resolveManualId(inner, locale, routes);
  return id ? `/${id}${rest.endsWith('/') ? '/' : ''}` : rest;
}

/** True when [pathname], in any locale, is the landing page or a manual page. */
export function isTranslatedSitePath(pathname: string, routes: ManualRoutes): boolean {
  const path = unlocalizeSitePath(pathname, routes);
  return path === '/' || isManualId(trimSlashes(path));
}

/**
 * [pathname] in [locale]: the landing page or the manual page under its
 * translated slug. Other paths are English-only and come back unchanged.
 * Returns an unencoded path.
 */
export function localizeSitePath(pathname: string, locale: SiteLocale, routes: ManualRoutes): string {
  const path = unlocalizeSitePath(pathname, routes);
  if (path === '/') return landingPath(locale);
  const id = trimSlashes(path);
  if (!isManualId(id)) return pathname;
  const trailing = path.endsWith('/') ? '/' : '';
  if (locale === 'en-US') return `/${id}${trailing}`;
  // A page without a locale copy keeps Starlight's prefixed English fallback.
  return `/${locale}/${translateManualId(id, locale, routes) ?? id}${trailing}`;
}

export const manualPath = (locale: SiteLocale, routes: ManualRoutes) => localizeSitePath('/manual/', locale, routes);

/** Sitemap `hreflang` alternates of a landing or manual page [url]; undefined for English-only pages. */
export function sitemapAlternates(url: string, routes: ManualRoutes): { url: string; lang: string }[] | undefined {
  const { origin, pathname } = new URL(url);
  if (!isTranslatedSitePath(pathname, routes)) return undefined;
  return siteLocales.map(({ id }) => ({
    lang: id === 'en-US' ? 'en' : id,
    url: new URL(localizeSitePath(pathname, id, routes), origin).href,
  }));
}

/**
 * Where a localized manual URL that is not canonical lives now: Starlight's
 * prefixed English path (the pre-translation URL, still built as a fallback
 * route) or another locale's slug under this prefix. Null when [pathname] is
 * canonical or not a manual page. Returns an unencoded path.
 */
export function manualRedirect(pathname: string, routes: ManualRoutes): string | null {
  const path = decodePath(pathname);
  const { locale, rest } = splitLocale(path);
  if (locale === 'en-US') return null;
  const inner = trimSlashes(rest);
  if (!inner || manualIdFromTranslated(inner, locale, routes)) return null;
  const id = resolveManualId(inner, locale, routes);
  const translated = id && translateManualId(id, locale, routes);
  if (!translated || translated === inner) return null;
  return `/${locale}/${translated}${rest.endsWith('/') ? '/' : ''}`;
}
