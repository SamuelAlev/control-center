/**
 * Shared HTTP transport for the docs MCP server, mounted at /.well-known/mcp
 * and /mcp. Protocol: MCP Streamable HTTP with plain application/json
 * responses (no SSE stream is opened); notifications get 202; GET gets a
 * discovery card.
 *
 * CORS is wide open on purpose: the server is read-only, serves only public
 * site content and holds no sessions or credentials, so a cross-origin page
 * gains nothing it could not fetch directly. (The DNS-rebinding concern the
 * spec's Origin check addresses does not apply to a stateless public read
 * surface.)
 */
import type { APIRoute } from 'astro';
import { getMarkdownPages, type MarkdownPage } from './markdown-pages';
import { createMcpHandler, type McpPage } from './mcp';

const SERVER = { name: 'control-center-docs', version: '1.0.0' } as const;

// The page index is build-time data; compute it once per isolate.
let pagesPromise: Promise<McpPage[]> | null = null;
const getPages = (): Promise<McpPage[]> => {
  pagesPromise ??= getMarkdownPages('https://usectrl.dev').then((pages) =>
    pages.map((p): McpPage => ({ path: p.path, title: p.title, description: p.description, markdown: p.markdown })),
  );
  return pagesPromise;
};

const handler = createMcpHandler(getPages, { ...SERVER, origin: 'https://usectrl.dev' });

const CORS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Accept, Authorization, MCP-Protocol-Version, MCP-Session-Id',
};

const json = (status: number, body: unknown): Response =>
  new Response(JSON.stringify(body, null, 2), {
    status,
    headers: { 'Content-Type': 'application/json; charset=utf-8', ...CORS },
  });

export const mcpOptions: APIRoute = () => new Response(null, { status: 204, headers: CORS });

export const mcpGet: APIRoute = () => json(200, handler.info());

export const mcpPost: APIRoute = async ({ request }) => {
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
  const outcome = await handler.handle(body);
  if (outcome.status === 202) return new Response(null, { status: 202, headers: CORS });
  return json(outcome.status, outcome.body);
};
