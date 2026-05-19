/**
 * WebMCP tools for usectrl.dev — the same three tools the docs MCP server
 * exposes over HTTP (src/agentic/mcp.ts), re-offered to a browser-resident
 * agent through the WebMCP API, plus one action only a browser can perform.
 *
 * Pure module — no Astro and no Cloudflare imports — so the tool table can be
 * imported and pinned by a unit test. Every dependency that touches the
 * outside world (fetch, the Pagefind loader, navigation) is injected, which is
 * also what lets the test exercise `execute` against fixtures.
 *
 * Ground rule: every tool reads real bytes from this origin. `list_pages` and
 * the search fallback parse /llms.txt (the curated index the site already
 * publishes), `get_page_markdown` fetches the page's build-time markdown twin
 * through the same path mapping the worker uses, and `search_pages` queries
 * the Pagefind index Starlight ships. Nothing here invents a result: a tool
 * that cannot answer says so instead of guessing.
 *
 * The API shape is the W3C WebMCP draft as implemented by Chrome:
 *
 *   await document.modelContext.registerTool(
 *     { name, title, description, inputSchema, annotations, execute },
 *     { signal },
 *   );
 *
 * `execute(inputObject, { signal })` resolves to a value the platform converts
 * to a string (`Promise<DOMString> executeTool(...)` in the IDL), so every
 * tool here returns a string: raw markdown, or JSON matching what the HTTP MCP
 * server puts in its text content block.
 */

import { markdownAssetPath } from './negotiation.ts';

/** The three tools this surface shares with the docs MCP server. */
export const SHARED_TOOL_NAMES = ['list_pages', 'get_page_markdown', 'search_pages'] as const;

/**
 * Tools that exist only in the browser, because they are actions rather than
 * reads. Kept as an explicit list so the test can tell a deliberate addition
 * apart from a name that drifted out of step with the HTTP server.
 */
export const BROWSER_ONLY_TOOL_NAMES = ['navigate_to_page'] as const;

/** Paths that appear in /llms.txt but are endpoints, not pages with twins. */
const NON_PAGE_PREFIXES = ['/.well-known/', '/mcp'];

/** A JSON Schema object, as WebMCP's `inputSchema` takes it. */
export interface JsonSchema {
  type: 'object';
  properties: Record<string, Record<string, unknown>>;
  required?: string[];
  additionalProperties?: boolean;
}

/** One entry of the site index parsed out of /llms.txt. */
export interface IndexedPage {
  /** Site path, e.g. '/manual/quick-start/'. */
  path: string;
  title: string;
  description?: string;
  /** The `## ...` heading the entry sits under, e.g. 'Docs — Concepts'. */
  section: string;
}

/** The slice of Pagefind's browser API this module uses. */
export interface PagefindModule {
  init?: () => Promise<void>;
  search: (query: string) => Promise<{ results: { data: () => Promise<PagefindResultData> }[] }>;
}

export interface PagefindResultData {
  url: string;
  excerpt?: string;
  meta?: { title?: string };
}

/** Everything the tools need from the outside world. */
export interface WebMcpDeps {
  /** Base for every request; '' means same-origin relative URLs. */
  origin?: string;
  fetch: typeof globalThis.fetch;
  /** Resolve the Pagefind module, or null when it is not reachable. */
  loadPagefind?: () => Promise<PagefindModule | null>;
  /** Perform a real navigation. Absent means the tool is not offered. */
  navigate?: (url: string) => void;
}

/** A tool descriptor in the shape `registerTool` accepts. */
export interface WebMcpToolDefinition {
  name: string;
  title: string;
  description: string;
  inputSchema: JsonSchema;
  annotations: { readOnlyHint: boolean };
  execute: (input: Record<string, unknown>, options?: { signal?: AbortSignal }) => Promise<string>;
}

/* ------------------------------------------------------------------ */
/* Parsing the site index                                              */
/* ------------------------------------------------------------------ */

/**
 * One `- [Title](href): description` bullet. The description group is
 * deliberately loose (`(.*)`) rather than anchored on `: `, so a bullet that
 * carries a second link — /llms.txt has one — still parses instead of being
 * silently dropped by a stricter pattern.
 */
const LINK_LINE = /^-\s+\[([^\]]+)\]\((https?:\/\/[^)\s]+|\/[^)\s]*)\)(.*)$/;
const HEADING_LINE = /^##\s+(.+?)\s*$/;

/** Split an href into its origin (null when relative) and its path. */
function splitHref(href: string): { origin: string | null; path: string } | null {
  if (href.startsWith('/')) return { origin: null, path: href };
  try {
    const url = new URL(href);
    return { origin: url.origin, path: url.pathname };
  } catch {
    return null;
  }
}

/**
 * Which origin the index is about.
 *
 * Deliberately NOT `location.origin`: /llms.txt is generated at build time
 * with the canonical site URL baked in, so on localhost or a preview
 * deployment every link names usectrl.dev while the page is served from
 * somewhere else — matching on the current origin would discard the entire
 * index exactly where it is most useful. The index is a document about one
 * site, so the site is the origin it overwhelmingly links to; the handful of
 * off-site links (the source repository) lose the vote and get filtered out.
 */
function inferSiteOrigin(origins: (string | null)[]): string | null {
  const tally = new Map<string, number>();
  for (const origin of origins) {
    if (origin) tally.set(origin, (tally.get(origin) ?? 0) + 1);
  }
  let winner: string | null = null;
  let best = 0;
  for (const [origin, count] of tally) {
    if (count > best) {
      best = count;
      winner = origin;
    }
  }
  return winner;
}

/** True when a path is a content page (has a markdown twin), not an endpoint. */
export function isContentPage(path: string): boolean {
  if (NON_PAGE_PREFIXES.some((p) => path === p || path.startsWith(p))) return false;
  return markdownAssetPath(path) !== null;
}

interface Candidate extends IndexedPage {
  origin: string | null;
}

/**
 * Parse /llms.txt into the page index. Only bullets that name a real content
 * page on this site survive: the feeds, the OpenAPI document, the MCP and
 * api-catalog endpoints and the off-site source link are all filtered out, so
 * every entry returned is something `get_page_markdown` can actually fetch.
 *
 * Pass `siteOrigin` to filter strictly against a known origin; leave it out
 * and the origin is inferred from the index (see inferSiteOrigin).
 */
export function parseLlmsIndex(body: string, siteOrigin?: string): IndexedPage[] {
  const candidates: Candidate[] = [];
  let section = '';
  for (const raw of body.split('\n')) {
    const heading = HEADING_LINE.exec(raw);
    if (heading) {
      section = heading[1];
      continue;
    }
    const match = LINK_LINE.exec(raw.trimEnd());
    if (!match) continue;
    const [, title, href, rest] = match;
    const split = splitHref(href);
    if (!split) continue;
    const described = /^\s*:\s*(.+)$/.exec(rest);
    candidates.push({
      origin: split.origin,
      path: split.path,
      title,
      ...(described ? { description: described[1].trim() } : {}),
      section,
    });
  }

  const site = siteOrigin
    ? new URL(siteOrigin).origin
    : inferSiteOrigin(candidates.map((c) => c.origin));

  const pages: IndexedPage[] = [];
  const seen = new Set<string>();
  for (const { origin, ...page } of candidates) {
    // A relative link is always ours; an absolute one must name the site.
    if (origin !== null && origin !== site) continue;
    if (!isContentPage(page.path)) continue;
    if (seen.has(page.path)) continue;
    seen.add(page.path);
    pages.push(page);
  }
  return pages;
}

/* ------------------------------------------------------------------ */
/* Shared helpers                                                      */
/* ------------------------------------------------------------------ */

/** Normalize an agent-supplied path the way the HTTP MCP server does. */
export function normalizePath(input: string): string {
  const trimmed = input.trim();
  const rooted = trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
  // Strip a query or fragment: neither selects a different page or twin.
  const bare = rooted.split(/[?#]/)[0];
  if (bare === '/') return '/';
  return bare.endsWith('/') ? bare : `${bare}/`;
}

const stripTags = (html: string) => html.replace(/<[^>]+>/g, '');

const clampLimit = (value: unknown, fallback = 10, max = 25): number =>
  typeof value === 'number' && Number.isInteger(value) ? Math.min(Math.max(value, 1), max) : fallback;

/** Read a text resource from this origin, or throw a message worth showing. */
async function fetchText(
  deps: WebMcpDeps,
  path: string,
  signal?: AbortSignal,
  accept = 'text/plain, text/markdown;q=0.9, */*;q=0.1',
): Promise<string> {
  const url = `${deps.origin ?? ''}${path}`;
  const response = await deps.fetch(url, { signal, headers: { Accept: accept } });
  if (!response.ok) throw new Error(`${url} responded ${response.status}`);
  return response.text();
}

/**
 * The site index, refetched per call so a tool never serves a stale list.
 * The site origin is inferred from the document rather than taken from
 * `deps.origin`, which is only a fetch base and is normally ''.
 */
async function loadIndex(deps: WebMcpDeps, signal?: AbortSignal): Promise<IndexedPage[]> {
  return parseLlmsIndex(await fetchText(deps, '/llms.txt', signal));
}

/* ------------------------------------------------------------------ */
/* Search                                                              */
/* ------------------------------------------------------------------ */

export interface SearchHit {
  path: string;
  title: string;
  snippet: string;
}

/**
 * Fallback search over the curated index: title and description only, which
 * is all /llms.txt carries. Scored like the HTTP server's — a title match
 * outweighs a body match — so the two surfaces rank alike.
 */
export function searchIndex(pages: IndexedPage[], query: string, limit: number): SearchHit[] {
  const terms = query.toLowerCase().split(/\s+/).filter(Boolean);
  if (terms.length === 0) return [];
  const scored: { hit: SearchHit; score: number }[] = [];
  for (const page of pages) {
    const title = page.title.toLowerCase();
    const description = (page.description ?? '').toLowerCase();
    let score = 0;
    for (const term of terms) {
      if (title.includes(term)) score += 5;
      if (description.includes(term)) score += 1;
    }
    if (score === 0) continue;
    scored.push({
      score,
      hit: { path: page.path, title: page.title, snippet: page.description ?? page.section },
    });
  }
  return scored
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map((s) => s.hit);
}

/**
 * Load Pagefind from the index Starlight builds at /pagefind/. The specifier
 * is computed at runtime and marked `@vite-ignore` on purpose: it is a
 * build-time asset of the site, not a module in the source graph, so the
 * bundler must leave the import alone. Any failure resolves to null and the
 * caller falls back to /llms.txt rather than reporting nothing.
 */
export function browserPagefindLoader(): () => Promise<PagefindModule | null> {
  let pending: Promise<PagefindModule | null> | null = null;
  return () => {
    if (pending) return pending;
    pending = (async () => {
      if (typeof window === 'undefined') return null;
      try {
        const specifier = new URL('/pagefind/pagefind.js', window.location.origin).href;
        const mod = (await import(/* @vite-ignore */ specifier)) as PagefindModule;
        if (typeof mod?.search !== 'function') return null;
        if (typeof mod.init === 'function') await mod.init();
        return mod;
      } catch {
        return null;
      }
    })();
    return pending;
  };
}

/* ------------------------------------------------------------------ */
/* The tool table                                                      */
/* ------------------------------------------------------------------ */

const LIST_PAGES_SCHEMA: JsonSchema = {
  type: 'object',
  properties: {},
  additionalProperties: false,
};

const GET_PAGE_SCHEMA: JsonSchema = {
  type: 'object',
  properties: {
    path: {
      type: 'string',
      description: 'Site path with trailing slash, e.g. /manual/quick-start/.',
    },
  },
  required: ['path'],
  additionalProperties: false,
};

const SEARCH_SCHEMA: JsonSchema = {
  type: 'object',
  properties: {
    query: { type: 'string', description: 'Words to search for.' },
    limit: { type: 'integer', description: 'Max results (default 10, max 25).', minimum: 1, maximum: 25 },
  },
  required: ['query'],
  additionalProperties: false,
};

const NAVIGATE_SCHEMA: JsonSchema = {
  type: 'object',
  properties: {
    path: {
      type: 'string',
      description: 'Site path to open, e.g. /manual/install/. Must be a page list_pages returns.',
    },
  },
  required: ['path'],
  additionalProperties: false,
};

/**
 * Build the tool table. Order is stable: the three shared tools first, then
 * the browser-only action, which is omitted entirely when no navigator was
 * supplied — an action tool that cannot act must not be advertised.
 */
export function createWebMcpTools(deps: WebMcpDeps): WebMcpToolDefinition[] {
  const loadPagefind = deps.loadPagefind;

  const tools: WebMcpToolDefinition[] = [
    {
      name: 'list_pages',
      title: 'List pages',
      description:
        'List every page published on this site (usectrl.dev, the Control Center product and docs site): path, title and one-line description. Use this to find the page you need, then fetch it with get_page_markdown.',
      inputSchema: LIST_PAGES_SCHEMA,
      annotations: { readOnlyHint: true },
      async execute(_input, options) {
        const pages = await loadIndex(deps, options?.signal);
        return JSON.stringify(
          pages.map((p) => ({ path: p.path, title: p.title, description: p.description, section: p.section })),
          null,
          2,
        );
      },
    },
    {
      name: 'get_page_markdown',
      title: 'Get page markdown',
      description:
        'Fetch one page of this site as markdown, from the build-time markdown twin the site publishes. Paths use a trailing slash, e.g. "/" for the landing page or "/manual/guides/mcp-server/" for a docs page. Call list_pages for the full set.',
      inputSchema: GET_PAGE_SCHEMA,
      annotations: { readOnlyHint: true },
      async execute(input, options) {
        const raw = input.path;
        if (typeof raw !== 'string' || raw.trim().length === 0) {
          return 'Missing or invalid argument: path (string, trailing slash, e.g. /manual/quick-start/). Call list_pages for valid values.';
        }
        const path = normalizePath(raw);
        const asset = isContentPage(path) ? markdownAssetPath(path) : null;
        if (!asset) {
          return `No page at ${path}. Call list_pages for the full route list, or search_pages to find it by content.`;
        }
        try {
          return await fetchText(deps, asset, options?.signal, 'text/markdown, text/plain;q=0.9');
        } catch {
          return `No page at ${path}. Call list_pages for the full route list, or search_pages to find it by content.`;
        }
      },
    },
    {
      name: 'search_pages',
      title: 'Search pages',
      description:
        'Full-text search over this site. Queries the site search index when it is available and falls back to the curated page index otherwise. Returns matching paths with snippets; fetch a result with get_page_markdown.',
      inputSchema: SEARCH_SCHEMA,
      annotations: { readOnlyHint: true },
      async execute(input, options) {
        const query = input.query;
        if (typeof query !== 'string' || query.trim().length === 0) {
          return 'Missing or invalid argument: query (non-empty string).';
        }
        const limit = clampLimit(input.limit);

        let hits: SearchHit[] = [];
        let source = 'llms.txt';
        const pagefind = loadPagefind ? await loadPagefind() : null;
        if (pagefind) {
          try {
            const found = await pagefind.search(query);
            const data = await Promise.all(found.results.slice(0, limit).map((r) => r.data()));
            hits = data
              .map((d) => {
                // Pagefind reports its own site-relative URLs.
                const split = splitHref(d.url);
                if (!split || !isContentPage(split.path)) return null;
                return {
                  path: normalizePath(split.path),
                  title: d.meta?.title ?? split.path,
                  snippet: stripTags(d.excerpt ?? '').replace(/\s+/g, ' ').trim(),
                };
              })
              .filter((h): h is SearchHit => h !== null);
            if (hits.length > 0) source = 'pagefind';
          } catch {
            hits = [];
          }
        }

        // No index, or the index matched nothing: the curated list is a real
        // second corpus, so try it rather than reporting an empty result.
        if (hits.length === 0) {
          hits = searchIndex(await loadIndex(deps, options?.signal), query, limit);
          source = 'llms.txt';
        }

        if (hits.length === 0) {
          return `No pages match "${query}". Try broader terms, or call list_pages.`;
        }
        return JSON.stringify({ source, results: hits }, null, 2);
      },
    },
  ];

  if (deps.navigate) {
    const navigate = deps.navigate;
    tools.push({
      name: 'navigate_to_page',
      title: 'Open a page',
      description:
        'Open a page of this site in the current tab. The path is checked against the published page list first, so this never navigates to a page that does not exist. Use get_page_markdown instead when you only need to read the page.',
      inputSchema: NAVIGATE_SCHEMA,
      annotations: { readOnlyHint: false },
      async execute(input, options) {
        const raw = input.path;
        if (typeof raw !== 'string' || raw.trim().length === 0) {
          return 'Missing or invalid argument: path (string), e.g. /manual/install/. Call list_pages for valid values.';
        }
        const path = normalizePath(raw);
        const pages = await loadIndex(deps, options?.signal);
        const page = pages.find((p) => normalizePath(p.path) === path);
        if (!page) {
          return `No page at ${path}, so nothing was opened. Call list_pages for the full route list.`;
        }
        navigate(page.path);
        return `Opened ${page.path} — ${page.title}.`;
      },
    });
  }

  return tools;
}

/* ------------------------------------------------------------------ */
/* Registration                                                        */
/* ------------------------------------------------------------------ */

/** The subset of the WebMCP surface this module calls. */
interface ModelContextLike {
  registerTool: (tool: WebMcpToolDefinition, options?: { signal?: AbortSignal }) => Promise<void> | void;
}

/**
 * Find the WebMCP entry point. `document.modelContext` is the current spec and
 * what Chrome 150+ exposes; `navigator.modelContext` was the origin-trial
 * spelling and is kept as a fallback so a browser still on it is served. Both
 * absent — every browser by default — returns null and the caller no-ops.
 */
export function findModelContext(scope: {
  document?: unknown;
  navigator?: unknown;
}): ModelContextLike | null {
  const candidates = [
    (scope.document as { modelContext?: unknown } | undefined)?.modelContext,
    (scope.navigator as { modelContext?: unknown } | undefined)?.modelContext,
  ];
  for (const candidate of candidates) {
    if (candidate && typeof (candidate as ModelContextLike).registerTool === 'function') {
      return candidate as ModelContextLike;
    }
  }
  return null;
}

/**
 * Register every tool, swallowing per-tool failures. The experimental API may
 * reject a descriptor whose shape it does not recognise, or reject a duplicate
 * name; neither is worth breaking a page over, so each registration is
 * isolated and the count of successes is returned.
 */
export async function registerWebMcpTools(
  context: ModelContextLike,
  tools: WebMcpToolDefinition[],
  signal?: AbortSignal,
): Promise<number> {
  let registered = 0;
  for (const tool of tools) {
    try {
      await context.registerTool(tool, signal ? { signal } : undefined);
      registered += 1;
    } catch {
      // An evolving API refusing one tool must not cost us the others.
    }
  }
  return registered;
}
