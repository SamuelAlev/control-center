// /agentic/pages/<locale>.json — every page a reader of one language can use,
// as markdown: that language's landing page and manual plus the English-only
// pages. The docs MCP server (src/worker.ts) reads it at request time instead
// of bundling the content collection into the Worker; one file per language
// keeps each well under the 25 MiB asset limit.
import type { APIRoute, GetStaticPaths } from 'astro';
import { getMarkdownPages, pagesForLocale } from '../../../agentic/markdown-pages';
import type { McpPage } from '../../../agentic/mcp';
import { siteLocales, type SiteLocale } from '../../../data/locales';

export const prerender = true;

export const getStaticPaths: GetStaticPaths = () => siteLocales.map(({ id }) => ({ params: { locale: id } }));

export const GET: APIRoute = async ({ params, site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  const pages = pagesForLocale(await getMarkdownPages(origin), params.locale as SiteLocale).map(
    (page): McpPage => ({
      path: page.path,
      title: page.title,
      description: page.description,
      markdown: page.markdown,
      locale: page.locale,
      ...(page.englishPath ? { englishPath: page.englishPath } : {}),
    }),
  );
  return new Response(JSON.stringify(pages), { headers: { 'Content-Type': 'application/json; charset=utf-8' } });
};
