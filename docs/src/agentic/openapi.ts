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

const notFoundRef = { $ref: '#/components/responses/NotFound' } as const;

export function buildOpenApi({ origin, version, compareToolIds, docSlugs }: OpenApiInputs): Record<string, unknown> {
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

  return {
    openapi: '3.1.0',
    info: {
      title: 'Control Center website API',
      version,
      description: `Machine-readable surface of usectrl.dev — the Control Center website. ${MARKDOWN_NOTE} The product's own API (103 MCP tools over Streamable HTTP) runs inside the self-hosted cc_server, not on this origin; see ${origin}/manual/guides/mcp-server/.`,
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
      '/': pageGet('getLandingPage', 'Landing page', `What the product is, the four pillars, downloads. ${MARKDOWN_NOTE}`),
      '/about': pageGet('getAboutPage', 'About', `What Control Center is, how it is built, who maintains it. ${MARKDOWN_NOTE}`),
      '/contact': pageGet('getContactPage', 'Contact', `How to reach the maintainers (GitHub issues; security and privacy process). ${MARKDOWN_NOTE}`),
      '/developers': pageGet(
        'getDevelopersPage',
        'Developer portal',
        `Integration surface: product MCP server, cc_server CLI and Docker images, plus this site's agent endpoints. ${MARKDOWN_NOTE}`,
      ),
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
      '/manual/{page}': pageGet('getDocsPage', 'Documentation page', `One manual page (tutorial, guide, concept or reference). ${MARKDOWN_NOTE}`, [
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
          description: 'The direct markdown twin of /. Every page has one: append .md to its path.',
          tags: ['Content'],
          responses: { '200': markdownResponse },
        },
      },
      '/llms.txt': {
        get: {
          operationId: 'getLlmsTxt',
          summary: 'Curated site index for LLMs',
          description:
            'The llmstxt.org index: product summary, when-to-use guidance, developer resources and every docs page with a one-line description.',
          tags: ['Agent'],
          responses: {
            '200': { description: 'The index.', content: { 'text/plain': { schema: { type: 'string' } } } },
          },
        },
      },
      '/llms-full.txt': {
        get: {
          operationId: 'getLlmsFullTxt',
          summary: 'Entire site as one text file',
          description: 'Product overview, FAQ, comparison matrix, changelog and every manual page body in one download.',
          tags: ['Agent'],
          responses: {
            '200': { description: 'The full dump.', content: { 'text/plain': { schema: { type: 'string' } } } },
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
      '/.well-known/mcp/server-card.json': {
        get: {
          operationId: 'getMcpServerCard',
          summary: 'MCP server card',
          description:
            'The SEP-2127 server card for the docs MCP server: its identity, the streamable-HTTP remotes it answers on and the protocol versions it speaks. The reserved extensionless path /.well-known/mcp/server-card serves the same document.',
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
              required: true,
              description: 'MCP clients send `application/json, text/event-stream`; this server always answers application/json.',
              schema: { type: 'string', default: 'application/json, text/event-stream' },
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
              description: 'The MCP methods this server implements.',
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
