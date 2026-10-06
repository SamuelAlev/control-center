import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { afterEach, beforeEach, describe, it } from 'node:test';
import { blobHash, checkManual, readManualRoutes, scaffoldManual, stampPage, type Problem } from '../scripts/manual-i18n.ts';

const english = {
  'manual/index.mdx': '---\ntitle: Manual\n---\n\nStart with [the guides](/manual/guides/).\n',
  'manual/guides/index.mdx': '---\ntitle: Guides\n---\n\nSee [Create an agent](/manual/guides/create-agent/#before-you-start).\n',
  'manual/guides/create-agent.mdx':
    '---\ntitle: Create an agent\n---\nimport Card from "../../../../components/Card.astro";\n\nBack to [the manual](/manual/).\n\n```md\n[literal](/manual/)\n```\n',
};

let root: string;
const docs = (path: string) => join(root, 'src/content/docs', path);
const write = (path: string, text: string) => {
  mkdirSync(dirname(docs(path)), { recursive: true });
  writeFileSync(docs(path), text);
};
const hashOf = (path: string) => blobHash(readFileSync(docs(path)));
const french = (path: string, slug: string, body: string, hash: string | null = hashOf(path)) =>
  write(`fr-FR/${path}`, `---\ntitle: Traduit\nslug: ${slug}\n${hash ? `sourceHash: ${hash}\n` : ''}---\n\n${body}\n`);
const check = () => checkManual({ root, locales: ['fr-FR'] });
const kinds = (problems: Problem[]) => problems.map(problem => `${problem.kind} ${problem.file}${problem.line ? `:${problem.line}` : ''}`);

function translateAll() {
  french('manual/index.mdx', 'fr-FR/manuel', 'Voir [les guides](/fr-FR/manuel/guides/).');
  french('manual/guides/index.mdx', 'fr-FR/manuel/guides', 'Voir [Créer un agent](/fr-FR/manuel/guides/creer-agent/#avant-de-commencer).');
  french('manual/guides/create-agent.mdx', 'fr-FR/manuel/guides/creer-agent', 'Retour au [manuel](/fr-FR/manuel/).');
}

beforeEach(() => {
  root = mkdtempSync(join(tmpdir(), 'manual-i18n-test-'));
  for (const [path, text] of Object.entries(english)) write(path, text);
});
afterEach(() => rmSync(root, { recursive: true, force: true }));

describe('checkManual', () => {
  it('passes a complete, current translation', () => {
    translateAll();
    assert.deepEqual(check(), []);
    assert.deepEqual(readManualRoutes(root)['fr-FR'], {
      manual: 'manuel',
      'manual/guides': 'manuel/guides',
      'manual/guides/create-agent': 'manuel/guides/creer-agent',
    });
  });

  it('reports missing, orphaned, untranslated and stale pages', () => {
    translateAll();
    rmSync(docs('fr-FR/manual/guides/create-agent.mdx'));
    write('fr-FR/manual/guides/old.mdx', '---\ntitle: Ancien\nslug: fr-FR/manuel/guides/ancien\n---\n');
    french('manual/index.mdx', 'fr-FR/manuel', 'Pas encore.', null);
    french('manual/guides/index.mdx', 'fr-FR/manuel/guides', 'Périmé.', '0'.repeat(40));
    assert.deepEqual(kinds(check()).sort(), [
      'missing src/content/docs/fr-FR/manual/guides/create-agent.mdx',
      'orphan src/content/docs/fr-FR/manual/guides/old.mdx',
      'stale src/content/docs/fr-FR/manual/guides/index.mdx',
      'untranslated src/content/docs/fr-FR/manual/index.mdx',
    ]);
  });

  it('reports a slug that is missing, misplaced or malformed', () => {
    const cases: Array<[string, string, RegExp]> = [
      ['', 'fr-FR/manuel/guides/creer-agent', /no `slug`/],
      ['de-DE/handbuch/guides/creer-agent', '', /must start with fr-FR\//],
      ['fr-FR/manuel/creer-agent', '', /has 2 segments/],
      ['fr-FR/manuel/autres/creer-agent', '', /must continue its section's slug fr-FR\/manuel\/guides\//],
      ['fr-FR/manuel/guides/Créer-agent', '', /lowercase ASCII/],
      ['fr-FR/manuel/guides/creer--agent', '', /lowercase ASCII/],
      ['fr-FR/manuel/guides', '', /has 2 segments/],
    ];
    for (const [slug, , message] of cases) {
      translateAll();
      const page = 'manual/guides/create-agent.mdx';
      const body = 'Retour au [manuel](/fr-FR/manuel/).';
      if (slug) french(page, slug, body);
      else write(`fr-FR/${page}`, `---\ntitle: Traduit\nsourceHash: ${hashOf(page)}\n---\n\n${body}\n`);
      const slugs = check().filter(problem => problem.kind === 'slugs');
      assert.ok(slugs.some(problem => message.test(problem.message)), `${slug}: ${JSON.stringify(slugs)}`);
    }
  });

  it('rejects two pages on one slug and a slug that is another page\'s English path', () => {
    write('manual/guides/other.mdx', '---\ntitle: Other\n---\n');
    french('manual/index.mdx', 'fr-FR/manual', 'Manuel.');
    french('manual/guides/index.mdx', 'fr-FR/manual/guides', 'Guides.');
    french('manual/guides/other.mdx', 'fr-FR/manual/guides/other', 'Autre.');
    french('manual/guides/create-agent.mdx', 'fr-FR/manual/guides/other', 'Créer.');
    const messages = check().filter(problem => problem.kind === 'slugs').map(problem => problem.message).join('\n');
    assert.match(messages, /same slug as manual\/guides\//);
    assert.match(messages, /English path of another page/);
  });

  it('allows non-Latin scripts in their locales and keeps them NFC', () => {
    write('ja-JP/manual/index.mdx', `---\ntitle: マニュアル\nslug: ja-JP/マニュアル\nsourceHash: ${hashOf('manual/index.mdx')}\n---\n\n[ガイド](/ja-JP/マニュアル/ガイド/)\n`);
    write('ja-JP/manual/guides/index.mdx', `---\ntitle: ガイド\nslug: ja-JP/マニュアル/ガイド\nsourceHash: ${hashOf('manual/guides/index.mdx')}\n---\n`);
    write('ja-JP/manual/guides/create-agent.mdx', `---\ntitle: 作成\nslug: ja-JP/マニュアル/ガイド/mcp-サーバー\nsourceHash: ${hashOf('manual/guides/create-agent.mdx')}\n---\n`);
    assert.deepEqual(checkManual({ root, locales: ['ja-JP'] }), []);
  });

  it('reports links to the English manual, other locales and missing pages', () => {
    translateAll();
    french(
      'manual/guides/create-agent.mdx',
      'fr-FR/manuel/guides/creer-agent',
      'Voir [EN](/manual/guides/), [DE](/de-DE/handbuch/), <a href="/fr-FR/manuel/inconnu/">x</a>, [ok](/fr-FR/manuel/guides/#x).\n\n```md\n[code](/manual/)\n```',
    );
    const links = check().filter(problem => problem.kind === 'links').map(problem => problem.message);
    assert.equal(links.length, 3, links.join('\n'));
    assert.match(links[0], /English manual/);
    assert.match(links[1], /de-DE manual/);
    assert.match(links[2], /not a fr-FR manual page/);
  });

  it('reports a link whose text lost its closing bracket', () => {
    translateAll();
    french(
      'manual/guides/create-agent.mdx',
      'fr-FR/manuel/guides/creer-agent',
      'Retour au [manuel(/fr-FR/manuel/), puis au [manuel\nentier(/fr-FR/manuel/), au [bon](/fr-FR/manuel/).\n\n```md\n[code(/fr-FR/manuel/)\n```',
    );
    const links = check().filter(problem => problem.kind === 'links');
    assert.deepEqual(
      links.map(problem => problem.line),
      [7, 8],
      links.map(problem => problem.message).join('\n'),
    );
    assert.match(links[0].message, /missing the `\]`/);
  });
});

describe('scaffoldManual', () => {
  it('copies English pages with localized links and imports, leaving the slug to translate', () => {
    french('manual/index.mdx', 'fr-FR/manuel', 'Voir [les guides](/fr-FR/manuel/guides/).');
    french('manual/guides/index.mdx', 'fr-FR/manuel/guides', 'Voir [les guides](/fr-FR/manuel/guides/).');
    const written = scaffoldManual({ root, locales: ['fr-FR'] });
    assert.deepEqual(written, [docs('fr-FR/manual/guides/create-agent.mdx')]);
    const text = readFileSync(written[0], 'utf8');
    assert.match(text, /import Card from "\.\.\/\.\.\/\.\.\/\.\.\/\.\.\/components\/Card\.astro";/);
    assert.match(text, /\[the manual\]\(\/fr-FR\/manuel\/\)/);
    assert.match(text, /\[literal\]\(\/manual\/\)/);
    assert.doesNotMatch(text, /^slug:/m);
    assert.deepEqual(kinds(check().filter(problem => problem.kind !== 'untranslated')), [
      'slugs src/content/docs/fr-FR/manual/guides/create-agent.mdx',
    ]);
  });
});

describe('stampPage', () => {
  it('records the English page\'s git blob id', () => {
    assert.equal(blobHash(Buffer.from('hello\n')), 'ce013625030ba8dba906f756967f9e9ca394464a');
    translateAll();
    french('manual/index.mdx', 'fr-FR/manuel', 'Voir [les guides](/fr-FR/manuel/guides/).', null);
    assert.deepEqual(kinds(check()), ['untranslated src/content/docs/fr-FR/manual/index.mdx']);
    stampPage(docs('fr-FR/manual/index.mdx'), root);
    assert.deepEqual(check(), []);
    stampPage(docs('fr-FR/manual/index.mdx'), root);
    assert.equal(readFileSync(docs('fr-FR/manual/index.mdx'), 'utf8').match(/^sourceHash:/gm)?.length, 1);
  });
});
