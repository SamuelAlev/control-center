---
name: translate-manual
description: Translate or update the localized Control Center manual (docs/src/content/docs/<locale>/manual) and the agent copy behind each language's llms.txt (docs/src/data/agent-copy) after the English source changes. Use when the docs build or `pnpm i18n check` reports untranslated, stale, missing, orphaned, slug, link or agent copy problems; when an English manual page or en-US agent copy is added, edited, moved or deleted; or when asked to translate the docs.
user-invocable: true
---

# Translate the manual

The English manual (`docs/src/content/docs/manual/**`) is the source. Each other site locale (`docs/src/data/locales.ts`) mirrors it file for file at `docs/src/content/docs/<locale>/manual/**`, with the same file names, and serves each page under a translated URL. `docs/scripts/manual-i18n.ts` fails `pnpm build` (and CI) until every locale page exists, has a valid translated `slug`, was translated from the current English revision and links only within its own locale. `astro dev` only warns.

Run every command below from `docs/`.

## A locale page

```mdx
---
title: Créer et configurer un agent
description: Ajoutez un agent à un espace de travail…
slug: fr-FR/manuel/guides/creer-agent
sourceHash: 3b18e512dba79e4c8300dd08aeb37f8e728bac34
---
```

- `slug` is the page's public URL: `<locale>/` and then the translated path. It has as many segments as the English id (`manual/guides/create-agent`) and extends its section page's slug, which is the `index.mdx` in the same folder.
- Segments are lowercase words joined by single hyphens. Latin-script locales (cs, de, en-GB, es, fr, hu, id, it, ms, nb, nl, pl, pt, ro, sv, tr, vi) use ASCII only, with each language's usual URL transliteration (`ä`→`ae` in German, tone marks dropped in Vietnamese, `ı`→`i` in Turkish). Other locales use their own script, NFC-normalized; separate words with hyphens where the language uses spaces. Product names and acronyms stay Latin (`mcp-サーバー`).
- Base each slug on the locale's sidebar label for that page (`docs.sidebar.*` in `docs/src/content/i18n/<locale>.json`), as concise as the English segment.
- A slug is a public URL. Don't rename a published one in passing: the Worker only redirects the pre-translation `/<locale>/manual/…` paths, not old translated ones.
- `sourceHash` is the git blob id of the English page this text was translated from. Write it only with `pnpm i18n stamp`, never by hand, and only after the page really is translated.

## Workflow

1. **See what's wrong.** `pnpm i18n status` gives counts per locale. `pnpm i18n check [--locale fr-FR]` lists every problem with `file:line`.
2. **Fix the structure first.**
   - *New English page:* run `pnpm i18n scaffold`. It copies the page into every locale with English text, `/manual/…` links pointed at existing translated pages, and no `slug`. Give each copy a `slug`, then translate it.
   - *Moved or renamed English page:* `git mv` every locale copy to the same new path. Keep each locale's slug unless the page changed section, and update any links that point at it.
   - *Deleted English page:* delete every locale copy (they show up as orphans), then fix the links the check reports.
   - *New site locale:* once it is in `src/data/locales.ts`, `pnpm i18n scaffold` creates the whole tree. Then give every page a slug and translate it.
3. **Translate.**
   - *Untranslated page* (no `sourceHash`): translate the whole English page.
   - *Stale page:* `pnpm i18n diff <locale file>` shows what changed in English since the page was translated. Make the same changes to the translation and keep the rest.
   - Then run `pnpm i18n stamp <locale files…>`.
4. **Verify.** `pnpm i18n check` must print "The translated manual is complete and current." Then run `pnpm test` and `pnpm build`.

## Agent copy

`docs/src/data/agent-copy/<locale>.json` holds the prose of each language's `llms.txt` and `llms-full.txt`, which AI agents read. `en-US.json` is the source. When a key is added or its English text changes, update that key in every other locale file, in the same key order. Keep every `{placeholder}` and every backtick span byte for byte; the check compares them. `{language}` is filled with the language's native name and region (e.g. `Deutsch (Deutschland)`), so write the sentence so the name needs no inflection.

## Translation rules

- Translate `title`, `description`, prose, headings, table text, alt text and user-visible component props or children. Keep frontmatter keys, `import` lines, component names, non-text props, code blocks, inline code, commands, flags, environment variables, file paths and non-manual URLs exactly as in English.
- UI labels the manual quotes from the app (**Settings → Workspace → Agents**) must match the app's own translation in `lib/l10n/app_<lang>.arb`. Find the key by its English value in `app_en.arb`. The sparse variants (`en_GB`, `es_MX`, `fr_CA`, `pt_PT`, `zh_HK`) fall back to their base language file.
- Keep product terminology consistent with the locale's `docs.sidebar.*` labels and its landing copy (`docs/src/data/landing-*.ts`).
- Product labels that the app and its API show in English stay in English, e.g. the AI-review verdicts **Ship**, **Hold** and **Block** (`approve_on_ship`). Brand and protocol names stay in Latin script.
- Point every link to another manual page at the same locale's translated URL (the target page's `slug`, with a leading `/` and a trailing `/`). Anchors (`#…`) are generated from the target page's translated heading text, so update them when you translate headings.
- Interactive components keep the same usage as in English: same components, same props, same order. Strings a component renders itself belong in `docs/src/content/i18n/<locale>.json` and are read with `Astro.locals.t()`, not hard-coded per page.
- en-GB is a real translation into British English (spelling and usage), not a copy.
- Write the way a native technical writer for that locale would. No translator's notes, and leave nothing in English except the items listed above.

## Working at scale

Many pages across 33 locales is a lot of work: split it by locale. Run at most 3 subagents at a time, on the opus model, and tell them not to spawn their own. Give each one its locales, this skill's path and the files to translate. Each runs `pnpm i18n check --locale <id>` and stamps only what it translated before reporting back. Run `pnpm build` once at the end.
