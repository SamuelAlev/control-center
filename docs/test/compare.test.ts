import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { cellLabel, columns, tools, vsTools, hasVsPage, trackedUrl } from '../src/data/compare.ts';

const byId = new Map(tools.map((t) => [t.id, t]));

describe('comparison data', () => {
  it('gives every tool a value for every column', () => {
    for (const tool of tools) {
      for (const column of columns) {
        assert.ok(
          tool.cells[column.id] !== undefined,
          `${tool.name} has no value for "${column.id}"`,
        );
      }
    }
  });

  it('explains every partial cell', () => {
    // A bare ≈ tells a reader something is narrower without saying how, which
    // is the one thing a comparison table must never do. The note is also the
    // cell's screen-reader label, so a missing one is an accessibility hole
    // and not only an editorial one.
    for (const tool of tools) {
      for (const column of columns) {
        if (tool.cells[column.id] !== 'partial') continue;
        const note = tool.notes?.[column.id];
        assert.ok(
          note && note.trim().length > 20,
          `${tool.name} → "${column.label}" is partial with no explanation in notes.${column.id}`,
        );
        assert.ok(
          note!.trim().endsWith('.'),
          `${tool.name} → "${column.label}" note should be a sentence: ${note}`,
        );
      }
    }
  });

  it('does not carry notes for cells that are not partial', () => {
    for (const tool of tools) {
      for (const [columnId, note] of Object.entries(tool.notes ?? {})) {
        assert.equal(
          tool.cells[columnId],
          'partial',
          `${tool.name} explains "${columnId}" (${note}) but that cell is not partial`,
        );
      }
    }
  });

  it('labels every cell for assistive tech', () => {
    for (const tool of tools) {
      for (const column of columns) {
        const label = cellLabel(tool, column.id);
        assert.ok(label.length > 0, `${tool.name} → ${column.id} has an empty label`);
        if (tool.cells[column.id] === 'partial') {
          assert.ok(
            label.startsWith('Partial — '),
            `a partial cell must announce why: ${label}`,
          );
        }
      }
    }
  });

  it('gives every competitor the copy its vs-page renders', () => {
    for (const tool of vsTools) {
      assert.ok(tool.verdict, `${tool.name} has no verdict for /compare/${tool.id}/`);
      assert.ok(tool.ccEdge, `${tool.name} has no ccEdge for /compare/${tool.id}/`);
      assert.ok(hasVsPage(tool), `${tool.name} is in vsTools but hasVsPage() says no`);
    }
    // Control Center and the baseline are the two rows with no head-to-head,
    // so the matrix renders them as plain text rather than a dead link.
    assert.equal(hasVsPage(byId.get('control-center')!), false);
    assert.equal(hasVsPage(byId.get('terminals')!), false);
  });

  it('states a starting price for every tool', () => {
    for (const tool of tools) {
      assert.ok(tool.price?.trim(), `${tool.name} has no price`);
      assert.ok(tool.price.length < 34, `${tool.name}'s price is too long for a cell: ${tool.price}`);
    }
  });

  it('tags outbound competitor links and leaves the rest clean', () => {
    assert.match(trackedUrl(byId.get('orca')!), /utm_source=usectrl\.dev/);
    assert.equal(trackedUrl(byId.get('control-center')!), byId.get('control-center')!.url);
    assert.equal(trackedUrl(byId.get('terminals')!), byId.get('terminals')!.url);
  });

  it('keeps ids unique and url-safe', () => {
    const ids = tools.map((t) => t.id);
    assert.equal(new Set(ids).size, ids.length, 'duplicate tool id');
    for (const id of ids) assert.match(id, /^[a-z0-9-]+$/, `id is not url-safe: ${id}`);
  });
});
