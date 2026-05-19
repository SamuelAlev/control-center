/**
 * The MCP Server Card for this site's docs MCP server, published at
 * /.well-known/mcp/server-card.json.
 *
 * Spec: SEP-2127 (originally filed as issue #1649), "MCP Server Cards — HTTP
 * Server Discovery", Final on the Extensions Track. The SEP charters the
 * extension; the normative wire format lives in the extension repository
 * (modelcontextprotocol/experimental-ext-server-card, `schema.ts`). A card is a
 * static, pre-connection metadata document: WHO the server is and WHERE to
 * connect, so a client can configure itself without opening the transport.
 *
 * Two things about that spec drive the shape below:
 *
 * 1. There is no `serverInfo` wrapper. Identity is top level — required
 *    `$schema`, `name` (reverse-DNS, exactly one slash), `version`,
 *    `description`; optional `title` / `websiteUrl` / `repository` / `icons` —
 *    and the transport endpoint is `remotes[].url`, not `endpoint`.
 * 2. Cards deliberately DO NOT enumerate primitives (tools, resources,
 *    prompts) and do not advertise capabilities, because a server's surface can
 *    vary per user, session and deployment. Runtime `tools/list` stays the
 *    authority.
 *
 * This server is the boring case that assumption guards against: it is static,
 * unauthenticated and identical for every caller, so its tool list cannot vary
 * and publishing it costs a client one fetch instead of a handshake. The card
 * therefore carries the spec document exactly as specified, and adds the
 * convenience mirror — `serverInfo`, `endpoint`, `capabilities` and the tool
 * summaries under a vendor-namespaced `_meta` — as ADDITIVE fields. The
 * published JSON Schema is an open object (no `additionalProperties: false`),
 * so a card carrying them still validates. Primitives stay out of the standard
 * field set and live only under `_meta`, where a client that follows the spec
 * ignores them.
 *
 * Nothing here is retyped. `MCP_SERVER` is the same object the wire handshake
 * answers with, and the tool summaries are mapped from the `TOOLS` array the
 * server actually serves, so the card cannot drift from the server.
 * test/mcp-server-card.test.ts pins both directions.
 *
 * Scope honesty, same rule as src/agentic/openapi.ts and
 * src/agentic/api-catalog.ts: this card describes the read-only docs MCP server
 * that answers on THIS origin. The product's own MCP server (103 tools over
 * your repos, tickets, pipelines and agents) runs inside the self-hosted
 * `cc_server` on whatever host the operator runs it on. It is not on this
 * origin and is never claimed here — only documented, at
 * /manual/guides/mcp-server/.
 *
 * Pure module: no Astro and no Cloudflare imports, so the endpoint and the unit
 * tests share one implementation.
 */
import { REPO_URL, SITE_NAME } from '../data/site.ts';
import { CAPABILITIES, PROTOCOL_VERSION, TOOLS } from './mcp.ts';

/**
 * Identity of the docs MCP server — the single source for both the `serverInfo`
 * the `initialize` handshake returns (src/agentic/mcp-http.ts imports this) and
 * the identity this card publishes. One const so a version bump cannot land in
 * one of the two places.
 */
export const MCP_SERVER = { name: 'control-center-docs', version: '1.0.0' } as const;

/**
 * Where the MCP server answers, canonical path first. It is mounted twice:
 * `/.well-known/mcp` is what the RFC 9727 API catalog anchors, `/mcp` is the
 * short alias. Both are the same server, so both are listed as `remotes`.
 */
export const MCP_ENDPOINT_PATHS = ['/.well-known/mcp', '/mcp'] as const;

/**
 * Where the card is published.
 *
 * The spec reserves `GET <streamable-http-url>/server-card` as the recommended
 * location, and explicitly declines to recommend a `.well-known` namespace for
 * cards (`.well-known` is for site-wide metadata; a card is application-level).
 * This path is the reserved suffix, not that namespace: the server's
 * streamable-HTTP URL simply IS `/.well-known/mcp`, so appending `/server-card`
 * lands under `.well-known` by construction. The `.json` extension is ours — an
 * Astro route ending in `.json` prerenders to a static file whose extension is
 * what makes the CDN answer `application/json`.
 */
export const SERVER_CARD_PATH = `${MCP_ENDPOINT_PATHS[0]}/server-card.json`;

/** The media type the spec registers for a Server Card. */
export const SERVER_CARD_MEDIA_TYPE = 'application/mcp-server-card+json';

/**
 * The v1 Server Card JSON Schema. Required, and pinned to an exact value by the
 * schema's own `@pattern` — a breaking revision publishes a new `vN` family
 * rather than changing this URL.
 */
export const SERVER_CARD_SCHEMA_URL = 'https://static.modelcontextprotocol.io/schemas/v1/server-card.schema.json';

/**
 * The `_meta` key carrying this card's additive, non-standard block.
 *
 * Reverse-DNS namespaced per the protocol's `_meta` rules. Any prefix
 * containing a `modelcontextprotocol` or `mcp` label is reserved for MCP, so
 * ours is anchored on the site's own domain.
 */
export const SERVER_CARD_META_KEY = 'dev.usectrl/docs-mcp';

/** `description` is capped at 100 characters by the schema. */
export const SERVER_CARD_DESCRIPTION_MAX = 100;

/** Repository metadata for the server's source code. */
export interface ServerCardRepository {
  url: string;
  /** Hosting service identifier, e.g. `github`. */
  source: string;
  /** Relative path from the repository root to the server. */
  subfolder?: string;
  /** Forge-owned repository id, stable across renames. */
  id?: string;
}

/** An optionally-sized icon a client may display. */
export interface ServerCardIcon {
  src: string;
  mimeType?: string;
  /** `WxH` strings, or `any` for scalable formats. */
  sizes?: string[];
  theme?: 'light' | 'dark';
}

/** One HTTP endpoint this server answers on. */
export interface ServerCardRemote {
  type: 'streamable-http' | 'sse';
  url: string;
  supportedProtocolVersions?: string[];
}

/** The MCP `ServerCapabilities` shape, as returned by `initialize`. */
export interface ServerCardCapabilities {
  tools?: { listChanged?: boolean };
  resources?: { subscribe?: boolean; listChanged?: boolean };
  prompts?: { listChanged?: boolean };
}

/** Name and one-line purpose of one tool. */
export interface ServerCardTool {
  name: string;
  description: string;
}

/**
 * The additive block under {@link SERVER_CARD_META_KEY}. Everything the spec
 * keeps out of the standard field set, kept honest by being namespaced: a
 * client following SEP-2127 ignores it, and one that reads it knows it came
 * from this vendor rather than from MCP.
 */
export interface ServerCardMeta {
  transport: 'streamable-http';
  protocolVersion: string;
  /**
   * The tools this server serves. Static and identical for every caller, which
   * is why publishing them is safe here; a client MUST still prefer a live
   * `tools/list`.
   */
  tools: ServerCardTool[];
  /** What this server does and does not cover. */
  scope: string;
}

/** A SEP-2127 Server Card, plus this site's additive fields. */
export interface ServerCard {
  $schema: string;
  name: string;
  version: string;
  description: string;
  title?: string;
  websiteUrl?: string;
  repository?: ServerCardRepository;
  icons?: ServerCardIcon[];
  remotes?: ServerCardRemote[];
  /** Additive: the `serverInfo` a client will observe once it connects. */
  serverInfo: { name: string; version: string };
  /** Additive: the canonical transport endpoint, also first in `remotes`. */
  endpoint: string;
  /** Additive: the capabilities `initialize` reports. */
  capabilities: ServerCardCapabilities;
  _meta: Record<string, ServerCardMeta>;
}

export interface ServerCardInputs {
  /** Site origin with no trailing slash, e.g. https://usectrl.dev. */
  origin: string;
}

/**
 * `example.com` -> `com.example`. The schema wants a reverse-DNS namespace and
 * the site's own hostname is the only one this server can honestly claim, so it
 * is derived rather than written down. `hostname` (not `host`) on purpose: a
 * port would not match the schema's `^[a-zA-Z0-9.-]+/[a-zA-Z0-9._-]+$`.
 */
const reverseDns = (hostname: string): string => hostname.split('.').reverse().join('.');

/**
 * Build the card. Every URL is absolute: a card is fetched by crawlers and
 * registries that may not keep the base URI around.
 */
export function buildServerCard({ origin }: ServerCardInputs): ServerCard {
  const at = (path: string) => `${origin}${path}`;
  const namespace = reverseDns(new URL(origin).hostname);

  return {
    $schema: SERVER_CARD_SCHEMA_URL,
    name: `${namespace}/${MCP_SERVER.name}`,
    version: MCP_SERVER.version,
    // Kept under 100 characters — the schema's cap on this field.
    description: `Read-only MCP server over the ${SITE_NAME} product site and manual: list, fetch, search pages.`,
    title: `${SITE_NAME} docs`,
    websiteUrl: at('/developers'),
    repository: { url: REPO_URL, source: 'github', subfolder: 'docs' },
    icons: [{ src: at('/favicon.svg'), mimeType: 'image/svg+xml', sizes: ['any'] }],
    remotes: MCP_ENDPOINT_PATHS.map(
      (path): ServerCardRemote => ({
        type: 'streamable-http',
        url: at(path),
        supportedProtocolVersions: [PROTOCOL_VERSION],
      }),
    ),
    serverInfo: { name: MCP_SERVER.name, version: MCP_SERVER.version },
    endpoint: at(MCP_ENDPOINT_PATHS[0]),
    capabilities: CAPABILITIES,
    _meta: {
      [SERVER_CARD_META_KEY]: {
        transport: 'streamable-http',
        protocolVersion: PROTOCOL_VERSION,
        tools: TOOLS.map((tool): ServerCardTool => ({ name: tool.name, description: tool.description })),
        scope: `Serves this site's own pages and nothing else. The Control Center product's MCP server (103 tools over your repos, tickets, pipelines and agents) runs inside the self-hosted cc_server, not on this origin — see ${at('/manual/guides/mcp-server/')}.`,
      },
    },
  };
}
