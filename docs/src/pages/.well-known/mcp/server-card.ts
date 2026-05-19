// /.well-known/mcp/server-card — the SEP-2127 RESERVED path for this server's
// card. The spec reserves `<streamable-http-url>/server-card`, and this
// server's streamable-HTTP URL is /.well-known/mcp, so a spec-following client
// guesses exactly this URL. The sibling `server-card.json` route serves the
// same document at the extension-bearing path; both come from one builder, so
// they cannot disagree.
//
// Server-rendered (`prerender = false`) for the same reason as
// /.well-known/api-catalog: a prerendered route emits an EXTENSIONLESS asset
// file and the static-asset layer types responses by extension, so the media
// type below would never reach the client. Rendering it here is what makes the
// media type ours to set.
import type { APIRoute } from 'astro';
import { SERVER_CARD_MEDIA_TYPE, buildServerCard } from '../../../agentic/mcp-server-card';

export const prerender = false;

export const GET: APIRoute = ({ site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  return new Response(JSON.stringify(buildServerCard({ origin }), null, 2), {
    headers: {
      // The spec's own media type, which only this path can honour — the .json
      // sibling is typed `application/json` by its extension.
      'Content-Type': SERVER_CARD_MEDIA_TYPE,
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
