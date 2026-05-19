import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { htmlToMarkdown } from '../src/agentic/html-to-markdown.ts';

describe('htmlToMarkdown', () => {
  it('converts paragraphs, emphasis, code and links', () => {
    const md = htmlToMarkdown(
      '<p>Run <code>cc_server</code> first, <strong>then</strong> read the <a href="/manual/quick-start/">quick start</a>.</p>',
    );
    assert.equal(md, 'Run `cc_server` first, **then** read the [quick start](/manual/quick-start/).');
  });

  it('converts headings to the right level', () => {
    assert.equal(htmlToMarkdown('<h2>One</h2><h3>Two</h3>'), '## One\n\n### Two');
  });

  it('converts unordered and ordered lists', () => {
    const md = htmlToMarkdown('<ul><li>alpha</li><li>beta</li></ul><ol><li>first</li><li>second</li></ol>');
    assert.equal(md, '- alpha\n- beta\n\n1. first\n2. second');
  });

  it('keeps bold/code inside list items', () => {
    const md = htmlToMarkdown('<ul><li><strong>Agents.</strong> Run in <code>worktrees</code>.</li></ul>');
    assert.equal(md, '- **Agents.** Run in `worktrees`.');
  });

  it('fences pre blocks without collapsing newlines', () => {
    const md = htmlToMarkdown('<pre><code>pnpm install\npnpm dev</code></pre>');
    assert.equal(md, '```pnpm install\npnpm dev\n```');
  });

  it('decodes entities', () => {
    const md = htmlToMarkdown('<p>It&rsquo;s here &amp; there &mdash; 5&nbsp;MB</p>');
    assert.equal(md, 'It’s here & there — 5 MB');
  });

  it('drops href-less anchors to plain text', () => {
    assert.equal(htmlToMarkdown('<p><a>plain</a></p>'), 'plain');
  });

  it('converts tables with a header separator', () => {
    const md = htmlToMarkdown(
      '<table><thead><tr><th>Flag</th><th>Default</th></tr></thead><tbody><tr><td><code>--port</code></td><td>9030</td></tr></tbody></table>',
    );
    assert.equal(md, '| Flag | Default |\n| --- | --- |\n| `--port` | 9030 |');
  });

  it('degrades unknown tags to their text content', () => {
    assert.equal(htmlToMarkdown('<p>a <custom-widget>x</custom-widget> b</p>'), 'a x b');
  });

  it('collapses excess blank lines', () => {
    const md = htmlToMarkdown('<p>one</p><p>two</p>');
    assert.equal(md, 'one\n\ntwo');
  });
});
