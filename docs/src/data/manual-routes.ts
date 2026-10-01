/**
 * The translated manual slugs at build time, from the content collection: each
 * locale page mirrors its English page's file and its id is its `slug`
 * frontmatter (see manual-paths.ts and scripts/manual-i18n.ts).
 */
import { getCollection } from 'astro:content';
import { localeManualPage, manualRoutesFrom, type ManualRoutes } from './manual-paths.ts';

let cached: Promise<ManualRoutes> | undefined;

/** Locale → English manual id → translated path. Built once per build; per call in dev, so slug edits show up. */
export function getManualRoutes(): Promise<ManualRoutes> {
  if (cached && import.meta.env.PROD) return cached;
  cached = getCollection('docs').then(entries =>
    manualRoutesFrom(
      entries.flatMap(entry => {
        const page = localeManualPage((entry.filePath ?? '').replace(/^src\/content\/docs\//, ''));
        return page ? [{ ...page, slug: entry.id }] : [];
      }),
    ),
  );
  return cached;
}
