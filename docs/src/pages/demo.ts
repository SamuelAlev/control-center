// /demo — the short public demo link: usectrl.dev/demo.
//
// A 302 to the web client pre-loaded with the demo connection fragment — the
// visitor lands in the furnished demo workspace with no account and no
// install. The destination is DEMO_HREF (src/data/demo.ts), the same constant
// the hero CTA and the nav button link to, so the fragment is built in
// exactly one place.
//
// An API endpoint, not an .astro page, for one concrete reason: a page lands
// in @astrojs/sitemap's output, and a redirect is a hop, not a page — as an
// endpoint it stays out of the sitemap and the search index, like the other
// non-HTML routes. Server-rendered (`prerender = false`), like /.well-known/mcp,
// because a redirect must be answered at request time — a prerendered route
// would emit an extensionless asset file instead.
//
// The status is deliberately 302, not 301: the target embeds the demo server
// endpoint, which is a build-time setting (PUBLIC_DEMO_SERVER), and a
// permanent redirect is cached by browsers and CDNs well past any change to
// it.
import type { APIRoute } from 'astro';
import { DEMO_HREF } from '../data/demo';

export const prerender = false;

export const GET: APIRoute = () => Response.redirect(DEMO_HREF, 302);
