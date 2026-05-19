import type { APIContext } from "astro";
import { buildChangelogFeed } from "../agentic/changelog-feed";
import { releases } from "../data/changelog";

export const prerender = true;

export function GET(context: APIContext) {
  // Falls back to the configured `site` (astro.config.mjs).
  const origin = (context.site ?? new URL("https://usectrl.dev")).origin;
  return buildChangelogFeed({ origin, releases });
}
