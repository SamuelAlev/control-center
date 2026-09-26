import { appendVary } from './agentic/negotiation.ts';
import {
  isSiteLocale, localeChoiceParameter, localeFromPath, localizePath,
  siteLanguageDefaults, siteLocales, unlocalizedPath, type SiteLocale,
} from './data/locales.ts';

const cookieName = 'cc-locale';
const languages = siteLocales.map(({ id }) => ({ id, tag: new Intl.Locale(id).maximize() }));
type Language = (typeof languages)[number];
type Preference = { tag: Intl.Locale | null; quality: number; specificity: number };

function languagePreferences(header: string | null): Preference[] {
  const preferences: Preference[] = [];
  for (const entry of header?.split(',') ?? []) {
    const [range, ...parameters] = entry.trim().split(';');
    const weight = parameters.find(parameter => /^\s*q\s*=/i.test(parameter));
    const rawQuality = weight ? weight.slice(weight.indexOf('=') + 1).trim() : '1';
    if (!/^(?:0(?:\.\d{0,3})?|1(?:\.0{0,3})?)$/.test(rawQuality)) continue;
    try {
      const tag = range.trim() === '*' ? null : new Intl.Locale(range.trim());
      preferences.push({ tag, quality: Number(rawQuality), specificity: tag ? 1 + Number(!!tag.script) + Number(!!tag.region) : 0 });
    } catch { /* Malformed language ranges do not override a usable preference. */ }
  }
  return preferences;
}

function matches(language: Language, preference: Preference): boolean {
  const tag = preference.tag;
  return !tag || (language.tag.language === tag.language &&
    (!tag.script || language.tag.script === tag.script) &&
    (!tag.region || language.tag.region === tag.region));
}

/** Respect q weights, regional/script preferences and specific q=0 exclusions. */
export function preferredLanguage(header: string | null): SiteLocale {
  const qualities = new Map<SiteLocale, number>();
  const preferences = languagePreferences(header);
  const available = languages.filter(language => {
    let best: Preference | undefined;
    for (const preference of preferences) {
      if (matches(language, preference) && (!best || preference.specificity > best.specificity)) best = preference;
    }
    if (best) qualities.set(language.id, best.quality);
    return best?.quality !== 0;
  });
  for (const preference of preferences.filter(p => p.quality > 0).sort((a, b) => b.quality - a.quality)) {
    const eligible = available.filter(language => (qualities.get(language.id) ?? 1) >= preference.quality);
    if (!preference.tag) {
      const fallback = eligible.find(language => language.id === 'en-US') ?? eligible[0];
      if (fallback) return fallback.id;
      continue;
    }
    const requested = preference.tag;
    const exact = eligible.find(language => language.id.toLowerCase() === requested.baseName.toLowerCase());
    if (exact) return exact.id;
    const expanded = requested.maximize();
    const candidates = eligible.filter(language => language.tag.language === expanded.language && language.tag.script === expanded.script);
    const match = candidates.find(language => language.tag.region === expanded.region) ??
      candidates.find(language => siteLanguageDefaults.has(language.id)) ?? candidates[0];
    if (match) return match.id;
  }
  return 'en-US';
}

function cookieLocale(header: string | null): SiteLocale | undefined {
  for (const part of header?.split(';') ?? []) {
    const separator = part.indexOf('=');
    if (part.slice(0, separator).trim() !== cookieName) continue;
    const value = part.slice(separator + 1).trim();
    if (isSiteLocale(value)) return value;
  }
}

export interface LocaleNegotiation {
  redirect: Response | null;
  cookie?: string;
}

/** Apply only to HTML requests. Explicit localized URLs remain cacheable. */
export function negotiateLocale(request: Request): LocaleNegotiation | null {
  if (request.method !== 'GET' && request.method !== 'HEAD') return null;
  const url = new URL(request.url);
  const unprefixed = unlocalizedPath(url.pathname);
  const path = unprefixed.replace(/\/index\.html$/, '/').replace(/\.html$/, '/');
  if (path !== '/' && path !== '/manual' && !path.startsWith('/manual/')) return null;
  if (path.slice(path.lastIndexOf('/') + 1).includes('.')) return null;

  const explicit = unprefixed !== url.pathname;
  const choice = url.searchParams.get(localeChoiceParameter);
  const selected = isSiteLocale(choice) ? choice : undefined;
  if (explicit && !selected) return null;
  const locale = explicit ? localeFromPath(url.pathname) :
    selected ?? cookieLocale(request.headers.get('Cookie')) ?? preferredLanguage(request.headers.get('Accept-Language'));
  const cookie = selected ? `${cookieName}=${locale}; Path=/; Max-Age=31536000; HttpOnly; SameSite=Lax${url.protocol === 'https:' ? '; Secure' : ''}` : undefined;
  const target = localizePath(path, locale);
  const decision: LocaleNegotiation = { redirect: null, cookie };
  if (target !== url.pathname) {
    url.pathname = target;
    if (selected && locale !== 'en-US') url.searchParams.delete(localeChoiceParameter);
    decision.redirect = applyLocaleHeaders(new Response(null, {
      status: 302,
      headers: { Location: url.pathname + url.search },
    }), decision);
  }
  // A same-path choice is served immediately, including English with cookies
  // disabled. The client removes the marker without a second HTTP request.
  return decision;
}

export function applyLocaleHeaders(response: Response, decision: LocaleNegotiation): Response {
  const headers = new Headers(response.headers);
  headers.set('Cache-Control', 'private, no-store');
  appendVary(headers, 'Accept');
  appendVary(headers, 'Accept-Language');
  appendVary(headers, 'Cookie');
  if (decision.cookie) headers.append('Set-Cookie', decision.cookie);
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}
