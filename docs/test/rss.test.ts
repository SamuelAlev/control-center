import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { describe, it } from 'node:test';
import { buildChangelogFeed, type ChangelogFeedRelease } from '../src/agentic/changelog-feed.ts';

const RELEASES: ChangelogFeedRelease[] = [
  {
    id: 'v0-0-1-rc-1',
    version: 'v0.0.1-rc.1',
    isoDate: '2026-09-10',
    title: 'Control Center takes off',
    lead: 'The first release candidate.',
  },
  {
    id: 'v0-0-1',
    version: 'v0.0.1',
    isoDate: '2026-10-01',
    title: 'Control Center 1.0',
    lead: 'Generally available.',
  },
];

const XML = await buildChangelogFeed({ origin: 'https://usectrl.dev', releases: RELEASES }).then((r) => r.text());

describe('changelog rss feed', () => {
  it('is RSS 2.0 with one item per release', () => {
    assert.ok(XML.includes('<rss'), 'missing rss root element');
    assert.ok(XML.includes('<channel>'), 'missing channel');
    assert.equal(XML.match(/<item>/g)?.length, RELEASES.length);
    assert.ok(XML.includes('<pubDate>Thu, 10 Sep 2026'), 'pubDate missing');
  });

  it('links each item to its changelog anchor, fragment intact', () => {
    // trailingSlash must stay off: a trailing slash after the fragment
    // (`#v0-0-1-rc-1/`) matches no anchor on the changelog page.
    assert.ok(XML.includes('<link>https://usectrl.dev/changelog#v0-0-1-rc-1</link>'), 'item link broken');
    assert.ok(!XML.includes('#v0-0-1-rc-1/'), 'fragment gained a trailing slash');
  });

  it('advertises a logo as the channel image', () => {
    // RSS 2.0 <channel><image> — readers render it as the feed avatar. The
    // spec requires an ABSOLUTE url, so the asset path is resolved against
    // the site origin rather than emitted root-relative.
    assert.match(
      XML,
      /<image>\s*<url>https:\/\/usectrl\.dev\/feed-icon\.png<\/url>\s*<title>[^<]+<\/title>\s*<link>https:\/\/usectrl\.dev<\/link>\s*<\/image>/,
    );
  });

  it('points the logo url at an asset that ships', () => {
    const [, assetPath] = XML.match(/<image>\s*<url>https:\/\/usectrl\.dev(\/[^<]+)<\/url>/) ?? [];
    assert.ok(assetPath, 'image url not found in feed');
    assert.ok(existsSync(new URL(`../public${assetPath}`, import.meta.url)), `${assetPath} missing from public/`);
  });
});
