// /llms-full.txt — the whole site as one plain-text file: product overview,
// landing FAQ, the comparison matrix, the full changelog and every manual
// page's body. Assembled at build time from the same data the pages render
// (data modules + the docs collection), so it always matches the site.
// Bodies are the raw MDX source with import lines stripped — Starlight
// container syntax (:::note) and component tags are left as-is; they read
// fine as text.
import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { releases } from '../data/changelog';
import { faqs } from '../data/faq';
import { columns, tools, compareSummary, compareReviewed, priceNote } from '../data/compare';
import { OVERVIEW } from '../data/site';

export const prerender = true;

const stripHtml = (html: string) => html.replace(/<[^>]+>/g, '');
const stripImports = (body: string) => body.replace(/^import\s[^\n]*$/gm, '').trim();

export const GET: APIRoute = async ({ site }) => {
  const origin = (site ?? new URL('https://usectrl.dev/')).toString().replace(/\/$/, '');
  const href = (path: string) => `${origin}/${path.replace(/^\//, '')}`;

  const entries = (await getCollection('docs', ({ id, data }) => id !== '404' && !id.endsWith('/404') && !data.draft)).sort(
    (a, b) => a.id.localeCompare(b.id),
  );

  const out: string[] = [
    '# Control Center — the complete manual',
    '',
    '> Everything on usectrl.dev in one file: product overview, FAQ, comparison, changelog and the full documentation. Generated from the same sources as the site.',
    '',
    '## Overview',
    '',
    OVERVIEW,
    '',
    '## Frequently asked questions',
    '',
  ];

  for (const f of faqs) {
    out.push(`### ${f.question}`, '', f.answer, '');
  }

  const glyph = { yes: '✓', partial: '≈', no: '—' } as const;
  out.push(
    '## How Control Center compares',
    '',
    compareSummary,
    '',
    `Legend: ✓ yes, ≈ partial, — not offered. Checked against each product's public site, ${compareReviewed}.`,
    '',
    priceNote,
    '',
    `| Tool | Starts at | ${columns.map((c) => c.label).join(' | ')} |`,
    `| --- | --- | ${columns.map(() => '---').join(' | ')} |`,
  );
  for (const tool of tools) {
    out.push(`| ${tool.name} (${tool.kind}) | ${tool.price} | ${columns.map((c) => glyph[tool.cells[c.id]]).join(' | ')} |`);
  }
  out.push('', 'Notes on partial cells:', '');
  for (const tool of tools.filter((t) => t.footnote)) {
    out.push(`- ${tool.name}: ${tool.footnote}`);
  }
  out.push('', 'When to pick each:', '');
  for (const tool of tools) {
    out.push(`- ${tool.name} (${tool.url}, starts at ${tool.price}): ${tool.bestFor}`);
  }

  out.push('', '## Changelog', '');
  for (const r of releases) {
    out.push(`### ${r.version} — ${r.date} — ${r.title}`, '', r.lead, '', `Notes: ${r.note ?? ''}`, '');
    for (const group of r.changes) {
      for (const item of group.items) {
        out.push(`- [${group.type}] ${stripHtml(item)}`);
      }
    }
    out.push('');
  }

  out.push('## Documentation', '');
  for (const e of entries) {
    const desc = e.data.description ? `> ${e.data.description}\n\n` : '';
    out.push(
      `### ${e.data.title}`,
      '',
      desc + `Source: ${href(`${e.id}/`)}`,
      '',
      stripImports(e.body ?? '(empty page)'),
      '',
    );
  }

  return new Response(out.join('\n'), {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
};
