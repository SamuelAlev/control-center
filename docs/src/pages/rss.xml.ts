import rss from '@astrojs/rss';
import type { APIContext } from 'astro';
import { releases } from '../data/changelog';

export const prerender = true;

export function GET(context: APIContext) {
  return rss({
    title: 'Control Center — Changelog',
    description:
      "Every change to Control Center — what's new, what got sharper, and what we fixed.",
    // Falls back to the configured `site` (astro.config.mjs).
    site: context.site ?? 'https://usectrl.dev',
    items: releases.map((release) => ({
      title: `${release.version} — ${release.title}`,
      description: release.lead,
      pubDate: new Date(release.isoDate),
      link: `/changelog#${release.id}`,
    })),
  });
}
