import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  isTranslatedSitePath,
  localeManualPage,
  localizeSitePath,
  manualPath,
  manualRedirect,
  manualRoutesFrom,
  unlocalizeSitePath,
  type ManualRoutes,
} from '../src/data/manual-paths.ts';

const routes: ManualRoutes = manualRoutesFrom([
  { locale: 'fr-FR', id: 'manual', slug: 'fr-FR/manuel' },
  { locale: 'fr-FR', id: 'manual/guides', slug: 'fr-FR/manuel/guides' },
  { locale: 'fr-FR', id: 'manual/guides/create-agent', slug: 'fr-FR/manuel/guides/creer-agent' },
  { locale: 'ja-JP', id: 'manual', slug: 'ja-JP/マニュアル' },
  { locale: 'ja-JP', id: 'manual/guides', slug: 'ja-JP/マニュアル/ハウツーガイド' },
  { locale: 'ja-JP', id: 'manual/guides/create-agent', slug: 'ja-JP/マニュアル/ハウツーガイド/エージェント作成' },
  { locale: 'en-GB', id: 'manual', slug: 'en-GB/manual' },
  { locale: 'en-GB', id: 'manual/guides', slug: 'en-GB/manual/guides' },
  { locale: 'en-GB', id: 'manual/guides/create-agent', slug: 'en-GB/manual/guides/create-agent' },
]);

describe('manual routes', () => {
  it('reads locale copies of English pages from their file paths', () => {
    assert.deepEqual(localeManualPage('fr-FR/manual/guides/create-agent.mdx'), { locale: 'fr-FR', id: 'manual/guides/create-agent' });
    assert.deepEqual(localeManualPage('ja-JP/manual/index.mdx'), { locale: 'ja-JP', id: 'manual' });
    assert.equal(localeManualPage('manual/install.mdx'), undefined);
    assert.equal(localeManualPage('xx-XX/manual/install.mdx'), undefined);
  });

  it('keys each locale slug by English id, without the locale prefix', () => {
    assert.equal(routes['fr-FR']['manual/guides/create-agent'], 'manuel/guides/creer-agent');
    assert.deepEqual(manualRoutesFrom([{ locale: 'de-DE', id: 'manual', slug: 'fr-FR/manuel' }]), {});
  });
});

describe('localizeSitePath', () => {
  it('moves a manual page onto each locale\'s translated slug', () => {
    assert.equal(localizeSitePath('/manual/guides/create-agent/', 'fr-FR', routes), '/fr-FR/manuel/guides/creer-agent/');
    assert.equal(localizeSitePath('/fr-FR/manuel/guides/creer-agent/', 'ja-JP', routes), '/ja-JP/マニュアル/ハウツーガイド/エージェント作成/');
    assert.equal(localizeSitePath(encodeURI('/ja-JP/マニュアル/ハウツーガイド/エージェント作成/'), 'en-US', routes), '/manual/guides/create-agent/');
    assert.equal(localizeSitePath('/fr-FR/manuel/guides/creer-agent', 'en-GB', routes), '/en-GB/manual/guides/create-agent');
    assert.equal(manualPath('fr-FR', routes), '/fr-FR/manuel/');
  });

  it('keeps Starlight\'s prefixed English path for a page with no locale copy', () => {
    assert.equal(localizeSitePath('/manual/install/', 'fr-FR', routes), '/fr-FR/manual/install/');
  });

  it('handles the landing page and leaves English-only pages unchanged', () => {
    assert.equal(localizeSitePath('/fr-FR/manuel/', 'en-US', routes), '/manual/');
    assert.equal(localizeSitePath('/', 'ja-JP', routes), '/ja-JP/');
    assert.equal(localizeSitePath('/compare/', 'fr-FR', routes), '/compare/');
  });
});

describe('unlocalizeSitePath', () => {
  it('resolves translated, prefixed English and other locales\' slugs to English paths', () => {
    assert.equal(unlocalizeSitePath('/fr-FR/manuel/guides/', routes), '/manual/guides/');
    assert.equal(unlocalizeSitePath('/fr-FR/manual/guides/', routes), '/manual/guides/');
    assert.equal(unlocalizeSitePath('/ja-JP/manuel/guides/creer-agent', routes), '/manual/guides/create-agent');
    assert.equal(unlocalizeSitePath('/fr-FR/', routes), '/');
    assert.equal(unlocalizeSitePath('/manual/install/', routes), '/manual/install/');
  });

  it('marks only the landing page and the manual as translated', () => {
    assert.equal(isTranslatedSitePath(encodeURI('/ja-JP/マニュアル/'), routes), true);
    assert.equal(isTranslatedSitePath('/ja-JP/', routes), true);
    assert.equal(isTranslatedSitePath('/compare/', routes), false);
  });
});

describe('manualRedirect', () => {
  it('sends prefixed English and foreign slugs to the canonical translated URL', () => {
    assert.equal(manualRedirect('/fr-FR/manual/guides/create-agent/', routes), '/fr-FR/manuel/guides/creer-agent/');
    assert.equal(manualRedirect('/ja-JP/manuel/guides', routes), '/ja-JP/マニュアル/ハウツーガイド');
  });

  it('serves canonical URLs, including slugs that match English', () => {
    assert.equal(manualRedirect('/fr-FR/manuel/guides/creer-agent/', routes), null);
    assert.equal(manualRedirect('/en-GB/manual/guides/create-agent/', routes), null);
    assert.equal(manualRedirect(encodeURI('/ja-JP/マニュアル/'), routes), null);
    assert.equal(manualRedirect('/manual/guides/', routes), null);
    assert.equal(manualRedirect('/fr-FR/manual/install/', routes), null);
  });
});
