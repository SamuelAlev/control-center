/**
 * The Control Center changelog RSS 2.0 feed, served at /rss.xml.
 *
 * Pure module — no Astro imports, inputs are passed in — so unit tests
 * assert the emitted XML without booting an Astro build (the same pattern
 * as openapi.ts / negotiation.ts). The page wrapper
 * (src/pages/rss.xml.ts) only wires in the site's origin and the release
 * data.
 */

import rss from "@astrojs/rss";

/** The subset of a changelog release the feed serializes. */
export interface ChangelogFeedRelease {
  id: string;
  version: string;
  /** ISO-8601 date, drives <pubDate>. */
  isoDate: string;
  title: string;
  lead: string;
}

export interface ChangelogFeedInputs {
  /** Absolute site origin, e.g. `https://usectrl.dev` (no trailing slash). */
  origin: string;
  releases: ChangelogFeedRelease[];
}

const FEED_TITLE = "Control Center — Changelog";
const FEED_DESCRIPTION =
  "Every change to Control Center — what's new, what got sharper and what we fixed.";

/**
 * Builds the RSS 2.0 response for the changelog. The channel advertises a
 * logo (`<channel><image>`, the brand mark at /feed-icon.png) because
 * readers render it as the feed avatar; the RSS 2.0 spec requires an
 * ABSOLUTE url, so it is resolved against the site origin rather than
 * reusing the root-relative asset path.
 */
export function buildChangelogFeed({
  origin,
  releases,
}: ChangelogFeedInputs): Response {
  return rss({
    title: FEED_TITLE,
    description: FEED_DESCRIPTION,
    site: origin,
    // Default trailingSlash would rewrite `/changelog#v0-0-1-rc-1` to
    // `…#v0-0-1-rc-1/` — a fragment that matches no anchor on the page.
    trailingSlash: false,
    items: releases.map((release) => ({
      title: `${release.version} — ${release.title}`,
      description: release.lead,
      pubDate: new Date(release.isoDate),
      link: `/changelog#${release.id}`,
    })),
    customData: `
  <image>
    <url>${origin}/feed-icon.png</url>
    <title>${FEED_TITLE}</title>
    <link>${origin}</link>
  </image>`,
  });
}
