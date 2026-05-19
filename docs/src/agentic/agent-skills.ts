/**
 * Agent Skills Discovery for usectrl.dev: the index published at
 * /.well-known/agent-skills/index.json per the Agent Skills Discovery RFC
 * v0.2.0, plus the SKILL.md documents it points at.
 *
 * Pure module — no Astro or Cloudflare imports — so the two endpoints and the
 * unit tests share one implementation. The index and the skill bodies live in
 * the same file on purpose: an index entry's `digest` is only meaningful if it
 * was computed from the very bytes the artifact route serves, and keeping both
 * behind one accessor is what makes that checkable.
 *
 * Two invariants this file exists to hold.
 *
 * 1. The digest is COMPUTED, never written down. A hardcoded hex string is
 *    correct exactly once: the next edit to a skill body silently invalidates
 *    every published digest, and a client that verifies (which is the entire
 *    point of publishing one) then rejects a skill that is perfectly fine.
 *    `buildAgentSkillsIndex` hashes `skillDocument(name)` at build time and the
 *    artifact route serves that same string, so the two cannot drift.
 *
 * 2. Scope honesty, the same rule as src/agentic/openapi.ts and
 *    src/agentic/api-catalog.ts: a skill served here may describe the Control
 *    Center product, but it must never imply the product's own API answers on
 *    this origin. The product's MCP tool server runs inside the self-hosted
 *    `cc_server` on whatever host the operator runs it on; the skill that
 *    covers it says so in its first paragraph.
 *
 * Skill bodies are deliberately ASCII-only (pinned by a test). The digest is
 * over UTF-8 bytes, so any typographic character would still hash correctly —
 * but restricting to ASCII removes the whole class of "which encoding did that
 * step use" question from an artifact whose only job is to hash predictably.
 */

/** Where the index is published (RFC v0.2.0 fixes this path). */
export const AGENT_SKILLS_INDEX_PATH = '/.well-known/agent-skills/index.json';

/** The `$schema` value identifying the index format. Pinned by a test. */
export const AGENT_SKILLS_SCHEMA = 'https://schemas.agentskills.io/discovery/0.2.0/schema.json';

/**
 * The RFC requires `application/json` for the index and `text/markdown` (or
 * `text/plain`) for a SKILL.md. Both routes prerender to a file with a real
 * extension, so the static-asset layer types them from `.json` / `.md` — the
 * opposite of /.well-known/api-catalog, whose extensionless path is why that
 * one has to be server-rendered.
 */
export const AGENT_SKILLS_INDEX_MEDIA_TYPE = 'application/json; charset=utf-8';
export const SKILL_MD_MEDIA_TYPE = 'text/markdown; charset=utf-8';

/**
 * RFC v0.2.0 `name`: 1-64 characters, lowercase alphanumeric and hyphens, no
 * leading, trailing or consecutive hyphens. Expressed as groups joined by
 * single hyphens, which forbids all three cases in one pattern.
 */
export const SKILL_NAME_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

/** RFC v0.2.0 `digest`: `sha256:` followed by 64 lowercase hex characters. */
export const SKILL_DIGEST_PATTERN = /^sha256:[0-9a-f]{64}$/;

/** The two artifact kinds v0.2.0 defines. We publish `skill-md` only. */
export type SkillType = 'skill-md' | 'archive';

/** One published entry, exactly the five members v0.2.0 requires. */
export interface SkillEntry {
  name: string;
  type: SkillType;
  description: string;
  url: string;
  digest: string;
}

/** The index document: two required members, nothing else. */
export interface AgentSkillsIndex {
  $schema: string;
  skills: SkillEntry[];
}

export interface AgentSkillsInputs {
  /** Site origin with no trailing slash, e.g. https://usectrl.dev. */
  origin: string;
}

/** A skill before it is hashed and published. */
interface SkillSource {
  name: string;
  /** Also used verbatim as the SKILL.md frontmatter description. */
  description: string;
  /** Markdown body, appended after the generated frontmatter block. */
  body: string;
}

/** Path of a skill's artifact, relative to the origin. */
export function skillUrlPath(name: string): string {
  return `/.well-known/agent-skills/${name}/SKILL.md`;
}

const SITE_ACCESS: SkillSource = {
  name: 'usectrl-dev-agent-access',
  description:
    'Read usectrl.dev, the Control Center documentation site, without parsing HTML: markdown twins via Accept: text/markdown or a .md suffix, /llms.txt and /llms-full.txt, a read-only docs MCP server at /mcp, an OpenAPI document, an RFC 9727 API catalog and structured JSON errors.',
  body: `# Read usectrl.dev without parsing HTML

usectrl.dev is the documentation and marketing site for Control Center, a
self-hosted developer operations deck for running AI coding agents. Every page
on it has a markdown twin and the whole site is queryable over MCP, so there is
never a reason to scrape the rendered HTML.

## Scope

This site is the documentation, not the product. Everything below answers on
\`https://usectrl.dev\`. The Control Center product's own MCP tool server runs
inside the \`cc_server\` binary you self-host, on your own host and port, and is
not reachable on this origin. For that surface, see the
\`control-center-mcp-tools\` skill.

## Get any page as markdown

Two spellings, same bytes:

- Send \`Accept: text/markdown\` on the page URL. Responses carry
  \`Vary: Accept\`, so a cache never hands the HTML variant to a markdown client
  or the other way round.
- Append \`.md\` to the path. \`/manual/quick-start/\` becomes
  \`/manual/quick-start.md\`; \`/\` becomes \`/index.md\`.

Trailing slashes and \`.html\` spellings collapse to the same twin, so every way
of writing a page URL negotiates identically. A path whose last segment already
contains a dot is an asset, a feed or a machine file and has no twin.

## Find out what exists

| Endpoint | What you get |
| --- | --- |
| \`GET /llms.txt\` | Curated site index (llmstxt.org convention): product pages, developer resources, then every docs page with a one-line description |
| \`GET /llms-full.txt\` | The entire site as one markdown file |
| \`GET /sitemap-index.xml\` | Every published route |
| \`GET /rss.xml\` | The changelog feed |

## Query the site over MCP

A read-only MCP server for this site's content is served over the Streamable
HTTP transport at both \`/mcp\` and \`/.well-known/mcp\`.

- \`POST\` JSON-RPC 2.0 with \`Accept: application/json, text/event-stream\`.
  Protocol version \`2025-06-18\`. Methods: \`initialize\`, \`ping\`,
  \`tools/list\`, \`tools/call\`, and \`notifications/*\` (acknowledged with 202
  and an empty body). Batch requests are accepted.
- \`GET\` returns a plain discovery card. No SSE stream is offered here, so do
  not wait on one.

Three tools:

| Tool | What it does |
| --- | --- |
| \`list_pages\` | Every page: path, title and one-line description |
| \`get_page_markdown\` | One page as markdown, selected by \`path\` |
| \`search_pages\` | Full-text search with titles weighted above bodies; returns matching paths with snippets |

\`get_page_markdown\` takes a site path with a trailing slash, for example \`/\`
for the landing page or \`/manual/guides/mcp-server/\` for a docs page. A path
without the trailing slash is normalized rather than rejected, and an unknown
path returns an error that points you back at \`list_pages\`.

## Machine-readable descriptions of the site

- \`GET /openapi.json\` returns OpenAPI 3.1 for this site's endpoints, with
  typed responses and unique operation ids.
- \`GET /.well-known/api-catalog\` returns an RFC 9727 catalog as
  \`application/linkset+json\`, naming each API on this origin together with its
  description and documentation.
- Every content page carries RFC 8288 \`Link\` headers with
  \`rel="api-catalog"\`, \`service-desc\`, \`service-doc\` and \`describedby\`.
  Whatever page you land on, the machine surface is one header read away.

## Errors are structured, not blank

A 404 is never an empty body:

- \`Accept: application/json\`, or any path under \`/api/\`, returns a JSON
  envelope with \`error.code\`, \`error.message\`, \`error.hint\`,
  \`error.status\`, \`error.docs\` and \`error.sitemap\`.
- \`Accept: text/markdown\` returns a short markdown recovery map linking the
  sitemap, llms.txt, the manual, the OpenAPI document and the MCP endpoint.
- Anything else gets the rendered HTML 404 page.

## Suggested route

1. \`GET /llms.txt\` to see what exists and pick a page.
2. Fetch that page's markdown twin, or call \`search_pages\` when you do not
   know the page name yet.
3. Reach for \`/llms-full.txt\` only when you genuinely want the whole site at
   once; it is large.
`,
};

const PRODUCT_MCP: SkillSource = {
  name: 'control-center-mcp-tools',
  description:
    "Call Control Center's own MCP tool server, which runs inside the self-hosted cc_server and not on usectrl.dev: the endpoint and protocol version, the mandatory workspace_id on every workspace-scoped tool, bearer-token auth beyond loopback, what the surface refuses, and the tool classes that ship but are not registered.",
  body: `# Use Control Center's MCP tool server

## This does not run on usectrl.dev

Control Center's tool server lives inside \`cc_server\`, the headless binary an
operator self-hosts. It answers on that operator's host and port. usectrl.dev
serves the documentation for it and a separate, much smaller MCP server over
this site's own content; it does not proxy the product. If you have no
\`cc_server\` address, you have no access to these tools.

## Find the endpoint

The MCP surface shares the main \`cc_server\` listener. There is no separate MCP
port.

| Endpoint | Method | Purpose |
| --- | --- | --- |
| \`/mcp\` | \`POST\` | Streamable HTTP transport; this is what a client speaks |
| \`/mcp\` | \`DELETE\` | End a session |
| \`/sse\` | \`GET\` | Server-sent notification stream |

Protocol version \`2024-11-05\`. A default local install is at
\`http://127.0.0.1:9030/mcp\`. The surface is on by default on a fresh install,
so a loopback client needs no settings trip, and it binds loopback unless the
server was started with \`--bind any\`.

## Scope every call to a workspace

Every tool that touches workspace-scoped data requires \`workspace_id\`. This is
the single most common reason a call fails.

- A missing or invalid \`workspace_id\` returns an explicit error. It is never
  resolved against a "current" or "default" workspace, because there is no such
  concept.
- A \`workspace_id\` that does not match the target entity's workspace is
  rejected outright rather than silently ignored.
- Repo-scoped tools additionally check that the repo is linked to that
  workspace.
- The id is the one in the app or browser URL: \`/workspaces/<workspace_id>/...\`.
  \`list_workspaces\` is global and takes none.
- When the server dispatches an agent, the workspace is forced server-side, so
  an agent cannot reach another workspace by passing a foreign id.

\`\`\`json
{
  "workspace_id": "acme",
  "title": "Fix login bug",
  "priority": "high"
}
\`\`\`

## Authenticate beyond the host

A tokenless surface refuses any non-loopback caller with 403. That is
fail-closed by design: configuring a token is what makes off-host service
possible at all.

1. Settings -> Server -> MCP servers -> Authentication token -> Set.
2. Send \`Authorization: Bearer <token>\` on every \`POST /mcp\` request. Token
   changes apply immediately, with no restart.

One caveat worth internalising: \`GET /sse\` deliberately skips the bearer check,
because a browser \`EventSource\` cannot send headers. Treat exposing the MCP
port off-host as exposing that notification stream.

## Discover tools

\`tools/list\` advertises the full registry with no discovery gating, because an
external MCP client refuses to call a tool that is not in its cached list.
Two tools help you narrow it down and both consult the mode guard, so they
report what is callable in the current conversation rather than in the
abstract:

- \`search_tool_bm25\` - search the catalogue by keyword; returns matching tools,
  their argument schemas, and whether each is callable right now.
- \`list_my_tools\` - the tools callable right now in this conversation,
  filtered by its mode.

Roughly 103 typed tools are registered, grouped into families: agents and peer
messaging (\`send_to_agent\`, \`ask_agent\`, \`delegate_task\`, \`consult_agent\`),
tickets, spaces and messaging, memory, review, governance, skills, plans and
artifacts, teams and pipelines, and the code graph. The authoritative catalogue
is the MCP tools reference on usectrl.dev; treat any count you remember as
approximate and call \`tools/list\` for the truth.

Two absences are worth knowing up front: there are no meeting or calendar tools
and no project tools. The code graph tools (\`search_code\`, \`code_symbol\`,
\`code_callers\`, \`code_callees\`, \`code_impact\`) index Dart, JavaScript,
TypeScript, TSX and PHP only, so symbols in any other language are simply not
present.

## Know what the surface will refuse

- **Mode gating.** A call is resolved against the mode of the calling agent's
  space, server-side. An agent in a read-only mode cannot reach a write tool by
  omitting \`space_id\`; the mode is looked up from its active run instead.
- **Action guardrails.** Mutating tools declare their effect classes and pass
  through the same policy the rest of the product uses.
- **Confirmation.** Some destructive tools build a confirmation payload that has
  to be approved before the call proceeds.

## A tool you read about may not exist

A set of tool classes ship in the codebase but are constructed in no registry,
so calling one returns "unknown tool" rather than failing usefully. Named
examples: \`create_workspace\`, the project tools, \`hire_agent\`, \`fire_agent\`,
\`doctor\`, \`ask_user_question\` and \`start_ai_review\`. If \`tools/list\` does
not name it, it is not callable, whatever the documentation of some other
version said.

## Connecting Claude Code

Claude Code will not pick this server up from a project \`.mcp.json\`: it gates
project-scoped MCP servers behind an approval prompt that a non-interactive
\`claude -p\` never answers. Pass the config explicitly.

\`\`\`bash
claude --mcp-config /path/to/mcp.json --strict-mcp-config
\`\`\`

\`--strict-mcp-config\` makes Claude use only that file, so the same server is
not also discovered from the project and registered twice.

\`\`\`json
{
  "mcpServers": {
    "control-center": {
      "type": "http",
      "url": "http://127.0.0.1:9030/mcp"
    }
  }
}
\`\`\`

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| Client sees no tools | MCP server card is not running, or the port does not match \`cc_server\` |
| 403 from a machine that is not the server | No bearer token configured; set one and send it |
| "Missing or invalid argument: workspace_id" | Add \`workspace_id\`; there is no implicit workspace |
| "unknown tool" | The tool class ships but is registered nowhere; check \`tools/list\` |

Full documentation: \`https://usectrl.dev/manual/guides/mcp-server/\` and
\`https://usectrl.dev/manual/reference/mcp-tools/\`.
`,
};

const SELF_HOSTING: SkillSource = {
  name: 'control-center-self-hosting',
  description:
    'Run and reach a Control Center cc_server instance: the binary and the four GHCR images, the flag and environment surface with its silent-typo trap, loopback and TLS rules, device pairing, the data-directory layout, and why the native libraries are required rather than optional.',
  body: `# Run a Control Center server

\`cc_server\` is the whole product. It is a pure-Dart native binary with no
Flutter engine, so it runs headless on macOS, Linux and Windows. It owns the
database, runs the agents and makes every external API call; the desktop, web
and phone clients only render what it sends. Get the server right and every
client is correct for free.

## Defaults worth memorising

| Setting | Default |
| --- | --- |
| Port | \`9030\` (\`0\` selects an ephemeral port) |
| Bind | \`loopback\` |
| Log level | \`warning\` (the booting and ready lines always print) |
| Data dir | The OS per-user application-data directory |

## Configure it

Every setting takes a CLI flag or an environment variable. Precedence is flag,
then environment, then default.

| Flag | Environment variable | Meaning |
| --- | --- | --- |
| \`--data-dir\` | \`CC_SERVER_DATA_DIR\` | Databases, secrets, models, cached media |
| \`--port\` | \`CC_SERVER_PORT\` | TCP port |
| \`--bind\` | \`CC_SERVER_BIND\` | \`loopback\`, or \`any\`/\`all\`/\`0.0.0.0\` |
| \`--log-level\` | \`CC_SERVER_LOG_LEVEL\` | \`debug\`, \`info\`, \`warning\`, \`error\` |
| \`--repo-roots\` | \`CC_SERVER_REPO_ROOTS\` | Base directories a client may browse; above a root is refused |
| \`--tls-cert\` / \`--tls-key\` | \`CC_SERVER_TLS_CERT\` / \`CC_SERVER_TLS_KEY\` | Serve \`wss://\` in-process |
| \`--insecure\` | \`CC_SERVER_INSECURE\` | Allow a plaintext non-loopback bind |
| \`--public-url\` | \`CC_SERVER_PUBLIC_URL\` | The RPC URL advertised to paired clients |
| \`--allowed-origins\` | \`CC_SERVER_ALLOWED_ORIGINS\` | Browser origins allowed to dial \`/rpc\` cross-origin |
| \`--sandbox\` | \`CC_SERVER_SANDBOX\` | Opt out of the OS-native sandbox wrapper |
| \`--code-index\` | \`CC_SERVER_CODE_INDEX\` | Kill switch for background code-graph indexing |

**The trap: unknown flags are ignored silently.** The argument parser is
hand-rolled and skips anything it does not recognise, so \`--tls-key-file\` or
\`--bindany\` produces no error at all; the server just starts with the default.
When a flag seems to have no effect, read the startup log lines rather than
assuming the flag took.

Two more rules that bite in practice:

- A non-loopback bind needs TLS configured or \`--insecure\` passed. \`--insecure\`
  is only safe behind a TLS-terminating proxy on a trusted network, and it is
  ignored when TLS is configured.
- Behind a proxy, NAT or tunnel, set \`--public-url\` explicitly. The default is
  derived from the local bind, which is a guess, and a wrong guess means paired
  clients dial an address that does not exist.

## Run it in Docker

Every release publishes four images to GHCR. Pin a version tag or ride
\`latest\`.

| Image | What it is | Container port |
| --- | --- | --- |
| \`ghcr.io/samuelalev/cc-server\` | The backend: database, agents, MCP, webhooks | \`9030\` |
| \`ghcr.io/samuelalev/cc-webapp\` | The web client (static nginx) | \`8080\` |
| \`ghcr.io/samuelalev/cc-remote\` | The phone companion PWA (static nginx) | \`8080\`, usually published on \`8081\` |
| \`ghcr.io/samuelalev/cc-signaling-server\` | The pairing relay (optional) | \`8788\` |

Things to know before exposing any of it:

- The \`cc-server\` image ships \`CC_SERVER_INSECURE=1\`, because it must bind
  \`0.0.0.0\` to receive published-port traffic. Put a TLS-terminating reverse
  proxy in front of it, or mount a certificate and set \`CC_SERVER_TLS_CERT\` /
  \`CC_SERVER_TLS_KEY\` and unset \`CC_SERVER_INSECURE\`.
- \`/data\` is the only state. Databases, paired-device secrets, downloaded
  models and meeting audio all live there. Back up that volume and the
  container is disposable.
- The signaling relay is a fallback only. A phone uses loopback, LAN, a tailnet
  or a direct \`wss://\` path when one is reachable. Skip the relay if your
  clients always reach the server directly.

## Pair a client before the first connection

\`\`\`bash
cc_server pair
\`\`\`

It provisions a device and prints its id and pairing key. Run it while no
server holds the data directory. In Docker, run it against the same volume with
\`--entrypoint /app/bin/cc_server\`.

- \`--device\` defaults to \`web-client\`; the platform is inferred from the id,
  so \`--device desktop\` mints a desktop row and \`--device ios\`/\`android\` a
  phone row.
- \`--host\` should be the LAN IP or tunnel host a client will actually dial.
- Re-running \`pair\` for the same \`--device\` rotates its key.
- A credential minted by the CLI has no expiry, unlike the 30 days an in-app
  pairing sets.

Other subcommands: \`cc_server calendar connect --workspace <id>\`,
\`cc_server update\` (refused for installs it does not own, such as the
desktop's embedded server, a source checkout or a container), and
\`cc_server --version\`, which prints the same identity \`/healthz\` and the RPC
handshake advertise.

## The data directory

Persistence is split by workspace, which is what makes workspace isolation
structural rather than a convention.

| Path | Contents |
| --- | --- |
| \`global.db\` | The workspace registry, users, paired devices, the newsfeed, the fleet queue |
| \`<workspaceId>/workspace.db\` | One database per workspace: agents, spaces, tickets, memory, the code graph |
| \`secrets.json\` | Pairing keys, the provider app identity, per-user tokens and SSO secrets, mode \`0600\` |
| \`models/\` | On-device embedding, diarization and speech models |
| \`meetings/<meetingId>/\` | Retained meeting audio |
| \`rigs/\` | Rig disk images, per-rig microVM state and the dev-domain certificate authority |

## Building from source

The native libraries are required and there is no degraded mode. Stage them
from the repository root before building:

\`\`\`bash
scripts/natives/build_natives.sh
cd apps/cc_server && dart build cli
\`\`\`

A missing native is treated as a broken install, not a runtime condition: the
boot preflight refuses to start and names the offending library. That is
deliberate, because a silent fallback hides a broken native behind a slower
working path forever.

Full documentation: \`https://usectrl.dev/manual/guides/run-headless-server/\`
and \`https://usectrl.dev/manual/reference/cc-server-cli/\`.
`,
};

/**
 * Everything published, in index order. Adding an entry here publishes both
 * the index row and its artifact route: the route's `getStaticPaths` reads
 * this same list, so a skill cannot appear in the index with no artifact
 * behind it.
 */
export const SKILLS: readonly SkillSource[] = [SITE_ACCESS, PRODUCT_MCP, SELF_HOSTING];

const BY_NAME = new Map(SKILLS.map((s) => [s.name, s]));

/** Every published skill name, in index order. */
export function skillNames(): string[] {
  return SKILLS.map((s) => s.name);
}

/**
 * The complete SKILL.md text for one skill: Agent Skills frontmatter carrying
 * the same name and description the index publishes, then the body.
 *
 * This is the ONLY definition of what the artifact route serves, and the digest
 * is taken over its return value, so "the bytes at `url`" and "the bytes that
 * were hashed" are the same expression rather than two things kept in step by
 * hand. The description is double-quoted because it contains colons, which an
 * unquoted YAML scalar cannot carry.
 */
export function skillDocument(name: string): string {
  const skill = BY_NAME.get(name);
  if (!skill) throw new Error(`Unknown skill: ${name}. Published: ${skillNames().join(', ')}.`);
  return `---\nname: ${skill.name}\ndescription: "${skill.description}"\n---\n\n${skill.body}`;
}

/** Lowercase hex SHA-256 of a string's UTF-8 bytes. */
export async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Build the discovery index. Async because hashing is: `crypto.subtle` is the
 * one SHA-256 available both in the Node build and in the Workers runtime, and
 * it only comes as a promise.
 *
 * Every `url` is absolute. The RFC permits a relative reference, but an index
 * is fetched by clients that may not keep the base URI around, and absolute
 * costs nothing — the same call the RFC 9727 catalog makes next door.
 */
export async function buildAgentSkillsIndex({ origin }: AgentSkillsInputs): Promise<AgentSkillsIndex> {
  const skills = await Promise.all(
    SKILLS.map(async (skill): Promise<SkillEntry> => {
      const hex = await sha256Hex(skillDocument(skill.name));
      return {
        name: skill.name,
        // Every artifact here is a single SKILL.md. There is no archive: one
        // would need real .tar.gz bytes to hash, and an entry whose digest
        // does not match a real artifact is worse than no entry at all.
        type: 'skill-md',
        description: skill.description,
        url: `${origin}${skillUrlPath(skill.name)}`,
        digest: `sha256:${hex}`,
      };
    }),
  );
  return { $schema: AGENT_SKILLS_SCHEMA, skills };
}
