---
version: alpha
name: Control Center
description: >-
  Design system for Control Center — the cockpit for multi-agent software
  development. A near-white, black-structured operator surface with a single
  orange signal and warm golden-hour brand moments kept to bounded
  graphics. Sharp architectural geometry, one type weight, color paired with
  shape for every status.

# ── COLORS ────────────────────────────────────────────────────────────────
# Machine values below are the resolved hexes used at runtime. Several are
# derived from a base token via color-mix() in oklab — the live formula is
# documented in the "Colors" section so the relationship is preserved.
colors:
  # Surface ladder — near-white canvas, warm-neutral surface, pure-white data
  bg: '#fcfbf9'            # the true page canvas (near-white off-white)
  surface: '#f2f0e9'       # faint warm-neutral — secondary buttons, soft chips
  panel: '#ffffff'         # pure white — the contrast / data surface
  sidebar: '#f6f5f0'       # faint neutral rail (app shell)
  rail: '#faf9f5'          # group-header rail inside panels

  # Foreground — Ink black, never pure #000; warm-tinted neutrals only
  fg: '#1f1f1f'            # primary text + dark button / footer surface
  muted: '#3d3d3d'         # secondary text, metadata
  idle: '#1f1f1f61'        # fg @ 38% — disabled, faint dots, tertiary meta

  # Borders — cool-neutral hairlines so panels never read yellow
  border: '#e8e5dc'
  border-soft: '#efece4'
  line-strong: '#1f1f1f29' # fg @ 16% — DAG edges, dividers that must show
  hover: '#1f1f1f0d'       # fg @ 5%  — row / nav hover wash
  hover-strong: '#1f1f1f14' # fg @ 8% — count chips, pressed states

  # Accent — the single orange signal fire
  accent: '#fa520f'        # Signal orange — primary signal, used <= twice/screen
  accent-on: '#ffffff'     # text/icon on accent
  accent-hover: '#fb6424'  # Flame — hover/active warm-up
  accent-active: '#dc480d' # accent mixed 12% black — pressed
  accent-soft: '#fa520f1f' # accent @ 12% — tinted backgrounds, active chips

  # Status — distinguishable from the warm palette; always paired w/ a shape
  success: '#17a34a'
  success-soft: '#17a34a24'
  warn: '#eab308'
  warn-soft: '#eab30833'
  danger: '#dc2626'
  danger-soft: '#dc26261f'

  # Sunshine scale — reserved for the bounded golden-hour brand graphics only
  sunshine-900: '#ff8a00'
  sunshine-700: '#ffa110'
  sunshine-500: '#ffb83e'
  sunshine-300: '#ffd06a'
  bright-yellow: '#ffd900'
  block-edge: '#c0400f'    # burnt-orange terminus of the block mosaic

# ── TYPOGRAPHY ────────────────────────────────────────────────────────────
# One family (Manrope), one weight (400). Hierarchy is size + color only.
typography:
  display-hero:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '82px'
    fontWeight: 400
    lineHeight: 1.0
    letterSpacing: '-0.025em'
  display-lg:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '56px'
    fontWeight: 400
    lineHeight: 1.0
    letterSpacing: '-0.03em'
  headline:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '48px'
    fontWeight: 400
    lineHeight: 1.02
    letterSpacing: '-0.025em'
  title:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '32px'
    fontWeight: 400
    lineHeight: 1.05
    letterSpacing: '-0.02em'
  subtitle:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '24px'
    fontWeight: 400
    lineHeight: 1.15
    letterSpacing: '-0.01em'
  body:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '16px'
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: '0'
  body-sm:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '14px'
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: '0'
  label:
    fontFamily: '"JetBrains Mono", ui-monospace, "SF Mono", Menlo, Consolas, monospace'
    fontSize: '12px'
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: '0.1em'
    # rendered text-transform: uppercase (eyebrows, nav labels, status)
  mono-num:
    fontFamily: '"JetBrains Mono", ui-monospace, "SF Mono", Menlo, Consolas, monospace'
    fontSize: '13px'
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: '0'
    fontFeature: '"tnum" 1'   # tabular-nums for counts, diffs, IDs, timestamps

# ── ROUNDED ───────────────────────────────────────────────────────────────
# Near-zero is the dominant radius. Sharp geometry vs. warm color is the tension.
rounded:
  none: '0px'
  sm: '2px'     # all standard elements — buttons, inputs, chips, cards
  md: '2px'     # intentionally equal to sm; no mid rounding
  lg: '4px'     # large containers / panels / device windows only
  full: '9999px' # pills + status capsules + live dots ONLY

# ── SPACING ───────────────────────────────────────────────────────────────
# 8px base unit. Semantic keys below map 1:1 to the --space-* CSS scale.
spacing:
  2xs: '4px'    # --space-1
  xs: '8px'     # --space-2
  sm: '12px'    # --space-3
  md: '16px'    # --space-4
  lg: '24px'    # --space-6
  xl: '32px'    # --space-8
  2xl: '48px'   # --space-12
  section-phone: '32px'
  section-tablet: '48px'
  section-desktop: '80px'

# ── COMPONENTS ────────────────────────────────────────────────────────────
# Variants use related names (button-primary / -hover / -active). Token refs
# use dot-notation: {colors.fg}, {typography.body}, {rounded.sm}, {spacing.md}.
components:
  button-primary:
    backgroundColor: '{colors.fg}'
    textColor: '{colors.accent-on}'
    typography: '{typography.body-sm}'
    rounded: '{rounded.sm}'
    padding: '12px 18px'
  button-primary-hover:
    backgroundColor: '{colors.accent}'
    textColor: '{colors.accent-on}'
  button-secondary:
    backgroundColor: '{colors.surface}'
    textColor: '{colors.fg}'
    borderColor: '{colors.border}'
    rounded: '{rounded.sm}'
    padding: '12px 18px'
  button-secondary-hover:
    borderColor: '{colors.line-strong}'
  button-accent:
    backgroundColor: '{colors.accent}'
    textColor: '{colors.accent-on}'
    rounded: '{rounded.sm}'
    padding: '9px 16px'
  button-accent-hover:
    backgroundColor: '{colors.accent-hover}'
  button-line:
    backgroundColor: '{colors.panel}'
    textColor: '{colors.fg}'
    borderColor: '{colors.border}'
    rounded: '{rounded.sm}'
    padding: '9px 16px'
  button-line-hover:
    borderColor: '{colors.fg}'
  button-sm:
    typography: '{typography.body-sm}'
    padding: '9px 14px'
  panel:
    backgroundColor: '{colors.panel}'
    borderColor: '{colors.border}'
    rounded: '{rounded.lg}'
  card:
    backgroundColor: '{colors.panel}'
    borderColor: '{colors.border}'
    rounded: '{rounded.sm}'
    padding: '11px 12px'
  input:
    backgroundColor: '{colors.panel}'
    textColor: '{colors.fg}'
    borderColor: '{colors.border}'
    rounded: '{rounded.sm}'
    padding: '9px 12px'
    typography: '{typography.body-sm}'
  input-focus:
    borderColor: '{colors.accent}'
    # plus focus ring: 0 0 0 3px {colors.accent-soft}
  status-run:
    backgroundColor: '{colors.success-soft}'
    textColor: '{colors.success}'
    typography: '{typography.label}'
    rounded: '{rounded.full}'
    padding: '3px 8px'
  status-blocked:
    backgroundColor: '{colors.warn-soft}'
    textColor: '{colors.warn}'
    typography: '{typography.label}'
    rounded: '{rounded.full}'
    padding: '3px 8px'
  status-failed:
    backgroundColor: '{colors.danger-soft}'
    textColor: '{colors.danger}'
    typography: '{typography.label}'
    rounded: '{rounded.full}'
    padding: '3px 8px'
  status-idle:
    backgroundColor: '{colors.surface}'
    textColor: '{colors.muted}'
    typography: '{typography.label}'
    rounded: '{rounded.full}'
    padding: '3px 8px'
  badge:
    backgroundColor: '{colors.surface}'
    textColor: '{colors.idle}'
    borderColor: '{colors.border}'
    typography: '{typography.label}'
    rounded: '{rounded.sm}'
    padding: '3px 8px'
  eyebrow:
    textColor: '{colors.muted}'
    typography: '{typography.label}'
  kbd:
    backgroundColor: '{colors.bg}'
    textColor: '{colors.muted}'
    borderColor: '{colors.border}'
    typography: '{typography.label}'
    rounded: '{rounded.sm}'
    padding: '1px 5px'
---

# Control Center — Design System

## Overview

Control Center is a native desktop cockpit for commanding a fleet of autonomous
coding agents. The interface has to do something most product UI doesn't: sit
open all day next to real work, report live machine state honestly, and never
shout. So the system rebalances a warm, expressive visual language for an
operator surface.

Its roots are golden-amber warmth, billboard typography, sharp architectural
geometry, and weight-400 everywhere — but tuned for a cockpit. A pure marketing
treatment would flood the canvas with ivory and cream; in a cockpit that reads
as "ugly yellow" and fights the data. So the canvas here is **near-white with
black as the structural color**, and the warm gold is **confined to bounded
graphics** — the 3×3 logo mosaic, one golden-hour horizon per page, the dark
sunset CTA. Warmth is a moment you earn, not a wash you apply.

**The posture in one breath:** near-white surfaces, ink-black text and
chrome, a single orange signal used at most twice per screen, sharp
2px corners, one type family at one weight, and color never carrying meaning
alone — every status pairs its color with an icon and a label.

Three layouts express it: a **landing page** (`landing.html`), a **changelog**
(`changelog.html`), and the **dashboard / app shell** (`dashboard.html`). All
three build on a shared token layer (`tokens.css`), then resolve it toward the
near-white canvas. This document codifies that **shipped** layer — it is the
real system, implemented in Flutter under `lib/core/theme/` (`design_system_palette.dart`,
`design_system_tokens.dart`) and read via `context.designSystem`.

## Colors

The palette is a four-rung surface ladder, a warm-neutral text/border set, one
accent, three status hues, and a sunshine scale reserved for brand graphics.

**Surfaces (lightest → data):**
- `{colors.bg}` `#fcfbf9` — the page canvas. Near-white, barely warm. Never
  pure white, never ivory/cream as a full bleed.
- `{colors.surface}` `#f2f0e9` — secondary buttons, soft chips, inert fills.
- `{colors.panel}` `#ffffff` — pure white, used **only** for data surfaces:
  cards, panels, product windows, popovers. White earns attention here because
  the page around it isn't white.
- `{colors.sidebar}` / `{colors.rail}` — faint neutral rails in the app shell.

**Text & lines (all warm-tinted, never cool gray):**
- `{colors.fg}` `#1f1f1f` — Ink black. Primary text, dark buttons, footer,
  and the sunset CTA base. Never `#000000`.
- `{colors.muted}` `#3d3d3d` — secondary text and metadata.
- `{colors.idle}` — `fg` at 38% — disabled states, faint dots, tertiary meta.
- `{colors.border}` `#e8e5dc` / `{colors.border-soft}` `#efece4` — cool-neutral
  hairlines so panels stop reading yellow.
- `{colors.line-strong}` — `fg` at 16% — dividers and DAG edges that must show.
- `{colors.hover}` / `{colors.hover-strong}` — `fg` at 5% / 8% — row washes.

**Accent — one signal fire, rationed:**
- `{colors.accent}` `#fa520f` — Signal orange. The single highest-signal color.
  Budget: **at most twice per screen** (typically eyebrow rule + primary CTA, or
  one active nav indicator + one link-arrow hover). Note the deliberate
  inversion: primary buttons are **black, not orange** — orange appears on
  *hover*, so the page rests calm and warms on intent.
- `{colors.accent-hover}` `#fb6424`, `{colors.accent-active}` `#dc480d`,
  `{colors.accent-soft}` (accent @ 12%) for tinted active chips.

**Status — distinguishable from the warm palette, always shape-paired:**
- `{colors.success}` `#17a34a`, `{colors.warn}` `#eab308`, `{colors.danger}`
  `#dc2626`, each with a `*-soft` tint for pill backgrounds. **Color is never
  the only signal** — see Components → Status.

**Sunshine scale — bounded brand graphics ONLY:**
`{colors.sunshine-900}` `#ff8a00` → `{colors.sunshine-700}` `#ffa110` →
`{colors.sunshine-500}` `#ffb83e` → `{colors.sunshine-300}` `#ffd06a` →
`{colors.bright-yellow}` `#ffd900`, terminating in `{colors.block-edge}`
`#c0400f`. These appear in the logo mosaic, the horizon flourish, and the CTA
sunset — never as text, never as a page background.

**Derivation contract.** Alpha tokens (`idle`, `line-strong`, `accent-soft`,
the `*-soft` set, hovers) are authored live with `color-mix(... in oklab)` off a
base token; the hexes above are their resolved values. Keep the live formula in
code so a base-color change propagates:

```css
--idle:        color-mix(in oklab, var(--fg) 38%, transparent);
--accent-soft: color-mix(in oklab, var(--accent), transparent 88%);
--accent-active: color-mix(in oklab, var(--accent), black 12%);
```

**The block mosaic / gradient** is the recognizable brand DNA, orange-dominant
(not yellow-led, or the small logo reads as a lemon square):

```css
--block-gradient: linear-gradient(135deg, #ffb83e 0%, #ff8105 34%, #fa520f 70%, #c0400f 100%);
```

## Typography

One family, one weight. **Manrope** for display and body; **JetBrains Mono**
for numerics, labels, code, and metadata. **Everything is weight 400 — even at
82px.** Hierarchy comes from size and color, never from bold. There is no 700
anywhere in the system.

| Token | Size | Line height | Tracking | Role |
|---|---|---|---|---|
| `{typography.display-hero}` | 82px | 1.0 | -0.025em | Hero billboard (clamps down on mobile) |
| `{typography.display-lg}` | 56px | 1.0 | -0.03em | Section anchors, big statements |
| `{typography.headline}` | 48px | 1.02 | -0.025em | Secondary section titles |
| `{typography.title}` | 32px | 1.05 | -0.02em | Card / feature titles |
| `{typography.subtitle}` | 24px | 1.15 | -0.01em | Sub-headings, block heads |
| `{typography.body}` | 16px | 1.5 | 0 | Standard body |
| `{typography.body-sm}` | 14px | 1.45 | 0 | Dense UI text, buttons |
| `{typography.label}` | 12px mono | 1.4 | 0.1em | Eyebrows, nav labels, status — UPPERCASE |
| `{typography.mono-num}` | 13px mono | 1.4 | 0 | Counts, diffs, IDs, timestamps — tabular |

**Principles**
- **Ultra-tight at scale.** Display line-heights of 1.0 pack ascenders against
  the descenders above into poster-like blocks. Use big `clamp()` ranges so the
  82px hero degrades to ~40px on phones without re-tracking.
- **Mono is structural, not decorative.** Anything countable, addressable, or
  time-stamped is monospace with tabular figures — it signals "machine truth."
- **Eyebrows are mono, uppercase, 0.1em tracked**, often prefixed with an 18px
  accent rule (`.eyebrow::before`). This is the system's signature label.
- **Never** introduce a second display family, a bold weight, or
  Inter/Roboto/Arial as a display face. Manrope (UI/body) and JetBrains Mono
  (mono) are wired through `google_fonts` in `core/theme/app_fonts.dart`.

## Layout

**Container.** `max-width: 1280px`, centered, with responsive gutters —
`24px` desktop, `16px` tablet, `12px` phone (`--container-gutter-*`).

**Spacing.** 8px base unit. Use the semantic scale (`{spacing.xs}` … `{spacing.2xl}`),
which maps 1:1 to the `--space-1 … --space-12` CSS variables (4 / 8 / 12 / 16 /
20 / 24 / 32 / 48 px). Vertical section rhythm is generous and viewport-scaled:
`{spacing.section-desktop}` 80px → `{spacing.section-tablet}` 48px →
`{spacing.section-phone}` 32px, authored as `clamp(56px, 9vw, 80px)`.

**App shell (dashboard).** A two-column grid: a `248px` sidebar rail + fluid
main column, each independently scrollable, `height: 100vh; overflow: hidden`.
A `48px` frosted top bar (`backdrop-filter: blur`) sits above a scrollable
canvas; content is capped at `1080px` inside the canvas. The sidebar collapses
to a `64px` icon rail at ≤900px and labels hide.

**Marketing / changelog.** Single scroll column inside the 1280px container; a
`64px` sticky frosted nav that gains a bottom hairline once scrolled. The
changelog adds a `232px` sticky version jump-rail beside the timeline that
collapses to inline chips at ≤920px.

**Whitespace philosophy.** Bold declarations get their own breathing room — one
big headline per band, surrounded by space. Empty space is *near-white*, not
stark, so it still feels warm. Photography/graphics double as whitespace.

**Responsive breakpoints:** `1024px` (grids collapse to single column), `920px`
(sidebar → icon rail; jump-rail → chips), `720px` (gutters shrink, nav links
hide), `560–680px` (drop search/crumbs, full-width controls). Verify no
horizontal scroll across the modern range (360 / 390 / 430 / 768 / 1024 / 1366 /
1440 / 1920).

## Elevation & Depth

Depth is rare and **warm**. Two levels only, plus a focus ring.

- **Flat (Level 0).** No shadow. Page backgrounds, text blocks, inert chips.
  Most of the UI lives here.
- **Hairline ring (`--elev-ring`).** `0 0 0 1px {colors.border}` — the default
  way to separate a surface. Borders, not shadows, do the structural work.
- **Golden float (Level 1).** A multi-layer, amber-tinted cascade — the
  signature "golden hour" elevation. Reserved for genuinely floating data
  surfaces: product windows, the hero deck, popovers, drawers, toasts.

```css
--shadow-golden:
  -8px  16px  39px rgba(127, 99, 21, 0.12),
  -28px 56px  64px rgba(127, 99, 21, 0.08),
  -64px 120px 88px rgba(127, 99, 21, 0.04);
--shadow-soft: 0 1px 2px rgba(127,99,21,0.05), 0 6px 18px rgba(127,99,21,0.05);
```

**Shadows are always warm.** The tint is `rgba(127, 99, 21, …)` — amber-black,
never cool gray — and the offset is to the **lower-left** (negative X), as if
lit by late-afternoon sun from the right. Never use a cool or symmetric drop
shadow.

**Focus ring.** `0 0 0 3px {colors.accent-soft}` plus a `2px` solid accent
outline at `2px` offset. Visible on every interactive element — keyboard
operability is a P0 of this product.

## Shapes

**Near-zero radius is the identity.** The contrast between soft warm color and
hard architectural geometry is deliberate.

- `{rounded.sm}` / `{rounded.md}` `2px` — every standard element: buttons,
  inputs, chips, cards, nodes, badges, menu rows. (sm and md are intentionally
  equal — there is no mid-rounding tier.)
- `{rounded.lg}` `4px` — large containers only: panels, product windows, the
  greeting hero, device frames.
- `{rounded.full}` `9999px` — pills exclusively: status capsules, count chips,
  live presence dots, the active-nav indicator bar.

No element rounds more than 4px except true pills. No `border-radius` on hero
imagery or section bands. **Never** soften the geometry to "feel friendlier" —
sharpness is the point.

Iconography is line-based (1.6–1.8 stroke, `currentColor`), sized 11–18px to
match its text. The brand mark is a **3×3 pixel mosaic** (`.mark`), a 24px grid
of nine 0.5px-rounded squares stepping amber → orange → burnt-orange.

## Components

All variants follow `name` / `name-hover` / `name-active`. Padding/typography
reference the scales above.

**Buttons.** The default primary is **dark, warming on hover** — calm at rest.
- `{components.button-primary}` — `{colors.fg}` bg, white text; hover →
  `{colors.accent}`. The main CTA.
- `{components.button-secondary}` — `{colors.surface}` bg + `{colors.border}`;
  hover strengthens the border to `{colors.line-strong}`.
- `{components.button-accent}` — solid `{colors.accent}`; hover →
  `{colors.accent-hover}`. For in-app "go" affordances where dark would be too
  heavy.
- `{components.button-line}` — `{colors.panel}` bg + border; hover → `fg`
  border. The quiet utility button in dense UI.
- `{components.button-sm}` — `9–14px` padding, `{typography.body-sm}`.
- All press with a `translateY(0.5–1px)` nudge; `2px` corners; no shadow.

**Panels & cards.** `{components.panel}` (white, `{rounded.lg}`, hairline
border) is the base data container; its header is a `{spacing.md}/{spacing.lg}`
padded row with a bottom border and a mono count. `{components.card}` is the
tighter `{rounded.sm}` unit used in rails and lists. Agent/PR cards tint their
**border** by status (`color-mix(success/warn/danger into border)`) rather than
their fill, so a busy fleet stays legible.

**Status — the load-bearing rule.** Every agent, PR, and pipeline state is a
pill that pairs **color + icon/shape + text label**, so it survives color-blind
viewing and grayscale print:
- `{components.status-run}` — success, with animated equalizer bars (presence).
- `{components.status-blocked}` — warn, with a "pause" glyph.
- `{components.status-failed}` — danger, with an alert glyph.
- `{components.status-idle}` — muted, neutral fill.
Live "running" presence uses 2px equalizer bars or a pinging dot; both have a
full reduced-motion fallback (bars settle at 70% height, ping stops) — never a
blank surface.

**Inputs.** `{components.input}` (white, hairline, `2px`) → `{components.input-focus}`
swaps the border to accent and adds the focus ring. Segmented controls and tabs
use the same vocabulary; the selected tab is a **dark** `{colors.fg}` fill with
white text. Inline validation recolors the border to accent and tints the field
`accent-soft` — never a separate red error chrome.

**Navigation.** Sticky frosted bar (marketing) or `248px` rail (app). Active nav
item = white `{components.panel}` chip with a `3px` accent indicator bar on its
left edge. Brand lockup = `.mark` mosaic + wordmark.

**Supporting:** `{components.badge}` (mono, uppercase, surface fill),
`{components.eyebrow}` (mono label + accent rule), `{components.kbd}` (mono key
caps), search field with `⌘K` hint, count chips (mono on `hover-strong`),
right-drawer + scrim (golden-float), bottom-center toast (dark, golden-float),
dropdown menus/popovers (white, golden-float), and DAG nodes/edges for pipelines
(2px nodes, `line-strong` arrowed edges, failed node tinted `danger-soft`).

**Distinctive brand components.**
- **Block mosaic (`.mark`).** The 3×3 amber→burnt-orange logo grid. The one
  place the full sunshine scale appears at small size.
- **Golden-hour horizon.** A faint Swiss-Alps ridge + lake + low sun rendered
  in SVG at the bottom of heroes, masked to ~40–50% opacity. This is the *one
  warm brand moment per page* — and the hook for **subtle, us-controlled
  regional cues** (a Zürich lake-and-Alps silhouette for a Swiss session, an
  atom motif for a Belgian one) without ever becoming a page wash.
- **Sunset CTA.** A dark band (`{colors.fg}` base) with a top-left radial of
  `sunshine-700`, fading to black — the page literally sets like the sun at the
  final call to action.
- **Product window.** A faithful slice of the live dashboard inside a
  traffic-light titlebar, on golden-float — used as the hero visual instead of a
  stock screenshot.

## Do's and Don'ts

**Do**
- Keep the canvas near-white (`{colors.bg}`) and let **black** (`{colors.fg}`)
  be the structural color; reserve white (`{colors.panel}`) for data surfaces.
- Confine all warm gold to **bounded graphics** — mosaic, horizon, CTA sunset.
- Ration `{colors.accent}` to **two uses per screen**; default primary buttons
  to dark and let orange arrive on hover.
- Pair every status color with an icon/shape **and** a text label.
- Keep one family at **weight 400**; build hierarchy from size and color.
- Hold corners at `2px` (`4px` for large panels, pills excepted).
- Make warm, lower-left, amber-tinted shadows — and only on floating surfaces.
- Set numerics, IDs, counts, and timestamps in mono with tabular figures.
- Ship a real reduced-motion path for every animated/presence element.
- Keep the `2px` accent focus ring visible on every interactive element.

**Don't**
- Don't use ivory/cream (`#fffaeb` / `#fff0c2`) as a full-bleed surface — that's
  the "ugly yellow" the derived layer exists to fix.
- Don't use pure `#000`, cool grays, or cool/symmetric drop shadows.
- Don't introduce blue/green/purple, or any cool gradient.
- Don't add a bold weight or a second display typeface.
- Don't round corners to feel friendlier, or add radius to hero imagery.
- Don't let color be the only carrier of meaning (status, validation, diffs).
- Don't lead the block mosaic with yellow — keep it orange-dominant.
- Don't spend the accent on decoration; it is a signal, not a highlight.
- Don't expose designer/demo chrome (viewport toggles, theme knobs, target
  badges) inside product UI.
