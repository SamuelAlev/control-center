import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  API_CATALOG_MEDIA_TYPE,
  API_CATALOG_PATH,
  appendDiscoveryLinks,
  buildApiCatalog,
  discoveryLinks,
  formatLink,
  type LinkTarget,
} from '../src/agentic/api-catalog.ts';
import { buildOpenApi } from '../src/agentic/openapi.ts';

const ORIGIN = 'https://usectrl.dev';

describe('buildApiCatalog', () => {
  const catalog = buildApiCatalog({ origin: ORIGIN });

  it('is a linkset array', () => {
    assert.ok(Array.isArray(catalog.linkset));
    assert.ok(catalog.linkset.length > 0, 'catalog must list at least one API');
  });

  it('serves the media type RFC 9727 registers, with no parameters', () => {
    // A validator may compare the Content-Type verbatim, so the profile is
    // advertised as a link relation instead of a `;profile=` parameter.
    assert.equal(API_CATALOG_MEDIA_TYPE, 'application/linkset+json');
  });

  it('is published at the well-known URI', () => {
    assert.equal(API_CATALOG_PATH, '/.well-known/api-catalog');
  });

  it('gives every entry an anchor plus service-desc and service-doc', () => {
    for (const entry of catalog.linkset) {
      assert.ok(entry.anchor, 'entry missing anchor');
      assert.ok(entry['service-desc']?.length, `${entry.anchor} missing service-desc`);
      assert.ok(entry['service-doc']?.length, `${entry.anchor} missing service-doc`);
    }
  });

  it('uses unique anchors', () => {
    const anchors = catalog.linkset.map((e) => e.anchor);
    assert.equal(new Set(anchors).size, anchors.length, 'two entries share an anchor');
  });

  it('makes every href and anchor an absolute URL on this origin', () => {
    const targets: LinkTarget[] = catalog.linkset.flatMap((entry) =>
      Object.entries(entry)
        .filter(([key]) => key !== 'anchor')
        .flatMap(([, links]) => links as LinkTarget[]),
    );
    for (const { href } of targets) {
      assert.ok(href.startsWith(`${ORIGIN}/`), `href is not absolute on the origin: ${href}`);
    }
    for (const { anchor } of catalog.linkset) {
      assert.ok(anchor.startsWith(`${ORIGIN}/`), `anchor is not absolute on the origin: ${anchor}`);
    }
  });

  it('gives every link target a media type and a title', () => {
    for (const entry of catalog.linkset) {
      for (const [rel, links] of Object.entries(entry)) {
        if (rel === 'anchor') continue;
        for (const link of links as LinkTarget[]) {
          assert.ok(link.type, `${entry.anchor} ${rel} ${link.href} missing type`);
          assert.ok(link.title, `${entry.anchor} ${rel} ${link.href} missing title`);
        }
      }
    }
  });

  it('catalogs both APIs that answer on this origin', () => {
    const anchors = catalog.linkset.map((e) => e.anchor);
    assert.deepEqual(anchors, [`${ORIGIN}/`, `${ORIGIN}/.well-known/mcp`]);
  });

  it('points every entry at a path the OpenAPI document publishes', () => {
    // The catalog and the spec are two descriptions of one site; a target the
    // spec does not publish means one of them is lying.
    const spec = buildOpenApi({
      origin: ORIGIN,
      version: 'v0.0.1-rc.1',
      compareToolIds: ['conductor'],
      docSlugs: ['manual'],
    }) as { paths: Record<string, unknown> };
    const published = new Set(Object.keys(spec.paths));
    const pathsUsed = new Set<string>();
    for (const entry of catalog.linkset) {
      pathsUsed.add(new URL(entry.anchor).pathname);
      for (const [rel, links] of Object.entries(entry)) {
        if (rel === 'anchor') continue;
        for (const link of links as LinkTarget[]) pathsUsed.add(new URL(link.href).pathname);
      }
    }
    for (const path of pathsUsed) {
      // /sitemap-index.xml and the rest are real spec paths; /manual/... is a
      // templated one and never appears as a catalog target.
      assert.ok(published.has(path), `catalog names ${path} but the OpenAPI document does not publish it`);
    }
  });
});

describe('discoveryLinks', () => {
  const links = discoveryLinks({ origin: ORIGIN });
  const byRel = new Map(links.map((l) => [l.rel, l]));

  it('advertises the four registered relations the homepage must carry', () => {
    for (const rel of ['api-catalog', 'service-desc', 'service-doc', 'describedby']) {
      assert.ok(byRel.has(rel), `missing rel=${rel}`);
    }
  });

  it('points api-catalog at the well-known URI', () => {
    assert.equal(byRel.get('api-catalog')?.href, `${ORIGIN}${API_CATALOG_PATH}`);
    assert.equal(byRel.get('api-catalog')?.type, API_CATALOG_MEDIA_TYPE);
  });

  it('emits header-safe ASCII, so Headers.append cannot throw on a page request', () => {
    // The worker stamps these on every content page: one non-ASCII character
    // would fail every request, not just spoil a header.
    for (const link of links) {
      const field = formatLink(link);
      assert.match(field, /^[\x20-\x7e]*$/, `non-ASCII in Link field value: ${field}`);
    }
  });

  it('folds typographic characters rather than emitting them', () => {
    assert.equal(
      formatLink({ rel: 'service-desc', href: 'https://e.test/x', title: 'this site’s “endpoints”' }),
      '<https://e.test/x>; rel="service-desc"; title="this site\'s \\"endpoints\\""',
    );
  });

  it('names the same service-desc and service-doc as the catalog', () => {
    // Two lists of the same facts drift unless something pins them together.
    const site = buildApiCatalog({ origin: ORIGIN }).linkset.find((e) => e.anchor === `${ORIGIN}/`);
    assert.equal(byRel.get('service-desc')?.href, site?.['service-desc'][0].href);
    assert.equal(byRel.get('service-doc')?.href, site?.['service-doc'][0].href);
  });
});

describe('formatLink', () => {
  it('serializes an RFC 8288 field value', () => {
    assert.equal(
      formatLink({ rel: 'api-catalog', href: `${ORIGIN}/.well-known/api-catalog` }),
      `<${ORIGIN}/.well-known/api-catalog>; rel="api-catalog"`,
    );
  });

  it('includes type and title when present', () => {
    assert.equal(
      formatLink({ rel: 'service-doc', href: `${ORIGIN}/developers`, type: 'text/html', title: 'Portal' }),
      `<${ORIGIN}/developers>; rel="service-doc"; type="text/html"; title="Portal"`,
    );
  });

  it('escapes quotes so a title cannot terminate the parameter', () => {
    assert.equal(
      formatLink({ rel: 'describedby', href: 'https://e.test/x', title: 'a "quoted" word' }),
      '<https://e.test/x>; rel="describedby"; title="a \\"quoted\\" word"',
    );
  });
});

describe('appendDiscoveryLinks', () => {
  it('appends one Link field per relation and keeps existing ones', () => {
    const headers = new Headers({ Link: '<https://e.test/pre>; rel="preconnect"' });
    appendDiscoveryLinks(headers, ORIGIN);
    const value = headers.get('Link') ?? '';
    assert.ok(value.includes('rel="preconnect"'), 'clobbered an existing Link header');
    for (const rel of ['api-catalog', 'service-desc', 'service-doc', 'describedby']) {
      assert.ok(value.includes(`rel="${rel}"`), `Link header missing rel=${rel}`);
    }
    assert.ok(value.includes(`<${ORIGIN}${API_CATALOG_PATH}>`), 'Link header missing the catalog URI');
  });
});
