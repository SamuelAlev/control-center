# Control Center docs

The documentation site for [Control Center](https://github.com/SamuelAlev/control-center),
published at **[usectrl.dev](https://usectrl.dev)**. Built with
[Astro](https://astro.build) + [Starlight](https://starlight.astro.build), themed
to match the marketing site and deployed to Cloudflare Pages.

## Structure

```
src/
├── content/docs/      # The manual (Markdown/MDX, organized Diátaxis-style)
│   └── manual/
│       ├── tutorials/ # Learning-oriented — guided first-time walks
│       ├── guides/    # Task-oriented — how to do a specific thing
│       ├── concepts/  # Understanding-oriented — how the system works
│       └── reference/ # Information-oriented — schemas, enums, maps
├── pages/             # Marketing + legal pages, machine endpoints (llms.txt,
│                      #   llms-full.txt, openapi.json, <page>.md twins, the MCP routes)
├── components/        # Starlight overrides + landing/legal/changelog components
├── data/              # Single source of truth (changelog, compare, faq, pages, site)
├── agentic/           # Agent-facing machinery: content negotiation, markdown twin
│                      #   assembly, the docs MCP server, the OpenAPI builder
├── layouts/           # Marketing layout
├── styles/            # Global + Starlight CSS (warm surfaces, cc_* tokens)
├── assets/            # Integration icons
└── worker.ts          # Custom Cloudflare Worker entry (wraps the adapter: markdown
                       #   negotiation, Vary: Accept, negotiated 404s, JSON errors)
astro.config.mjs       # Starlight config — sidebar, theme, fonts, Expressive Code
```

## Agent surface

The site is built to be read by agents as well as people:

- **`Accept: text/markdown`** on any page serves its markdown twin; the same
  twin is published at `<page>.md` (e.g. `/manual/quick-start.md`, `/index.md`).
  Negotiated responses carry `Vary: Accept`. The twins are prerendered from the
  same data modules and docs collection the HTML renders (`src/agentic/markdown-pages.ts`).
- **`/llms.txt`** / **`/llms-full.txt`** — the llmstxt.org index, including
  when-to-use guidance and the developer-resources map.
- **`/openapi.json`** — OpenAPI 3.1 for the site's endpoints, generated from
  the route inventory (`src/agentic/openapi.ts`).
- **`/.well-known/mcp`** (and `/mcp`) — a Streamable HTTP MCP server exposing
  the site's pages as `list_pages` / `get_page_markdown` / `search_pages`
  (`src/agentic/mcp.ts`, transport in `src/agentic/mcp-http.ts`).
- **404s negotiate**: markdown recovery map for markdown clients, a JSON error
  envelope for `Accept: application/json` and any `/api/*` path, the rendered
  HTML 404 page for browsers.

The interception lives in `src/worker.ts` (the wrangler `main`): it wraps the
Astro adapter entry, and only page routes run through it — binary assets keep
the free direct-asset path (see `run_worker_first` in `wrangler.jsonc`). When
the wrangler `main` changes, the adapter emits the deploy config at
`dist/server/wrangler.json` instead of `dist/client/wrangler.json`;
`scripts/fix-wrangler.mjs` patches whichever exists.

Tests for the negotiation, MCP, converter and OpenAPI logic are dependency-free
`node --test` units in `test/` (`pnpm test`), and run in the deploy workflow
before the build.

The documentation follows the [Diátaxis](https://diataxis.fr/) framework: four
content types kept separate so each page answers one kind of question. Diátaxis
picks the type from two axes — whether the content informs **action** or
**cognition** and whether it serves **acquisition** (study) or **application**
(work):

| If the content…   | …and serves the user's… | …then it is               |
| ----------------- | ----------------------- | ------------------------- |
| informs action    | acquisition of skill    | a tutorial                |
| informs action    | application of skill    | a how-to guide            |
| informs cognition | application of skill    | reference                 |
| informs cognition | acquisition of skill    | explanation (`concepts/`) |

In practice:

- **`tutorials/`** — a lesson that is _guaranteed to succeed_. One path, no
  choices, minimal theory. If a reader following it verbatim gets stuck, that is
  a bug in the tutorial.
- **`guides/`** — a recipe for a competent user. The title states the goal. May
  branch. No teaching.
- **`reference/`** — austere, factual, **complete**. Incompleteness is its
  characteristic failure, so reconcile against the code, don't eyeball it.
- **`concepts/`** — discursive; why it works this way. No numbered procedure.

When adding a page, place it in the folder that matches its intent and register
it in the `sidebar` array in `astro.config.mjs`.

Each of the four sections has an `index.mdx` landing page (slug `manual/guides`,
`manual/concepts`, …) that orients the reader and maps the section. Add new
pages to the relevant landing page as well as the sidebar.

## Develop

```bash
pnpm install
pnpm dev      # local server at http://localhost:4321
```

## Build & preview

```bash
pnpm build    # production build to ./dist/ (runs the wrangler fixup script)
pnpm preview  # preview the build locally
```

## Deploy

A Cloudflare Worker (adapter `@astrojs/cloudflare`, config in `wrangler.jsonc`),
deployed by **`.github/workflows/deploy-docs.yml`** on every push to `main` that
touches `docs/` — the same model as the web client, the phone client and the
design-system gallery. Cloudflare's own git auto-build is deliberately off: two
builders racing for one Worker is how a deploy ends up reflecting neither commit.

`pnpm build` is `astro build` plus `scripts/fix-wrangler.mjs`, which strips the
`SESSION` KV binding the adapter emits for a namespace this site does not have.
Deploy with `pnpm exec wrangler deploy`; wrangler redirects itself to the
generated `dist/server/wrangler.json`, which is the file that fixup patches.
`pnpm generate-types` regenerates Cloudflare env types after a binding change.

## Conventions

- **Content lives in `src/content/docs/`** — Starlight routes each file by its
  path. The landing page and changelog are authored in `src/pages/`.
- **The sidebar is hand-curated** in `astro.config.mjs` — a new page is invisible
  in the nav until you add it there.
- **Cross-links use Starlight slugs**, e.g. `/manual/concepts/agent-model/`
  (trailing slash). The source-of-truth ARB/glossary in the app repo is
  `GLOSSARY.md`; this site's `reference/glossary` is a curated subset. Note that
  `reference/glossary.mdx` keeps every definition **twice** — once in the
  `glossaryTerms` JSON-LD array and once in prose. Edit both, or they drift.
- **Every non-index page ends with a cross-link section**, pointing both _down_
  (the task that applies an idea) and _up_ (the idea behind a task). The
  headings are fixed: `## Related guides` and/or `## Related concepts` on guide
  and concept pages, `## See also` on reference pages. Tutorials instead close
  with a short `## Recap` and a `**Next:** [link]` line.
- **Claims must be checked against the code, not against other docs.** A 2026
  audit of the whole manual found several hundred defects, the large majority of
  them features documented as working that were implemented but never wired up.
  When in doubt, grep for the call site before writing that something happens.
- **The changelog is a single source of truth** in `src/data/changelog.ts`,
  consumed by both the changelog page and the RSS feed.
