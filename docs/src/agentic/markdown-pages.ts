/**
 * Assembles the markdown twin of every negotiable page on the site, at build
 * time, from the same data modules and content collection the HTML pages
 * render. Consumed by:
 *
 * - `src/pages/index.md.ts` / `src/pages/[...slug].md.ts` — the public
 *   `<page>.md` assets the worker serves for `Accept: text/markdown`,
 * - `src/agentic/mcp.ts` (via the page index) — the docs MCP server.
 *
 * Format per page: H1, blockquoted description, body, then a canonical-URL
 * footer so an agent always knows where the twin came from.
 */
import { getCollection } from 'astro:content';
import { releases } from '../data/changelog';
import { faqs } from '../data/faq';
import { columns, tools, vsTools, compareSummary, compareReviewed } from '../data/compare';
import { sitePages } from '../data/pages';
import { OVERVIEW, REPO_URL } from '../data/site';
import { htmlToMarkdown } from './html-to-markdown';

export interface MarkdownPage {
  /** Site path, trailing slash, e.g. `/manual/quick-start/` (`/` = landing). */
  path: string;
  title: string;
  description?: string;
  markdown: string;
}

const stripHtml = (html: string) => html.replace(/<[^>]+>/g, '');
const stripImports = (body: string) => body.replace(/^import\s[^\n]*$/gm, '').trim();

const LANDING_TITLE = 'Control Center — the developer operations deck';
const LANDING_DESCRIPTION =
  'Dispatch and review AI coding agents, hand them disposable VMs to test in, capture and summarize meetings and keep tickets, pipelines and your calendar on one deck. Desktop on macOS, Windows and Linux, plus web and phone.';

function landingMarkdown(origin: string): string {
  const out: string[] = [
    `# ${LANDING_TITLE}`,
    '',
    `> ${LANDING_DESCRIPTION}`,
    '',
    OVERVIEW,
    '',
    '## Frequently asked questions',
    '',
  ];
  for (const f of faqs) {
    out.push(`### ${f.question}`, '', f.answer, '');
    if (f.links?.length) {
      out.push(`See also: ${f.links.map((l) => `[${l.label}](${origin}${l.href})`).join(' · ')}`, '');
    }
  }
  out.push(
    '## Learn more',
    '',
    `- [Documentation](${origin}/manual/) — tutorials, guides, concepts and reference`,
    `- [Developers](${origin}/developers) — MCP server, CLI and this site's machine-readable surface`,
    `- [Compare](${origin}/compare/) — honest feature matrix against the alternatives`,
    `- [Changelog](${origin}/changelog) — what shipped, newest first`,
    `- [Source code](${REPO_URL}) — MIT-licensed`,
    '',
  );
  return out.join('\n');
}

function compareIndexMarkdown(origin: string): string {
  const glyph = { yes: '✓', partial: '≈', no: '—' } as const;
  const out: string[] = [
    '# Compare Control Center',
    '',
    `> Control Center compared with ${tools
      .filter((t) => t.id !== 'control-center')
      .map((t) => t.name)
      .join(', ')} — parallel agents, PR review, pipelines, meetings, self-hosting and multiplayer, side by side.`,
    '',
    compareSummary,
    '',
    `Legend: ✓ yes, ≈ partial, — not offered. Checked against each product's public site, ${compareReviewed}.`,
    '',
    `| Tool | ${columns.map((c) => c.label).join(' | ')} |`,
    `| ${columns.map(() => '---').join(' | ')} |`,
  ];
  for (const tool of tools) {
    out.push(`| ${tool.name} (${tool.kind}) | ${columns.map((c) => glyph[tool.cells[c.id]]).join(' | ')} |`);
  }
  out.push('', 'Notes on partial cells:', '');
  for (const tool of tools.filter((t) => t.footnote)) {
    out.push(`- ${tool.name}: ${tool.footnote}`);
  }
  out.push('', 'When to pick each:', '');
  for (const tool of tools) {
    out.push(`- ${tool.name} (${tool.url}): ${tool.bestFor}`);
  }
  out.push('', `Per-tool deep dives: ${vsTools.map((t) => `[vs ${t.name}](${origin}/compare/${t.id}/)`).join(' · ')}`, '');
  return out.join('\n');
}

function compareToolMarkdown(origin: string, id: string): string | null {
  const tool = tools.find((t) => t.id === id);
  if (!tool) return null;
  const glyph = { yes: '✓', partial: '≈', no: '—' } as const;
  const out: string[] = [
    `# Control Center vs ${tool.name}`,
    '',
    `> ${tool.verdict ?? tool.blurb}`,
    '',
    `## ${tool.name}`,
    '',
    `${tool.blurb}`,
    '',
    `Pick ${tool.name} if: ${tool.bestFor}`,
    '',
    '## Where Control Center pulls ahead',
    '',
    tool.ccEdge ?? '',
    '',
    '## Side by side',
    '',
    `| | ${columns.map((c) => c.label).join(' | ')} |`,
    `| ${columns.map(() => '---').join(' | ')} |`,
  ];
  const cc = tools.find((t) => t.id === 'control-center')!;
  out.push(`| Control Center | ${columns.map((c) => glyph[cc.cells[c.id]]).join(' | ')} |`);
  out.push(`| ${tool.name} | ${columns.map((c) => glyph[tool.cells[c.id]]).join(' | ')} |`);
  if (tool.footnote) out.push('', `Note: ${tool.footnote}`);
  out.push('', `Full matrix: ${origin}/compare/ · ${tool.name}'s own site: ${tool.url}`, '');
  return out.join('\n');
}

function changelogMarkdown(): string {
  const out: string[] = [
    '# Changelog',
    '',
    '> Control Center release notes and changelog: every new feature, improvement and fix, newest first.',
    '',
  ];
  for (const r of releases) {
    out.push(`## ${r.version} — ${r.date} — ${r.title}`, '', r.lead, '');
    if (r.note) out.push(`Notes: ${r.note}`, '');
    for (const group of r.changes) {
      for (const item of group.items) {
        out.push(`- [${group.type}] ${stripHtml(item)}`);
      }
    }
    out.push('');
  }
  return out.join('\n');
}

/** Every page that answers `Accept: text/markdown`, keyed by site path. */
export async function getMarkdownPages(origin: string): Promise<MarkdownPage[]> {
  const pages: MarkdownPage[] = [
    { path: '/', title: LANDING_TITLE, description: LANDING_DESCRIPTION, markdown: landingMarkdown(origin) },
    {
      path: '/compare/',
      title: 'Compare Control Center',
      description: 'Feature matrix against the alternatives.',
      markdown: compareIndexMarkdown(origin),
    },
    { path: '/changelog/', title: 'Changelog', description: 'Release notes, newest first.', markdown: changelogMarkdown() },
  ];

  for (const t of vsTools) {
    const markdown = compareToolMarkdown(origin, t.id);
    if (markdown) {
      pages.push({
        path: `/compare/${t.id}/`,
        title: `Control Center vs ${t.name}`,
        description: t.verdict,
        markdown,
      });
    }
  }

  for (const page of sitePages) {
    const out: string[] = [`# ${page.heading}`, '', `> ${page.description}`, '', page.intro, ''];
    for (const s of page.sections) {
      out.push(`## ${s.title}`, '', htmlToMarkdown(s.html), '');
    }
    pages.push({ path: `/${page.id}/`, title: page.heading, description: page.description, markdown: out.join('\n') });
  }

  const entries = (await getCollection('docs', ({ id, data }) => id !== '404' && !id.endsWith('/404') && !data.draft)).sort(
    (a, b) => a.id.localeCompare(b.id),
  );
  for (const e of entries) {
    const desc = e.data.description ? `> ${e.data.description}\n\n` : '';
    pages.push({
      path: `/${e.id}/`,
      title: e.data.title,
      description: e.data.description,
      markdown: [`# ${e.data.title}`, '', desc + stripImports(e.body ?? '(empty page)'), ''].join('\n'),
    });
  }

  return pages.map((p) => ({
    ...p,
    markdown: `${p.markdown.trimEnd()}\n\n---\nCanonical page: ${origin}${p.path}\n`,
  }));
}
