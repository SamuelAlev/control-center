/**
 * Custom Worker entry for usectrl.dev.
 *
 * Wraps the Astro/Cloudflare adapter entry (`@astrojs/cloudflare/entrypoints/server`)
 * to add the agent-facing behavior the static pipeline cannot express:
 *
 * 1. Markdown content negotiation — `Accept: text/markdown` on a content page
 *    serves its build-time markdown twin (`<page>.md` asset), per
 *    acceptmarkdown.com. Only page routes reach this worker (see
 *    `run_worker_first` in wrangler.jsonc); everything else keeps the free
 *    direct-asset path.
 * 2. `Vary: Accept` on every HTML response that has a markdown twin, so a CDN
 *    never serves the cached HTML variant to a markdown client (or back).
 * 3. Agent-friendly 404s — a real 404 status with a markdown recovery map for
 *    markdown clients, a JSON error envelope for `Accept: application/json`
 *    and any `/api/*` path, and the rendered HTML 404 page for browsers.
 *
 * Anything this file does not explicitly handle is delegated to the adapter
 * untouched.
 */
import adapter from '@astrojs/cloudflare/entrypoints/server';
import {
  appendVary,
  errorEnvelope,
  jsonErrorHeaders,
  markdownAssetPath,
  markdownHeaders,
  notFoundMarkdown,
  parseAccept,
} from './agentic/negotiation.ts';

interface AgenticEnv {
  ASSETS: { fetch(input: string | URL | Request): Promise<Response> };
}

const METHODS: Record<string, true> = { GET: true, HEAD: true };

export default {
  async fetch(request: Request, env: AgenticEnv, ctx: unknown): Promise<Response> {
    const url = new URL(request.url);
    const { pathname } = url;
    const origin = url.origin;
    const accept = METHODS[request.method] ? parseAccept(request.headers.get('Accept')) : { markdown: false, json: false };

    // 1. Markdown twin, when asked for one and the page has one.
    if (accept.markdown) {
      const twin = markdownAssetPath(pathname);
      if (twin) {
        const asset = await env.ASSETS.fetch(new URL(twin, origin));
        if (asset.ok) {
          return new Response(request.method === 'HEAD' ? null : asset.body, {
            status: 200,
            headers: markdownHeaders(),
          });
        }
      }
    }

    const response = await adapter.fetch(request, env, ctx);

    if (response.status === 404 && METHODS[request.method]) {
      // JSON envelope for API paths and JSON clients…
      if (accept.json || pathname === '/api' || pathname.startsWith('/api/')) {
        const body = errorEnvelope(
          404,
          'not_found',
          `No route matches ${pathname}.`,
          'Fetch the sitemap or llms.txt for the full route list, or the OpenAPI document for the machine-readable surface.',
          { origin },
        );
        return new Response(request.method === 'HEAD' ? null : JSON.stringify(body, null, 2), {
          status: 404,
          headers: jsonErrorHeaders(),
        });
      }
      // …a markdown recovery map for markdown clients…
      if (accept.markdown) {
        return new Response(request.method === 'HEAD' ? null : notFoundMarkdown(pathname, { origin }), {
          status: 404,
          headers: markdownHeaders(),
        });
      }
      // …and the rendered 404 page for browsers (Vary so caches hold both).
      const headers = new Headers(response.headers);
      appendVary(headers, 'Accept');
      return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
    }

    // 2. Vary: Accept on HTML pages with a markdown twin.
    if (accept.markdown || (response.headers.get('Content-Type') ?? '').includes('text/html')) {
      if (markdownAssetPath(pathname) !== null) {
        const headers = new Headers(response.headers);
        appendVary(headers, 'Accept');
        return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
      }
    }
    return response;
  },
};
