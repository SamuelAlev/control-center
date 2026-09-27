# Control Center docs

[usectrl.dev](https://usectrl.dev) is built with Astro, Starlight and a Cloudflare Worker. Repository architecture is in [ARCH.md](../ARCH.md); this file covers site-specific authoring and deployment.

## Develop and deploy

From `docs/`:

```sh
pnpm install
pnpm dev                 # http://localhost:4321
pnpm test                # dependency-free node --test units
pnpm build               # dist/ plus scripts/fix-wrangler.mjs
pnpm preview             # built site
pnpm exec wrangler deploy
pnpm generate-types      # after a Worker binding change
```

`pnpm dev` does not execute `src/worker.ts`, and Pagefind search requires a build. Test language routing, content negotiation and redirects against the built Wrangler preview. `.github/workflows/deploy-docs.yml` deploys on `main` changes under `docs/`; Cloudflare git auto-build is off to avoid competing deploys. `scripts/fix-wrangler.mjs` removes the adapter's unused `SESSION` KV binding from the emitted config (`dist/server/wrangler.json` or `dist/client/wrangler.json`).

## Content and theme

- `src/content/docs/manual/{tutorials,guides,concepts,reference}/` holds Starlight articles. Tutorials teach one reproducible path; guides solve a task; concepts explain; reference must be complete. Register new pages in `astro.config.mjs` and their section's `index.mdx` landing page. The sidebar is hand-curated.
- `src/pages/` holds marketing, legal, changelog and machine endpoints. `src/data/` holds locale copy, `changelog.ts` (also used by RSS), comparison and page data; `src/agentic/` builds Markdown twins, MCP, OpenAPI and negotiation. Check behavior claims against wired call sites, not another article.
- Cross-links use trailing-slash Starlight slugs, e.g. `/manual/concepts/agent-model/`. Keep the app's [GLOSSARY.md](../GLOSSARY.md) as the terminology source; when changing `reference/glossary.mdx`, update both prose and `glossaryTerms` JSON-LD.
- Non-index guides and concepts close with `## Related guides` and/or `## Related concepts`; references use `## See also`; tutorials use a short `## Recap` and `**Next:**` link.
- `src/styles/brand.css` owns shared tokens and fonts; `global.css`, `landing.css` and `starlight.css` consume them. Starlight does not import the marketing reset. Reuse Starlight `LinkButton`/`LinkCard`, navigation and preference controls instead of duplicating kits. Review both themes, phone/tablet/desktop layouts, keyboard focus, menus, contents dropdown and built search.

## Locales and caching

English is Starlight's `root` locale (`/manual/`, no `/en/`). `src/content.config.ts` uses native `docsLoader()`/`i18nLoader()`: keep authored path casing, explicit slugs and `/index` semantics. `src/content/i18n/en.json` is the UI-copy reference; add English values and blank entries in the other locale dictionaries for each new key. Blank values retain native/English fallback. Filenames match exact BCP 47 tags (`fr-FR.json`); do not lowercase route prefixes, since case-insensitive build filesystems and case-sensitive deployed URLs disagree. `localizeSidebar()` resolves stable translation keys; `src/data/locales.ts` is the shared locale registry. The documentation language picker offers only languages with translated articles; untranslated articles retain the selected UI locale and show an untranslated-content notice. Translate articles under `src/content/docs/<locale>/manual/`, keeping filenames and MDX syntax aligned.

The Worker chooses locale in this order: explicit URL, `?lang=` picker choice, `cc-locale` cookie, weighted `Accept-Language`, English. The one-year cookie is HttpOnly, SameSite=Lax and Secure over HTTPS; visiting a localized link must not overwrite the preference. Picker links preserve manual article, query and anchor, work without JavaScript and do not read browser storage. Unsupported regions use the supported language default; Chinese script preferences distinguish simplified/traditional.

All localized pages are prerendered. Locale redirects are temporary `302`; personalized redirects, unprefixed HTML and explicit-choice responses are `private, no-store` and vary on `Accept`, `Accept-Language`, `Cookie`. Explicit locale URLs remain cacheable. Markdown/JSON, assets and other routes do not use browser-language negotiation. Register new locale paths in `wrangler.jsonc` as well as `locales.ts` and landing copy.

## Landing and accessibility

`LandingPage.astro` supplies `/` (en-US) and localized landing routes. `landing-en.ts` defines the copy shape; other `landing-*.ts` modules translate all text, metadata and accessible labels. Canonicals and reciprocal HTML `hreflang` include full BCP 47 tags; bare language codes point to one primary region, `x-default` to `/`. RTL languages set `dir="rtl"`. Do not advertise untranslated legal/comparison pages. The sitemap includes published HTML, not Markdown twins, redirects, machine endpoints or 404. Flutter app shells and the gallery use `noindex`, which is not access control.

`ProductMedia.astro` slots are intentionally descriptive placeholders, **not** screenshots. Use `data-media-slot` to replace them with actual captures; retain translated alt text and reserved source dimensions (desktop 1440 × 900, phone 390 × 844). Videos need captions, transcripts where required, accessible controls, silent autoplay policy and pause in hidden panels. The tour starts paused; arrows/Home/End and previous/next work, selection stops playback, and hover/focus/dialog/hidden state pauses it. The dialog closes on Escape and restores focus. The native mobile menu and language disclosures dismiss on Escape/outside click. Without JavaScript, all six hero descriptions remain readable. Keep landing content visible without reveal animations, and freeze the hero shader at time zero on reduced motion, including preference changes. Avoid double-counting sticky-header offsets: do not combine root scroll padding and target scroll margins.

The `/download/{macos,windows,linux}` Worker routes select only the matching installer (Apple Silicon DMG, Windows x64 setup EXE, Linux x86_64 AppImage) from GitHub's latest stable release. Release metadata caches for up to five minutes; the GET/HEAD redirect is `no-store` and bytes come from GitHub. Missing assets return 404, malformed metadata 502, upstream failure 503. These routes bypass Markdown negotiation.

### Alpine pilot assets

The two pilots are sourced from the packed `art/alpine/alpine-journey.blend`; **the retained pilot skins originated in Meshy**. Keep that source and its exporter modules so shipped assets remain reproducible. Regenerate on macOS from the repository root (requires Blender, ffmpeg, Node and `pnpm -C docs install`):

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b docs/art/alpine/alpine-journey.blend --python-exit-code 1 --python docs/art/alpine/render_install_pilot.py
```

Append `-- --quick-check` for geometry checks without rendering/exporting; a full run is required to publish. `render_install_pilot.py` and `compress_pilots.mjs` write two self-contained GLBs and WebP posters under `public/alpine/`. Their Meshopt-compressed GLBs require `EXT_texture_webp`, `KHR_mesh_quantization` and `EXT_meshopt_compression`; morph normal deltas must stay float/range-safe, skin and animation precision intact. The compression script verifies decoded geometry, rig/morph metadata, textures and animation samples. Do not multiply baked contact AO into albedo; preserve UV0 color/normal/metallic maps and UV1 non-overlapping AO. Dispose generated studio environments with viewers.

To refresh only the install poster after a camera change, use the same Blender command with `-- --install-poster-only`; it leaves the GLBs and hero poster untouched.

Maintain loaded models only on desktop widths above 900px and near viewport; mobile must fetch neither 3D chunks, GLBs nor posters, even without JavaScript. Cancel pending mounts and dispose viewers across resize, BFCache and load failures; keep poster visible on failure. Drag/orbit, arrow-key bank/pitch, R reset and Space pause must not steal vertical touch scroll or wheel. Motion stops offscreen/hidden, reduced motion holds a neutral pose but permits manual orbit. Rig checks must retain weighted skin, hands on toggles, attachment endpoints, synchronized cloth/cord morphs and loop closure. `flightBounds` must cover idle, brake, wind, pitch and bank; resize preserves orbit until reset. Additive turn conversion clones glTF track buffers before mutation; full neutral skeleton keys prevent hands separating from handles. Rooted hair masks exclude face, beard, helmet and harness, and mixer animation must not overwrite hair morph weights. On visual review, check both directions, both pitch limits, pause/reduced motion, resize and no mobile asset requests.

On the install section, pointer movement over the five platform/remote cards steers the front-facing desktop pilot and pulls the matching brake handle. The install pilot is displayed at up to 1.5× its former size, with a matching 1800 × 1575 WebP poster rendered from its head-on camera. Clicking a macOS, Windows or Linux card starts the native download immediately and makes the pilot dive through one loop while the page remains open; modified clicks, mobile, reduced motion and paused flight keep native navigation without the loop. The web app and phone companion cards only steer the pilot.

## Agent-facing routes

`src/worker.ts` wraps the Astro adapter; `wrangler.jsonc` routes pages through it and leaves binary assets directly served. `Accept: text/markdown` or `<page>.md` returns the same generated Markdown twin, with `Vary: Accept`. `/llms.txt`, `/llms-full.txt`, `/openapi.json` and `/.well-known/mcp` (`/mcp`) expose discovery, an OpenAPI 3.1 inventory and Streamable HTTP `list_pages`/`get_page_markdown`/`search_pages`. Missing routes negotiate HTML, Markdown recovery or JSON error (`Accept: application/json` and `/api/*`). Keep twins derived from the same data and collection as HTML; test negotiation, MCP and OpenAPI with `pnpm test` and the built Worker.

## Website analytics

Umami at `https://analytics.alev.dev` uses public website ID `d84f01cc-5611-4363-b598-ddd31e3011c1` (not an API credential). `install_section_click`, `release_page_click` and `demo_open_click` count CTA actions, **not** completed downloads, installs or activated users. The release event ID remains for reporting continuity even though current OS cards redirect to installers. Limit properties to CTA placement and explicit platform; omit query/fragment, respect Do Not Track, track only `usectrl.dev`, add no visitor ID or cross-domain attribution, and never block navigation when tracking is unavailable.
