// /<page>.md — markdown twins of every content page (docs, compare,
// changelog, about, contact, developers), prerendered as static assets. The
// worker (src/worker.ts) serves the same asset when a client sends
// `Accept: text/markdown` on the page's own URL.
import type { APIRoute, GetStaticPaths } from 'astro';
import { getMarkdownPages } from '../agentic/markdown-pages';

export const prerender = true;

export const getStaticPaths: GetStaticPaths = async () => {
  const origin = 'https://usectrl.dev';
  const pages = await getMarkdownPages(origin);
  return pages
    .filter((p) => p.path !== '/')
    .map((p) => ({
      params: { slug: p.path.replace(/^\//, '').replace(/\/$/, '') },
      props: { markdown: p.markdown },
    }));
};

export const GET: APIRoute<{ markdown: string }> = ({ props }) =>
  new Response(props.markdown, {
    headers: { 'Content-Type': 'text/markdown; charset=utf-8' },
  });
