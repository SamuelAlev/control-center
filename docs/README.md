# Control Center docs

The documentation site for [Control Center](https://github.com/SamuelAlev/control-center),
published at **[usectrl.dev](https://usectrl.dev)**. Built with
[Astro](https://astro.build) + [Starlight](https://starlight.astro.build), themed
to match the marketing site, and deployed to Cloudflare Pages.

## Structure

```
src/
├── content/docs/      # The manual (Markdown/MDX, organized Diátaxis-style)
│   └── manual/
│       ├── tutorials/ # Learning-oriented — guided first-time walks
│       ├── guides/    # Task-oriented — how to do a specific thing
│       ├── concepts/  # Understanding-oriented — how the system works
│       └── reference/ # Information-oriented — schemas, enums, maps
├── pages/             # Marketing + legal pages (index, changelog, terms, privacy)
├── components/        # Starlight overrides + landing/legal/changelog components
├── data/              # Single source of truth for the changelog (TS)
├── layouts/           # Marketing layout
├── styles/            # Global + Starlight CSS (warm surfaces, cc_* tokens)
└── assets/            # Integration icons
astro.config.mjs       # Starlight config — sidebar, theme, fonts, Expressive Code
```

The documentation follows the [Diátaxis](https://diataxis.fr/) framework: four
content types (tutorials, how-to guides, reference, explanation) kept separate
so each page answers one kind of question. When adding a page, place it in the
folder that matches its intent and register it in the `sidebar` array in
`astro.config.mjs`.

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

Cloudflare Pages (adapter `@astrojs/cloudflare`, config in `wrangler.jsonc`).
`pnpm generate-types` regenerates Cloudflare env types after a binding change.

## Conventions

- **Content lives in `src/content/docs/`** — Starlight routes each file by its
  path. The landing page and changelog are authored in `src/pages/`.
- **The sidebar is hand-curated** in `astro.config.mjs` — a new page is invisible
  in the nav until you add it there.
- **Cross-links use Starlight slugs**, e.g. `/manual/concepts/agent-model/`
  (trailing slash). The source-of-truth ARB/glossary in the app repo is
  `GLOSSARY.md`; this site's `reference/glossary` is a curated subset.
- **The changelog is a single source of truth** in `src/data/changelog.ts`,
  consumed by both the changelog page and the RSS feed.
