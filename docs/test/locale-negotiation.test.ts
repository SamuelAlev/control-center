import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import type { ManualRoutes } from '../src/data/manual-paths.ts';
import { applyLocaleHeaders, negotiateLocale as negotiate, preferredLanguage, redirectManual } from '../src/locale-negotiation.ts';

const request = (path: string, headers: HeadersInit = {}, method = 'GET') =>
  new Request(`https://usectrl.dev${path}`, { headers, method });

const routes: ManualRoutes = {
  'de-DE': { manual: 'handbuch', 'manual/install': 'handbuch/installieren' },
  'fr-CA': { manual: 'manuel', 'manual/install': 'manuel/installer' },
  'fr-FR': { manual: 'manuel', 'manual/install': 'manuel/installation' },
  'ja-JP': { manual: 'マニュアル', 'manual/install': 'マニュアル/インストール' },
};
const negotiateLocale = (req: Request) => negotiate(req, routes);

describe('preferredLanguage', () => {
  it('uses English when no supported preference is available', () => {
    assert.equal(preferredLanguage(null), 'en-US');
    assert.equal(preferredLanguage('invalid_tag, xx-XX'), 'en-US');
  });

  it('orders preferences by quality, retaining header order for ties', () => {
    assert.equal(preferredLanguage('fr;q=0.5,de-DE;q=0.9'), 'de-DE');
    assert.equal(preferredLanguage('fr-CA;q=0.8,de-DE;q=0.8'), 'fr-CA');
  });

  it('matches bare languages and unsupported regions to their supported default', () => {
    assert.equal(preferredLanguage('fr-CH'), 'fr-FR');
    assert.equal(preferredLanguage('pt'), 'pt-BR');
    assert.equal(preferredLanguage('en-AU'), 'en-US');
  });

  it('preserves Chinese script and region preferences', () => {
    assert.equal(preferredLanguage('zh-Hant'), 'zh-TW');
    assert.equal(preferredLanguage('zh-Hant-HK'), 'zh-HK');
    assert.equal(preferredLanguage('zh-Hans-SG'), 'zh-CN');
  });

  it('does not let a broad range bypass a specific refusal or lower weight', () => {
    assert.equal(preferredLanguage('en-US;q=0,en;q=1'), 'en-GB');
    assert.equal(preferredLanguage('fr-FR;q=0.1,fr;q=0.8'), 'fr-CA');
    assert.equal(preferredLanguage('en;q=0,en-GB;q=0.9,fr;q=0.5'), 'en-GB');
    assert.equal(preferredLanguage('*;q=0,fr;q=0.7'), 'fr-FR');
  });

  it('ignores malformed weights and tolerates casing and whitespace', () => {
    assert.equal(preferredLanguage('fr;q=oops,de;q=0.8'), 'de-DE');
    assert.equal(preferredLanguage('fr;q=2,de;q=0.8'), 'de-DE');
    assert.equal(preferredLanguage(' FR-ca ; Q = 0.9, en;q=0.5'), 'fr-CA');
  });
});

describe('server locale negotiation', () => {
  it('redirects the first landing and deep-manual request before HTML is served', () => {
    const headers = { 'Accept-Language': 'fr-CA,fr;q=0.9,en;q=0.8' };
    assert.equal(negotiateLocale(request('/', headers))?.redirect?.headers.get('Location'), '/fr-CA/');
    const response = negotiateLocale(request('/manual/install/?download=desktop', headers))?.redirect;
    assert.equal(response?.status, 302);
    assert.equal(response.headers.get('Location'), '/fr-CA/manuel/installer/?download=desktop');
    assert.equal(response.headers.get('Cache-Control'), 'private, no-store');
    assert.equal(response.headers.get('Vary'), 'Accept, Accept-Language, Cookie');
  });

  it('puts a saved choice before the browser language', () => {
    const headers = { Cookie: 'session=opaque; cc-locale=de-DE', 'Accept-Language': 'fr-FR' };
    assert.equal(negotiateLocale(request('/manual/', headers))?.redirect?.headers.get('Location'), '/de-DE/handbuch/');
    assert.equal(negotiateLocale(request('/', { ...headers, Cookie: 'cc-locale=en-US' }))?.redirect, null);
  });

  it('ignores malformed cookies rather than building untrusted redirect targets', () => {
    const response = negotiateLocale(request('/', { Cookie: 'cc-locale=https://evil.example', 'Accept-Language': 'fr' }))?.redirect;
    assert.equal(response?.headers.get('Location'), '/fr-FR/');
  });

  it('honors explicit URLs without changing their cacheable response', () => {
    assert.equal(negotiateLocale(request(encodeURI('/ja-JP/マニュアル/インストール/'), {
      Cookie: 'cc-locale=de-DE', 'Accept-Language': 'fr',
    })), null);
  });

  it('lands on translated manual slugs, percent-encoded', () => {
    const response = negotiateLocale(request('/manual/install/', { 'Accept-Language': 'ja' }))?.redirect;
    assert.equal(response?.headers.get('Location'), encodeURI('/ja-JP/マニュアル/インストール/'));
    const choice = negotiateLocale(request(`${encodeURI('/ja-JP/マニュアル/インストール/')}?lang=ja-JP`));
    assert.equal(choice?.redirect, null);
  });

  it('serves explicit English immediately and persists it without a redirect loop', () => {
    const decision = negotiateLocale(request('/manual/install/?lang=en-US&source=footer', {
      Cookie: 'cc-locale=fr-FR', 'Accept-Language': 'fr-FR',
    }));
    assert.ok(decision);
    assert.equal(decision.redirect, null);
    const response = applyLocaleHeaders(new Response('English article'), decision);
    assert.match(response.headers.get('Set-Cookie')!, /^cc-locale=en-US; Path=\/;/);
    assert.match(response.headers.get('Set-Cookie')!, /HttpOnly; SameSite=Lax; Secure$/);
    assert.equal(response.headers.get('Cache-Control'), 'private, no-store');
  });

  it('persists a picker choice while keeping a conflicting URL authoritative', () => {
    const decision = negotiateLocale(request('/fr-FR/manuel/?lang=de-DE'));
    assert.equal(decision?.redirect, null);
    assert.match(decision?.cookie ?? '', /^cc-locale=fr-FR;/);
  });

  it('canonicalizes an English index alias without losing its explicit choice', () => {
    assert.equal(negotiateLocale(request('/index.html?lang=en-US'))?.redirect?.headers.get('Location'), '/?lang=en-US');
  });

  it('varies English root HTML as well as redirects, preserving existing headers', () => {
    const decision = negotiateLocale(request('/manual/'))!;
    const response = applyLocaleHeaders(new Response('article', { headers: { Vary: 'Accept-Encoding, Accept', 'X-Article': 'install' } }), decision);
    assert.equal(response.headers.get('Cache-Control'), 'private, no-store');
    assert.equal(response.headers.get('Vary'), 'Accept-Encoding, Accept, Accept-Language, Cookie');
    assert.equal(response.headers.get('X-Article'), 'install');
    assert.equal(response.headers.get('Set-Cookie'), null);
  });

  it('leaves unrelated pages, assets and mutating methods alone', () => {
    for (const path of ['/privacy/', '/download/server', '/api/test', '/compare.md', '/manual/logo.svg', '/openapi.json']) {
      assert.equal(negotiateLocale(request(path, { 'Accept-Language': 'fr' })), null, path);
    }
    assert.equal(negotiateLocale(request('/', {}, 'POST')), null);
  });

  it('sends agents to the translated markdown twin and llms.txt', () => {
    const french = { 'Accept-Language': 'fr-FR' };
    assert.equal(negotiateLocale(request('/manual/install.md', french))?.redirect?.headers.get('Location'), '/fr-FR/manuel/installation.md');
    assert.equal(negotiateLocale(request('/index.md', french))?.redirect?.headers.get('Location'), '/fr-FR.md');
    assert.equal(negotiateLocale(request('/llms.txt', french))?.redirect?.headers.get('Location'), '/fr-FR/llms.txt');
    assert.equal(negotiateLocale(request('/llms-full.txt', { 'Accept-Language': 'ja' }))?.redirect?.headers.get('Location'), '/ja-JP/llms-full.txt');
    assert.equal(negotiateLocale(request('/llms.txt'))?.redirect, null);
    // Explicit language URLs stay put, whatever the reader prefers.
    for (const path of ['/fr-FR.md', '/fr-FR/llms.txt', '/fr-FR/manuel/installation.md']) {
      assert.equal(negotiateLocale(request(path, { 'Accept-Language': 'de' })), null, path);
    }
  });

  it('supports HEAD and development HTTP cookies', () => {
    const response = negotiateLocale(request('/', { 'Accept-Language': 'de' }, 'HEAD'))?.redirect;
    assert.equal(response?.status, 302);
    assert.equal(response.body, null);
    const decision = negotiateLocale(new Request('http://localhost:4332/?lang=en-US'));
    assert.match(decision?.cookie ?? '', /SameSite=Lax$/);
  });
});

describe('pre-translation manual URLs', () => {
  it('move permanently to the translated slug, keeping the query', () => {
    const response = redirectManual(request('/fr-CA/manual/install/?download=desktop'), routes);
    assert.equal(response?.status, 301);
    assert.equal(response?.headers.get('Location'), '/fr-CA/manuel/installer/?download=desktop');
    assert.equal(redirectManual(request('/ja-JP/manual/install/'), routes)?.headers.get('Location'), encodeURI('/ja-JP/マニュアル/インストール/'));
  });

  it('follow another locale\'s slug to this locale\'s page', () => {
    assert.equal(redirectManual(request('/de-DE/manuel/installer/'), routes)?.headers.get('Location'), '/de-DE/handbuch/installieren/');
  });

  it('leave canonical, untranslated and non-manual URLs alone', () => {
    for (const path of ['/fr-CA/manuel/installer/', encodeURI('/ja-JP/マニュアル/'), '/manual/install/', '/fr-CA/', '/privacy/', '/it-IT/manual/install/']) {
      assert.equal(redirectManual(request(path), routes), null, path);
    }
    assert.equal(redirectManual(request('/fr-CA/manual/install/', {}, 'POST'), routes), null);
  });
});
