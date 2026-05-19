/**
 * Content negotiation + agent-friendly error envelopes for usectrl.dev.
 *
 * Pure module — no Astro or Cloudflare imports — so the worker wrapper
 * (src/worker.ts), the Astro endpoints and the unit tests all share one
 * implementation.
 *
 * The contract:
 * - `Accept: text/markdown` on a content page serves its markdown twin
 *   (emitted at build time as `<page>.md`), with `Vary: Accept` so caches
 *   keep the two variants apart.
 * - A 404 is never an empty body: markdown for markdown clients, a JSON
 *   error envelope for JSON clients and anything under /api/, the rendered
 *   HTML 404 page otherwise.
 */

export interface AcceptPreference {
  /** Client listed text/markdown (q > 0). */
  markdown: boolean;
  /** Client listed application/json (or application/problem+json), q > 0. */
  json: boolean;
}

/**
 * Parse an Accept header into the two variants this site negotiates.
 * Missing header means "no preference" (browsers send text/html first).
 * q=0 entries are explicit refusals and never count.
 */
export function parseAccept(header: string | null): AcceptPreference {
  const pref: AcceptPreference = { markdown: false, json: false };
  if (!header) return pref;
  for (const part of header.split(',')) {
    const [type, ...params] = part.trim().split(';');
    const media = type.trim().toLowerCase();
    let q = 1;
    for (const p of params) {
      const [k, v] = p.split('=');
      if (k.trim().toLowerCase() === 'q') {
        const parsed = Number.parseFloat(v ?? '1');
        q = Number.isNaN(parsed) ? 1 : parsed;
      }
    }
    if (q <= 0) continue;
    if (media === 'text/markdown' || media === 'text/x-markdown') pref.markdown = true;
    if (media === 'application/json' || media === 'application/problem+json' || media.endsWith('+json'))
      pref.json = true;
  }
  return pref;
}

/**
 * Map a site pathname to the build-time markdown twin asset, or null when the
 * path has no markdown variant (assets, feeds, machine files, the MCP
 * endpoint). Trailing slashes and `.html`/`/index.html` forms collapse to the
 * same twin so every spelling of a page negotiates identically.
 *
 *   `/`                       → `/index.md`
 *   `/manual/quick-start/`    → `/manual/quick-start.md`
 *   `/compare`                → `/compare.md`
 */
export function markdownAssetPath(pathname: string): string | null {
  if (pathname === '/' || pathname === '/index.html') return '/index.md';
  let path = pathname.replace(/\/+$/, '');
  if (path.endsWith('/index.html')) path = path.slice(0, -'/index.html'.length);
  if (path.endsWith('.html')) path = path.slice(0, -'.html'.length);
  if (path === '') return '/index.md';
  // Anything that still names a file is an asset, feed or machine file —
  // never a page with a markdown twin. (`.md` itself included: requesting the
  // twin directly is served by the assets layer as-is.)
  const lastSegment = path.slice(path.lastIndexOf('/') + 1);
  if (lastSegment.includes('.')) return null;
  return `${path}.md`;
}

/** Headers for a negotiated markdown response. */
export function markdownHeaders(extra?: HeadersInit): Headers {
  const h = new Headers(extra);
  h.set('Content-Type', 'text/markdown; charset=utf-8');
  h.set('Cache-Control', 'public, max-age=0, must-revalidate');
  appendVary(h, 'Accept');
  return h;
}

/** Append a token to Vary without duplicating existing ones. */
export function appendVary(headers: Headers, token: string): void {
  const existing = headers.get('Vary');
  if (!existing) {
    headers.set('Vary', token);
    return;
  }
  const tokens = existing.split(',').map((t) => t.trim().toLowerCase());
  if (tokens.includes('*') || tokens.includes(token.toLowerCase())) return;
  headers.set('Vary', `${existing}, ${token}`);
}

export interface SiteLinks {
  origin: string;
}

const abs = (origin: string, path: string) => `${origin}${path}`;

/**
 * Short markdown 404 body: what was missed plus the recovery map an agent
 * needs (sitemap, llms.txt, docs index, OpenAPI, MCP).
 */
export function notFoundMarkdown(pathname: string, { origin }: SiteLinks): string {
  return [
    `# 404 — not found`,
    '',
    `\`${pathname}\` does not exist on usectrl.dev.`,
    '',
    '## Where to look next',
    '',
    `- [Sitemap](${abs(origin, '/sitemap-index.xml')}) — every published page`,
    `- [llms.txt](${abs(origin, '/llms.txt')}) — curated index of the whole site`,
    `- [llms-full.txt](${abs(origin, '/llms-full.txt')}) — the entire site as one markdown file`,
    `- [Documentation](${abs(origin, '/manual/')}) — the manual (tutorials, guides, concepts, reference)`,
    `- [Developers](${abs(origin, '/developers')}) — API, MCP server, CLI and quickstarts`,
    `- [OpenAPI](${abs(origin, '/openapi.json')}) — machine-readable description of this site's endpoints`,
    `- [MCP server](${abs(origin, '/.well-known/mcp')}) — Streamable HTTP MCP endpoint exposing this site's content as tools`,
    '',
    'Tip: send `Accept: text/markdown` on any page to get its markdown twin instead of HTML.',
    '',
  ].join('\n');
}

export interface ErrorEnvelope {
  error: {
    code: string;
    message: string;
    hint: string;
    status: number;
    docs: string;
    sitemap: string;
  };
}

/** Structured JSON error body — what an agent gets for /api/* or Accept: application/json. */
export function errorEnvelope(status: number, code: string, message: string, hint: string, { origin }: SiteLinks): ErrorEnvelope {
  return {
    error: {
      code,
      message,
      hint,
      status,
      docs: abs(origin, '/openapi.json'),
      sitemap: abs(origin, '/sitemap-index.xml'),
    },
  };
}

/** Headers for a JSON error response. */
export function jsonErrorHeaders(): Headers {
  const h = new Headers();
  h.set('Content-Type', 'application/json; charset=utf-8');
  h.set('Cache-Control', 'no-store');
  appendVary(h, 'Accept');
  return h;
}
