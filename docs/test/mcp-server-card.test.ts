import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  MCP_ENDPOINT_PATHS,
  MCP_SERVER,
  SERVER_CARD_DESCRIPTION_MAX,
  SERVER_CARD_MEDIA_TYPE,
  SERVER_CARD_META_KEY,
  SERVER_CARD_PATH,
  SERVER_CARD_SCHEMA_URL,
  buildServerCard,
  type ServerCardMeta,
} from '../src/agentic/mcp-server-card.ts';
import { CAPABILITIES, PROTOCOL_VERSION, TOOLS, createMcpHandler } from '../src/agentic/mcp.ts';

const ORIGIN = 'https://usectrl.dev';
const card = buildServerCard({ origin: ORIGIN });
const meta = card._meta[SERVER_CARD_META_KEY] as ServerCardMeta;

/** The real handler, over an empty page index — the card claims no page data. */
const handler = createMcpHandler(async () => [], { ...MCP_SERVER, origin: ORIGIN });

const rpc = async (method: string): Promise<Record<string, unknown>> => {
  const outcome = await handler.handle({ jsonrpc: '2.0', id: 1, method });
  assert.equal(outcome.status, 200, `${method} did not answer 200`);
  const body = outcome.body as { result?: Record<string, unknown>; error?: unknown };
  assert.ok(body.result, `${method} answered an error: ${JSON.stringify(body.error)}`);
  return body.result;
};

describe('server card — SEP-2127 required fields', () => {
  it('declares the pinned v1 schema URL', () => {
    // The schema's own @pattern is an exact match on this URL; a breaking
    // revision publishes a new vN family rather than editing it in place.
    assert.equal(card.$schema, SERVER_CARD_SCHEMA_URL);
    assert.match(card.$schema, /^https:\/\/static\.modelcontextprotocol\.io\/schemas\/v1\/server-card\.schema\.json$/);
  });

  it('carries every required member', () => {
    for (const key of ['$schema', 'name', 'version', 'description'] as const) {
      assert.ok(card[key], `missing required member: ${key}`);
    }
  });

  it('names itself in reverse-DNS form, one slash, derived from the origin', () => {
    assert.match(card.name, /^[a-zA-Z0-9.-]+\/[a-zA-Z0-9._-]+$/);
    assert.equal(card.name.split('/').length, 2);
    assert.equal(card.name, `dev.usectrl/${MCP_SERVER.name}`);
    assert.ok(card.name.length >= 3 && card.name.length <= 200);
  });

  it('keeps description inside the schema cap and non-empty', () => {
    assert.ok(card.description.length > 0);
    assert.ok(
      card.description.length <= SERVER_CARD_DESCRIPTION_MAX,
      `description is ${card.description.length} chars, cap is ${SERVER_CARD_DESCRIPTION_MAX}`,
    );
  });

  it('publishes a concrete version, never a range', () => {
    assert.equal(card.version, MCP_SERVER.version);
    assert.doesNotMatch(card.version, /[\^~*]|>=|<=|\.x/, 'version ranges are rejected by the schema');
  });

  it('is published at the reserved <streamable-http-url>/server-card location', () => {
    assert.equal(SERVER_CARD_PATH, `${MCP_ENDPOINT_PATHS[0]}/server-card.json`);
    assert.equal(SERVER_CARD_PATH, '/.well-known/mcp/server-card.json');
    assert.equal(SERVER_CARD_MEDIA_TYPE, 'application/mcp-server-card+json');
  });

  it('round-trips through JSON unchanged', () => {
    // The route serializes it; anything undefined-valued or non-serializable
    // would silently vanish between here and the wire.
    assert.deepEqual(JSON.parse(JSON.stringify(card)), card);
  });
});

describe('server card — transport', () => {
  it('lists a streamable-http remote for every path the server is mounted at', () => {
    const urls = (card.remotes ?? []).map((r) => r.url);
    assert.deepEqual(
      urls,
      MCP_ENDPOINT_PATHS.map((p) => `${ORIGIN}${p}`),
      'remotes and the mounted endpoint paths disagree',
    );
    for (const remote of card.remotes ?? []) {
      assert.equal(remote.type, 'streamable-http', `${remote.url} is not streamable-http`);
      assert.ok(remote.url.startsWith(`${ORIGIN}/`), `remote url is not absolute on the origin: ${remote.url}`);
    }
  });

  it('advertises the protocol version the handshake actually negotiates', async () => {
    const initialize = await rpc('initialize');
    for (const remote of card.remotes ?? []) {
      assert.deepEqual(remote.supportedProtocolVersions, [PROTOCOL_VERSION]);
      assert.deepEqual(remote.supportedProtocolVersions, [initialize.protocolVersion]);
    }
    assert.equal(meta.protocolVersion, initialize.protocolVersion);
  });

  it('points endpoint at the canonical remote', () => {
    assert.equal(card.endpoint, `${ORIGIN}/.well-known/mcp`);
    assert.ok(
      (card.remotes ?? []).some((r) => r.url === card.endpoint),
      'endpoint is not one of the remotes',
    );
  });

  it('makes every published URL absolute on this origin', () => {
    const urls = [card.websiteUrl, card.endpoint, ...(card.icons ?? []).map((i) => i.src), ...(card.remotes ?? []).map((r) => r.url)];
    for (const url of urls) {
      assert.ok(url?.startsWith(`${ORIGIN}/`), `not absolute on the origin: ${url}`);
    }
  });

  it('derives its namespace from whatever origin it is built for', () => {
    const local = buildServerCard({ origin: 'http://localhost:4321' });
    assert.equal(local.name, `localhost/${MCP_SERVER.name}`);
    assert.match(local.name, /^[a-zA-Z0-9.-]+\/[a-zA-Z0-9._-]+$/, 'a port must not leak into the card name');
    assert.equal(local.endpoint, 'http://localhost:4321/.well-known/mcp');
  });
});

describe('server card — identity matches the live handshake', () => {
  it('publishes the serverInfo initialize returns', async () => {
    const initialize = await rpc('initialize');
    assert.deepEqual(card.serverInfo, initialize.serverInfo);
    assert.deepEqual(card.serverInfo, { name: MCP_SERVER.name, version: MCP_SERVER.version });
  });

  it('publishes the capabilities initialize returns', async () => {
    const initialize = await rpc('initialize');
    assert.deepEqual(card.capabilities, initialize.capabilities);
    assert.deepEqual(card.capabilities, CAPABILITIES);
  });

  it('carries the card version through to the wire', async () => {
    const initialize = await rpc('initialize');
    assert.equal(card.version, (initialize.serverInfo as { version: string }).version);
  });
});

describe('server card — advertised tools are pinned to the real tool surface', () => {
  const advertised = meta.tools.map((t) => t.name);
  const real = TOOLS.map((t) => t.name);

  it('advertises no tool the server does not serve', () => {
    for (const name of advertised) {
      assert.ok(real.includes(name), `the card advertises "${name}" but the server does not serve it`);
    }
  });

  it('advertises every tool the server serves', () => {
    for (const name of real) {
      assert.ok(advertised.includes(name), `the server serves "${name}" but the card does not advertise it`);
    }
  });

  it('advertises them in the same order, with no duplicates', () => {
    assert.deepEqual(advertised, real);
    assert.equal(new Set(advertised).size, advertised.length, 'a tool is advertised twice');
  });

  it('copies each description verbatim rather than paraphrasing it', () => {
    const byName = new Map<string, string>(TOOLS.map((t) => [t.name, t.description] as [string, string]));
    for (const tool of meta.tools) {
      assert.equal(tool.description, byName.get(tool.name), `description drifted for "${tool.name}"`);
      assert.ok(tool.description.length > 0, `"${tool.name}" has no description`);
    }
  });

  it('matches what tools/list answers over the wire', async () => {
    const { tools } = (await rpc('tools/list')) as { tools: { name: string }[] };
    assert.deepEqual(
      meta.tools.map((t) => t.name),
      tools.map((t) => t.name),
      'the card and tools/list disagree',
    );
  });

  it('is exactly the three read-only docs tools', () => {
    assert.deepEqual(advertised, ['list_pages', 'get_page_markdown', 'search_pages']);
  });
});

describe('server card — scope honesty', () => {
  it('claims tools only, never resources or prompts', () => {
    // Absence is the MCP signal for unsupported; a false claim here would send
    // a client into resources/list against a server that has none.
    assert.ok(card.capabilities.tools, 'the card must claim the tools capability');
    assert.equal(card.capabilities.resources, undefined);
    assert.equal(card.capabilities.prompts, undefined);
    assert.equal(card.capabilities.tools?.listChanged, false, 'this server never emits list-changed');
  });

  it('keeps primitives out of the standard field set, per the spec', () => {
    // SEP-2127 deliberately omits tools/resources/prompts from a card. Ours
    // live only under a vendor _meta key, where a spec-following client
    // ignores them.
    const standard = card as unknown as Record<string, unknown>;
    for (const key of ['tools', 'resources', 'prompts', 'primitives']) {
      assert.equal(standard[key], undefined, `"${key}" must not be a top-level card field`);
    }
    assert.ok(Array.isArray(meta.tools), 'the tool summaries belong under _meta');
  });

  it('namespaces _meta on a domain MCP has not reserved', () => {
    const [prefix, name] = SERVER_CARD_META_KEY.split('/');
    assert.ok(name, '_meta key needs a prefix and a name');
    assert.match(prefix, /^[a-zA-Z](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?(?:\.[a-zA-Z](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)*$/);
    assert.match(name, /^[a-zA-Z0-9](?:[a-zA-Z0-9._-]*[a-zA-Z0-9])?$/);
    assert.doesNotMatch(prefix, /(^|\.)(modelcontextprotocol|mcp)$/, 'that prefix is reserved for MCP');
    assert.deepEqual(Object.keys(card._meta), [SERVER_CARD_META_KEY], '_meta must carry only the namespaced block');
  });

  it("never claims the product's cc_server MCP server on this origin", () => {
    // The 103-tool product server runs inside the self-hosted cc_server, on a
    // host this site knows nothing about. The card documents it and stops.
    const serialized = JSON.stringify(card);
    assert.ok(meta.scope.includes('cc_server'), 'the scope note must name where the product server actually runs');
    assert.ok(meta.scope.includes(`${ORIGIN}/manual/guides/mcp-server/`), 'the scope note must link the manual');
    assert.doesNotMatch(serialized, /127\.0\.0\.1|localhost:9030/, 'a card must not publish a private endpoint');
    for (const remote of card.remotes ?? []) {
      assert.doesNotMatch(remote.url, /9030/, 'the cc_server port is not an endpoint on this origin');
    }
  });

  it('publishes no credential-shaped material', () => {
    // Cards are public by design and MUST NOT carry credentials.
    assert.doesNotMatch(JSON.stringify(card), /authorization|api[_-]?key|secret|token|password/i);
  });
});
