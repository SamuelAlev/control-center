/**
 * Agent discovery for usectrl.dev: the RFC 9727 API catalog served at
 * /.well-known/api-catalog, and the RFC 8288 `Link` headers that advertise it
 * from every content page (RFC 9727 §3).
 *
 * Pure module — no Astro or Cloudflare imports — so the endpoint, the worker
 * wrapper (src/worker.ts) and the unit tests share one implementation. The two
 * halves live together on purpose: the Link header and the catalog must name
 * the same resources, and a test pins them against each other.
 *
 * Scope honesty, same rule as src/agentic/openapi.ts: this catalogs the APIs
 * that answer on THIS origin — the website API and the docs MCP server. The
 * product's own API (103 MCP tools) runs inside the self-hosted `cc_server` on
 * whatever host the operator runs it on, so it has no anchor URI to publish
 * and is deliberately absent. It is documented, not catalogued, at
 * /manual/guides/mcp-server/ and /manual/reference/mcp-tools/.
 */

/** Where the catalog is published. */
export const API_CATALOG_PATH = '/.well-known/api-catalog';

/**
 * RFC 9727 §2 media type. Deliberately bare: the profile parameter
 * (`;profile="https://www.rfc-editor.org/info/rfc9727"`) that the RFC's
 * examples carry is advertised as a `profile` link relation on the response
 * instead, so consumers doing an exact-match on the Content-Type still see the
 * media type the spec registers. JSON is UTF-8 by definition (RFC 8259 §8.1),
 * so there is no charset to add either.
 */
export const API_CATALOG_MEDIA_TYPE = 'application/linkset+json';

/** The RFC 6906 profile URI identifying this document as an RFC 9727 catalog. */
export const API_CATALOG_PROFILE = 'https://www.rfc-editor.org/info/rfc9727';

export interface CatalogInputs {
  /** Site origin with no trailing slash, e.g. https://usectrl.dev. */
  origin: string;
}

/** One link target inside a linkset context object (RFC 9264 §4.2). */
export interface LinkTarget {
  href: string;
  type?: string;
  title?: string;
}

/**
 * One catalogued API. `anchor` is the API's own base URI; the relations are
 * the RFC 8631 set RFC 9727 builds on. `service-desc` and `service-doc` are
 * required here (not by the RFC) so an entry cannot ship without both.
 */
export interface CatalogEntry {
  anchor: string;
  'service-desc': LinkTarget[];
  'service-doc': LinkTarget[];
  'service-meta'?: LinkTarget[];
  alternate?: LinkTarget[];
  status?: LinkTarget[];
}

export interface ApiCatalog {
  linkset: CatalogEntry[];
}

/**
 * Build the catalog. Every href is absolute — RFC 9264 permits relative
 * references, but a catalog is fetched by crawlers that may not keep the base
 * URI around, and absolute costs nothing.
 */
export function buildApiCatalog({ origin }: CatalogInputs): ApiCatalog {
  const at = (path: string) => `${origin}${path}`;

  // Both APIs are described by the one OpenAPI document and documented by the
  // one developer portal, so these targets are shared rather than duplicated.
  const openApi: LinkTarget = {
    href: at('/openapi.json'),
    // The endpoint answers `application/json`; it does not send
    // `application/openapi+json`, so the catalog does not claim it does.
    type: 'application/json',
    title: 'OpenAPI 3.1 description of this site’s endpoints',
  };
  const developerPortal: LinkTarget = {
    href: at('/developers'),
    type: 'text/html',
    title: 'Developer portal — endpoints, MCP servers, CLI and containers',
  };

  return {
    linkset: [
      {
        // The website API: every page, its markdown twin, the feeds and the
        // machine-readable files.
        anchor: at('/'),
        'service-desc': [openApi],
        'service-doc': [developerPortal],
        'service-meta': [
          {
            href: at('/llms.txt'),
            type: 'text/plain',
            title: 'Curated site index for LLMs (llmstxt.org)',
          },
          {
            href: at('/sitemap-index.xml'),
            type: 'application/xml',
            title: 'Every published route',
          },
          {
            href: at('/.well-known/agent-skills/index.json'),
            type: 'application/json',
            title: 'Agent skills discovery index (digest-verifiable SKILL.md artifacts)',
          },
        ],
      },
      {
        // The docs MCP server: JSON-RPC 2.0 over Streamable HTTP, exposing
        // this site's content as tools.
        anchor: at('/.well-known/mcp'),
        'service-desc': [openApi],
        'service-doc': [developerPortal],
        'service-meta': [
          {
            href: at('/.well-known/mcp/server-card.json'),
            type: 'application/json',
            title: 'MCP server card (SEP-2127)',
          },
        ],
        alternate: [
          {
            href: at('/mcp'),
            type: 'application/json',
            title: 'The same MCP server at its short path',
          },
        ],
      },
    ],
  };
}

/** A single RFC 8288 link, before serialization. */
export interface DiscoveryLink {
  rel: string;
  href: string;
  type?: string;
  title?: string;
}

/**
 * The links every content page advertises. `api-catalog` is the RFC 9727 §3
 * relation; the rest are the registered relations an agent looks for when it
 * wants the machine surface without fetching the catalog first.
 */
export function discoveryLinks({ origin }: CatalogInputs): DiscoveryLink[] {
  const at = (path: string) => `${origin}${path}`;
  return [
    {
      rel: 'api-catalog',
      href: at(API_CATALOG_PATH),
      type: API_CATALOG_MEDIA_TYPE,
      title: 'API catalog (RFC 9727)',
    },
    {
      rel: 'service-desc',
      href: at('/openapi.json'),
      type: 'application/json',
      // ASCII on purpose — see toAscii below; these become header values.
      title: "OpenAPI 3.1 description of this site's endpoints",
    },
    {
      rel: 'service-doc',
      href: at('/developers'),
      type: 'text/html',
      title: 'Developer portal',
    },
    {
      rel: 'describedby',
      href: at('/llms.txt'),
      type: 'text/plain',
      title: 'Curated site index for LLMs',
    },
  ];
}

/**
 * Fold a parameter value to ASCII.
 *
 * Header field values are ByteStrings: one non-ASCII character makes
 * `Headers.append` throw, and because the worker stamps these links on every
 * content page, that failure would take down EVERY page request rather than
 * just spoil a header. RFC 8288 §3.4 reserves `title*` (RFC 8187) for
 * non-ASCII titles; rather than emit one for a label, fold the typography we
 * actually write and drop anything else, so a future title edit degrades the
 * label instead of the site.
 */
const ASCII_FOLD: Record<string, string> = {
  '‘': "'",
  '’': "'",
  '“': '"',
  '”': '"',
  '–': '-',
  '—': '-',
  '…': '...',
  ' ': ' ',
};

const toAscii = (value: string): string =>
  value
    .replace(/[‘’“”–—… ]/g, (c) => ASCII_FOLD[c])
    // eslint-disable-next-line no-control-regex
    .replace(/[^\x20-\x7e]/g, '');

/** Quote an RFC 8288 parameter value, escaping what would end the string. */
const quote = (value: string): string => `"${toAscii(value).replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;

/** Serialize one link to an RFC 8288 field value. */
export function formatLink({ rel, href, type, title }: DiscoveryLink): string {
  const parts = [`<${href}>`, `rel=${quote(rel)}`];
  if (type) parts.push(`type=${quote(type)}`);
  if (title) parts.push(`title=${quote(title)}`);
  return parts.join('; ');
}

/**
 * Append the discovery links to a response's headers, one `Link` field each.
 * RFC 8288 §3 allows either repeated fields or one comma-separated value;
 * repeated fields keep any Link the platform already set intact.
 */
export function appendDiscoveryLinks(headers: Headers, origin: string): void {
  for (const link of discoveryLinks({ origin })) headers.append('Link', formatLink(link));
}
