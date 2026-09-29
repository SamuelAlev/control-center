import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { describe, it } from 'node:test';
import { FILES_ORIGIN, cdn, media } from '../src/data/cdn.ts';

function collect(value: unknown, out: string[] = []): string[] {
  if (typeof value === 'string') {
    if (value.startsWith(`${FILES_ORIGIN}/`)) out.push(value);
    return out;
  }
  if (value && typeof value === 'object') {
    for (const nested of Object.values(value)) collect(nested, out);
  }
  return out;
}

const urls = [...new Set([...collect(cdn), ...collect(media)])];

describe('files CDN assets', () => {
  it('points every published file at a content-hashed path that exists in public/', () => {
    assert.ok(urls.length > 0);
    for (const url of urls) {
      const path = new URL(url).pathname;
      assert.match(path, /\.[0-9a-f]{8}\.[a-z0-9]+$/);
      assert.ok(existsSync(new URL(`../public${path}`, import.meta.url)), `${path} missing from public/`);
    }
  });

  it('uses the same font files in brand.css', () => {
    const css = readFileSync(new URL('../src/styles/brand.css', import.meta.url), 'utf8');
    assert.ok(css.includes(cdn.fonts.manrope));
    assert.ok(css.includes(cdn.fonts.firaCode));
  });
});
