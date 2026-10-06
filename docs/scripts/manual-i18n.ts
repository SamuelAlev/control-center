/**
 * Guard and tooling for the translated manual.
 *
 * The English manual (`src/content/docs/manual/**`) is the source. Every other
 * site locale mirrors it file for file under `src/content/docs/<locale>/manual/**`
 * (same file names) and gives each page its translated URL as the `slug`
 * frontmatter (`slug: fr-FR/manuel/guides/creer-agent`). A locale page records
 * the English revision it was translated from as `sourceHash` — the git blob id
 * of the English file — so an English edit turns its translations stale.
 *
 * It also guards the agent copy (`src/data/agent-copy/<locale>.json`, the prose
 * of each language's llms.txt): every key of `en-US.json`, translated, with the
 * same `{placeholders}` and code spans.
 *
 * `astro build` fails on any problem below; `astro dev` warns.
 *
 *   pnpm i18n check [--locale <id>]   list every problem, exit 1 if any
 *   pnpm i18n status                  per-locale counts
 *   pnpm i18n scaffold                add missing locale pages (English text, no slug yet)
 *   pnpm i18n diff <locale file>      English changes since the page was translated
 *   pnpm i18n stamp <locale file>…    record the current English revision after translating
 */
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { AstroIntegration } from 'astro';
import { siteLocales } from '../src/data/locales.ts';
import {
  isManualId,
  manualRoutesFrom,
  translateManualId,
  translatedLocales,
  type ManualRoutes,
  type TranslatedLocale,
} from '../src/data/manual-paths.ts';

const defaultRoot = fileURLToPath(new URL('../', import.meta.url));

/** Locales whose slugs are ASCII; every other locale keeps its own script. */
const asciiSlugLocales = new Set<string>([
  'cs-CZ', 'de-DE', 'en-GB', 'es-ES', 'es-MX', 'fr-CA', 'fr-FR', 'hu-HU', 'id-ID', 'it-IT',
  'ms-MY', 'nb-NO', 'nl-NL', 'pl-PL', 'pt-BR', 'pt-PT', 'ro-RO', 'sv-SE', 'tr-TR', 'vi-VN',
]);
const asciiSegment = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const scriptSegment = /^[\p{Ll}\p{Lm}\p{Lo}\p{M}\p{Nd}]+(?:-[\p{Ll}\p{Lm}\p{Lo}\p{M}\p{Nd}]+)*$/u;
const maxSegmentLength = 64;

export type ProblemKind = 'slugs' | 'missing' | 'orphan' | 'untranslated' | 'stale' | 'links' | 'copy';

export interface Problem {
  kind: ProblemKind;
  locale: string;
  /** Path relative to the docs root. */
  file: string;
  line?: number;
  message: string;
}

export interface CheckOptions {
  /** The docs package directory (holding `src/content/docs`). */
  root?: string;
  locales?: readonly string[];
}

interface LocalePage {
  id: string;
  file: string;
  text: string;
  slug?: string;
  sourceHash?: string;
}

interface ManualTree {
  /** English id → absolute file. */
  english: Map<string, string>;
  /** Locale → English id → its copy. */
  localized: Map<string, Map<string, LocalePage>>;
}

const contentDir = (root: string) => join(root, 'src', 'content', 'docs');

function markdownFiles(dir: string): string[] {
  if (!existsSync(dir)) return [];
  return readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return markdownFiles(path);
    return /\.mdx?$/.test(entry.name) ? [path] : [];
  });
}

/** `manual/guides/create-agent.mdx` → `manual/guides/create-agent`; `manual/index.mdx` → `manual`. */
function idOf(relativePath: string): string {
  return relativePath.split(sep).join('/').replace(/\.mdx?$/, '').replace(/\/index$/, '');
}

function frontmatter(text: string): string {
  return /^---\r?\n([\s\S]*?)\r?\n---/.exec(text)?.[1] ?? '';
}

function field(text: string, name: string): string | undefined {
  const value = new RegExp(`^${name}:[ \\t]*(.*)$`, 'm').exec(frontmatter(text))?.[1]?.trim();
  return value ? value.replace(/^(['"])(.*)\1$/, '$2') : undefined;
}

export const sourceHashOf = (text: string) => {
  const hash = field(text, 'sourceHash');
  return hash && /^[0-9a-f]{40}$/.test(hash) ? hash : undefined;
};

function readTree(root: string, locales: readonly string[]): ManualTree {
  const docs = contentDir(root);
  const english = new Map(markdownFiles(join(docs, 'manual')).map(file => [idOf(relative(docs, file)), file]));
  const localized = new Map<string, Map<string, LocalePage>>();
  for (const locale of locales) {
    const base = join(docs, locale);
    const pages = new Map<string, LocalePage>();
    for (const file of markdownFiles(join(base, 'manual'))) {
      const text = readFileSync(file, 'utf8');
      const id = idOf(relative(base, file));
      pages.set(id, { id, file, text, slug: field(text, 'slug')?.normalize('NFC'), sourceHash: sourceHashOf(text) });
    }
    localized.set(locale, pages);
  }
  return { english, localized };
}

function routesOf(tree: ManualTree): ManualRoutes {
  return manualRoutesFrom([...tree.localized].flatMap(([locale, pages]) =>
    [...pages.values()].flatMap(page => (page.slug ? [{ locale, id: page.id, slug: page.slug }] : [])),
  ));
}

/** Locale → English manual id → translated path, read from the locale pages' `slug` frontmatter. */
export function readManualRoutes(root = defaultRoot): ManualRoutes {
  return routesOf(readTree(root, translatedLocales));
}

/** The git blob id of [bytes] — what `git hash-object` prints for the file. */
export function blobHash(bytes: Buffer): string {
  return createHash('sha1').update(`blob ${bytes.length}\0`).update(bytes).digest('hex');
}

/** Maps every line of [text] outside fenced code through [map] (1-based line numbers). */
function mapProseLines(text: string, map: (source: string, line: number) => string): string {
  let fence: string | undefined;
  return text
    .split('\n')
    .map((source, index) => {
      const marker = /^\s*(`{3,}|~{3,})/.exec(source)?.[1];
      if (marker && (!fence || marker[0] === fence[0])) {
        fence = fence ? undefined : marker;
        return source;
      }
      return fence ? source : map(source, index + 1);
    })
    .join('\n');
}

/**
 * Calls [visit] with every root-relative link target (`](/x)`, `href="/x"`)
 * outside fenced code, replacing it with the result when one is returned.
 */
export function mapRootLinks(text: string, visit: (path: string, line: number) => string | undefined): string {
  return mapProseLines(text, (source, line) => {
    const replace = (_: string, lead: string, path: string) => lead + (visit(path, line) ?? path);
    return source
      .replace(/(\]\()(\/[^)\s#?"]*)/g, replace)
      .replace(/(\bhref=["'])(\/[^"'\s#?]*)/g, replace);
  });
}

/**
 * Lines outside fenced code with a link whose text lost its closing bracket
 * (`[text(/x)`, the text possibly wrapped over several lines). Markdown
 * renders that as literal text, and [mapRootLinks] never sees the target, so
 * the link checks would pass it silently.
 */
export function unclosedLinkLines(text: string): number[] {
  // Fenced code blanked, so offsets still map to line numbers.
  const prose = new Set<number>();
  mapProseLines(text, (source, line) => (prose.add(line), source));
  const visible = text.split('\n').map((source, index) => (prose.has(index + 1) ? source : '')).join('\n');
  const lines: number[] = [];
  for (const match of visible.matchAll(/\((\/[^)\s]*)\)/g)) {
    const at = match.index;
    if (visible[at - 1] === ']') continue;
    const before = visible.slice(0, at);
    const open = before.lastIndexOf('[');
    if (open > before.lastIndexOf(']') && open > before.lastIndexOf('\n\n')) {
      lines.push(before.split('\n').length);
    }
  }
  return lines;
}

const trimSlashes = (path: string) => path.replace(/^\/+|\/+$/g, '');

function decodePath(path: string): string {
  try {
    return decodeURI(path).normalize('NFC');
  } catch {
    return path;
  }
}

/**
 * The locale copy of an English page's text: manual links point at [locale]'s
 * translated URLs where [routes] has them, and relative imports still resolve.
 */
export function localizePage(text: string, locale: TranslatedLocale, englishFile: string, localizedFile: string, routes: ManualRoutes): string {
  const linked = mapRootLinks(text, path => {
    const id = trimSlashes(path);
    if (!isManualId(id)) return undefined;
    const translated = translateManualId(id, locale, routes);
    return translated ? `/${locale}/${translated}${path.endsWith('/') ? '/' : ''}` : undefined;
  });
  return linked.replace(/^(\s*import\s+(?:[^'"]*?\s+from\s+)?['"])(\.{1,2}\/[^'"]+)(['"])/gm, (_, lead: string, specifier: string, quote: string) => {
    const target = resolve(dirname(englishFile), specifier);
    const moved = relative(dirname(localizedFile), target).split(sep).join('/');
    return lead + (moved.startsWith('.') ? moved : `./${moved}`) + quote;
  });
}

function slugProblems(locale: string, pages: Map<string, LocalePage>, englishIds: Set<string>, relativeTo: (file: string) => string): Problem[] {
  const problems: Problem[] = [];
  const pattern = asciiSlugLocales.has(locale) ? asciiSegment : scriptSegment;
  const owners = new Map<string, string>();
  for (const page of pages.values()) {
    if (!englishIds.has(page.id)) continue;
    const add = (message: string) => problems.push({ kind: 'slugs', locale, file: relativeTo(page.file), message });
    if (!page.slug) {
      add(`no \`slug\`: give the page its ${locale} URL (\`slug: ${locale}/…\`)`);
      continue;
    }
    if (!page.slug.startsWith(`${locale}/`)) {
      add(`\`slug: ${page.slug}\` must start with ${locale}/`);
      continue;
    }
    const segments = page.slug.slice(locale.length + 1).split('/');
    const englishSegments = page.id.split('/');
    if (segments.length !== englishSegments.length) {
      add(`\`slug: ${page.slug}\` has ${segments.length} segments; ${page.id} has ${englishSegments.length}`);
      continue;
    }
    const bad = segments.find(segment => segment.length > maxSegmentLength || !pattern.test(segment));
    if (bad !== undefined) {
      add(asciiSlugLocales.has(locale)
        ? `"${bad}" must be lowercase ASCII words joined by single hyphens (at most ${maxSegmentLength} characters)`
        : `"${bad}" must be lowercase letters or digits joined by single hyphens (at most ${maxSegmentLength} characters)`);
      continue;
    }
    // A page sits in its section: its slug extends its parent page's slug.
    const parent = pages.get(englishSegments.slice(0, -1).join('/'));
    if (englishSegments.length > 1 && parent?.slug && page.slug.slice(0, page.slug.lastIndexOf('/')) !== parent.slug) {
      add(`\`slug: ${page.slug}\` must continue its section's slug ${parent.slug}/`);
    }
    const path = segments.join('/');
    const owner = owners.get(path);
    if (owner) add(`same slug as ${owner}`);
    else owners.set(path, page.id);
    // Starlight pairs a translation with its English page by path: a slug equal
    // to a different English page's path would hide that page's translation.
    if (path !== page.id && englishIds.has(path)) add(`\`slug: ${page.slug}\` is the English path of another page`);
  }
  return problems;
}

function linkProblems(locale: string, page: LocalePage, file: string, routes: ManualRoutes): Problem[] {
  const problems: Problem[] = [];
  const valid = new Set(Object.values(routes[locale] ?? {}));
  const prefixes = siteLocales.map(({ id }) => id);
  mapRootLinks(page.text, (path, line) => {
    const decoded = decodePath(path);
    const prefix = decoded.split('/')[1] ?? '';
    const add = (message: string) => problems.push({ kind: 'links', locale, file, line, message });
    if (isManualId(trimSlashes(decoded))) {
      add(`links to the English manual (${path}); use the ${locale} URL`);
    } else if (prefix !== locale && prefixes.includes(prefix as (typeof prefixes)[number])) {
      add(`links into the ${prefix} manual (${path})`);
    } else if (prefix === locale) {
      const inner = trimSlashes(decoded.slice(locale.length + 1));
      if (inner && !valid.has(inner)) add(`links to ${path}, which is not a ${locale} manual page`);
    }
    return undefined;
  });
  for (const line of unclosedLinkLines(page.text)) {
    problems.push({ kind: 'links', locale, file, line, message: 'has a link missing the `]` after its text' });
  }
  return problems;
}

const placeholders = (text: string) => (text.match(/\{[a-zA-Z]+\}/g) ?? []).sort().join(' ');
const codeSpans = (text: string) => (text.match(/`[^`]*`/g) ?? []).sort().join(' ');

/** Problems with each language's agent copy against `en-US.json`; none when the site has no agent copy. */
function agentCopyProblems(root: string, locales: readonly string[]): Problem[] {
  const dir = join(root, 'src', 'data', 'agent-copy');
  const source = join(dir, 'en-US.json');
  if (!existsSync(source)) return [];
  const english = JSON.parse(readFileSync(source, 'utf8')) as Record<string, string>;
  const problems: Problem[] = [];
  for (const locale of locales) {
    const file = `src/data/agent-copy/${locale}.json`;
    const add = (message: string) => problems.push({ kind: 'copy', locale, file, message });
    if (!existsSync(join(root, file))) {
      add(`no agent copy: translate src/data/agent-copy/en-US.json into ${locale}`);
      continue;
    }
    let copy: Record<string, unknown>;
    try {
      copy = JSON.parse(readFileSync(join(root, file), 'utf8'));
    } catch (error) {
      add(`not valid JSON (${(error as Error).message})`);
      continue;
    }
    for (const [key, text] of Object.entries(english)) {
      const translated = copy[key];
      if (typeof translated !== 'string' || translated.trim() === '') add(`"${key}" is not translated`);
      else if (placeholders(translated) !== placeholders(text)) add(`"${key}" must keep the placeholders ${placeholders(text) || '(none)'}`);
      else if (codeSpans(translated) !== codeSpans(text)) add(`"${key}" must keep its code spans verbatim: ${codeSpans(text)}`);
    }
    for (const key of Object.keys(copy)) {
      if (!(key in english)) add(`"${key}" is not in en-US.json`);
    }
  }
  return problems;
}

/** Every problem with the translated manual; empty when it is complete and current. */
export function checkManual(options: CheckOptions = {}): Problem[] {
  const root = options.root ?? defaultRoot;
  const locales = options.locales ?? translatedLocales;
  const tree = readTree(root, locales);
  const routes = routesOf(tree);
  const englishIds = new Set(tree.english.keys());
  const englishHashes = new Map([...tree.english].map(([id, file]) => [id, blobHash(readFileSync(file))]));
  const docs = contentDir(root);
  const relativeTo = (file: string) => relative(root, file).split(sep).join('/');
  const problems: Problem[] = agentCopyProblems(root, locales);
  for (const locale of locales) {
    const pages = tree.localized.get(locale)!;
    for (const [id, englishFile] of tree.english) {
      if (!pages.has(id)) {
        const file = relativeTo(join(docs, locale, relative(docs, englishFile)));
        problems.push({ kind: 'missing', locale, file, message: `no ${locale} copy of ${id} (\`pnpm i18n scaffold\`)` });
      }
    }
    problems.push(...slugProblems(locale, pages, englishIds, relativeTo));
    for (const page of pages.values()) {
      const file = relativeTo(page.file);
      if (!englishIds.has(page.id)) {
        problems.push({ kind: 'orphan', locale, file, message: `${page.id} has no English page; delete it or move it with its source` });
        continue;
      }
      if (!page.sourceHash) problems.push({ kind: 'untranslated', locale, file, message: 'not translated yet (no sourceHash)' });
      else if (page.sourceHash !== englishHashes.get(page.id)) {
        problems.push({ kind: 'stale', locale, file, message: `the English page changed since this translation (\`pnpm i18n diff ${file}\`)` });
      }
      problems.push(...linkProblems(locale, page, file, routes));
    }
  }
  return problems;
}

const kindLabels: Record<ProblemKind, string> = {
  slugs: 'slug problems',
  missing: 'missing pages',
  orphan: 'orphaned pages',
  untranslated: 'untranslated pages',
  stale: 'stale translations',
  links: 'bad links',
  copy: 'agent copy problems',
};

const describe = (problem: Problem) => `${problem.file}${problem.line ? `:${problem.line}` : ''}: ${problem.message}`;

/** A report of [problems]: counts per kind, then up to [limit] entries. */
export function formatProblems(problems: Problem[], limit = 25): string {
  const counts = new Map<ProblemKind, number>();
  for (const problem of problems) counts.set(problem.kind, (counts.get(problem.kind) ?? 0) + 1);
  const locales = new Set(problems.map(problem => problem.locale));
  const lines = [
    `The translated manual is out of date in ${locales.size} locale${locales.size === 1 ? '' : 's'}: ` +
      [...counts].map(([kind, count]) => `${count} ${kindLabels[kind]}`).join(', ') + '.',
    ...problems.slice(0, limit).map(problem => `  ${describe(problem)}`),
  ];
  if (problems.length > limit) lines.push(`  … and ${problems.length - limit} more. Run \`pnpm i18n check\` for the full list.`);
  lines.push('Translate with the translate-manual skill (.agents/skills/translate-manual/SKILL.md).');
  return lines.join('\n');
}

/** Fails `astro build` on any manual translation problem; `astro dev` warns. */
export function manualTranslations(options: CheckOptions = {}): AstroIntegration {
  return {
    name: 'cc-manual-translations',
    hooks: {
      'astro:config:setup': ({ command, logger }) => {
        const problems = checkManual(options);
        if (problems.length === 0) return;
        const report = formatProblems(problems);
        if (command === 'build') throw new Error(report);
        logger.warn(report);
      },
    },
  };
}

/**
 * Creates every missing locale page from its English source: English text,
 * links to already-translated pages localized, and no `slug` — the check flags
 * it until the page gets its translated URL.
 */
export function scaffoldManual(options: CheckOptions = {}): string[] {
  const root = options.root ?? defaultRoot;
  const locales = options.locales ?? translatedLocales;
  const tree = readTree(root, locales);
  const routes = routesOf(tree);
  const docs = contentDir(root);
  const written: string[] = [];
  for (const locale of locales) {
    const pages = tree.localized.get(locale)!;
    for (const [id, englishFile] of tree.english) {
      if (pages.has(id)) continue;
      const target = join(docs, locale, relative(docs, englishFile));
      mkdirSync(dirname(target), { recursive: true });
      writeFileSync(target, localizePage(readFileSync(englishFile, 'utf8'), locale as TranslatedLocale, englishFile, target, routes));
      written.push(target);
    }
  }
  return written;
}

/** The English file a locale page translates. */
function englishFileFor(localizedFile: string, root: string): string {
  const docs = contentDir(root);
  const parts = relative(docs, resolve(localizedFile)).split(sep);
  if (parts.length < 3 || !translatedLocales.includes(parts[0] as TranslatedLocale) || parts[1] !== 'manual') {
    throw new Error(`${localizedFile} is not a locale manual page (src/content/docs/<locale>/manual/…)`);
  }
  return join(docs, ...parts.slice(1));
}

/** Records the current English revision as the page's `sourceHash`. */
export function stampPage(localizedFile: string, root = defaultRoot): void {
  const hash = blobHash(readFileSync(englishFileFor(localizedFile, root)));
  const text = readFileSync(localizedFile, 'utf8');
  const match = /^---\r?\n([\s\S]*?)(\r?\n)---/.exec(text);
  if (!match) throw new Error(`${localizedFile} has no frontmatter`);
  const body = /^sourceHash:.*$/m.test(match[1])
    ? match[1].replace(/^sourceHash:.*$/m, `sourceHash: ${hash}`)
    : `${match[1]}${match[2]}sourceHash: ${hash}`;
  writeFileSync(localizedFile, `---\n${body}${match[2]}---${text.slice(match[0].length)}`);
}

/** The unified diff of the English page since [localizedFile] was translated. */
export function englishDiff(localizedFile: string, root = defaultRoot): string {
  const english = englishFileFor(localizedFile, root);
  const hash = sourceHashOf(readFileSync(localizedFile, 'utf8'));
  if (!hash) return `${localizedFile} was never translated: translate all of ${relative(root, english)}.`;
  if (hash === blobHash(readFileSync(english))) return 'Up to date: the English page has not changed since this translation.';
  let previous: string;
  try {
    previous = execFileSync('git', ['cat-file', '-p', hash], { cwd: root, encoding: 'utf8' });
  } catch {
    return `English revision ${hash} is not in git. Compare by hand with \`git log -p -- ${relative(root, english)}\`.`;
  }
  const scratch = mkdtempSync(join(tmpdir(), 'manual-i18n-'));
  try {
    const before = join(scratch, 'translated-from.mdx');
    writeFileSync(before, previous);
    try {
      return execFileSync('git', ['diff', '--no-index', '--no-color', before, english], { encoding: 'utf8' });
    } catch (error) {
      // `git diff --no-index` exits 1 when the files differ.
      const { status, stdout } = error as { status?: number; stdout?: string };
      if (status === 1 && stdout) return stdout;
      throw error;
    }
  } finally {
    rmSync(scratch, { recursive: true, force: true });
  }
}

function status(root: string): string {
  const problems = checkManual({ root });
  const rows = translatedLocales.map(locale => {
    const mine = problems.filter(problem => problem.locale === locale);
    const count = (...kinds: ProblemKind[]) => mine.filter(problem => kinds.includes(problem.kind)).length;
    return [locale, count('untranslated'), count('stale'), count('missing'), count('slugs'), count('links', 'orphan'), count('copy')];
  });
  const header = ['locale', 'untranslated', 'stale', 'missing', 'slugs', 'links/orphans', 'agent copy'];
  return [header, ...rows].map(row => row.map(cell => String(cell).padEnd(14)).join('')).join('\n');
}

function main(args: string[]): number {
  const [command, ...rest] = args;
  const root = defaultRoot;
  switch (command) {
    case 'check': {
      const localeFlag = rest.indexOf('--locale');
      const locales = localeFlag === -1 ? undefined : [rest[localeFlag + 1]];
      const problems = checkManual({ root, locales });
      if (problems.length === 0) {
        console.log('The translated manual is complete and current.');
        return 0;
      }
      console.error(formatProblems(problems, Infinity));
      return 1;
    }
    case 'status':
      console.log(status(root));
      return 0;
    case 'scaffold': {
      const written = scaffoldManual({ root });
      console.log(`Created ${written.length} locale page${written.length === 1 ? '' : 's'}. Give each a translated \`slug\`.`);
      return 0;
    }
    case 'diff':
      if (rest.length !== 1) break;
      console.log(englishDiff(rest[0], root));
      return 0;
    case 'stamp':
      if (rest.length === 0) break;
      for (const file of rest) stampPage(file, root);
      console.log(`Stamped ${rest.length} page${rest.length === 1 ? '' : 's'}.`);
      return 0;
  }
  console.error('Usage: pnpm i18n check [--locale <id>] | status | scaffold | diff <file> | stamp <file>…');
  return 2;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  process.exitCode = main(process.argv.slice(2));
}
