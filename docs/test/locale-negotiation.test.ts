import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { applyLocaleHeaders, negotiateLocale, preferredLanguage } from '../src/locale-negotiation.ts';

const request = (path: string, headers: HeadersInit = {}, method = 'GET') =>
  new Request(`https://usectrl.dev${path}`, { headers, method });

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
    assert.equal(response.headers.get('Location'), '/fr-CA/manual/install/?download=desktop');
    assert.equal(response.headers.get('Cache-Control'), 'private, no-store');
    assert.equal(response.headers.get('Vary'), 'Accept, Accept-Language, Cookie');
  });

  it('puts a saved choice before the browser language', () => {
    const headers = { Cookie: 'session=opaque; cc-locale=de-DE', 'Accept-Language': 'fr-FR' };
    assert.equal(negotiateLocale(request('/manual/', headers))?.redirect?.headers.get('Location'), '/de-DE/manual/');
    assert.equal(negotiateLocale(request('/', { ...headers, Cookie: 'cc-locale=en-US' }))?.redirect, null);
  });

  it('ignores malformed cookies rather than building untrusted redirect targets', () => {
    const response = negotiateLocale(request('/', { Cookie: 'cc-locale=https://evil.example', 'Accept-Language': 'fr' }))?.redirect;
    assert.equal(response?.headers.get('Location'), '/fr-FR/');
  });

  it('honors explicit URLs without changing their cacheable response', () => {
    assert.equal(negotiateLocale(request('/ja-JP/manual/install/', {
      Cookie: 'cc-locale=de-DE', 'Accept-Language': 'fr',
    })), null);
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
    const decision = negotiateLocale(request('/fr-FR/manual/?lang=de-DE'));
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
    for (const path of ['/privacy/', '/download/server', '/api/test', '/manual/install.md', '/manual/logo.svg']) {
      assert.equal(negotiateLocale(request(path, { 'Accept-Language': 'fr' })), null, path);
    }
    assert.equal(negotiateLocale(request('/', {}, 'POST')), null);
  });

  it('supports HEAD and development HTTP cookies', () => {
    const response = negotiateLocale(request('/', { 'Accept-Language': 'de' }, 'HEAD'))?.redirect;
    assert.equal(response?.status, 302);
    assert.equal(response.body, null);
    const decision = negotiateLocale(new Request('http://localhost:4332/?lang=en-US'));
    assert.match(decision?.cookie ?? '', /SameSite=Lax$/);
  });
});
