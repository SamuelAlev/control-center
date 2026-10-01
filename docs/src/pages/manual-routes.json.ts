// /manual-routes.json — every locale's translated manual slug, keyed by the
// English page id (`{ "fr-FR": { "manual/install": "manuel/installer" } }`).
// Generated at build time from the locale pages' `slug` frontmatter; the
// Worker reads it to redirect pre-translation URLs and negotiate languages
// (src/worker.ts), since it has no content collection at request time.
import type { APIRoute } from 'astro';
import { getManualRoutes } from '../data/manual-routes.ts';

export const prerender = true;

export const GET: APIRoute = async () =>
  new Response(JSON.stringify(await getManualRoutes()), {
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
  });
