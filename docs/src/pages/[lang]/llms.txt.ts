// /<locale>/llms.txt — the llms.txt index in one site language: its landing
// copy, manual and translated URLs (src/agentic/llms.ts). The Worker sends a
// `/llms.txt` request here when Accept-Language prefers this language.
import type { APIRoute, GetStaticPaths } from 'astro';
import { llmsIndex } from '../../agentic/llms';
import { siteLocales, type SiteLocale } from '../../data/locales';

export const prerender = true;

export const getStaticPaths: GetStaticPaths = () =>
  siteLocales.filter(locale => locale.id !== 'en-US').map(locale => ({ params: { lang: locale.id } }));

export const GET: APIRoute = async ({ params, site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  return new Response(await llmsIndex(origin, params.lang as SiteLocale), {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
};
