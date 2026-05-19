import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  appendVary,
  errorEnvelope,
  markdownAssetPath,
  notFoundMarkdown,
  parseAccept,
} from '../src/agentic/negotiation.ts';

const SITE = { origin: 'https://usectrl.dev' };

describe('parseAccept', () => {
  it('treats a missing header as no preference', () => {
    assert.deepEqual(parseAccept(null), { markdown: false, json: false });
  });

  it('detects text/markdown anywhere in the list', () => {
    const pref = parseAccept('text/html,application/xhtml+xml,text/markdown;q=0.9,*/*;q=0.8');
    assert.equal(pref.markdown, true);
    assert.equal(pref.json, false);
  });

  it('detects application/json and +json types', () => {
    assert.equal(parseAccept('application/json').json, true);
    assert.equal(parseAccept('application/problem+json').json, true);
    assert.equal(parseAccept('application/ld+json').json, true);
  });

  it('honors q=0 as a refusal', () => {
    const pref = parseAccept('text/markdown;q=0, application/json;q=0.0');
    assert.deepEqual(pref, { markdown: false, json: false });
  });

  it('is case-insensitive and tolerates whitespace', () => {
    assert.equal(parseAccept('  Text/Markdown ').markdown, true);
  });

  it('does not treat text/html or wildcards as markdown', () => {
    assert.deepEqual(parseAccept('text/html,*/*'), { markdown: false, json: false });
  });
});

describe('markdownAssetPath', () => {
  it('maps the homepage to /index.md', () => {
    assert.equal(markdownAssetPath('/'), '/index.md');
    assert.equal(markdownAssetPath('/index.html'), '/index.md');
  });

  it('maps trailing-slash pages to <path>.md', () => {
    assert.equal(markdownAssetPath('/manual/quick-start/'), '/manual/quick-start.md');
    assert.equal(markdownAssetPath('/manual/quick-start'), '/manual/quick-start.md');
    assert.equal(markdownAssetPath('/compare/conductor/'), '/compare/conductor.md');
  });

  it('collapses .html spellings to the same twin', () => {
    assert.equal(markdownAssetPath('/about.html'), '/about.md');
    assert.equal(markdownAssetPath('/changelog/index.html'), '/changelog.md');
  });

  it('returns null for assets, feeds and machine files', () => {
    assert.equal(markdownAssetPath('/llms.txt'), null);
    assert.equal(markdownAssetPath('/openapi.json'), null);
    assert.equal(markdownAssetPath('/rss.xml'), null);
    assert.equal(markdownAssetPath('/manual/quick-start.md'), null);
    assert.equal(markdownAssetPath('/fonts/Manrope-Variable.woff2'), null);
    assert.equal(markdownAssetPath('/_astro/app.8f3c.js'), null);
    assert.equal(markdownAssetPath('/favicon.svg'), null);
  });
});

describe('appendVary', () => {
  it('sets Vary when absent', () => {
    const h = new Headers();
    appendVary(h, 'Accept');
    assert.equal(h.get('Vary'), 'Accept');
  });

  it('appends without clobbering existing tokens', () => {
    const h = new Headers({ Vary: 'Accept-Encoding' });
    appendVary(h, 'Accept');
    assert.equal(h.get('Vary'), 'Accept-Encoding, Accept');
  });

  it('never duplicates', () => {
    const h = new Headers({ Vary: 'accept' });
    appendVary(h, 'Accept');
    assert.equal(h.get('Vary'), 'accept');
  });
});

describe('notFoundMarkdown', () => {
  it('names the missed path and every recovery link an agent needs', () => {
    const body = notFoundMarkdown('/nope', SITE);
    assert.match(body, /^# 404/);
    assert.ok(body.includes('/nope'));
    for (const link of ['/sitemap-index.xml', '/llms.txt', '/llms-full.txt', '/manual/', '/developers', '/openapi.json', '/.well-known/mcp']) {
      assert.ok(body.includes(`https://usectrl.dev${link}`), `missing ${link}`);
    }
    assert.ok(body.includes('Accept: text/markdown'));
  });
});

describe('errorEnvelope', () => {
  it('carries code, message, resolution hint and recovery links', () => {
    const { error } = errorEnvelope(404, 'not_found', 'No route matches /x.', 'Fetch the sitemap.', SITE);
    assert.equal(error.code, 'not_found');
    assert.equal(error.status, 404);
    assert.equal(error.docs, 'https://usectrl.dev/openapi.json');
    assert.equal(error.sitemap, 'https://usectrl.dev/sitemap-index.xml');
  });
});
