// /.well-known/api-catalog — the RFC 9727 API catalog for this origin.
// Logic lives in src/agentic/api-catalog.ts.
//
// Server-rendered (`prerender = false`), like /.well-known/mcp, for one
// concrete reason: a prerendered route emits an EXTENSIONLESS asset file, and
// the static-asset layer types responses by file extension — an
// `api-catalog` file with no suffix would be served as octet-stream and the
// `application/linkset+json` the spec requires would never reach the client.
// Rendering it here is what makes the media type ours to set.
import type { APIRoute } from 'astro';
import {
  API_CATALOG_MEDIA_TYPE,
  API_CATALOG_PROFILE,
  buildApiCatalog,
  formatLink,
} from '../../agentic/api-catalog';

export const prerender = false;

export const GET: APIRoute = ({ site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  const catalog = buildApiCatalog({ origin });
  return new Response(JSON.stringify(catalog, null, 2), {
    headers: {
      'Content-Type': API_CATALOG_MEDIA_TYPE,
      // The profile the RFC's examples carry as a Content-Type parameter,
      // advertised as a link instead so the media type stays exact.
      Link: formatLink({ rel: 'profile', href: API_CATALOG_PROFILE }),
      'Cache-Control': 'public, max-age=3600',
      'Access-Control-Allow-Origin': '*',
    },
  });
};
