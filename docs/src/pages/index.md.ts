// /index.md — the landing page's markdown twin. One of the two ways agents
// read pages here; the other is `Accept: text/markdown` on the page itself
// (see src/worker.ts). Content comes from getMarkdownPages, which assembles
// it from the same data the HTML landing renders.
import type { APIRoute } from 'astro';
import { getMarkdownPages } from '../agentic/markdown-pages';

export const prerender = true;

export const GET: APIRoute = async ({ site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  const landing = (await getMarkdownPages(origin)).find((p) => p.path === '/');
  return new Response(landing?.markdown ?? '# Control Center\n', {
    headers: { 'Content-Type': 'text/markdown; charset=utf-8' },
  });
};
