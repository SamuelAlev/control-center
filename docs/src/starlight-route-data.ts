/**
 * Starlight route middleware for the translated manual.
 *
 * Starlight pairs a translation with its English page by path, but locale
 * manuals are served under translated slugs (see src/data/manual-paths.ts). So
 * for every manual page this:
 *
 * - emits the same `hreflang` set as the landing page (every BCP 47 tag, the
 *   bare language for each language's main region, `x-default`), pointing at
 *   each locale's translated URL, and the matching `og:locale` alternates;
 * - points the sidebar and prev/next links at this locale's translated URLs
 *   (Starlight resolves them to its prefixed English fallback routes) and marks
 *   the current page;
 * - shows an untranslated locale page (no `sourceHash` yet) as English text
 *   with Starlight's "not translated yet" notice;
 * - keeps Starlight's prefixed English fallback of a page that has a locale
 *   copy out of search and indexes — the Worker redirects that URL anyway.
 */
import { defineRouteMiddleware, type StarlightRouteData } from '@astrojs/starlight/route-data';
import { siteLanguageDefaults, siteLocales, type SiteLocale } from './data/locales.ts';
import {
  isManualId,
  localeManualPage,
  localizeSitePath,
  translateManualId,
  type ManualRoutes,
} from './data/manual-paths.ts';
import { getManualRoutes } from './data/manual-routes.ts';

type SidebarEntry = StarlightRouteData['sidebar'][number];
type SidebarLink = Extract<SidebarEntry, { type: 'link' }>;

/** The English manual id a route renders, from its source file. */
function englishId(route: StarlightRouteData): string | undefined {
  // Starlight's built-in 404 route has no source file.
  const file = (route.entry.filePath ?? '').replace(/^src\/content\/docs\//, '');
  const id = localeManualPage(file)?.id ?? file.replace(/\.mdx?$/, '').replace(/\/index$/, '');
  return isManualId(id) ? id : undefined;
}

const ogLocale = (locale: SiteLocale) => locale.replace('-', '_');

const comparable = (path: string) => {
  let decoded = path;
  try {
    decoded = decodeURI(path);
  } catch {
    // Keep the raw path.
  }
  return decoded.normalize('NFC').replace(/\/+$/, '');
};

function links(entries: SidebarEntry[]): SidebarLink[] {
  return entries.flatMap(entry => (entry.type === 'group' ? links(entry.entries) : [entry]));
}

function localizeNavigation(route: StarlightRouteData, locale: SiteLocale, routes: ManualRoutes, pathname: string) {
  const current = comparable(pathname);
  const flat = links(route.sidebar);
  for (const link of flat) {
    link.href = localizeSitePath(link.href, locale, routes);
    link.isCurrent = comparable(link.href) === current;
  }
  // Starlight computed prev/next before the hrefs above matched the page.
  const index = flat.findIndex(link => link.isCurrent);
  const { prev, next } = route.entry.data;
  route.pagination = {
    prev: prev === false || index < 1 ? undefined : flat[index - 1],
    next: next === false || index === -1 ? undefined : flat[index + 1],
  };
}

export const onRequest = defineRouteMiddleware(async context => {
  const route = context.locals.starlightRoute;
  const id = englishId(route);
  if (!id) return;
  const routes = await getManualRoutes();
  const locale: SiteLocale = (route.locale as SiteLocale | undefined) ?? 'en-US';
  const site = context.site ?? context.url;
  const href = (target: SiteLocale) => new URL(localizeSitePath(`/${id}/`, target, routes), site).href;

  // Starlight pairs locales by path prefix; replace its alternates wholesale.
  route.head = route.head.filter(
    tag => !(tag.tag === 'link' && tag.attrs?.rel === 'alternate' && typeof tag.attrs.hreflang === 'string') &&
      !(tag.tag === 'meta' && (tag.attrs?.property === 'og:locale' || tag.attrs?.property === 'og:locale:alternate')),
  );
  for (const { id: target } of siteLocales) {
    route.head.push({ tag: 'link', attrs: { rel: 'alternate', hreflang: target, href: href(target) }, content: '' });
    if (siteLanguageDefaults.has(target)) {
      route.head.push({ tag: 'link', attrs: { rel: 'alternate', hreflang: target.split('-')[0], href: href(target) }, content: '' });
    }
  }
  route.head.push({ tag: 'link', attrs: { rel: 'alternate', hreflang: 'x-default', href: href('en-US') }, content: '' });
  route.head.push({ tag: 'meta', attrs: { property: 'og:locale', content: ogLocale(locale) }, content: '' });
  for (const { id: other } of siteLocales) {
    if (other !== locale) route.head.push({ tag: 'meta', attrs: { property: 'og:locale:alternate', content: ogLocale(other) }, content: '' });
  }
  if (locale === 'en-US') return;

  const translated = translateManualId(id, locale, routes);
  if (route.isFallback && translated && `${locale}/${translated}` !== route.id) {
    route.entry.data.pagefind = false;
    route.head.push({ tag: 'meta', attrs: { name: 'robots', content: 'noindex' }, content: '' });
    for (const tag of route.head) {
      if (tag.tag === 'link' && tag.attrs?.rel === 'canonical') tag.attrs.href = href(locale);
    }
  } else if (!route.isFallback && !route.entry.data.sourceHash) {
    // Still the English text: never an indexable duplicate of the original.
    // (The build refuses untranslated pages; this guards dev and previews.)
    route.isFallback = true;
    route.entryMeta = { ...route.entryMeta, lang: 'en', dir: 'ltr', locale: undefined };
    route.head.push({ tag: 'meta', attrs: { name: 'robots', content: 'noindex' }, content: '' });
    for (const tag of route.head) {
      if (tag.tag === 'link' && tag.attrs?.rel === 'canonical') tag.attrs.href = href('en-US');
    }
  }
  localizeNavigation(route, locale, routes, context.url.pathname);
});
