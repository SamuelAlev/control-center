import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { createMcpHandler, type McpPage } from '../src/agentic/mcp.ts';

const FIXTURE_PAGES: McpPage[] = [
  { path: '/', title: 'Control Center', description: 'The deck.', markdown: '# Control Center\n\nWorktree isolation for agent fleets.' },
  {
    path: '/manual/guides/mcp-server/',
    title: 'Use the MCP server',
    description: 'Connect an external MCP client.',
    markdown: '# Use the MCP server\n\nPoint your client at http://127.0.0.1:9030/mcp.',
  },
  {
    path: '/manual/concepts/workspaces/',
    title: 'Workspaces and isolation',
    description: 'Hard-boundary tenants.',
    markdown: '# Workspaces and isolation\n\nWorkspaces are isolated tenants with worktree isolation per channel.',
  },
];

const SERVER = { name: 'control-center-docs', version: '1.0.0', origin: 'https://usectrl.dev' };

const makeHandler = () => createMcpHandler(async () => FIXTURE_PAGES, SERVER);

describe('MCP handshake', () => {
  it('answers initialize with protocol version, capabilities and serverInfo', async () => {
    const handler = makeHandler();
    const outcome = await handler.handle({ jsonrpc: '2.0', id: 1, method: 'initialize', params: {} });
    assert.equal(outcome.status, 200);
    const body = outcome.body as { result: { protocolVersion: string; capabilities: { tools: object }; serverInfo: { name: string } } };
    assert.equal(body.result.protocolVersion, '2025-06-18');
    assert.ok(body.result.capabilities.tools);
    assert.equal(body.result.serverInfo.name, 'control-center-docs');
  });

  it('acknowledges notifications with 202 and no body', async () => {
    const handler = makeHandler();
    const outcome = await handler.handle({ jsonrpc: '2.0', method: 'notifications/initialized' });
    assert.equal(outcome.status, 202);
    assert.equal(outcome.body, null);
  });

  it('answers ping with an empty result', async () => {
    const handler = makeHandler();
    const outcome = await handler.handle({ jsonrpc: '2.0', id: 'p', method: 'ping' });
    assert.deepEqual(outcome.body, { jsonrpc: '2.0', id: 'p', result: {} });
  });

  it('rejects unknown methods with -32601 naming the supported set', async () => {
    const handler = makeHandler();
    const outcome = await handler.handle({ jsonrpc: '2.0', id: 7, method: 'resources/list' });
    const body = outcome.body as { error: { code: number; message: string } };
    assert.equal(body.error.code, -32601);
    assert.match(body.error.message, /tools\/list/);
  });

  it('rejects malformed envelopes with -32600', async () => {
    const handler = makeHandler();
    const outcome = await handler.handle({ id: 1, method: 'ping' });
    const body = outcome.body as { error: { code: number } };
    assert.equal(body.error.code, -32600);
  });

  it('handles batches, dropping notification acknowledgements', async () => {
    const handler = makeHandler();
    const outcome = await handler.handle([
      { jsonrpc: '2.0', id: 1, method: 'ping' },
      { jsonrpc: '2.0', method: 'notifications/initialized' },
      { jsonrpc: '2.0', id: 2, method: 'ping' },
    ]);
    assert.equal(outcome.status, 200);
    const bodies = outcome.body as { id: number }[];
    assert.deepEqual(bodies.map((b) => b.id), [1, 2]);
  });
});

describe('MCP tools', () => {
  it('tools/list returns three tools with closed input schemas', async () => {
    const handler = makeHandler();
    const outcome = await handler.handle({ jsonrpc: '2.0', id: 1, method: 'tools/list' });
    const body = outcome.body as { result: { tools: { name: string; description: string; inputSchema: { type: string } }[] } };
    const names = body.result.tools.map((t) => t.name);
    assert.deepEqual(names, ['list_pages', 'get_page_markdown', 'search_pages']);
    for (const tool of body.result.tools) {
      assert.ok(tool.description.length > 20, `${tool.name} needs a real description`);
      assert.equal(tool.inputSchema.type, 'object');
    }
  });

  it('list_pages returns every page as JSON text', async () => {
    const handler = makeHandler();
    const outcome = await handler.handle({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: 'list_pages', arguments: {} } });
    const body = outcome.body as { result: { content: { text: string }[] } };
    const pages = JSON.parse(body.result.content[0].text) as { path: string }[];
    assert.equal(pages.length, FIXTURE_PAGES.length);
    assert.deepEqual(pages.map((p) => p.path), FIXTURE_PAGES.map((p) => p.path));
  });

  it('get_page_markdown returns the page body, normalizing the path', async () => {
    const handler = makeHandler();
    for (const path of ['/manual/guides/mcp-server/', 'manual/guides/mcp-server', '/manual/guides/mcp-server']) {
      const outcome = await handler.handle({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: 'get_page_markdown', arguments: { path } } });
      const body = outcome.body as { result: { content: { text: string }[]; isError?: boolean } };
      assert.ok(!body.result.isError, `path ${path} should resolve`);
      assert.match(body.result.content[0].text, /Use the MCP server/);
    }
  });

  it('get_page_markdown errors with a recovery hint for unknown or missing paths', async () => {
    const handler = makeHandler();
    const unknown = await handler.handle({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: 'get_page_markdown', arguments: { path: '/nope/' } } });
    const unknownBody = unknown.body as { result: { isError: boolean; content: { text: string }[] } };
    assert.equal(unknownBody.result.isError, true);
    assert.match(unknownBody.result.content[0].text, /list_pages/);

    const missing = await handler.handle({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: 'get_page_markdown', arguments: {} } });
    const missingBody = missing.body as { result: { isError: boolean; content: { text: string }[] } };
    assert.equal(missingBody.result.isError, true);
    assert.match(missingBody.result.content[0].text, /Missing or invalid argument: path/);
  });

  it('search_pages ranks title hits first and respects the limit', async () => {
    const handler = makeHandler();
    const outcome = await handler.handle({
      jsonrpc: '2.0',
      id: 1,
      method: 'tools/call',
      params: { name: 'search_pages', arguments: { query: 'worktree isolation', limit: 2 } },
    });
    const body = outcome.body as { result: { content: { text: string }[] } };
    const hits = JSON.parse(body.result.content[0].text) as { path: string; score: number; snippet: string }[];
    assert.ok(hits.length <= 2);
    assert.equal(hits[0].path, '/manual/concepts/workspaces/');
    assert.ok(hits[0].snippet.length > 0);
  });

  it('search_pages reports no-match instead of fabricating', async () => {
    const handler = makeHandler();
    const outcome = await handler.handle({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: 'search_pages', arguments: { query: 'xyzzy-not-here' } } });
    const body = outcome.body as { result: { content: { text: string }[]; isError?: boolean } };
    assert.ok(!body.result.isError);
    assert.match(body.result.content[0].text, /No pages match/);
  });

  it('unknown tools fail with isError, not a crash', async () => {
    const handler = makeHandler();
    const outcome = await handler.handle({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: 'delete_everything', arguments: {} } });
    const body = outcome.body as { result: { isError: boolean; content: { text: string }[] } };
    assert.equal(body.result.isError, true);
    assert.match(body.result.content[0].text, /list_pages/);
  });
});
