/**
 * Custom Worker entry for usectrl.dev.
 *
 * Wraps the Astro/Cloudflare adapter entry (`@astrojs/cloudflare/entrypoints/server`)
 * to add request-time behavior the static pipeline cannot express:
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
 * 4. RFC 8288 `Link` headers on every content page pointing at the machine
 *    surface — the RFC 9727 §3 `api-catalog` relation plus `service-desc`,
 *    `service-doc` and `describedby` — so an agent finds the API catalog from
 *    any page it happens to land on, without parsing HTML.
 * 5. A five-minute edge-cached GitHub star count in the HTML navigation,
 *    with no browser request or stale count when GitHub is unavailable.
 * 6. Translated manual slugs — a 301 from each locale's pre-translation
 *    `/<locale>/manual/…` URL to its translated one, and language negotiation
 *    (Accept-Language, cookie, `?lang=`) that lands browsers and agents alike
 *    on the translated page, markdown twin or llms.txt, with a
 *    `Content-Language` header on every text response.
 * 7. The docs MCP server (/mcp, /.well-known/mcp), answering from the build's
 *    per-language page index so the content collection never enters this
 *    bundle.
 *
 * Anything this file does not explicitly handle is delegated to the adapter
 * untouched.
 */
import adapter from '@astrojs/cloudflare/entrypoints/server';
import { applyLocaleHeaders, negotiateLocale, redirectManual } from './locale-negotiation.ts';
import { localeFromPath } from './data/locales.ts';
import type { ManualRoutes } from './data/manual-paths.ts';
import { MCP_PATHS, serveMcp } from './agentic/mcp-http.ts';
import { renderRepoStars } from './data/repo-stars.ts';
import { appendDiscoveryLinks } from './agentic/api-catalog.ts';
import {
  appendVary,
  errorEnvelope,
  jsonErrorHeaders,
  markdownAssetPath,
  markdownHeaders,
  notFoundMarkdown,
  parseAccept,
  type AcceptPreference,
} from './agentic/negotiation.ts';

interface AgenticEnv {
  ASSETS: { fetch(input: string | URL | Request): Promise<Response> };
}

const METHODS: Record<string, true> = { GET: true, HEAD: true };

let manualRoutes: Promise<ManualRoutes> | undefined;

/**
 * The translated manual slugs, from the build's `/manual-routes.json` (see
 * src/pages/manual-routes.json.ts), fetched once per isolate. Without them the
 * site still serves every page; only slug-aware redirects fall back to the
 * prefixed English paths.
 */
function loadManualRoutes(env: AgenticEnv, origin: string): Promise<ManualRoutes> {
  manualRoutes ??= env.ASSETS.fetch(new URL('/manual-routes.json', origin))
    .then(response => (response.ok ? (response.json() as Promise<ManualRoutes>) : Promise.reject(new Error(`HTTP ${response.status}`))))
    .catch(() => {
      manualRoutes = undefined;
      return {};
    });
  return manualRoutes;
}

const content = {
  async fetch(request: Request, env: AgenticEnv, ctx: unknown, accept: AcceptPreference): Promise<Response> {
    const url = new URL(request.url);
    const { pathname } = url;
    // Installer redirects are request-time routes, not content pages. Never
    // negotiate a .md twin or replace an installer error with a page 404.
    if (pathname.startsWith('/download/')) return adapter.fetch(request, env, ctx);
    const origin = url.origin;

    // 1. Markdown twin, when asked for one and the page has one.
    if (accept.markdown) {
      const twin = markdownAssetPath(pathname);
      if (twin) {
        const asset = await env.ASSETS.fetch(new URL(twin, origin));
        if (asset.ok) {
          const headers = markdownHeaders();
          appendDiscoveryLinks(headers, origin);
          return new Response(request.method === 'HEAD' ? null : asset.body, {
            status: 200,
            headers,
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

    // 2. Vary: Accept + discovery Link headers on pages with a markdown twin.
    if (accept.markdown || (response.headers.get('Content-Type') ?? '').includes('text/html')) {
      if (markdownAssetPath(pathname) !== null) {
        const headers = new Headers(response.headers);
        appendVary(headers, 'Accept');
        appendDiscoveryLinks(headers, origin);
        return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
      }
    }
    return response;
  },
};

/**
 * Language and indexing headers on a successful text response (page, markdown
 * twin, llms.txt): `Content-Language` from its URL, so agents and search
 * engines need not guess; and `noindex` on a machine copy fetched at its own
 * URL (`<page>.md`, llms-full.txt), so it never competes with the HTML it
 * duplicates. A twin negotiated at the page's URL stays indexable: that URL is
 * the page's.
 */
function withAgentHeaders(response: Response, pathname: string): Response {
  const type = response.headers.get('Content-Type') ?? '';
  if (!response.ok || !/^text\/(html|markdown|plain)/.test(type)) return response;
  const headers = new Headers(response.headers);
  // A `.md` twin's language is its page's: `/fr-FR.md` is the French landing page.
  const locale = localeFromPath(pathname.replace(/\.md$/, '/'));
  if (!headers.has('Content-Language')) headers.set('Content-Language', locale === 'en-US' ? 'en' : locale);
  if (pathname.endsWith('.md') || pathname.endsWith('/llms-full.txt')) headers.set('X-Robots-Tag', 'noindex');
  return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

export default {
  async fetch(request: Request, env: AgenticEnv, ctx: unknown): Promise<Response> {
    const url = new URL(request.url);
    if (MCP_PATHS.has(url.pathname)) return serveMcp(request, env.ASSETS);
    const accept = METHODS[request.method] ? parseAccept(request.headers.get('Accept')) : { markdown: false, json: false };
    const routes = await loadManualRoutes(env, url.origin);
    // Pre-translation manual URLs move permanently, for every representation.
    const moved = redirectManual(request, routes);
    if (moved) return moved;
    // Pages, markdown twins and llms.txt follow the reader's language; JSON
    // machine files keep their URLs.
    const locale = accept.json ? null : negotiateLocale(request, routes);
    if (locale?.redirect) return locale.redirect;
    let response = withAgentHeaders(await content.fetch(request, env, ctx, accept), url.pathname);
    if (request.method === 'GET' && response.status === 200 &&
        (response.headers.get('Content-Type') ?? '').includes('text/html')) {
      response = renderRepoStars(response);
    }
    return locale ? applyLocaleHeaders(response, locale) : response;
  },
};
