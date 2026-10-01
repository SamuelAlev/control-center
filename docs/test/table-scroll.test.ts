import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { tableScroll, tableScrollPlugin } from '../src/table-scroll.ts';

type Visitor = { filter: string[]; visit: (node: unknown, ctx: unknown) => void };

describe('tableScrollPlugin', () => {
  it('wraps every table in a scroll frame', () => {
    const plugin = tableScrollPlugin();
    const visitors = plugin.element as unknown as Visitor[];
    assert.deepEqual(visitors.map(visitor => visitor.filter), [['table']]);

    const wrapped: { node: unknown; parent: unknown }[] = [];
    const table = { type: 'element', tagName: 'table', properties: {}, children: [] };
    visitors[0].visit(table, { wrapNode: (node: unknown, parent: unknown) => wrapped.push({ node, parent }) });
    assert.deepEqual(wrapped, [
      { node: table, parent: { type: 'element', tagName: 'div', properties: { className: ['table-scroll'] }, children: [] } },
    ]);
  });
});

describe('tableScroll', () => {
  const setup = (processor: { name: string; options: { hastPlugins?: unknown[] } }) => {
    const warnings: string[] = [];
    const hook = tableScroll().hooks['astro:config:setup'] as (options: unknown) => void;
    hook({ config: { markdown: { processor } }, logger: { warn: (message: string) => warnings.push(message) } });
    return warnings;
  };

  it("adds the plugin to Astro's Sätteri processor", () => {
    const processor = { name: 'satteri', options: { hastPlugins: [] as unknown[] } };
    assert.deepEqual(setup(processor), []);
    assert.equal((processor.options.hastPlugins[0] as { name: string }).name, 'table-scroll');
  });

  it('warns rather than failing under another processor', () => {
    assert.equal(setup({ name: 'unified', options: {} }).length, 1);
  });
});
