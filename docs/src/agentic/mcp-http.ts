/**
 * HTTP transport for the docs MCP server, served by the Worker
 * (src/worker.ts) at /.well-known/mcp and /mcp. Protocol: MCP Streamable
 * HTTP with plain application/json responses (no SSE stream is opened);
 * notifications get 202; GET gets a discovery card.
 *
 * Pages come from the build's per-language index
 * (`/agentic/pages/<locale>.json`, see src/pages/agentic/pages/), read through
 * the assets binding and cached per isolate, so the Worker never bundles the
 * content collection. The request's Accept-Language picks the default
 * language; a tool's `locale` argument overrides it.
 *
 * CORS is wide open on purpose: the server is read-only, serves only public
 * site content and holds no sessions or credentials, so a cross-origin page
 * gains nothing it could not fetch directly. (The DNS-rebinding concern the
 * spec's Origin check addresses does not apply to a stateless public read
 * surface.)
 */
import { preferredLanguage } from '../locale-negotiation.ts';
import { createMcpHandler, type McpPage } from './mcp.ts';
import { MCP_SERVER as SERVER } from './mcp-server-card.ts';

/** Paths the MCP endpoint answers on. */
export const MCP_PATHS: ReadonlySet<string> = new Set(['/mcp', '/mcp/', '/.well-known/mcp', '/.well-known/mcp/']);

export interface AssetFetcher {
  fetch(input: string | URL | Request): Promise<Response>;
}

const indexes = new Map<string, Promise<McpPage[]>>();

/** One language's page index, fetched once per isolate (and again after a failure). */
function pagesFor(assets: AssetFetcher, origin: string, locale: string): Promise<McpPage[]> {
  let index = indexes.get(locale);
  if (!index) {
    index = assets.fetch(new URL(`/agentic/pages/${locale}.json`, origin)).then(response => {
      if (!response.ok) throw new Error(`page index for ${locale} responded ${response.status}`);
      return response.json() as Promise<McpPage[]>;
    });
    index.catch(() => indexes.delete(locale));
    indexes.set(locale, index);
  }
  return index;
}

const CORS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Accept, Accept-Language, Authorization, MCP-Protocol-Version, MCP-Session-Id',
};

const json = (status: number, body: unknown): Response =>
  new Response(JSON.stringify(body, null, 2), {
    status,
    headers: { 'Content-Type': 'application/json; charset=utf-8', ...CORS },
  });

/** Answers one MCP HTTP request. */
export async function serveMcp(request: Request, assets: AssetFetcher): Promise<Response> {
  const origin = new URL(request.url).origin;
  const handler = createMcpHandler(locale => pagesFor(assets, origin, locale), { ...SERVER, origin: 'https://usectrl.dev' });
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
  if (request.method === 'GET' || request.method === 'HEAD') return json(200, handler.info());
  if (request.method !== 'POST') {
    return new Response(null, { status: 405, headers: { Allow: 'GET, POST, OPTIONS', ...CORS } });
  }
  // Spec posture: a client that sends Accept lists application/json (or */*)
  // — we always answer JSON. A missing header is tolerated so simple probes
  // (curl, audit bots) still complete the handshake.
  const accept = request.headers.get('Accept');
  if (accept && !/(application\/json|\*\/\*)/.test(accept)) {
    return json(406, {
      jsonrpc: '2.0',
      id: null,
      error: { code: -32600, message: 'Not Acceptable: this server answers application/json.' },
    });
  }
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return json(400, { jsonrpc: '2.0', id: null, error: { code: -32700, message: 'Parse error: body must be JSON.' } });
  }
  const acceptLanguage = request.headers.get('Accept-Language');
  const outcome = await handler.handle(body, { locale: acceptLanguage ? preferredLanguage(acceptLanguage) : undefined });
  if (outcome.status === 202) return new Response(null, { status: 202, headers: CORS });
  return json(outcome.status, outcome.body);
}
