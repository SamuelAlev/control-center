// /llms.txt — the curated index for LLMs, per the llmstxt.org convention:
// H1 name, blockquote summary, then titled sections of links with one-line
// descriptions. Generated at build time from the same sources the site
// renders (docs collection, changelog, compare data), so it can never drift
// from the real navigation. The full single-file dump lives at llms-full.txt.
import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { releases } from '../data/changelog';
import { vsTools } from '../data/compare';

export const prerender = true;

const DESCRIPTION =
  'Control Center (usectrl.dev) is a free and open-source developer operations deck: dispatch AI coding agents across isolated copy-on-write Git worktrees, review and merge their pull requests, and run the surrounding operation — tickets, pipelines, meetings, calendar, memory, a code graph — in one native app. Self-hosted cc_server with desktop (macOS/Windows/Linux), web and phone clients; multiplayer for humans and agents; MIT-licensed.';

// Human-facing section order for the docs half of the index.
const SECTION_ORDER = ['basics', 'concepts', 'guides', 'tutorials', 'reference'] as const;
const SECTION_TITLES: Record<(typeof SECTION_ORDER)[number], string> = {
  basics: 'Docs — Start here',
  concepts: 'Docs — Concepts',
  guides: 'Docs — Guides',
  tutorials: 'Docs — Tutorials',
  reference: 'Docs — Reference',
};

function sectionOf(slug: string): (typeof SECTION_ORDER)[number] {
  const parts = slug.split('/');
  if (parts[0] === 'manual' && parts.length >= 3) {
    const s = parts[1];
    if ((SECTION_ORDER.slice(1) as readonly string[]).includes(s)) return s as (typeof SECTION_ORDER)[number];
  }
  return 'basics';
}

export const GET: APIRoute = async ({ site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  const href = (path: string) => `${origin}/${path.replace(/^\//, '')}`;

  const entries = (await getCollection('docs', ({ id, data }) => id !== '404' && !id.endsWith('/404') && !data.draft)).sort(
    (a, b) => a.id.localeCompare(b.id),
  );

  const latest = releases[0];

  const lines: string[] = [
    '# Control Center',
    '',
    `> ${DESCRIPTION}`,
    '',
    '## Product',
    '',
    `- [Landing page](${href('/')}): what the deck is, the four pillars, the platform under the hood, downloads.`,
    `- [Compare Control Center](${href('/compare/')}): feature matrix and starting prices against Conductor, Superset, Orca, Paperclip, Multica, OpenClaw, Hermes Agent, Goose and Cursor.`,
    `- [Changelog](${href('/changelog/')}): newest first; latest is ${latest.version} — ${latest.title} (${latest.date}).`,
    ...vsTools.map((t) => `- [Control Center vs ${t.name}](${href(`/compare/${t.id}/`)}): ${t.verdict}`),
    `- [RSS feed](${href('/rss.xml')}) and [llms-full.txt](${href('/llms-full.txt')}): this whole site as one file.`,
    '',
    '## When to use this',
    '',
    'Reach for Control Center when the job is:',
    '',
    '- Running several AI coding agents at once on one repo — each agent gets its own copy-on-write worktree, OS-native sandbox and budget, so parallel runs never trip over each other.',
    '- Reviewing and merging what agents ship — a PR review cockpit with AI reviewers (P0–P3 findings, ship/hold/block verdicts) across GitHub, GitLab and Bitbucket.',
    '- Automating the operation around agents — DAG pipelines on cron or domain events, tickets with two-way Linear sync, delegation with budget inheritance and autonomy ceilings.',
    '- Giving an agent a machine to test in — disposable desktop, browser and Android VMs (rigs) that a human can watch live and take over.',
    '- Running a shared human+agent workspace — roles, presence, long-term memory and steer/take-over/hand-back on any run.',
    '',
    'It is the wrong tool when you want a single in-editor pair-programmer (that is Cursor/Goose territory — see the compare pages) or a hosted SaaS you never operate.',
    '',
    'If you are an agent reading this: this site is the documentation, not the product. The product is the self-hosted `cc_server`; once installed it exposes 103 typed MCP tools at `http://127.0.0.1:9030/mcp` (see the MCP server guide below). To read this site, prefer markdown: send `Accept: text/markdown` on any page URL, append `.md` to the path, or call the docs MCP server.',
    '',
    '## Developer resources',
    '',
    `- [Developers portal](${href('/developers')}): quickstart, product MCP server, CLI, containers and this site's agent endpoints.`,
    `- [OpenAPI document](${href('/openapi.json')}): OpenAPI 3.1 for this site's endpoints — typed responses, unique operation ids, error envelopes.`,
    `- [API catalog](${href('/.well-known/api-catalog')}): RFC 9727 linkset naming every API on this origin and its description, docs and metadata. Every page links to it with \`rel="api-catalog"\`.`,
    `- [MCP server card](${href('/.well-known/mcp/server-card.json')}): SEP-2127 card for the docs MCP server — identity, remotes and protocol versions.`,
    `- [Agent skills index](${href('/.well-known/agent-skills/index.json')}): published SKILL.md artifacts, each with a SHA-256 digest over the exact bytes served. Fetch, hash, compare before trusting one.`,
    `- [Docs MCP server](${href('/.well-known/mcp')}): Streamable HTTP MCP over this site's content (tools: list_pages, get_page_markdown, search_pages). Also at ${href('/mcp')}.`,
    `- [MCP tools reference](${href('/manual/reference/mcp-tools/')}): the product's full 103-tool catalog.`,
    `- [cc_server CLI](${href('/manual/reference/cc-server-cli/')}): every flag, environment variable and subcommand of the headless server.`,
    `- [Source code](https://github.com/SamuelAlev/control-center): MIT-licensed monorepo (app, server, worker, clients, this site).`,
  ];

  for (const section of SECTION_ORDER) {
    const inSection = entries.filter((e) => sectionOf(e.id) === section);
    if (inSection.length === 0) continue;
    lines.push('', `## ${SECTION_TITLES[section]}`, '');
    for (const e of inSection) {
      const desc = e.data.description ? `: ${e.data.description}` : '';
      lines.push(`- [${e.data.title}](${href(`${e.id}/`)})${desc}`);
    }
  }

  lines.push('');

  return new Response(lines.join('\n'), {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
};
