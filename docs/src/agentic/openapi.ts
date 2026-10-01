/**
 * The OpenAPI 3.1 document for usectrl.dev's machine-readable surface,
 * published at /openapi.json.
 *
 * Scope honesty: this describes the WEBSITE's endpoints (content, feeds,
 * markdown twins, the docs MCP server). The product's own API is the MCP tool
 * server inside the self-hosted `cc_server` — documented in the manual at
 * /manual/guides/mcp-server/ and /manual/reference/mcp-tools/ — and is not
 * claimable here because it does not live on this origin.
 *
 * Pure module: inputs are passed in, so unit tests assert structure without
 * touching Astro collections.
 */

import { skillNames } from './agent-skills.ts';

export interface OpenApiInputs {
  origin: string;
  /** Site/release version string, e.g. v0.0.1-rc.1. */
  version: string;
  /** Compare-page tool slugs (for the enum on /compare/{tool}). */
  compareToolIds: string[];
  /** Docs slugs, e.g. 'manual/guides/mcp-server' (for the enum on /manual/{page}). */
  docSlugs: string[];
  /** BCP 47 tags the landing page and manual are published in, en-US first. */
  locales: string[];
}

const MARKDOWN_NOTE =
  'Every HTML page here serves a markdown twin: send `Accept: text/markdown` on the page URL (responses carry `Vary: Accept`), or append `.md` to the path (e.g. /manual/quick-start.md).';

const acceptParam = {
  name: 'Accept',
  in: 'header',
  required: false,
  description: 'Content negotiation: `text/markdown` returns the markdown twin; anything else returns HTML.',
  schema: { type: 'string', enum: ['text/html', 'text/markdown'], default: 'text/html' },
} as const;

const markdownResponse = {
  description: 'The page as markdown (title, description, body, canonical-URL footer).',
  headers: {
    Vary: { schema: { type: 'string' }, description: 'Always includes `Accept`.' },
  },
  content: { 'text/markdown': { schema: { type: 'string' } } },
} as const;

const htmlResponse = {
  description: 'The page as HTML.',
  headers: {
    Vary: { schema: { type: 'string' }, description: 'Always includes `Accept`.' },
  },
  content: { 'text/html': { schema: { type: 'string' } } },
} as const;

const htmlOnlyResponse = {
  description: 'The page as HTML. This route has no markdown twin.',
  content: { 'text/html': { schema: { type: 'string' } } },
} as const;

const notFoundRef = { $ref: '#/components/responses/NotFound' } as const;

const LANGUAGE_NOTE =
  'The landing page, manual and llms.txt are published in every site language under `/{locale}/` (manual pages under translated slugs; /manual-routes.json maps them). On an unprefixed URL the Worker answers 302 to the reader\u2019s language: `?lang=`, then the `cc-locale` cookie, then `Accept-Language`, else English. `/{locale}/` URLs are never redirected. Responses carry `Content-Language`.';

const acceptLanguageParam = {
  name: 'Accept-Language',
  in: 'header',
  required: false,
  description: `Picks the language this unprefixed URL redirects to (302, \`Vary: Accept-Language\`). ${LANGUAGE_NOTE}`,
  schema: { type: 'string', examples: ['fr-FR', 'ja', 'pt-BR;q=0.9, en;q=0.5'] },
} as const;

const redirectToLanguage = {
  description: 'The same resource in the reader\u2019s language, at its `/{locale}/` URL.',
  headers: { Location: { schema: { type: 'string' }, description: 'The localized URL (percent-encoded).' } },
} as const;

const contentLanguageHeader = {
  'Content-Language': { schema: { type: 'string' }, description: 'The response\u2019s language: `en` or a site locale such as `fr-FR`.' },
} as const;

export function buildOpenApi({ origin, version, compareToolIds, docSlugs, locales }: OpenApiInputs): Record<string, unknown> {
  const pageGet = (operationId: string, summary: string, description: string, extraParams: unknown[] = []) => ({
    get: {
      operationId,
      summary,
      description,
      tags: ['Content'],
      parameters: [acceptParam, ...extraParams],
      responses: { '200': { ...htmlResponse }, '404': notFoundRef },
    },
  });

  /** A translated resource at its English URL: negotiated to the reader's language. */
  const translatedGet = (operationId: string, summary: string, description: string, extraParams: unknown[] = []) => {
    const page = pageGet(operationId, summary, `${description} ${LANGUAGE_NOTE}`, [acceptLanguageParam, ...extraParams]);
    return {
      get: {
        ...page.get,
        responses: { '200': { ...htmlResponse, headers: { ...htmlResponse.headers, ...contentLanguageHeader } }, '302': redirectToLanguage, '404': notFoundRef },
      },
    };
  };

  const localeParam = {
    name: 'locale',
    in: 'path',
    required: true,
    description: 'A site language other than English (English lives at the unprefixed URL).',
    schema: { type: 'string', enum: locales.filter((locale) => locale !== 'en-US') },
  } as const;

  const textGet = (operationId: string, summary: string, description: string, extraParams: unknown[] = [], negotiated = false) => ({
    get: {
      operationId,
      summary,
      description,
      tags: ['Agent'],
      ...(extraParams.length || negotiated ? { parameters: [...(negotiated ? [acceptLanguageParam] : []), ...extraParams] } : {}),
      responses: {
        '200': { description: 'The text.', headers: contentLanguageHeader, content: { 'text/plain': { schema: { type: 'string' } } } },
        ...(negotiated ? { '302': redirectToLanguage } : {}),
      },
    },
  });

  const htmlOnlyGet = (operationId: string, summary: string, description: string) => ({
    get: {
      operationId,
      summary,
      description,
      tags: ['Content'],
      responses: { '200': htmlOnlyResponse, '404': notFoundRef },
    },
  });

  return {
    openapi: '3.1.0',
    info: {
      title: 'Control Center website API',
      version,
      description: `Machine-readable surface of usectrl.dev — the Control Center website. ${MARKDOWN_NOTE} ${LANGUAGE_NOTE} Languages: ${locales.join(', ')}. The product's own API (110 MCP tools over Streamable HTTP) runs inside the self-hosted cc_server, not on this origin; see ${origin}/manual/guides/mcp-server/.`,
      contact: { name: 'Control Center maintainers', url: 'https://github.com/SamuelAlev/control-center/issues' },
      license: { name: 'MIT', url: 'https://github.com/SamuelAlev/control-center/blob/main/LICENSE' },
    },
    servers: [{ url: origin, description: 'Production' }],
    externalDocs: { description: 'Product manual', url: `${origin}/manual/` },
    tags: [
      { name: 'Content', description: 'Pages and their markdown twins (Accept-negotiated).' },
      { name: 'Feeds', description: 'Whole-site serializations for agents and readers.' },
      { name: 'Agent', description: 'Endpoints designed for AI agents: MCP server, llms.txt, this document.' },
      { name: 'Errors', description: 'Structured error behavior for every unpublished path.' },
    ],
    paths: {
      '/': translatedGet('getLandingPage', 'Landing page', `What the product is, the five pillars, downloads. ${MARKDOWN_NOTE}`),
      '/{locale}/': pageGet('getLocalizedLandingPage', 'Landing page in one language', `The landing page in a site language. ${MARKDOWN_NOTE}`, [localeParam]),
      '/{locale}/{page}': pageGet(
        'getLocalizedDocsPage',
        'Documentation page in one language',
        `One manual page under its translated slug, e.g. /fr-FR/manuel/guides/creer-agent/; /manual-routes.json maps every English page to each language's slug. The prefixed English path a language used before its slugs were translated answers 301 to the translated one. ${MARKDOWN_NOTE}`,
        [
          localeParam,
          {
            name: 'page',
            in: 'path',
            required: true,
            description: 'Translated slug path; may span multiple segments and use the language\u2019s own script (percent-encoded).',
            style: 'simple',
            allowReserved: true,
            schema: { type: 'string' },
          },
        ],
      ),
      '/about': pageGet('getAboutPage', 'About', `What Control Center is, how it is built, who maintains it. ${MARKDOWN_NOTE}`),
      '/contact': pageGet('getContactPage', 'Contact', `How to reach the maintainers (GitHub issues; security and privacy process). ${MARKDOWN_NOTE}`),
      '/developers': pageGet(
        'getDevelopersPage',
        'Developer portal',
        `Integration surface: product MCP server, cc_server CLI and Docker images, plus this site's agent endpoints. ${MARKDOWN_NOTE}`,
      ),
      '/privacy': htmlOnlyGet('getPrivacyPage', 'Privacy policy', 'What the app and this site store and send. HTML only — no markdown twin.'),
      '/terms': htmlOnlyGet('getTermsPage', 'Terms of service', 'Terms that govern use of Control Center. HTML only — no markdown twin.'),
      '/acknowledgements': htmlOnlyGet(
        'getAcknowledgementsPage',
        'Acknowledgements',
        'Credits for third-party software. HTML only — no markdown twin.',
      ),
      '/licenses': htmlOnlyGet(
        'getLicensesPage',
        'Licenses',
        'Full license text for bundled third-party software. HTML only — no markdown twin.',
      ),
      '/demo': {
        get: {
          operationId: 'getDemoRedirect',
          summary: 'Live demo redirect',
          description:
            'A 302 to the web client pre-loaded with the demo connection. Not a content page and not in the sitemap — the destination is the demo fragment, which can change between builds.',
          tags: ['Content'],
          responses: { '302': { description: 'Redirect to the demo web client.' } },
        },
      },
      '/changelog': pageGet('getChangelogPage', 'Changelog', `Every release, newest first. ${MARKDOWN_NOTE}`),
      '/compare': pageGet('getComparePage', 'Comparison matrix', `Control Center vs the alternatives, capability by capability. ${MARKDOWN_NOTE}`),
      '/compare/{tool}': pageGet('getCompareToolPage', 'Per-tool comparison', `Control Center vs one named tool. ${MARKDOWN_NOTE}`, [
        {
          name: 'tool',
          in: 'path',
          required: true,
          description: 'Competitor slug.',
          schema: { type: 'string', enum: compareToolIds },
        },
      ]),
      '/manual/{page}': translatedGet('getDocsPage', 'Documentation page', `One manual page (tutorial, guide, concept or reference). ${MARKDOWN_NOTE}`, [
        {
          name: 'page',
          in: 'path',
          required: true,
          description: 'Docs slug; may span multiple segments (e.g. manual/guides/mcp-server).',
          style: 'simple',
          allowReserved: true,
          schema: { type: 'string', enum: docSlugs },
        },
      ]),
      '/index.md': {
        get: {
          operationId: 'getLandingMarkdown',
          summary: 'Landing page as markdown',
          description: `The direct markdown twin of /. Content pages that have a twin also answer at \`<path>.md\`; legal pages and /demo do not. ${LANGUAGE_NOTE}`,
          tags: ['Content'],
          parameters: [acceptLanguageParam],
          responses: { '200': { ...markdownResponse, headers: { ...markdownResponse.headers, ...contentLanguageHeader } }, '302': redirectToLanguage },
        },
      },
      '/llms.txt': textGet(
        'getLlmsTxt',
        'Curated site index for LLMs',
        `The llmstxt.org index: product summary, when-to-use guidance, developer resources and every docs page with a one-line description, plus each other language\u2019s index. ${LANGUAGE_NOTE}`,
        [],
        true,
      ),
      '/{locale}/llms.txt': textGet(
        'getLocalizedLlmsTxt',
        'Curated site index in one language',
        'The llms.txt index in a site language: its landing copy and manual under translated URLs; English-only pages are marked.',
        [localeParam],
      ),
      '/llms-full.txt': textGet(
        'getLlmsFullTxt',
        'Entire site as one text file',
        `Product overview, FAQ, comparison matrix, changelog and every manual page body in one download. ${LANGUAGE_NOTE}`,
        [],
        true,
      ),
      '/{locale}/llms-full.txt': textGet(
        'getLocalizedLlmsFullTxt',
        'Entire site in one language as one text file',
        'Overview, FAQ and every manual page body in a site language, in one download.',
        [localeParam],
      ),
      '/manual-routes.json': {
        get: {
          operationId: 'getManualRoutes',
          summary: 'Translated manual slugs',
          description:
            'Every language\u2019s manual URL for each English page: `{ "<locale>": { "<English id>": "<translated path>" } }`, e.g. `{ "fr-FR": { "manual/install": "manuel/installer" } }`. Prefix the path with `/<locale>/`.',
          tags: ['Agent'],
          responses: {
            '200': { description: 'The slug table.', content: { 'application/json': { schema: { type: 'object', additionalProperties: { type: 'object', additionalProperties: { type: 'string' } } } } } },
          },
        },
      },
      '/agentic/pages/{locale}.json': {
        get: {
          operationId: 'getPageIndex',
          summary: 'One language\u2019s page index',
          description:
            'Every page a reader of one language can use (its landing page and manual plus the English-only pages), as markdown with title, description, language and English original. The docs MCP server answers from these.',
          tags: ['Agent'],
          parameters: [{ name: 'locale', in: 'path', required: true, description: 'Any site language, en-US included.', schema: { type: 'string', enum: locales } }],
          responses: {
            '200': { description: 'The page index.', content: { 'application/json': { schema: { type: 'array', items: { type: 'object' } } } } },
            '404': notFoundRef,
          },
        },
      },
      '/openapi.json': {
        get: {
          operationId: 'getOpenApiDocument',
          summary: 'This OpenAPI document',
          description: 'The OpenAPI 3.1 description of this site\u2019s endpoints.',
          tags: ['Agent'],
          responses: {
            '200': { description: 'This document.', content: { 'application/json': { schema: { type: 'object' } } } },
          },
        },
      },
      '/mcp': {
        post: {
          operationId: 'callDocsMcpServerShortPath',
          summary: 'Docs MCP server (short path)',
          description:
            'The same Streamable HTTP MCP server as /.well-known/mcp, mounted at the conventional /mcp path. Identical request and response contract; either path may be used.',
          tags: ['Agent'],
          parameters: [
            {
              name: 'Accept',
              in: 'header',
              required: false,
              description:
                'MCP clients send `application/json, text/event-stream`; this server always answers application/json. A missing header is tolerated. A header that lists neither application/json nor */* is answered 406.',
              schema: { type: 'string', default: 'application/json, text/event-stream' },
            },
            {
              name: 'Accept-Language',
              in: 'header',
              required: false,
              description: `Default language of the pages tool calls return (a tool's \`locale\` argument overrides it); English when absent. Languages: ${locales.join(', ')}.`,
              schema: { type: 'string', examples: ['fr-FR', 'ja'] },
            },
          ],
          requestBody: {
            required: true,
            content: { 'application/json': { schema: { $ref: '#/components/schemas/JsonRpcRequest' } } },
          },
          responses: {
            '200': {
              description: 'JSON-RPC response (initialize, ping, tools/list, tools/call).',
              content: { 'application/json': { schema: { $ref: '#/components/schemas/JsonRpcResponse' } } },
            },
            '202': { description: 'Notification accepted (empty body).' },
            '400': { $ref: '#/components/responses/BadRequest' },
            '406': {
              description: 'Accept header present but lists neither application/json nor */*.',
              content: { 'application/json': { schema: { $ref: '#/components/schemas/JsonRpcResponse' } } },
            },
          },
        },
        get: {
          operationId: 'docsMcpServerInfoShortPath',
          summary: 'MCP server discovery card (short path)',
          description: 'The same JSON discovery card as GET /.well-known/mcp, naming the server and how to POST to it.',
          tags: ['Agent'],
          responses: {
            '200': { description: 'Discovery card.', content: { 'application/json': { schema: { type: 'object' } } } },
          },
        },
      },
      '/.well-known/api-catalog': {
        get: {
          operationId: 'getApiCatalog',
          summary: 'API catalog (RFC 9727)',
          description:
            'The linkset cataloguing the APIs on this origin — the website API and the docs MCP server — each with its service-desc (this OpenAPI document) and service-doc (the developer portal). Served as application/linkset+json. Every content page also advertises it with a `Link: <…>; rel="api-catalog"` header.',
          tags: ['Agent'],
          responses: {
            '200': {
              description: 'The catalog.',
              content: { 'application/linkset+json': { schema: { type: 'object' } } },
            },
          },
        },
      },
      '/.well-known/agent-skills/index.json': {
        get: {
          operationId: 'getAgentSkillsIndex',
          summary: 'Agent skills discovery index',
          description:
            'The Agent Skills Discovery index (v0.2.0): every published skill with its type, description, artifact URL and the SHA-256 digest of the exact bytes served at that URL.',
          tags: ['Agent'],
          responses: {
            '200': { description: 'The skills index.', content: { 'application/json': { schema: { type: 'object' } } } },
          },
        },
      },
      '/.well-known/agent-skills/{skill}/SKILL.md': {
        get: {
          operationId: 'getAgentSkillDocument',
          summary: 'One agent skill artifact',
          description:
            'The SKILL.md for one published skill. These are the exact bytes the index digest covers — fetch the artifact, hash it, and compare before trusting it.',
          tags: ['Agent'],
          parameters: [
            {
              name: 'skill',
              in: 'path',
              required: true,
              description: 'Skill name, as published in the index.',
              schema: { type: 'string', enum: skillNames() },
            },
          ],
          responses: {
            '200': { description: 'The skill document.', content: { 'text/markdown': { schema: { type: 'string' } } } },
            '404': notFoundRef,
          },
        },
      },
      '/.well-known/mcp/server-card': {
        get: {
          operationId: 'getMcpServerCardReservedPath',
          summary: 'MCP server card (reserved path)',
          description:
            'The SEP-2127 server card at the spec-reserved <streamable-http-url>/server-card path. Same document as /.well-known/mcp/server-card.json; this path answers application/mcp-server-card+json.',
          tags: ['Agent'],
          responses: {
            '200': {
              description: 'The server card.',
              content: { 'application/mcp-server-card+json': { schema: { type: 'object' } } },
            },
          },
        },
      },
      '/.well-known/mcp/server-card.json': {
        get: {
          operationId: 'getMcpServerCard',
          summary: 'MCP server card',
          description:
            'The SEP-2127 server card for the docs MCP server: its identity, the streamable-HTTP remotes it answers on and the protocol versions it speaks. The reserved extensionless path /.well-known/mcp/server-card serves the same document as application/mcp-server-card+json.',
          tags: ['Agent'],
          responses: {
            '200': { description: 'The server card.', content: { 'application/json': { schema: { type: 'object' } } } },
          },
        },
      },
      '/sitemap-index.xml': {
        get: {
          operationId: 'getSitemapIndex',
          summary: 'XML sitemap index',
          description: 'Every published page, for crawlers and agents.',
          tags: ['Feeds'],
          responses: { '200': { description: 'Sitemap index.', content: { 'application/xml': { schema: { type: 'string' } } } } },
        },
      },
      '/rss.xml': {
        get: {
          operationId: 'getRssFeed',
          summary: 'Changelog RSS feed',
          description: 'Release notes as RSS 2.0.',
          tags: ['Feeds'],
          responses: { '200': { description: 'RSS feed.', content: { 'application/rss+xml': { schema: { type: 'string' } } } } },
        },
      },
      '/.well-known/mcp': {
        post: {
          operationId: 'callDocsMcpServer',
          summary: 'Docs MCP server (Streamable HTTP)',
          description:
            'A Model Context Protocol endpoint exposing this site\u2019s content as tools — list_pages, get_page_markdown, search_pages. Speaks JSON-RPC 2.0 over POST with plain JSON responses; notifications get 202. Also reachable at /mcp.',
          tags: ['Agent'],
          parameters: [
            {
              name: 'Accept',
              in: 'header',
              required: false,
              description:
                'MCP clients send `application/json, text/event-stream`; this server always answers application/json. A missing header is tolerated. A header that lists neither application/json nor */* is answered 406.',
              schema: { type: 'string', default: 'application/json, text/event-stream' },
            },
            {
              name: 'Accept-Language',
              in: 'header',
              required: false,
              description: `Default language of the pages tool calls return (a tool's \`locale\` argument overrides it); English when absent. Languages: ${locales.join(', ')}.`,
              schema: { type: 'string', examples: ['fr-FR', 'ja'] },
            },
          ],
          requestBody: {
            required: true,
            content: { 'application/json': { schema: { $ref: '#/components/schemas/JsonRpcRequest' } } },
          },
          responses: {
            '200': {
              description: 'JSON-RPC response (initialize, ping, tools/list, tools/call).',
              content: { 'application/json': { schema: { $ref: '#/components/schemas/JsonRpcResponse' } } },
            },
            '202': { description: 'Notification accepted (empty body).' },
            '400': { $ref: '#/components/responses/BadRequest' },
            '406': {
              description: 'Accept header present but lists neither application/json nor */*.',
              content: { 'application/json': { schema: { $ref: '#/components/schemas/JsonRpcResponse' } } },
            },
          },
        },
        get: {
          operationId: 'docsMcpServerInfo',
          summary: 'MCP server discovery card',
          description: 'A small JSON card naming the server and how to POST to it. (SSE streaming is not offered.)',
          tags: ['Agent'],
          responses: {
            '200': { description: 'Discovery card.', content: { 'application/json': { schema: { type: 'object' } } } },
          },
        },
      },
      '/{path}': {
        get: {
          operationId: 'getUnpublishedPath',
          summary: 'Any unpublished path',
          description:
            'Every unpublished path returns a real 404 — never a 200 app shell. The body negotiates: HTML for browsers, markdown for `Accept: text/markdown`, a JSON error envelope for `Accept: application/json` and for any /api/* path.',
          tags: ['Errors'],
          parameters: [
            acceptParam,
            {
              name: 'path',
              in: 'path',
              required: true,
              description: 'Any path not published by this site.',
              schema: { type: 'string' },
            },
          ],
          responses: { '404': notFoundRef },
        },
      },
    },
    components: {
      schemas: {
        Error: {
          type: 'object',
          required: ['error'],
          properties: {
            error: {
              type: 'object',
              required: ['code', 'message', 'hint', 'status', 'docs', 'sitemap'],
              properties: {
                code: { type: 'string', description: 'Stable machine code, e.g. not_found.' },
                message: { type: 'string', description: 'What happened, in one sentence.' },
                hint: { type: 'string', description: 'How to recover: where the route list lives.' },
                status: { type: 'integer', description: 'HTTP status, repeated for clients that only read the body.' },
                docs: { type: 'string', format: 'uri', description: 'This OpenAPI document.' },
                sitemap: { type: 'string', format: 'uri', description: 'Every published route.' },
              },
            },
          },
        },
        JsonRpcRequest: {
          type: 'object',
          required: ['jsonrpc', 'method'],
          properties: {
            jsonrpc: { type: 'string', const: '2.0' },
            id: { oneOf: [{ type: 'string' }, { type: 'number' }, { type: 'null' }] },
            method: {
              type: 'string',
              enum: ['initialize', 'ping', 'tools/list', 'tools/call', 'notifications/initialized'],
              description:
                'The MCP methods this server implements. Any method whose name starts with notifications/ is accepted as a notification (202, empty body), not only notifications/initialized.',
            },
            params: { type: 'object' },
          },
        },
        JsonRpcResponse: {
          type: 'object',
          properties: {
            jsonrpc: { type: 'string', const: '2.0' },
            id: { oneOf: [{ type: 'string' }, { type: 'number' }, { type: 'null' }] },
            result: { type: 'object', description: 'Method result (initialize result, tools array, call content).' },
            error: {
              type: 'object',
              properties: {
                code: { type: 'integer', description: 'JSON-RPC error code (-32601 method not found, -32602 invalid params).' },
                message: { type: 'string' },
              },
            },
          },
        },
      },
      responses: {
        NotFound: {
          description: 'Not found. Body negotiates on Accept: JSON envelope (application/json), markdown recovery map (text/markdown), or the HTML 404 page.',
          content: {
            'application/json': { schema: { $ref: '#/components/schemas/Error' } },
            'text/markdown': { schema: { type: 'string' }, example: '# 404 — not found\n\n…\n## Where to look next\n…' },
            'text/html': { schema: { type: 'string' } },
          },
        },
        BadRequest: {
          description: 'Malformed JSON-RPC envelope.',
          content: { 'application/json': { schema: { $ref: '#/components/schemas/JsonRpcResponse' } } },
        },
      },
    },
  };
}
