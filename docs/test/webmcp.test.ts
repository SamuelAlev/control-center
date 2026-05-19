import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  BROWSER_ONLY_TOOL_NAMES,
  SHARED_TOOL_NAMES,
  createWebMcpTools,
  findModelContext,
  isContentPage,
  normalizePath,
  parseLlmsIndex,
  registerWebMcpTools,
  searchIndex,
  type JsonSchema,
  type WebMcpDeps,
  type WebMcpToolDefinition,
} from '../src/agentic/webmcp-tools.ts';
import { TOOLS as SERVER_TOOLS } from '../src/agentic/mcp.ts';

const ORIGIN = 'https://usectrl.dev';

/**
 * A slice of the real /llms.txt, verbatim in shape: the `## Section` headings,
 * a product bullet, the two-link RSS bullet, the endpoint bullets that are not
 * pages, the off-site source link and a couple of docs entries.
 */
const LLMS_TXT = `# Control Center

> Control Center (usectrl.dev) is a developer operations deck.

## Product

- [Landing page](${ORIGIN}/): what the deck is, the four pillars, the platform under the hood, downloads.
- [Compare Control Center](${ORIGIN}/compare/): feature matrix against Conductor and others.
- [Changelog](${ORIGIN}/changelog/): newest first; latest is v0.0.1-rc.1.
- [Control Center vs Conductor](${ORIGIN}/compare/conductor/): Conductor is the smoother start.
- [RSS feed](${ORIGIN}/rss.xml) and [llms-full.txt](${ORIGIN}/llms-full.txt): this whole site as one file.

## When to use this

Reach for Control Center when the job is:

- Running several AI coding agents at once on one repo.

## Developer resources

- [Developers portal](${ORIGIN}/developers): quickstart, product MCP server, CLI and containers.
- [OpenAPI document](${ORIGIN}/openapi.json): OpenAPI 3.1 for this site's endpoints.
- [API catalog](${ORIGIN}/.well-known/api-catalog): RFC 9727 linkset.
- [Docs MCP server](${ORIGIN}/.well-known/mcp): Streamable HTTP MCP over this site's content.
- [Source code](https://github.com/SamuelAlev/control-center): MIT-licensed monorepo.

## Docs — Start here

- [Quick start](${ORIGIN}/manual/quick-start/): install, first workspace, first agent.
- [Install](${ORIGIN}/manual/install/): downloads for macOS, Windows and Linux.

## Docs — Concepts

- [Workspaces and isolation](${ORIGIN}/manual/concepts/workspaces/): hard-boundary tenants.
`;

const QUICK_START_MD = '# Quick start\n\nInstall the app, then dispatch an agent.\n';

/** A fetch stub serving only the assets this origin really publishes. */
function stubFetch(overrides: Record<string, string> = {}) {
  const calls: string[] = [];
  const body: Record<string, string> = {
    '/llms.txt': LLMS_TXT,
    '/manual/quick-start.md': QUICK_START_MD,
    ...overrides,
  };
  const impl = (async (input: string | URL | Request) => {
    const url = String(input);
    calls.push(url);
    const found = body[url];
    if (found === undefined) return new Response('Not found', { status: 404 });
    return new Response(found, { status: 200 });
  }) as unknown as typeof globalThis.fetch;
  return { impl, calls };
}

const deps = (extra: Partial<WebMcpDeps> = {}): WebMcpDeps => ({
  origin: '',
  fetch: stubFetch().impl,
  ...extra,
});

const byName = (tools: WebMcpToolDefinition[]) => new Map(tools.map((t) => [t.name, t]));

const ALL_TOOLS = createWebMcpTools(deps({ navigate: () => {} }));

describe('WebMCP tool table', () => {
  it('gives every tool a name, a title and a description', () => {
    for (const tool of ALL_TOOLS) {
      assert.ok(tool.name, 'tool missing name');
      assert.match(tool.name, /^[a-z][a-z0-9_]*$/, `tool name is not snake_case: ${tool.name}`);
      assert.ok(tool.title, `${tool.name} missing title`);
      assert.ok(tool.description && tool.description.length > 30, `${tool.name} needs a real description`);
      assert.equal(typeof tool.execute, 'function', `${tool.name} missing execute`);
    }
  });

  it('uses unique names', () => {
    const names = ALL_TOOLS.map((t) => t.name);
    assert.equal(new Set(names).size, names.length, 'two tools share a name');
  });

  it('gives every tool a valid object JSON Schema', () => {
    for (const tool of ALL_TOOLS) {
      const schema: JsonSchema = tool.inputSchema;
      assert.equal(schema.type, 'object', `${tool.name} inputSchema must be an object schema`);
      assert.equal(typeof schema.properties, 'object', `${tool.name} inputSchema needs properties`);
      assert.equal(schema.additionalProperties, false, `${tool.name} must close its schema`);
      for (const [prop, def] of Object.entries(schema.properties)) {
        assert.ok(def.type, `${tool.name}.${prop} missing a type`);
        assert.ok(def.description, `${tool.name}.${prop} missing a description`);
      }
      for (const required of schema.required ?? []) {
        assert.ok(schema.properties[required], `${tool.name} requires "${required}" but never declares it`);
      }
      // The schema must survive the structured clone the platform does when
      // it hands the descriptor across to the agent.
      assert.doesNotThrow(() => structuredClone(schema), `${tool.name} inputSchema is not cloneable`);
    }
  });

  it('marks the read tools read-only and the navigation tool not', () => {
    const tools = byName(ALL_TOOLS);
    for (const name of SHARED_TOOL_NAMES) {
      assert.equal(tools.get(name)?.annotations.readOnlyHint, true, `${name} should be read-only`);
    }
    assert.equal(tools.get('navigate_to_page')?.annotations.readOnlyHint, false);
  });

  it('omits the navigation tool when nothing can navigate', () => {
    const names = createWebMcpTools(deps()).map((t) => t.name);
    assert.deepEqual(names, [...SHARED_TOOL_NAMES], 'an action tool that cannot act must not be advertised');
  });
});

describe('agreement with the docs MCP server', () => {
  // The real table from src/agentic/mcp.ts, read-only. The browser surface
  // and the HTTP surface are two doors onto the same content; an agent that
  // learns one vocabulary must not have to learn a second.
  const serverNames = SERVER_TOOLS.map((t) => t.name);

  it('re-offers every tool the HTTP MCP server exposes', () => {
    const browserNames = new Set(ALL_TOOLS.map((t) => t.name));
    for (const name of serverNames) {
      assert.ok(browserNames.has(name), `the HTTP MCP server exposes ${name} but the browser surface does not`);
    }
  });

  it('pins SHARED_TOOL_NAMES to the server table exactly', () => {
    assert.deepEqual([...SHARED_TOOL_NAMES], serverNames, 'the shared vocabulary drifted from src/agentic/mcp.ts');
  });

  it('declares every browser-only addition explicitly', () => {
    const extra = ALL_TOOLS.map((t) => t.name).filter((n) => !serverNames.includes(n));
    assert.deepEqual(
      extra,
      [...BROWSER_ONLY_TOOL_NAMES],
      'a browser tool has no counterpart on the HTTP server and is not listed as browser-only',
    );
  });

  it('argues the shared tools alike — same properties and same required set', () => {
    // Same name, different arguments would be worse than a different name:
    // an agent would call it with what the other surface taught it.
    const tools = byName(ALL_TOOLS);
    for (const serverTool of SERVER_TOOLS) {
      const browserTool = tools.get(serverTool.name);
      assert.ok(browserTool, `${serverTool.name} missing from the browser surface`);
      const serverSchema = serverTool.inputSchema as JsonSchema;
      assert.deepEqual(
        Object.keys(browserTool.inputSchema.properties).sort(),
        Object.keys(serverSchema.properties).sort(),
        `${serverTool.name} takes different properties on the two surfaces`,
      );
      assert.deepEqual(
        [...(browserTool.inputSchema.required ?? [])].sort(),
        [...(serverSchema.required ?? [])].sort(),
        `${serverTool.name} requires different arguments on the two surfaces`,
      );
    }
  });
});

describe('parseLlmsIndex', () => {
  const pages = parseLlmsIndex(LLMS_TXT, ORIGIN);
  const paths = pages.map((p) => p.path);

  it('finds the real content pages', () => {
    assert.deepEqual(paths, [
      '/',
      '/compare/',
      '/changelog/',
      '/compare/conductor/',
      '/developers',
      '/manual/quick-start/',
      '/manual/install/',
      '/manual/concepts/workspaces/',
    ]);
  });

  it('drops feeds, machine files and the off-site link', () => {
    for (const path of ['/rss.xml', '/llms-full.txt', '/openapi.json']) {
      assert.ok(!paths.includes(path), `${path} is not a page and must not be listed`);
    }
    assert.ok(!paths.some((p) => p.includes('github.com')), 'an off-site link leaked into the index');
  });

  it('drops the endpoints under /.well-known/, which have no markdown twin', () => {
    assert.ok(!paths.some((p) => p.startsWith('/.well-known/')), '/.well-known/* is not a page');
  });

  it('carries the title, description and section of each entry', () => {
    const quickStart = pages.find((p) => p.path === '/manual/quick-start/');
    assert.equal(quickStart?.title, 'Quick start');
    assert.equal(quickStart?.description, 'install, first workspace, first agent.');
    assert.equal(quickStart?.section, 'Docs — Start here');
  });

  it('ignores the prose bullets that carry no link', () => {
    assert.ok(!pages.some((p) => p.title.startsWith('Running several')));
  });

  it('returns nothing rather than guessing when the index is empty', () => {
    assert.deepEqual(parseLlmsIndex('', ORIGIN), []);
    assert.deepEqual(parseLlmsIndex(''), []);
  });

  it('infers the site origin from the index when none is configured', () => {
    // /llms.txt bakes in the canonical https://usectrl.dev links at build
    // time, so on localhost or a preview deploy the current origin does not
    // match. Inference keeps the index usable there — and still drops the
    // off-site GitHub link, which loses the vote.
    const inferred = parseLlmsIndex(LLMS_TXT).map((p) => p.path);
    assert.deepEqual(inferred, paths);
    assert.ok(!inferred.includes('/SamuelAlev/control-center'), 'the off-site repo link leaked in as a page');
  });

  it('still filters strictly when a site origin is given', () => {
    assert.deepEqual(parseLlmsIndex(LLMS_TXT, 'https://example.test'), []);
  });
});

describe('path handling', () => {
  it('normalizes to a trailing slash, leaving the root alone', () => {
    assert.equal(normalizePath('/'), '/');
    assert.equal(normalizePath('manual/quick-start'), '/manual/quick-start/');
    assert.equal(normalizePath('/manual/quick-start/'), '/manual/quick-start/');
    assert.equal(normalizePath('  /developers  '), '/developers/');
  });

  it('drops a query or fragment, which never select a different twin', () => {
    assert.equal(normalizePath('/manual/install/?utm=x#downloads'), '/manual/install/');
  });

  it('rejects endpoints and assets as content pages', () => {
    assert.equal(isContentPage('/'), true);
    assert.equal(isContentPage('/manual/quick-start/'), true);
    assert.equal(isContentPage('/rss.xml'), false);
    assert.equal(isContentPage('/openapi.json'), false);
    assert.equal(isContentPage('/.well-known/mcp'), false);
    assert.equal(isContentPage('/mcp'), false);
  });
});

describe('searchIndex', () => {
  const pages = parseLlmsIndex(LLMS_TXT, ORIGIN);

  it('ranks a title match above a description-only match', () => {
    const hits = searchIndex(pages, 'install', 10);
    assert.equal(hits[0].path, '/manual/install/');
    assert.ok(hits.some((h) => h.path === '/manual/quick-start/'), 'the description match should still appear');
  });

  it('honours the limit', () => {
    assert.equal(searchIndex(pages, 'control center', 2).length, 2);
  });

  it('returns nothing for an empty query', () => {
    assert.deepEqual(searchIndex(pages, '   ', 10), []);
  });
});

describe('execute reads real bytes from this origin', () => {
  it('list_pages fetches /llms.txt and returns the parsed index', async () => {
    const { impl, calls } = stubFetch();
    const tool = byName(createWebMcpTools(deps({ fetch: impl }))).get('list_pages')!;
    const out = JSON.parse(await tool.execute({}));
    assert.deepEqual(calls, ['/llms.txt']);
    assert.ok(Array.isArray(out) && out.length === 8);
    assert.equal(out[0].path, '/');
  });

  it('get_page_markdown fetches the page markdown twin', async () => {
    const { impl, calls } = stubFetch();
    const tool = byName(createWebMcpTools(deps({ fetch: impl }))).get('get_page_markdown')!;
    const out = await tool.execute({ path: '/manual/quick-start/' });
    assert.equal(out, QUICK_START_MD);
    assert.deepEqual(calls, ['/manual/quick-start.md'], 'must read the build-time twin, not the HTML page');
  });

  it('get_page_markdown reports a miss instead of inventing a page', async () => {
    const tool = byName(createWebMcpTools(deps({ fetch: stubFetch().impl }))).get('get_page_markdown')!;
    assert.match(await tool.execute({ path: '/nope/' }), /No page at \/nope\/\. Call list_pages/);
    assert.match(await tool.execute({}), /Missing or invalid argument: path/);
    assert.match(await tool.execute({ path: '/rss.xml' }), /No page at/);
  });

  it('search_pages falls back to /llms.txt when Pagefind is unreachable', async () => {
    const { impl } = stubFetch();
    const tool = byName(
      createWebMcpTools(deps({ fetch: impl, loadPagefind: async () => null })),
    ).get('search_pages')!;
    const out = JSON.parse(await tool.execute({ query: 'workspaces' }));
    assert.equal(out.source, 'llms.txt');
    assert.equal(out.results[0].path, '/manual/concepts/workspaces/');
  });

  it('search_pages uses Pagefind when it answers', async () => {
    const { impl } = stubFetch();
    const tool = byName(
      createWebMcpTools(
        deps({
          fetch: impl,
          loadPagefind: async () => ({
            search: async () => ({
              results: [
                {
                  data: async () => ({
                    url: '/manual/install/',
                    excerpt: 'Downloads for <mark>macOS</mark>, Windows and Linux.',
                    meta: { title: 'Install' },
                  }),
                },
              ],
            }),
          }),
        }),
      ),
    ).get('search_pages')!;
    const out = JSON.parse(await tool.execute({ query: 'macOS' }));
    assert.equal(out.source, 'pagefind');
    assert.deepEqual(out.results, [
      { path: '/manual/install/', title: 'Install', snippet: 'Downloads for macOS, Windows and Linux.' },
    ]);
  });

  it('search_pages validates its query rather than searching for nothing', async () => {
    const tool = byName(createWebMcpTools(deps({ fetch: stubFetch().impl }))).get('search_pages')!;
    assert.match(await tool.execute({ query: '   ' }), /Missing or invalid argument: query/);
  });

  it('navigate_to_page only navigates to a page the index really lists', async () => {
    const visited: string[] = [];
    const tools = byName(
      createWebMcpTools(deps({ fetch: stubFetch().impl, navigate: (u) => visited.push(u) })),
    );
    const tool = tools.get('navigate_to_page')!;

    assert.match(await tool.execute({ path: '/manual/install' }), /Opened \/manual\/install\//);
    assert.deepEqual(visited, ['/manual/install/']);

    assert.match(await tool.execute({ path: '/made-up/' }), /nothing was opened/);
    assert.deepEqual(visited, ['/manual/install/'], 'a miss must not navigate');
  });
});

describe('registration', () => {
  it('finds no model context in a browser without WebMCP', () => {
    assert.equal(findModelContext({ document: {}, navigator: {} }), null);
    assert.equal(findModelContext({}), null);
  });

  it('prefers document.modelContext, the current spec entry point', () => {
    const onDocument = { registerTool: () => {} };
    const onNavigator = { registerTool: () => {} };
    assert.equal(findModelContext({ document: { modelContext: onDocument }, navigator: { modelContext: onNavigator } }), onDocument);
  });

  it('still finds the origin-trial navigator.modelContext spelling', () => {
    const onNavigator = { registerTool: () => {} };
    assert.equal(findModelContext({ document: {}, navigator: { modelContext: onNavigator } }), onNavigator);
  });

  it('passes the abort signal through with every tool', async () => {
    const seen: { name: string; signal?: AbortSignal }[] = [];
    const controller = new AbortController();
    const count = await registerWebMcpTools(
      { registerTool: (tool, options) => void seen.push({ name: tool.name, signal: options?.signal }) },
      ALL_TOOLS,
      controller.signal,
    );
    assert.equal(count, ALL_TOOLS.length);
    assert.deepEqual(seen.map((s) => s.name), ALL_TOOLS.map((t) => t.name));
    for (const entry of seen) assert.equal(entry.signal, controller.signal, `${entry.name} lost the signal`);
  });

  it('keeps registering after one tool is rejected by an evolving API', async () => {
    const registered: string[] = [];
    const count = await registerWebMcpTools(
      {
        registerTool: async (tool) => {
          if (tool.name === 'get_page_markdown') throw new TypeError('unsupported descriptor');
          registered.push(tool.name);
        },
      },
      ALL_TOOLS,
    );
    assert.equal(count, ALL_TOOLS.length - 1);
    assert.ok(registered.includes('search_pages'), 'a later tool was lost to an earlier rejection');
  });
});
