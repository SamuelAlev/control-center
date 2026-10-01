// /llms-full.txt — the whole site as one plain-text file: product overview,
// landing FAQ, the comparison matrix, the full changelog and every manual
// page's body. Assembled at build time from the same data the pages render
// (data modules + the docs collection), so it always matches the site.
// Bodies are the raw MDX source with import lines stripped — Starlight
// container syntax (:::note) and component tags are left as-is; they read
// fine as text. Each other language has /<locale>/llms-full.txt.
import type { APIRoute } from 'astro';
import { llmsFull } from '../agentic/llms';

export const prerender = true;

export const GET: APIRoute = async ({ site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  return new Response(await llmsFull(origin, 'en-US'), {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
};
