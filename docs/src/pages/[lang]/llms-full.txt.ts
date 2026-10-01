// /<locale>/llms-full.txt — one site language's landing copy, FAQ and manual
// in one file (src/agentic/llms.ts).
import type { APIRoute, GetStaticPaths } from 'astro';
import { llmsFull } from '../../agentic/llms';
import { siteLocales, type SiteLocale } from '../../data/locales';

export const prerender = true;

export const getStaticPaths: GetStaticPaths = () =>
  siteLocales.filter(locale => locale.id !== 'en-US').map(locale => ({ params: { lang: locale.id } }));

export const GET: APIRoute = async ({ params, site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  return new Response(await llmsFull(origin, params.lang as SiteLocale), {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
};
