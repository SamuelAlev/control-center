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
- `src/pages/` holds marketing, legal, changelog and machine endpoints. `src/data/` holds locale copy, `changelog.ts` (also used by RSS), comparison and page data; `src/agentic/` builds Markdown twins, MCP, OpenAPI and negotiation. New competitors belong in `src/data/compare.ts`: its rows drive the matrix, individual `/compare/<id>/` pages, footer links and Markdown twins. Update the hub's featured/adjacent grouping and FAQ in `src/pages/compare.astro` when the set changes, and check capability claims against the vendor's own site or docs. Check Control Center behavior claims against wired call sites, not another article.
- Cross-links use trailing-slash Starlight slugs, e.g. `/manual/concepts/agent-model/`. Keep the app's [GLOSSARY.md](../GLOSSARY.md) as the terminology source; when changing `reference/glossary.mdx`, update both prose and `glossaryTerms` JSON-LD.
- Non-index guides and concepts close with `## Related guides` and/or `## Related concepts`; references use `## See also`; tutorials use a short `## Recap` and `**Next:**` link.
- `src/styles/brand.css` owns shared tokens and fonts; `global.css`, `landing.css` and `starlight.css` consume them. Starlight does not import the marketing reset. Reuse Starlight `LinkButton`/`LinkCard`, navigation and preference controls instead of duplicating kits. Review both themes, phone/tablet/desktop layouts, keyboard focus, menus, contents dropdown and built search.

For a comparison refresh, verify every competitor’s feature and price claims against its current vendor docs, then set `compareReviewed` in `src/data/compare.ts` to the actual review date. The same data and date feed the HTML hub, all head-to-head pages, Markdown twins and `/llms-full.txt`; keep the hub FAQ and price caveat consistent.

## Locales and caching

English is Starlight's `root` locale (`/manual/`, no `/en/`). `src/content.config.ts` uses native `docsLoader()`/`i18nLoader()`: keep authored path casing, explicit slugs and `/index` semantics. `src/content/i18n/en.json` is the UI-copy reference; add English values and blank entries in the other locale dictionaries for each new key. Blank values retain native/English fallback. Filenames match exact BCP 47 tags (`fr-FR.json`); do not lowercase route prefixes, since case-insensitive build filesystems and case-sensitive deployed URLs disagree. `localizeSidebar()` resolves stable translation keys; `src/data/locales.ts` is the shared locale registry. The documentation language picker offers only languages with translated articles; untranslated articles retain the selected UI locale and show an untranslated-content notice. Translate articles under `src/content/docs/<locale>/manual/`, keeping filenames and MDX syntax aligned.

The Worker chooses locale in this order: explicit URL, `?lang=` picker choice, `cc-locale` cookie, weighted `Accept-Language`, English. The one-year cookie is HttpOnly, SameSite=Lax and Secure over HTTPS; visiting a localized link must not overwrite the preference. Picker links preserve manual article, query and anchor, work without JavaScript and do not read browser storage. Unsupported regions use the supported language default; Chinese script preferences distinguish simplified/traditional.

All localized pages are prerendered. Locale redirects are temporary `302`; personalized redirects, unprefixed HTML and explicit-choice responses are `private, no-store` and vary on `Accept`, `Accept-Language`, `Cookie`. Explicit locale HTML is also `no-store` once the Worker injects the live star count; the prerendered asset remains edge-served, but caching the rewritten page in a browser could keep its count past five minutes. Markdown/JSON, assets and other routes do not use browser-language negotiation. Register new locale paths in `wrangler.jsonc` as well as `locales.ts` and landing copy.

## Landing and accessibility

`LandingPage.astro` supplies `/` (en-US) and localized landing routes. `landing-en.ts` defines the copy shape; other `landing-*.ts` modules translate all text, metadata and accessible labels. Canonicals and reciprocal HTML `hreflang` include full BCP 47 tags; bare language codes point to one primary region, `x-default` to `/`. RTL languages set `dir="rtl"`. Do not advertise untranslated legal/comparison pages. The sitemap includes published HTML, not Markdown twins, redirects, machine endpoints or 404. Flutter app shells and the gallery use `noindex`, which is not access control.

`MarketingLayout.astro` renders the landing navigation and footer on every marketing page, including comparisons, changelog and legal pages. Only the landing page advertises localized alternates; other marketing pages remain English-only, so their footer language picker opens the selected language's landing page. Starlight shares the landing navigation but retains its article footer.

`ProductMedia.astro` renders a labeled diagram until a surface has a capture in `src/data/captures.ts`. Hero stops play silent H.264 loops at the source frame size (2880×1864, or 2884×1864 for pipelines and usage, about 1.54) with a WebP poster. The hero frame uses that ratio. Rebuild the files with `scripts/encode-landing-media.sh`. Inline clips autoplay muted and inline, with no native controls, and pause offscreen, in hidden tour panels, inside a closed dialog, and when the viewer prefers reduced motion. A corner control pauses or plays without the platform video player. The hero carousel attaches a media URL only to the visible clip and the next one. Usage quota, soundscapes, parallel agents, pull request review, repeatable pipelines, account switching, observability, skill and agent editors, meeting notes, and connected tickets use an 8/5 frame with `object-fit: cover`. Hover or keyboard focus plays a muted 60 fps preview; a click opens the full-frame mp4 with native controls. The workflow steps use the hero ticket clip, the hero agents clip, and the pull request review clip. “Approve a push before it runs” uses the agent permissions clip. The desktop surface stays a labeled diagram. Accessible descriptions are translated with the landing copy. The slideshow starts playing. Arrows, Home, and End still move between stops, selection stops playback, and hover, focus, or reduced motion pauses it. Dialogs close on Escape and restore focus. The native mobile menu and language disclosures dismiss on Escape/outside click. Without JavaScript, all six hero descriptions remain readable. Keep landing content visible without reveal animations, and freeze the hero shader at time zero on reduced motion, including preference changes. Avoid double-counting sticky-header offsets: do not combine root scroll padding and target scroll margins.

The `/download/{macos,windows,linux}` Worker routes select only the matching installer (Apple Silicon DMG, Windows x64 setup EXE, Linux x86_64 AppImage) from GitHub's latest stable release. Release metadata caches for up to five minutes; the GET/HEAD redirect is `no-store` and bytes come from GitHub. Missing assets return 404, malformed metadata 502, upstream failure 503. These routes bypass Markdown negotiation.

The Worker inserts the repository star count into HTML navigation at response time, with no browser-side API request. It fetches public GitHub metadata and caches successful responses at each Cloudflare edge for five minutes. Rewritten HTML is `no-store` so the embedded count cannot outlive that TTL in a browser; GitHub failure leaves the repository link visible without a count. The static `pnpm dev` server does not run this Worker transformation.

### Alpine pilot assets

The two pilots are sourced from the packed `art/alpine/alpine-journey.blend`; **the retained pilot skins originated in Meshy**. Keep that source and its exporter modules so shipped assets remain reproducible. Regenerate on macOS from the repository root (requires Blender, ffmpeg, Node and `pnpm -C docs install`):

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b docs/art/alpine/alpine-journey.blend --python-exit-code 1 --python docs/art/alpine/render_install_pilot.py
```

Append `-- --quick-check` for geometry checks without rendering/exporting; a full run is required to publish. `render_install_pilot.py` and `compress_pilots.mjs` write two self-contained GLBs and WebP posters under `public/alpine/`. Their Meshopt-compressed GLBs require `EXT_texture_webp`, `KHR_mesh_quantization` and `EXT_meshopt_compression`; morph normal deltas must stay float/range-safe, skin and animation precision intact. The compression script verifies decoded geometry, rig/morph metadata, textures and animation samples. Do not multiply baked contact AO into albedo; preserve UV0 color/normal/metallic maps and UV1 non-overlapping AO. Dispose generated studio environments with viewers.

To refresh only the install poster after a camera change, use the same Blender command with `-- --install-poster-only`; it leaves the GLBs and hero poster untouched.

Maintain loaded models only on desktop widths above 900px and near viewport; mobile must fetch neither 3D chunks, GLBs nor posters, even without JavaScript. Cancel pending mounts and dispose viewers across resize, BFCache and load failures; keep poster visible on failure. Drag/orbit, arrow-key bank/pitch, R reset and Space pause must not steal vertical touch scroll or wheel. Motion stops offscreen/hidden, reduced motion holds a neutral pose but permits manual orbit. Rig checks must retain weighted skin, hands on toggles, attachment endpoints, synchronized cloth/cord morphs and loop closure. `flightBounds` must cover idle, brake, wind, pitch and bank; resize preserves orbit until reset. Additive turn conversion clones glTF track buffers before mutation; full neutral skeleton keys prevent hands separating from handles. Rooted hair masks exclude face, beard, helmet and harness, and mixer animation must not overwrite hair morph weights. On visual review, check both directions, both pitch limits, pause/reduced motion, resize and no mobile asset requests.

The desktop hero pilot makes occasional alternating left/right brake pulls using the baked arm, cord, canopy and bank clips. The wing banks further with each pull and returns to level between maneuvers. Dragging or using the arrow keys takes priority and postpones the next autonomous turn; pause, offscreen/hidden state and reduced motion suspend it. The install pilot remains interaction-driven.

On the install section, pointer movement over the five platform/remote cards steers the front-facing desktop pilot and pulls the matching brake handle. The install pilot is displayed at up to 1.5× its former size, with a matching 1800 × 1575 WebP poster rendered from its head-on camera. Clicking a macOS, Windows or Linux card starts the native download immediately and makes the pilot dive through one loop while the page remains open; modified clicks, mobile, reduced motion and paused flight keep native navigation without the loop. The web app and phone companion cards only steer the pilot.

## Agent-facing routes

`src/worker.ts` wraps the Astro adapter; `wrangler.jsonc` routes pages through it and leaves binary assets directly served. `Accept: text/markdown` or `<page>.md` returns the same generated Markdown twin, with `Vary: Accept`. `/llms.txt`, `/llms-full.txt`, `/openapi.json` and `/.well-known/mcp` (`/mcp`) expose discovery, an OpenAPI 3.1 inventory and Streamable HTTP `list_pages`/`get_page_markdown`/`search_pages`. Missing routes negotiate HTML, Markdown recovery or JSON error (`Accept: application/json` and `/api/*`). Keep twins derived from the same data and collection as HTML; test negotiation, MCP and OpenAPI with `pnpm test` and the built Worker.

## Website analytics

Umami at `https://analytics.alev.dev` uses public website ID `d84f01cc-5611-4363-b598-ddd31e3011c1` (not an API credential). `install_section_click`, `release_page_click` and `demo_open_click` count CTA actions, **not** completed downloads, installs or activated users. The release event ID remains for reporting continuity even though current OS cards redirect to installers. Limit properties to CTA placement and explicit platform; omit query/fragment, respect Do Not Track, track only `usectrl.dev`, add no visitor ID or cross-domain attribution, and never block navigation when tracking is unavailable.

The Umami script is inserted only on the `usectrl.dev` hostname. `pnpm dev` and local Wrangler previews do not download it or send analytics requests.
