/**
 * A minimal MCP (Model Context Protocol) server over the Streamable HTTP
 * transport, exposing this site's content as read-only tools. Served at
 * /.well-known/mcp and /mcp.
 *
 * Deliberately dependency-free: the surface is three JSON-RPC methods
 * (initialize, tools/list, tools/call, plus ping and notifications) answered
 * with `application/json` — the transport allows plain JSON responses when no
 * SSE stream is opened. GET returns a discovery card (no SSE here).
 *
 * Pure module: the page index is injected, so unit tests run the full
 * protocol against fixtures without Astro collections.
 */

export interface McpPage {
  /** Site path with trailing slash, e.g. '/manual/quick-start/'. */
  path: string;
  title: string;
  description?: string;
  markdown: string;
}

export interface McpServerInfo {
  name: string;
  version: string;
  /** Absolute base URL of the site, e.g. 'https://usectrl.dev'. */
  origin: string;
}

export interface McpOutcome {
  status: number;
  /** null = notification acknowledged (202, empty body). */
  body: unknown | null;
}

/** Exported so the SEP-2127 server card advertises the version served here. */
export const PROTOCOL_VERSION = '2025-06-18';

/**
 * What `initialize` reports. Exported so the server card cannot claim a
 * capability this server does not answer with. Tools only: no resources, no
 * prompts, no sampling, no subscriptions — absence means unsupported.
 */
export const CAPABILITIES = { tools: { listChanged: false } } as const;

/**
 * The complete tool surface. Exported so the server card's tool summaries are
 * mapped from this array rather than retyped; test/mcp-server-card.test.ts pins
 * the two against each other in both directions.
 */
export const TOOLS = [
  {
    name: 'list_pages',
    description:
      'List every page published on usectrl.dev (the Control Center product + docs site): path, title and one-line description. Use this to find the page you need, then fetch it with get_page_markdown.',
    inputSchema: {
      type: 'object',
      properties: {},
      additionalProperties: false,
    },
  },
  {
    name: 'get_page_markdown',
    description:
      'Fetch one page of usectrl.dev as markdown. Paths use a trailing slash, e.g. "/" for the landing page, "/manual/guides/mcp-server/" for a docs page, "/developers" as "/developers/". Call list_pages for the full set.',
    inputSchema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'Site path with trailing slash, e.g. /manual/quick-start/.' },
      },
      required: ['path'],
      additionalProperties: false,
    },
  },
  {
    name: 'search_pages',
    description:
      'Full-text search over every usectrl.dev page (titles weighted above bodies). Returns matching paths with snippets; fetch the page with get_page_markdown.',
    inputSchema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Words to search for (case-insensitive substring match).' },
        limit: { type: 'integer', description: 'Max results (default 10, max 25).', minimum: 1, maximum: 25 },
      },
      required: ['query'],
      additionalProperties: false,
    },
  },
] as const;

const text = (value: string) => [{ type: 'text', text: value }];

const rpcError = (id: unknown, code: number, message: string) => ({
  jsonrpc: '2.0',
  id: id ?? null,
  error: { code, message },
});

const rpcResult = (id: unknown, result: unknown) => ({ jsonrpc: '2.0', id: id ?? null, result });

interface SearchHit {
  page: McpPage;
  score: number;
  snippet: string;
}

function searchPages(pages: McpPage[], query: string, limit: number): SearchHit[] {
  const terms = query.toLowerCase().split(/\s+/).filter(Boolean);
  if (terms.length === 0) return [];
  const hits: SearchHit[] = [];
  for (const page of pages) {
    const title = page.title.toLowerCase();
    const body = page.markdown.toLowerCase();
    let score = 0;
    let firstAt = -1;
    for (const term of terms) {
      if (title.includes(term)) score += 5;
      const at = body.indexOf(term);
      if (at >= 0) {
        score += body.split(term).length - 1;
        if (firstAt < 0 || at < firstAt) firstAt = at;
      }
    }
    if (score === 0) continue;
    const start = Math.max(0, firstAt - 80);
    const snippet = page.markdown.slice(start, firstAt + 160).replace(/\s+/g, ' ').trim();
    hits.push({ page, score, snippet });
  }
  return hits.sort((a, b) => b.score - a.score).slice(0, limit);
}

export function createMcpHandler(getPages: () => Promise<McpPage[]>, server: McpServerInfo) {
  async function callTool(name: string, args: Record<string, unknown>): Promise<Record<string, unknown>> {
    const pages = await getPages();
    if (name === 'list_pages') {
      const list = pages.map((p) => ({ path: p.path, title: p.title, description: p.description }));
      return { content: text(JSON.stringify(list, null, 2)) };
    }
    if (name === 'get_page_markdown') {
      const rawPath = args.path;
      if (typeof rawPath !== 'string' || rawPath.length === 0) {
        return {
          isError: true,
          content: text('Missing or invalid argument: path (string, trailing slash, e.g. /manual/quick-start/). Call list_pages for valid values.'),
        };
      }
      const normalized = rawPath.startsWith('/') ? rawPath : `/${rawPath}`;
      const withSlash = normalized.endsWith('/') ? normalized : `${normalized}/`;
      const page = pages.find((p) => p.path === withSlash);
      if (!page) {
        return {
          isError: true,
          content: text(`No page at ${withSlash}. Call list_pages for the full route list, or search_pages to find it by content.`),
        };
      }
      return { content: text(page.markdown) };
    }
    if (name === 'search_pages') {
      const query = args.query;
      if (typeof query !== 'string' || query.trim().length === 0) {
        return { isError: true, content: text('Missing or invalid argument: query (non-empty string).') };
      }
      const limit = typeof args.limit === 'number' && Number.isInteger(args.limit) ? Math.min(Math.max(args.limit, 1), 25) : 10;
      const hits = searchPages(pages, query, limit);
      if (hits.length === 0) {
        return { content: text(`No pages match "${query}". Try broader terms, or call list_pages.`) };
      }
      return {
        content: text(
          JSON.stringify(
            hits.map((h) => ({ path: h.page.path, title: h.page.title, score: h.score, snippet: h.snippet })),
            null,
            2,
          ),
        ),
      };
    }
    return {
      isError: true,
      content: text(`Unknown tool "${name}". Available: ${TOOLS.map((t) => t.name).join(', ')}.`),
    };
  }

  /** Handle one parsed JSON-RPC message. Returns the outcome for it. */
  async function handleOne(message: unknown): Promise<McpOutcome> {
    if (typeof message !== 'object' || message === null || Array.isArray(message)) {
      return { status: 200, body: rpcError(null, -32600, 'Invalid Request: expected a JSON-RPC object.') };
    }
    const { jsonrpc, id, method, params } = message as {
      jsonrpc?: unknown;
      id?: unknown;
      method?: unknown;
      params?: unknown;
    };
    if (jsonrpc !== '2.0' || typeof method !== 'string') {
      return { status: 200, body: rpcError(id ?? null, -32600, 'Invalid Request: jsonrpc must be "2.0" and method a string.') };
    }
    // Notifications (no id) are acknowledged with 202 and no body.
    if (id === undefined || id === null) {
      if (method.startsWith('notifications/')) return { status: 202, body: null };
    }
    if (method === 'initialize') {
      return {
        status: 200,
        body: rpcResult(id, {
          protocolVersion: PROTOCOL_VERSION,
          capabilities: CAPABILITIES,
          serverInfo: { name: server.name, version: server.version },
          instructions: `Read-only MCP server over usectrl.dev — the Control Center product site and manual. Tools: list_pages, get_page_markdown, search_pages. The product's own MCP server (103 tools over your repos, tickets, pipelines and agents) runs inside the self-hosted cc_server; see ${server.origin}/manual/guides/mcp-server/.`,
        }),
      };
    }
    if (method === 'ping') return { status: 200, body: rpcResult(id, {}) };
    if (method === 'tools/list') return { status: 200, body: rpcResult(id, { tools: TOOLS }) };
    if (method === 'tools/call') {
      const p = (params ?? {}) as { name?: unknown; arguments?: unknown };
      if (typeof p.name !== 'string') {
        return { status: 200, body: rpcError(id, -32602, 'Invalid params: tools/call requires params.name (string).') };
      }
      const args = typeof p.arguments === 'object' && p.arguments !== null ? (p.arguments as Record<string, unknown>) : {};
      return { status: 200, body: rpcResult(id, await callTool(p.name, args)) };
    }
    return { status: 200, body: rpcError(id, -32601, `Method not found: ${method}. Supported: initialize, ping, tools/list, tools/call, notifications/*.`) };
  }

  return {
    /** Discovery card for GETs (no SSE stream is offered). */
    info(): Record<string, unknown> {
      return {
        name: server.name,
        version: server.version,
        protocol: 'mcp',
        protocolVersion: PROTOCOL_VERSION,
        transport: 'streamable-http',
        endpoint: `${server.origin}/.well-known/mcp`,
        howTo: 'POST JSON-RPC 2.0 (Accept: application/json, text/event-stream): initialize, then tools/list, then tools/call.',
        tools: TOOLS.map((t) => ({ name: t.name, description: t.description })),
        docs: `${server.origin}/developers`,
      };
    },
    /** Handle a parsed request body (single message or batch). */
    async handle(body: unknown): Promise<McpOutcome> {
      if (Array.isArray(body)) {
        if (body.length === 0) {
          return { status: 200, body: rpcError(null, -32600, 'Invalid Request: empty batch.') };
        }
        const outcomes = await Promise.all(body.map(handleOne));
        const responses = outcomes.filter((o) => o.body !== null).map((o) => o.body);
        if (responses.length === 0) return { status: 202, body: null };
        return { status: 200, body: responses };
      }
      return handleOne(body);
    },
  };
}
