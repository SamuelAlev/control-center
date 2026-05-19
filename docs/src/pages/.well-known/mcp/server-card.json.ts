// /.well-known/mcp/server-card.json — the SEP-2127 MCP Server Card for this
// site's docs MCP server. Logic lives in src/agentic/mcp-server-card.ts.
//
// Path: the spec reserves `<streamable-http-url>/server-card`. This server's
// streamable-HTTP URL is /.well-known/mcp, so the reserved suffix lands here.
// The sibling route file src/pages/.well-known/mcp.ts (the live MCP server)
// stays exactly as it is — a page file and a same-named directory are two
// distinct routes, the way src/pages/compare.astro sits beside
// src/pages/compare/[slug].astro today.
//
// Static at build time. As a prerendered .json the CDN serves it from the
// asset store and derives `application/json` from the extension; the headers
// below are what `astro dev` and any SSR fallback answer with. The spec's
// CORS/caching requirements for a card endpoint are set here for that path and
// belong in public/_headers for the static one.
import type { APIRoute } from 'astro';
import { buildServerCard } from '../../../agentic/mcp-server-card';

export const prerender = true;

export const GET: APIRoute = ({ site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  return new Response(JSON.stringify(buildServerCard({ origin }), null, 2), {
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      // Cards carry only public, read-only metadata; the spec requires open
      // CORS so browser-based clients can read one.
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET',
      'Access-Control-Allow-Headers': 'Content-Type, If-None-Match',
      'Access-Control-Expose-Headers': 'ETag',
      'Cache-Control': 'public, max-age=3600',
    },
  });
};
