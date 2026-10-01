/**
 * Assembles the markdown twin of every negotiable page on the site, at build
 * time, from the same data modules and content collection the HTML pages
 * render. Consumed by:
 *
 * - `src/pages/index.md.ts` / `src/pages/[...slug].md.ts` — the public
 *   `<page>.md` assets the worker serves for `Accept: text/markdown`,
 * - `src/pages/agentic/pages/[locale].json.ts` — each language's page index,
 *   which the docs MCP server (src/worker.ts) reads at request time,
 * - the per-language `llms.txt` / `llms-full.txt`.
 *
 * Format per page: H1, blockquoted description, body, then a footer with the
 * canonical URL and language (plus the English original of a translation) so
 * an agent always knows where the twin came from.
 */
import { getCollection } from 'astro:content';
import { releases } from '../data/changelog';
import { columns, tools, vsTools, compareSummary, compareReviewed, reviewScopeNote } from '../data/compare';
import { sitePages } from '../data/pages';
import { OVERVIEW, REPO_URL } from '../data/site';
import { landingCopy } from '../data/landing';
import { localeFromPath, siteLocales, type SiteLocale } from '../data/locales';
import { localeManualPage, localizeSitePath, type ManualRoutes } from '../data/manual-paths';
import { getManualRoutes } from '../data/manual-routes';
import { htmlToMarkdown } from './html-to-markdown';

export interface MarkdownPage {
  /** Site path, trailing slash, e.g. `/manual/quick-start/` (`/` = landing). */
  path: string;
  title: string;
  description?: string;
  markdown: string;
  /** The page's language. English-only pages (compare, changelog, …) are `en-US`. */
  locale: SiteLocale;
  /** The English page this one translates (itself for English pages); only translated pages (landing, manual) have one. */
  englishPath?: string;
}

const stripHtml = (html: string) => html.replace(/<[^>]+>/g, '');
const stripImports = (body: string) => body.replace(/^import\s[^\n]*$/gm, '').trim();

const LANDING_TITLE = landingCopy['en-US'].meta.title;
const LANDING_DESCRIPTION = landingCopy['en-US'].meta.description;

function landingMarkdown(origin: string, routes: ManualRoutes, locale: SiteLocale = 'en-US'): string {
  const t = landingCopy[locale];
  // Manual links land on this language's translated page.
  const at = (href: string) => `${origin}${localizeSitePath(href, locale, routes)}`;
  const out = [
    `# ${t.meta.title}`, '', `> ${t.meta.description}`, '',
    ...(locale === 'en-US' ? [OVERVIEW, ''] : [t.hero.description, '', t.surfaces.description, '']),
    `## ${t.grid.title}`, '', t.grid.description, '',
    ...[...t.grid.items, ...t.grid.supporting].flatMap(feature => [
      `### [${feature.title}](${at(feature.href)})`, '', feature.description, '',
    ]),
    `## ${t.boundaries.title}`, '', t.boundaries.description, '', t.boundaries.note, '',
    `## ${t.faq.title}`, '',
    ...t.faq.items.flatMap(faq => [
      `### ${faq.question}`, '', faq.answer, '',
      ...(faq.links?.map(link => `[${link.label}](${at(link.href)})`) ?? []), '',
    ]),
    `## ${t.install.title.replace('\n', ' ')}`, '', t.install.description, '',
    `- [${t.nav.download} · macOS](${origin}/download/macos)`,
    `- [${t.nav.download} · Windows](${origin}/download/windows)`,
    `- [${t.nav.download} · Linux](${origin}/download/linux)`,
    `- [${t.install.release}](${REPO_URL}/releases/latest)`,
    `- [${t.install.guide}](${at('/manual/quick-start/')})`,
    `- [${t.footer.source}](${REPO_URL})`, '',
  ];
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
    `Legend: ✓ yes, ≈ partial, — not offered. Last updated: ${compareReviewed}. Checked against each product's public site.`,
    '',
    reviewScopeNote,
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
    `Last updated: ${compareReviewed}. Checked against ${tool.name}'s public site.`,
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
    reviewScopeNote,
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
  const routes = await getManualRoutes();
  const pages: MarkdownPage[] = [
    { path: '/', title: LANDING_TITLE, description: LANDING_DESCRIPTION, markdown: landingMarkdown(origin, routes), locale: 'en-US', englishPath: '/' },
    ...siteLocales.filter(language => language.id !== 'en-US').map(language => ({
      path: language.path,
      title: landingCopy[language.id].meta.title,
      description: landingCopy[language.id].meta.description,
      markdown: landingMarkdown(origin, routes, language.id),
      locale: language.id,
      englishPath: '/',
    })),
    {
      path: '/compare/',
      title: 'Compare Control Center',
      description: 'Feature matrix against the alternatives.',
      markdown: compareIndexMarkdown(origin),
      locale: 'en-US',
    },
    { path: '/changelog/', title: 'Changelog', description: 'Release notes, newest first.', markdown: changelogMarkdown(), locale: 'en-US' },
  ];

  for (const t of vsTools) {
    const markdown = compareToolMarkdown(origin, t.id);
    if (markdown) {
      pages.push({
        path: `/compare/${t.id}/`,
        title: `Control Center vs ${t.name}`,
        description: t.verdict,
        markdown,
        locale: 'en-US',
      });
    }
  }

  for (const page of sitePages) {
    const out: string[] = [`# ${page.heading}`, '', `> ${page.description}`, '', page.intro, ''];
    for (const s of page.sections) {
      out.push(`## ${s.title}`, '', htmlToMarkdown(s.html), '');
    }
    pages.push({ path: `/${page.id}/`, title: page.heading, description: page.description, markdown: out.join('\n'), locale: 'en-US' });
  }

  const entries = (await getCollection('docs', ({ id, data }) => id !== '404' && !id.endsWith('/404') && !data.draft)).sort(
    (a, b) => a.id.localeCompare(b.id),
  );
  for (const e of entries) {
    const desc = e.data.description ? `> ${e.data.description}\n\n` : '';
    const english = localeManualPage((e.filePath ?? '').replace(/^src\/content\/docs\//, ''))?.id ?? e.id;
    pages.push({
      path: `/${e.id}/`,
      title: e.data.title,
      description: e.data.description,
      markdown: [`# ${e.data.title}`, '', desc + stripImports(e.body ?? '(empty page)'), ''].join('\n'),
      locale: localeFromPath(`/${e.id}`),
      englishPath: `/${english}/`,
    });
  }

  return pages.map((p) => ({
    ...p,
    markdown: [
      `${p.markdown.trimEnd()}`,
      '',
      '---',
      `Canonical page: ${origin}${p.path}`,
      `Language: ${p.locale}`,
      ...(p.englishPath && p.englishPath !== p.path ? [`English original: ${origin}${p.englishPath}`] : []),
      '',
    ].join('\n'),
  }));
}

/**
 * The pages a reader of [locale] can use: that language's landing page and
 * manual, plus the English-only pages (compare, changelog, …) every language
 * links to.
 */
export function pagesForLocale(pages: MarkdownPage[], locale: SiteLocale): MarkdownPage[] {
  return pages.filter(page => page.locale === locale || (page.locale === 'en-US' && !page.englishPath));
}
