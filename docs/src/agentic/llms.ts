/**
 * llms.txt / llms-full.txt for every site language.
 *
 * `/llms.txt` and `/llms-full.txt` are English; `/<locale>/llms.txt` and
 * `/<locale>/llms-full.txt` carry that language's landing copy, manual and
 * agent copy (src/data/agent-copy), linking its translated URLs. English-only
 * pages (compare, changelog, developers) are linked from every language and
 * marked as English. The Worker sends `/llms.txt` requests to the reader's
 * language by Accept-Language (src/locale-negotiation.ts).
 *
 * Build-time only: the endpoints in src/pages prerender these.
 */
import { getCollection } from 'astro:content';
import { agentText, type AgentCopyKey } from '../data/agent-copy';
import { releases } from '../data/changelog';
import { columns, compareReviewed, compareSummary, priceNote, reviewScopeNote, tools, vsTools } from '../data/compare';
import { faqs } from '../data/faq';
import { landingCopy } from '../data/landing';
import { landingPath, localeFromPath, siteLocales, type SiteLocale } from '../data/locales';
import { localeManualPage, localizeSitePath } from '../data/manual-paths';
import { getManualRoutes } from '../data/manual-routes';
import { OVERVIEW, REPO_URL } from '../data/site';

const DESCRIPTION =
  'Control Center (usectrl.dev) is a free and open-source developer operations deck: dispatch AI coding agents across isolated copy-on-write Git worktrees, review and merge their pull requests, and run the surrounding operation — tickets, pipelines, meetings, calendar, memory, a code graph — in one native app. Self-hosted cc_server with desktop (macOS/Windows/Linux), web and phone clients; multiplayer for humans and agents; MIT-licensed.';

// Human-facing section order for the docs half of the index.
const SECTION_ORDER = ['basics', 'concepts', 'guides', 'tutorials', 'reference'] as const;
type Section = (typeof SECTION_ORDER)[number];
const ENGLISH_SECTION_TITLES: Record<Section, string> = {
  basics: 'Docs — Start here',
  concepts: 'Docs — Concepts',
  guides: 'Docs — Guides',
  tutorials: 'Docs — Tutorials',
  reference: 'Docs — Reference',
};
const SECTION_LABEL_KEYS: Record<Section, string> = {
  basics: 'docs.sidebar.gettingStarted',
  concepts: 'docs.sidebar.concepts',
  guides: 'docs.sidebar.guides',
  tutorials: 'docs.sidebar.tutorials',
  reference: 'docs.sidebar.reference',
};

function sectionOf(englishId: string): Section {
  const parts = englishId.split('/');
  if (parts[0] === 'manual' && parts.length >= 3 && (SECTION_ORDER.slice(1) as readonly string[]).includes(parts[1])) {
    return parts[1] as Section;
  }
  return 'basics';
}

const uiFiles = import.meta.glob<Record<string, string>>('../content/i18n/*.json', { eager: true, import: 'default' });
const uiCopies = Object.fromEntries(
  Object.entries(uiFiles).map(([file, copy]) => [file.slice('../content/i18n/'.length, -'.json'.length), copy]),
);
/** A Starlight UI string (`src/content/i18n`) in [locale], English when blank. */
const ui = (locale: SiteLocale, key: string) => uiCopies[locale === 'en-US' ? 'en' : locale]?.[key] || uiCopies.en[key];

const nativeName = (locale: SiteLocale) => siteLocales.find(({ id }) => id === locale)!.name;
export const llmsPath = (locale: SiteLocale) => (locale === 'en-US' ? '/llms.txt' : `/${locale}/llms.txt`);
export const llmsFullPath = (locale: SiteLocale) => (locale === 'en-US' ? '/llms-full.txt' : `/${locale}/llms-full.txt`);

const stripHtml = (html: string) => html.replace(/<[^>]+>/g, '');
const stripImports = (body: string) => body.replace(/^import\s[^\n]*$/gm, '').trim();

interface Doc {
  /** Site path, slash-terminated, in this language. */
  path: string;
  englishId: string;
  title: string;
  description?: string;
  body?: string;
}

/** [locale]'s manual pages, sorted by English id. */
async function docsFor(locale: SiteLocale): Promise<Doc[]> {
  const entries = await getCollection(
    'docs',
    ({ id, data }) => id !== '404' && !id.endsWith('/404') && !data.draft && localeFromPath(`/${id}`) === locale,
  );
  return entries
    .map(entry => ({
      path: `/${entry.id}/`,
      englishId: localeManualPage((entry.filePath ?? '').replace(/^src\/content\/docs\//, ''))?.id ?? entry.id,
      title: entry.data.title,
      description: entry.data.description,
      body: entry.body,
    }))
    .sort((a, b) => a.englishId.localeCompare(b.englishId));
}

/** The llms.txt index of [locale]. */
export async function llmsIndex(origin: string, locale: SiteLocale): Promise<string> {
  const routes = await getManualRoutes();
  const docs = await docsFor(locale);
  const english = locale === 'en-US';
  const t = (key: AgentCopyKey, vars?: Record<string, string>) => agentText(locale, key, vars);
  const href = (path: string) => `${origin}/${path.replace(/^\//, '')}`;
  const localized = (path: string) => href(localizeSitePath(path, locale, routes));
  const inEnglish = english ? '' : ` (${t('llms.inEnglish')})`;
  const landing = landingCopy[locale];
  const titleOf = (englishId: string) => docs.find(doc => doc.englishId === englishId)?.title ?? englishId;
  const latest = releases[0];

  const lines: string[] = [
    '# Control Center',
    '',
    `> ${english ? DESCRIPTION : landing.meta.description}`,
    '',
    ...(english
      ? []
      : [t('llms.editionNote', { language: nativeName(locale), englishUrl: href('/llms.txt'), inEnglish: t('llms.inEnglish') }), '']),
    `## ${t('llms.product')}`,
    '',
    `- [${english ? 'Landing page' : landing.nav.home}](${href(landingPath(locale))}): ${t('llms.landing')}`,
    `- [${english ? 'Compare Control Center' : landing.footer.compare}](${href('/compare/')})${inEnglish}: ${t('llms.compare', {
      tools: vsTools.map(tool => tool.name).join(', '),
    })}`,
    `- [${english ? 'Changelog' : landing.footer.changelog}](${href('/changelog/')})${inEnglish}: ${t('llms.changelog', {
      version: latest.version,
      title: latest.title,
      date: latest.date,
    })}`,
    ...(english ? vsTools.map(tool => `- [Control Center vs ${tool.name}](${href(`/compare/${tool.id}/`)}): ${tool.verdict}`) : []),
    `- [${t('llms.feedLabel')}](${href('/rss.xml')})${inEnglish} and [llms-full.txt](${href(llmsFullPath(locale))}): ${t('llms.fullText')}`,
    '',
    `## ${t('llms.whenToUse')}`,
    '',
    t('llms.whenIntro'),
    '',
    ...(['llms.when1', 'llms.when2', 'llms.when3', 'llms.when4', 'llms.when5'] as const).map(key => `- ${t(key)}`),
    '',
    t('llms.wrongTool'),
    '',
    t('llms.agentNote'),
    '',
    `## ${t('llms.developerResources')}`,
    '',
    `- [Developers portal](${href('/developers')})${inEnglish}: ${t('llms.devPortal')}`,
    `- [OpenAPI document](${href('/openapi.json')}): ${t('llms.devOpenapi')}`,
    `- [API catalog](${href('/.well-known/api-catalog')}): ${t('llms.devCatalog')}`,
    `- [MCP server card](${href('/.well-known/mcp/server-card.json')}): ${t('llms.devServerCard')}`,
    `- [Agent skills index](${href('/.well-known/agent-skills/index.json')}): ${t('llms.devSkills')}`,
    `- [Docs MCP server](${href('/.well-known/mcp')}): ${t('llms.devMcp', { url: href('/mcp') })}`,
    `- [${english ? 'MCP tools reference' : titleOf('manual/reference/mcp-tools')}](${localized('/manual/reference/mcp-tools/')}): ${t('llms.devMcpTools')}`,
    `- [${english ? 'cc_server CLI' : titleOf('manual/reference/cc-server-cli')}](${localized('/manual/reference/cc-server-cli/')}): ${t('llms.devCli')}`,
    `- [${english ? 'Source code' : landing.footer.source}](${REPO_URL}): ${t('llms.devSource')}`,
  ];

  for (const section of SECTION_ORDER) {
    const inSection = docs.filter(doc => sectionOf(doc.englishId) === section);
    if (inSection.length === 0) continue;
    const title = english
      ? ENGLISH_SECTION_TITLES[section]
      : `${ui(locale, 'docs.documentation')} — ${ui(locale, SECTION_LABEL_KEYS[section])}`;
    lines.push('', `## ${title}`, '');
    for (const doc of inSection) {
      lines.push(`- [${doc.title}](${href(doc.path)})${doc.description ? `: ${doc.description}` : ''}`);
    }
  }

  lines.push('', `## ${t('llms.otherLanguages')}`, '');
  for (const language of siteLocales) {
    if (language.id !== locale) lines.push(`- [${language.name}](${href(llmsPath(language.id))}) · [llms-full.txt](${href(llmsFullPath(language.id))})`);
  }
  lines.push('');
  return lines.join('\n');
}

/** The llms-full.txt of [locale]: everything in one file. */
export async function llmsFull(origin: string, locale: SiteLocale): Promise<string> {
  const docs = await docsFor(locale);
  const english = locale === 'en-US';
  const t = (key: AgentCopyKey, vars?: Record<string, string>) => agentText(locale, key, vars);
  const href = (path: string) => `${origin}/${path.replace(/^\//, '')}`;
  const landing = landingCopy[locale];
  const out: string[] = [
    `# ${t('llmsFull.title')}`,
    '',
    `> ${english ? t('llmsFull.intro') : t('llmsFull.editionIntro', { language: nativeName(locale), englishUrl: href('/llms-full.txt') })}`,
    '',
    `## ${t('llmsFull.overview')}`,
    '',
    ...(english ? [OVERVIEW] : [landing.hero.description, '', landing.surfaces.description]),
    '',
    `## ${english ? 'Frequently asked questions' : landing.faq.title}`,
    '',
  ];
  for (const faq of english ? faqs : landing.faq.items) {
    out.push(`### ${faq.question}`, '', faq.answer, '');
  }

  if (english) {
    const glyph = { yes: '✓', partial: '≈', no: '—' } as const;
    out.push(
      '## How Control Center compares',
      '',
      compareSummary,
      '',
      `Legend: ✓ yes, ≈ partial, — not offered. Last updated: ${compareReviewed}. Checked against each product's public site.`,
      '',
      reviewScopeNote,
      '',
      priceNote,
      '',
      `| Tool | Starts at | ${columns.map(column => column.label).join(' | ')} |`,
      `| --- | --- | ${columns.map(() => '---').join(' | ')} |`,
    );
    for (const tool of tools) {
      out.push(`| ${tool.name} (${tool.kind}) | ${tool.price} | ${columns.map(column => glyph[tool.cells[column.id]]).join(' | ')} |`);
    }
    out.push('', 'Notes on partial cells:', '');
    for (const tool of tools.filter(tool => tool.footnote)) out.push(`- ${tool.name}: ${tool.footnote}`);
    out.push('', 'When to pick each:', '');
    for (const tool of tools) out.push(`- ${tool.name} (${tool.url}, starts at ${tool.price}): ${tool.bestFor}`);
    out.push('', '## Changelog', '');
    for (const release of releases) {
      out.push(`### ${release.version} — ${release.date} — ${release.title}`, '', release.lead, '', `Notes: ${release.note ?? ''}`, '');
      for (const group of release.changes) {
        for (const item of group.items) out.push(`- [${group.type}] ${stripHtml(item)}`);
      }
      out.push('');
    }
  } else {
    out.push(t('llmsFull.englishOnly', { compareUrl: href('/compare/'), changelogUrl: href('/changelog/') }), '');
  }

  out.push(`## ${english ? 'Documentation' : ui(locale, 'docs.documentation')}`, '');
  for (const doc of docs) {
    out.push(
      `### ${doc.title}`,
      '',
      `${doc.description ? `> ${doc.description}\n\n` : ''}Source: ${href(doc.path)}`,
      '',
      stripImports(doc.body ?? '(empty page)'),
      '',
    );
  }
  return out.join('\n');
}
