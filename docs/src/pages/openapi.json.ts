// /openapi.json — OpenAPI 3.1 for this site's machine-readable surface.
// Static at build time; generated from the same route/data inventory the site
// ships, so it cannot drift from reality. Scope note: this documents the
// WEBSITE; the product API is the MCP tool server inside cc_server (linked
// from the spec description).
import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { releases } from '../data/changelog';
import { vsTools } from '../data/compare';
import { buildOpenApi } from '../agentic/openapi';

export const prerender = true;

export const GET: APIRoute = async ({ site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  const docEntries = await getCollection('docs', ({ id, data }) => id !== '404' && !id.endsWith('/404') && !data.draft);
  const doc = buildOpenApi({
    origin,
    version: releases[0]?.version ?? '0.0.1',
    compareToolIds: vsTools.map((t) => t.id),
    docSlugs: docEntries.map((e) => e.id).sort(),
  });
  return new Response(JSON.stringify(doc, null, 2), {
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
    },
  });
};
