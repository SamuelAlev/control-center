// Content for the /about, /contact and /developers pages. Single source of
// truth: the .astro pages render these sections as HTML and the markdown
// mirrors (`<page>.md`, served under `Accept: text/markdown`) derive from the
// same strings via htmlToMarkdown — the two can never drift.
//
// Keep the HTML constrained to <p>, <ul>/<ol>/<li>, <a>, <strong> and <code>:
// those are the tags the converter round-trips exactly.
//
// Factual accuracy rule (same as the manual): claims here are checked against
// the code and the manual, not against other marketing copy.

import { ISSUES_URL, REPO_URL } from './site';

export interface PageSection {
  id: string;
  title: string;
  /** HTML string, rendered with set:html. */
  html: string;
}

export interface SitePageData {
  /** Route leaf, e.g. 'about' → /about. */
  id: 'about' | 'contact' | 'developers';
  /** Small caps label above the title. */
  eyebrow: string;
  /** Full HTML <title> (with the " \\ Control Center" delimiter). */
  title: string;
  /** Short H1 (no delimiter). */
  heading: string;
  /** meta description. */
  description: string;
  /** Lead paragraph under the title. */
  intro: string;
  sections: PageSection[];
}

export const aboutPage: SitePageData = {
  id: 'about',
  eyebrow: 'About',
  title: 'About \\\\ Control Center',
  heading: 'About',
  description:
    'What Control Center is, why it exists and how it is built: a free, open-source developer operations deck for running a fleet of AI coding agents — self-hosted, cross-platform, multiplayer.',
  intro:
    'Control Center is the deck for your whole developer operation: dispatch and review AI coding agents, hand them disposable VMs to test in, and keep tickets, pipelines, meetings and your calendar in one place.',
  sections: [
    {
      id: 'what',
      title: 'What it is',
      html: `<p>Control Center is a free and open-source (MIT) developer operations deck. You dispatch AI coding agents across isolated copy-on-write Git worktrees, review and merge their pull requests, and run the surrounding operation — tickets, pipelines, meetings, calendar, memory and a code graph — in one native app.</p>
<p>It is built for operators who run more than one agent at a time. One-off prompts are easy; the hard part is everything around them: knowing what each agent is doing, keeping its changes off your working tree, reviewing what it produced and turning that into merged work. Control Center is that layer.</p>`,
    },
    {
      id: 'how',
      title: 'How it is built',
      html: `<p>Every client — the desktop apps for macOS, Windows and Linux, the web app and the phone companion — is a thin renderer over one headless <code>cc_server</code> you run. The server owns the database, the external API calls and the execution; clients hold no business logic. Self-hosted first: your code, credentials and run logs stay on hardware you control.</p>
<p>Agents run inside OS-native sandboxes (macOS Seatbelt, Linux bubblewrap) with deny-by-default network egress for enclosed rigs, per-launch scoped credentials and a unified guardrail store with a per-space autonomy dial. Humans and agents are co-equal members of a workspace with roles, presence and live revocation.</p>`,
    },
    {
      id: 'open-source',
      title: 'Open source',
      html: `<p>The whole product — app, server, worker, clients and this site — is MIT-licensed and developed in the open at <a href="${REPO_URL}">github.com/SamuelAlev/control-center</a>. The <a href="/changelog">changelog</a> records what shipped and the <a href="/compare/">comparison pages</a> say plainly where Control Center pulls ahead of alternatives and where it does not.</p>
<p>The project is maintained by Samuel Alev and contributors.</p>`,
    },
    {
      id: 'next',
      title: 'Where to go next',
      html: `<ul>
<li><a href="/">The landing page</a> — the four pillars and downloads.</li>
<li><a href="/manual/">The manual</a> — tutorials, how-to guides, concepts and reference.</li>
<li><a href="/developers">Developers</a> — the MCP server, CLI and this site's machine-readable surface.</li>
<li><a href="/contact">Contact</a> — how to reach the maintainers.</li>
</ul>`,
    },
  ],
};

export const contactPage: SitePageData = {
  id: 'contact',
  eyebrow: 'Contact',
  title: 'Contact \\\\ Control Center',
  heading: 'Contact',
  description:
    'How to reach the Control Center maintainers: GitHub issues for bugs, features, privacy and security reports, and where to look before you write.',
  intro:
    'Control Center is an open-source project maintained in public on GitHub. There is one front door — the issue tracker — and it covers bugs, features, privacy requests and security reports.',
  sections: [
    {
      id: 'bugs-features',
      title: 'Bugs and feature requests',
      html: `<p>Open an issue at <a href="${ISSUES_URL}">${ISSUES_URL.replace('https://', '')}</a>. Search the tracker first — the project is young and many reports are already in flight. A good bug report names your platform (macOS, Windows or Linux), the app version (<code>cc_server --version</code> prints the build and git SHA) and what you expected versus what happened.</p>`,
    },
    {
      id: 'security',
      title: 'Security reports',
      html: `<p>If you believe you have found a security vulnerability, open an issue at <a href="${ISSUES_URL}">GitHub issues</a> and say that it is security-sensitive in the title — the maintainers will arrange a private channel before details are posted. Please do not attach exploit material to a public issue.</p>`,
    },
    {
      id: 'privacy',
      title: 'Privacy requests',
      html: `<p>Questions about what the app stores and sends are answered in the <a href="/privacy">privacy policy</a>. For requests that involve personal information you would rather not post publicly, open an issue, say so, and a private channel will be arranged — the policy's <a href="/privacy#contact">contact section</a> describes the process.</p>`,
    },
    {
      id: 'answers',
      title: 'Before you write',
      html: `<p>Most operational questions are already answered in the manual: <a href="/manual/quick-start/">quick start</a>, <a href="/manual/guides/">how-to guides</a> and the <a href="/manual/reference/">reference</a> section (routes, MCP tools, CLI flags, glossary). The <a href="/changelog">changelog</a> says what changed between versions.</p>`,
    },
  ],
};

export const developersPage: SitePageData = {
  id: 'developers',
  eyebrow: 'Developers',
  title: 'Developers \\\\ Control Center',
  heading: 'Developers',
  description:
    'Integrate with Control Center: 103 MCP tools over Streamable HTTP, the cc_server CLI and Docker images, and this site\u2019s own machine-readable surface — llms.txt, markdown twins, an OpenAPI document and a docs MCP server.',
  intro:
    'Two surfaces, one page: the Control Center product you integrate with (its MCP tool server, CLI and Docker images) and this website itself, which is built to be read by agents — llms.txt, per-page markdown, an OpenAPI document and a docs MCP server.',
  sections: [
    {
      id: 'quickstart',
      title: 'Quickstart',
      html: `<p>Run the server, then point any MCP client at it:</p>
<ul>
<li>Install the desktop app or grab the standalone <code>cc_server</code> binary from <a href="${REPO_URL}/releases">GitHub Releases</a> (<code>cc_server-&lt;version&gt;-macos-arm64.tar.gz</code>, <code>-linux-x64.tar.gz</code>, <code>-windows-x64.zip</code>), or run the Docker image <code>ghcr.io/samuelalev/cc-server</code> with <code>-p 9030:9030</code>.</li>
<li>Start it: <code>cc_server</code> (listens on <code>127.0.0.1:9030</code> by default).</li>
<li>Connect a client: the MCP endpoint is <code>http://127.0.0.1:9030/mcp</code> (Streamable HTTP).</li>
</ul>
<p>The <a href="/manual/quick-start/">quick start tutorial</a> walks the same path through the app, and <a href="/manual/guides/run-headless-server/">Run a headless server</a> covers Docker, TLS, tunnels and pairing.</p>`,
    },
    {
      id: 'mcp',
      title: 'The MCP server',
      html: `<p>Control Center registers <strong>103 typed tools</strong> and serves them over the Model Context Protocol on the main <code>cc_server</code> listener — no separate port:</p>
<ul>
<li><code>POST /mcp</code> — Streamable HTTP transport; the one clients speak.</li>
<li><code>GET /sse</code> — server-sent notification stream.</li>
<li><code>DELETE /mcp</code> — end a session.</li>
</ul>
<p>The surface is on by default and binds loopback; serving beyond the host requires a bearer token (fail-closed by design). Every workspace-scoped tool requires a <code>workspace_id</code> — there is no implicit "current workspace". <a href="/manual/guides/mcp-server/">Use the MCP server</a> has the client configuration, and <a href="/manual/reference/mcp-tools/">MCP tools</a> is the full tool catalog.</p>`,
    },
    {
      id: 'cli',
      title: 'CLI and containers',
      html: `<p><code>cc_server</code> is scriptable: every setting takes a CLI flag or an environment variable (flag wins), and subcommands cover device pairing (<code>cc_server pair</code>), Google Calendar connect and self-update (<code>cc_server update</code>). <a href="/manual/reference/cc-server-cli/">cc_server CLI</a> is the complete reference.</p>
<p>Each release publishes four GHCR images — <code>cc-server</code>, <code>cc-webapp</code>, <code>cc-remote</code> and <code>cc-signaling-server</code> — with a compose file in <a href="/manual/guides/run-headless-server/">the headless-server guide</a>.</p>`,
    },
    {
      id: 'this-site',
      title: 'This site, for agents',
      html: `<p>usectrl.dev itself is agent-readable. Every page below is live:</p>
<ul>
<li><a href="/llms.txt">llms.txt</a> — the curated site index; <a href="/llms-full.txt">llms-full.txt</a> — the whole site as one file, including when-to-use guidance.</li>
<li>Markdown twins — send <code>Accept: text/markdown</code> on any page, or append <code>.md</code> to its URL (<a href="/index.md">/index.md</a>, <code>/manual/quick-start.md</code>, …).</li>
<li><a href="/openapi.json">openapi.json</a> — an OpenAPI 3.1 description of this site's endpoints, with typed responses and operation ids.</li>
<li><a href="/.well-known/api-catalog">/.well-known/api-catalog</a> — an <a href="https://www.rfc-editor.org/rfc/rfc9727">RFC 9727</a> catalog of the APIs on this origin, each with its description and docs. Every page also carries <code>Link</code> headers for it (<code>rel="api-catalog"</code>, <code>service-desc</code>, <code>service-doc</code>, <code>describedby</code>), so nothing here needs HTML parsing to find.</li>
<li><a href="/.well-known/mcp/server-card.json">/.well-known/mcp/server-card.json</a> — the MCP server card for the docs server above: who it is, which URLs it answers on and which protocol versions it speaks.</li>
<li><a href="/.well-known/agent-skills/index.json">/.well-known/agent-skills/index.json</a> — published skills, each a <code>SKILL.md</code> with a SHA-256 digest over the exact bytes served, so you can verify what you loaded.</li>
<li><a href="/.well-known/mcp">/.well-known/mcp</a> — a Streamable HTTP MCP server (also at <a href="/mcp">/mcp</a>) exposing this site's pages as tools: <code>list_pages</code>, <code>get_page_markdown</code>, <code>search_pages</code>.</li>
<li><a href="/sitemap-index.xml">Sitemap</a>, <a href="/rss.xml">RSS</a> and structured JSON error envelopes for missed routes.</li>
</ul>`,
    },
    {
      id: 'source',
      title: 'Source code',
      html: `<p>Everything above is MIT-licensed at <a href="${REPO_URL}">github.com/SamuelAlev/control-center</a> — app, server, fleet worker, web and phone clients, signaling relay, and this site (in <code>docs/</code>). Issues and reproductions: <a href="${ISSUES_URL}">the tracker</a>.</p>`,
    },
  ],
};

export const sitePages: SitePageData[] = [aboutPage, contactPage, developersPage];
