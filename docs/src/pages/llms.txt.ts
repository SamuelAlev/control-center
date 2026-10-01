// /llms.txt — the curated index for LLMs, per the llmstxt.org convention:
// H1 name, blockquote summary, then titled sections of links with one-line
// descriptions. Generated at build time from the same sources the site
// renders (docs collection, changelog, compare data), so it can never drift
// from the real navigation. The full single-file dump lives at llms-full.txt;
// every other language has its own at /<locale>/llms.txt (src/agentic/llms.ts).
import type { APIRoute } from 'astro';
import { llmsIndex } from '../agentic/llms';

export const prerender = true;

export const GET: APIRoute = async ({ site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  return new Response(await llmsIndex(origin, 'en-US'), {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
};
