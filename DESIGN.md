---
version: alpha
name: Control Center
description: >-
  Design system for Control Center, a unified developer operations hub for a
  solo, multi-platform operator (desktop, web, phone). A near-white,
  ink-structured operator deck with a single orange signal and earned
  golden-hour warmth, kept to bounded graphics. Sharp 2px geometry, a
  near-single type weight, and every status carried by color paired with shape,
  never color alone. Dual light/dark theme.

# ── COLORS ────────────────────────────────────────────────────────────────
# Values are the LIGHT-theme resolved ARGB hexes used at runtime by cc_ui
# (packages/cc_ui/lib/src/tokens/). A full DARK theme exists with the same
# token names (see Colors → "Dual theme"). Alpha tokens (idle, line-strong,
# the *-soft set, hovers) are an opacity of a base token; both formula and
# resolved hex are documented in the Colors section.
colors:
  # Surface ladder, near-white canvas, warm-neutral surface, pure-white data
  bg: '#fcfbf9'            # canvas, the true page background (gray50)
  surface: '#f2f0e9'       # warm-neutral, secondary buttons, soft chips (gray100)
  panel: '#ffffff'         # pure white, the contrast / data surface
  sidebar: '#f7f5f0'       # faint neutral rail (app shell)
  rail: '#faf9f5'          # group-header rail inside panels

  # Foreground, Ink black, never pure #000; warm-tinted neutrals only
  fg: '#1f1f1f'            # primary text + dark button / footer surface (gray900)
  muted: '#3d3d3d'         # secondary text, metadata (gray600)
  placeholder: '#8c8578'   # placeholder / quaternary text only (gray500)
  idle: '#1f1f1f61'        # fg @ 38%, disabled, faint dots, tertiary meta

  # Borders, warm-neutral hairlines so panels never read yellow
  border: '#e8e5dc'        # default hairline (gray200)
  border-soft: '#efece4'   # softest hairline
  line-strong: '#1f1f1f29' # fg @ 16%, DAG edges, dividers that must show
  hover: '#1f1f1f0d'       # fg @ 5%, row / nav hover wash
  hover-strong: '#1f1f1f14' # fg @ 8%, count chips, pressed states

  # Accent, the single orange signal fire
  accent: '#fa520f'        # Signal orange, primary signal, used <= twice/screen (brand600)
  accent-on: '#ffffff'     # text/icon on accent
  accent-hover: '#fb6424'  # Flame, hover/active warm-up (brand500)
  accent-active: '#dc480d' # Burnt orange, pressed (brand700)
  accent-soft: '#fa520f1f' # accent @ 12%, tinted backgrounds, active chips

  # Status, distinguishable from the warm palette; always paired w/ a shape
  success: '#17a34a'
  success-soft: '#17a34a24' # success @ 14%
  warn: '#eab308'
  warn-soft: '#eab30833'    # warn @ 20%
  danger: '#dc2626'
  danger-soft: '#dc26261f'  # danger @ 12%

  # Sunshine scale, reserved for the bounded golden-hour brand graphics only
  sunshine-900: '#ff8a00'
  sunshine-700: '#ffa110'
  sunshine-500: '#ffb83e'
  sunshine-300: '#ffd06a'
  bright-yellow: '#ffd900'
  block-edge: '#c0400f'    # burnt-orange terminus of the block mosaic

# ── TYPOGRAPHY ────────────────────────────────────────────────────────────
# One family (Manrope) for UI/body, one (Fira Code) for mono. Weight 400
# throughout; the SOLE exception is the mono `label` eyebrow at 500. These are
# the real cc_ui CcTypography sizes, a dense product scale, not a marketing
# billboard scale. Hierarchy is size + color, not bold.
typography:
  display-hero:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '40px'
    fontWeight: 400
    lineHeight: 1.1
  display:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '28px'
    fontWeight: 400
    lineHeight: 1.2
  title:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '18px'
    fontWeight: 400
    lineHeight: 1.35
  body:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '14px'
    fontWeight: 400
    lineHeight: 1.5
  body-sm:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '13px'
    fontWeight: 400
    lineHeight: 1.45
  caption:
    fontFamily: 'Manrope, ui-sans-serif, system-ui, sans-serif'
    fontSize: '12px'
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: '"Fira Code", ui-monospace, "SF Mono", Menlo, Consolas, monospace'
    fontSize: '12px'
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: '0.6px'
    # rendered text-transform: uppercase (eyebrows, nav labels, status)
  mono-num:
    fontFamily: '"Fira Code", ui-monospace, "SF Mono", Menlo, Consolas, monospace'
    fontSize: '13px'
    fontWeight: 400
    lineHeight: 1.4
    fontFeature: '"tnum" 1'   # tabular-nums for counts, diffs, IDs, timestamps

# ── ROUNDED ───────────────────────────────────────────────────────────────
# Near-zero is the dominant radius. Sharp geometry vs. warm color is the tension.
rounded:
  sm: '2px'     # all standard elements, buttons, inputs, chips, cards (xs/sm/md all = 2px)
  md: '2px'     # intentionally equal to sm; no mid rounding
  lg: '4px'     # large containers / panels / device windows only (lg/xl = 4px)
  pill: '9999px' # pills + status capsules + live dots ONLY

# ── SPACING ───────────────────────────────────────────────────────────────
# 4px base unit (2px hairline floor). Keys mirror cc_ui AppSpacing exactly.
spacing:
  xxs: '2px'    # hairline gaps
  xs: '4px'     # tight gaps
  sm: '8px'     # default small gap
  md: '12px'    # gap between controls
  lg: '16px'    # gap between groups
  xl: '24px'    # section padding
  xxl: '32px'   # between major sections
  xxxl: '48px'  # page-level breathing room

# ── COMPONENTS ────────────────────────────────────────────────────────────
# Variants use related names (button-primary / -hover / -active). Token refs
# use dot-notation: {colors.fg}, {typography.body}, {rounded.sm}, {spacing.md}.
# Borders/shadows/focus rings live in prose + the .impeccable/design.json
# sidecar (Stitch component schema holds only 8 props).
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
    rounded: '{rounded.sm}'
    padding: '12px 18px'
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
    rounded: '{rounded.sm}'
    padding: '9px 16px'
  button-sm:
    typography: '{typography.body-sm}'
    padding: '9px 14px'
  panel:
    backgroundColor: '{colors.panel}'
    rounded: '{rounded.lg}'
  card:
    backgroundColor: '{colors.panel}'
    rounded: '{rounded.sm}'
    padding: '11px 12px'
  input:
    backgroundColor: '{colors.panel}'
    textColor: '{colors.fg}'
    rounded: '{rounded.sm}'
    padding: '9px 12px'
    typography: '{typography.body-sm}'
  status-run:
    backgroundColor: '{colors.success-soft}'
    textColor: '{colors.success}'
    typography: '{typography.label}'
    rounded: '{rounded.pill}'
    padding: '3px 8px'
  status-blocked:
    backgroundColor: '{colors.warn-soft}'
    textColor: '{colors.warn}'
    typography: '{typography.label}'
    rounded: '{rounded.pill}'
    padding: '3px 8px'
  status-failed:
    backgroundColor: '{colors.danger-soft}'
    textColor: '{colors.danger}'
    typography: '{typography.label}'
    rounded: '{rounded.pill}'
    padding: '3px 8px'
  status-idle:
    backgroundColor: '{colors.surface}'
    textColor: '{colors.muted}'
    typography: '{typography.label}'
    rounded: '{rounded.pill}'
    padding: '3px 8px'
  badge:
    backgroundColor: '{colors.surface}'
    textColor: '{colors.idle}'
    typography: '{typography.label}'
    rounded: '{rounded.sm}'
    padding: '3px 8px'
  kbd:
    backgroundColor: '{colors.bg}'
    textColor: '{colors.muted}'
    typography: '{typography.label}'
    rounded: '{rounded.sm}'
    padding: '1px 5px'
---

# Control Center Design System

## 1. Overview

**Creative North Star: "The Golden-Hour Deck."**

Control Center is the operator deck for a one-person developer operations hub: a single technical operator running many concurrent streams of work (coding agents on isolated worktrees, a meeting recording, a calendar filling up, PRs to review, feeds and conversations updating) and holding all of it in view at once. The interface has to do something most product UI doesn't: sit open all day next to real work, report live machine state honestly across every pillar, and never shout. The personality is **alive, warm, confident**: alive because the surface reports real work as it happens, warm in the Anthropic register (intelligent, on-your-side, never cold or corporate), confident because it is direct and technical with no hype.

The visual roots are golden-amber warmth, sharp architectural geometry, and one near-single type weight, but tuned for a deck, not a billboard. A pure marketing treatment would flood the canvas with ivory and cream; on an operator deck that reads as "ugly yellow" and fights the data. So the canvas is **near-white with ink-black as the structural color**, the warm gold is **confined to bounded graphics** (the 3×3 logo mosaic, one golden-hour horizon, the dark sunset CTA), and the single orange signal is **rationed to at most twice per screen**. Warmth is a moment you earn at a threshold, not a wash you apply everywhere. This is how the system reads warm and confident while staying quiet and dense for ten-hours-a-day use.

This system explicitly rejects two looks. It is **not a generic SaaS dashboard**. No gradient hero-metric cards, no identical rounded card grids marching down a page, no decorative charts, no purple gradients. And it is **not the default component-kit / template look**. Distinction comes from making the underlying model legible (an agent thinking vs. blocked, a meeting recording, a conversation threading a PR), never from decoration. Density is welcome; density *without hierarchy* is not.

**Key Characteristics:**
- **Near-white canvas, ink-black structure, one rationed orange signal.** Black does the structural work; orange is a signal, not a highlight.
- **Earned warmth.** Golden-hour gold lives only in bounded brand graphics and the amber elevation shadows, never as a page wash.
- **Sharp 2px geometry.** Near-zero radius everywhere (4px on large panels, pills excepted). The tension between soft warm color and hard geometry is the identity.
- **One family, near-one weight.** Manrope (UI/body) + Fira Code (mono). Weight 400 throughout; the one exception is the mono eyebrow label at 500. Hierarchy is size + color, never bold.
- **Presence over decoration.** Motion and color report real state (running / blocked / failed / recording / syncing) or they are cut. Every animated element has a reduced-motion path.
- **Status is never color alone.** Every state pairs a color with an icon/shape and a text label.
- **Dual theme.** A full light and dark theme ship from the same token names; design for both.
- **Multi-platform, one operation.** The same system serves a dense keyboard-driven desktop deck, a web thin client, and a touch-first phone remote. No surface is a degraded afterthought.

**Layout & density.** The desktop app shell is a two-column grid: a ~248px sidebar rail + a fluid, independently scrollable main column, under a ~48px frosted top bar (`backdrop-filter: blur`); content caps around 1080px inside the canvas. The sidebar collapses to a ~64px icon rail on narrow widths. Spacing rides the 4px base scale (`{spacing.xxs}` 2px → `{spacing.xxxl}` 48px); bold declarations earn their own breathing room and the empty space is *near-white*, not stark, so it still reads warm. On the **phone remote**, the same content must stay operable touch-first: ≥44px targets, no hover-only affordances, gestures that degrade gracefully. Verify no horizontal scroll across the modern range (360 / 390 / 430 / 768 / 1024 / 1280 / 1440 / 1920).

## 2. Colors

A four-rung surface ladder, a warm-neutral text/border set, one accent, three status hues, and a sunshine scale reserved for brand graphics.

### Primary
- **Signal Orange** (`{colors.accent}` `#fa520f`): the single highest-signal color. Budget **at most twice per screen** (typically an eyebrow rule + the primary CTA, or one active-nav indicator + one link-arrow hover). Note the deliberate inversion: primary buttons are **ink-black, not orange**. Orange appears on *hover*, so the page rests calm and warms on intent. Warm-up states: **Flame** (`{colors.accent-hover}` `#fb6424`), **Burnt orange** pressed (`{colors.accent-active}` `#dc480d`), and `{colors.accent-soft}` (accent @ 12%) for tinted active chips. `{colors.accent-on}` `#ffffff` is the only text/icon color placed on accent.

### Secondary (status)
- **Success** (`{colors.success}` `#17a34a`), **Warn** (`{colors.warn}` `#eab308`), **Danger** (`{colors.danger}` `#dc2626`), each with a `*-soft` tint (`success-soft` @ 14%, `warn-soft` @ 20%, `danger-soft` @ 12%) for pill backgrounds. Tuned to stay distinguishable from the warm palette. **Color is never the only signal**. See Components → Status.

### Tertiary (brand sunshine, bounded graphics ONLY)
- The golden-hour scale: `{colors.sunshine-900}` `#ff8a00` → `{colors.sunshine-700}` `#ffa110` → `{colors.sunshine-500}` `#ffb83e` → `{colors.sunshine-300}` `#ffd06a` → `{colors.bright-yellow}` `#ffd900`, terminating in `{colors.block-edge}` `#c0400f`. Appears only in the logo mosaic, the horizon flourish, and the CTA sunset. Never as text, never as a page background.

### Neutral
- **Canvas** (`{colors.bg}` `#fcfbf9`): the page background, near-white, barely warm. Never pure white, never ivory/cream as a full bleed.
- **Surface** (`{colors.surface}` `#f2f0e9`): secondary buttons, soft chips, inert fills.
- **Panel** (`{colors.panel}` `#ffffff`): pure white, **only** for data surfaces (cards, panels, product windows, popovers). White earns attention here because the page around it isn't white.
- **Sidebar / Rail** (`{colors.sidebar}` `#f7f5f0`, `{colors.rail}` `#faf9f5`): faint neutral rails in the app shell.
- **Ink black** (`{colors.fg}` `#1f1f1f`): primary text, dark buttons, the sunset CTA base. Never `#000000`.
- **Muted** (`{colors.muted}` `#3d3d3d`): secondary text and metadata, clears AAA on the canvas.
- **Placeholder** (`{colors.placeholder}` `#8c8578`) and **Idle** (`{colors.idle}`, fg @ 38%): the lightest tier, placeholder input text and disabled/tertiary meta only.
- **Borders**: `{colors.border}` `#e8e5dc` / `{colors.border-soft}` `#efece4` (warm-neutral hairlines so panels stop reading yellow); `{colors.line-strong}` (fg @ 16%) for dividers and DAG edges that must show; `{colors.hover}` / `{colors.hover-strong}` (fg @ 5% / 8%) for row washes.

### Dual theme
A full **dark theme** ships under the same token names (`DesignSystemTokens.light()` / `.dark()`): canvas → warm near-black `#171614`, panel → `#1f1f1f`, fg → near-white, and the accent shifts to **Flame** (`#fb6424`) so orange stays legible on dark surfaces. Design and review in both; the `cc_gallery` theme addon toggles them side by side.

### Named Rules
**The One Voice Rule.** `{colors.accent}` appears on ≤2 elements per screen. Its rarity is the signal; spend it on the one thing that matters next, never on decoration.

**The Earned-Warmth Rule.** All warm gold is confined to bounded graphics (mosaic, horizon, sunset CTA) and the amber elevation shadows. Gold is never a text color and never a page background.

**The Contrast Rule (AAA where feasible, AA is the floor).** Body and essential text target **7:1 (AAA)**; `{colors.fg}` (~14:1) and `{colors.muted}` (~9:1) on the canvas clear it comfortably and are the defaults. AA (4.5:1) is the *minimum*, never the target. The lightest grays, `{colors.placeholder}` (~3.3:1) and `{colors.idle}`, clear only the disabled-state bar; never carry meaningful text in them. Promote any hint or label that must be read to `{colors.muted}`.

**The Derivation Contract.** Alpha tokens (`idle`, `line-strong`, `accent-soft`, the `*-soft` set, hovers) are an opacity of a base token, `idle` = fg @ 38%, `accent-soft` = accent @ 12%, etc. Keep the relationship in code (Flutter `Color.withValues` / web `color-mix(... in oklab)`) so a base-color change propagates. The block mosaic gradient is orange-dominant (never yellow-led, or the small logo reads as a lemon square): `linear-gradient(135deg, #ffb83e 0%, #ff8105 34%, #fa520f 70%, #c0400f 100%)`.

## 3. Typography

**Display / Body Font:** Manrope (with `ui-sans-serif, system-ui, sans-serif`)
**Label / Mono Font:** Fira Code (with `ui-monospace, "SF Mono", Menlo, Consolas, monospace`)

**Character:** A warm grotesque (Manrope) carries everything human-readable; a structural monospace (Fira Code) carries everything machine: counts, IDs, diffs, timestamps, and uppercase labels. The pairing reads as "considered, technical, honest." Both are bundled as host assets by `cc_ui` and resolved via `CcFonts.ui` / `CcFonts.code`. Never pass a raw family string.

### Hierarchy
- **Display Hero** (Manrope 400, 40px, line-height 1.1): earned brand moments only, onboarding, the dashboard greeting deck. The ceiling of the app scale.
- **Display** (Manrope 400, 28px, 1.2): top-of-screen headings, big statements.
- **Title** (Manrope 400, 18px, 1.35): section / card / feature titles.
- **Body** (Manrope 400, 14px, 1.5): standard body and prose. Cap measured text at 65–75ch.
- **Body Small** (Manrope 400, 13px, 1.45): dense UI text, control labels, buttons.
- **Caption** (Manrope 400, 12px, 1.4): metadata and secondary annotations.
- **Label** (Fira Code 500, 12px, 1.4, +0.6px tracking, UPPERCASE): eyebrows, nav labels, status pills. The system's signature label, and the one place a 500 weight is used.
- **Mono Num** (Fira Code 400, 13px, 1.4, tabular figures): anything countable, addressable, or time-stamped.

### Named Rules
**The One-Weight Rule.** Everything is Manrope 400, even Display Hero at 40px. Hierarchy comes from size and color, never bold. The sole 500 in the system is the mono `label` (its tracking and small size need the extra weight to read). Never introduce a 700, a second display family, or Inter/Roboto/Arial as a display face.

**The Machine-Truth Rule.** Anything countable, addressable, or time-stamped is Fira Code with tabular figures. Mono signals "this is machine truth," not decoration.

## 4. Elevation

Depth is rare and **warm**. Two levels only, plus the focus ring; structure is carried by hairline borders, not shadows.

- **Flat (Level 0).** No shadow. Page backgrounds, text blocks, inert chips, most of the UI. Surfaces separate by a `1px {colors.border}` hairline ring, not a drop shadow.
- **Soft (Level 0.5).** A subtle warm lift for hover on cards and sticky chrome that must read as slightly raised. `0 1px 2px rgba(127,99,21,0.05), -2px 6px 18px rgba(127,99,21,0.05)`.
- **Golden float (Level 1).** The signature multi-layer "golden hour" cascade, reserved for genuinely floating data surfaces: dialogs, popovers, drawers, toasts, the hero deck.

```
golden float:
  -8px  16px  39px rgba(127, 99, 21, 0.12),
  -28px 56px  64px rgba(127, 99, 21, 0.08),
  -64px 120px 88px rgba(127, 99, 21, 0.06);
```

### Named Rules
**The Warm-Shadow Rule.** Shadows are always amber-tinted (`rgba(127, 99, 21, …)`, never cool gray) and offset to the **lower-left** (negative X), as if lit by late-afternoon sun from the right. Never a cool, symmetric, or top-down drop shadow.

**The Borders-Not-Shadows Rule.** A surface separates with a hairline ring by default. Reach for a shadow only when something genuinely floats above the canvas.

**The Always-Visible-Focus Rule.** Every interactive element shows a focus ring: a 2px solid `{colors.accent}` outline at 2px offset plus a `0 0 0 3px {colors.accent-soft}` glow. Keyboard operability is a P0 of this product; never remove the ring without an equal replacement.

## 5. Components

35 `Cc*` widgets ship in `cc_ui`; document and reuse those rather than re-styling primitives. Variants follow `name` / `name-hover` / `name-active`. Read tokens via `context.designSystem`.

### Buttons
- **Shape:** sharp 2px corners (`{rounded.sm}`); a `translateY(0.5–1px)` press nudge; no shadow.
- **Primary** (`{components.button-primary}`): ink-black `{colors.fg}` fill, white text; hover warms to `{colors.accent}`. The main CTA, calm at rest, orange on intent.
- **Accent** (`{components.button-accent}`): solid `{colors.accent}`; hover → `{colors.accent-hover}`. For in-app "go" affordances where dark would feel too heavy.
- **Secondary** (`{components.button-secondary}`): `{colors.surface}` fill + `{colors.border}` hairline; hover strengthens the border to `{colors.line-strong}`.
- **Line** (`{components.button-line}`): `{colors.panel}` fill + border; hover → `{colors.fg}` border. The quiet utility button in dense UI.
- On the phone remote, button hit-targets expand to ≥44px regardless of visual size.

### Cards / Containers
- **Panel** (`{components.panel}`): white, `{rounded.lg}` (4px), hairline `{colors.border}` ring; header is a padded row with a bottom border and a mono count. The base data container.
- **Card** (`{components.card}`): tighter `{rounded.sm}` (2px) unit for rails and lists. Agent / PR cards tint their **border** by status (success / warn / danger mixed into the border), never their fill, so a busy fleet stays legible. Never nest a card inside a card.

### Inputs / Fields
- **Style** (`{components.input}`): white, hairline border, 2px corners, `{typography.body-sm}`.
- **Focus:** border swaps to `{colors.accent}` and adds the accent focus ring.
- **Validation:** recolor the border to accent and tint the field `{colors.accent-soft}`. Never a separate red error chrome. Selected tabs/segments use a **dark `{colors.fg}` fill with white text**, matching the primary-button logic.
- Placeholder text uses `{colors.placeholder}`; keep real hints in `{colors.muted}` (placeholder color is below the body-contrast floor).

### Status (the load-bearing rule)
Every agent, PR, pipeline, meeting, and sync state is a pill pairing **color + icon/shape + text label**, so it survives color-blind viewing and grayscale:
- `{components.status-run}`, success tint, with animated equalizer bars (live presence).
- `{components.status-blocked}`, warn tint, with a "pause" glyph.
- `{components.status-failed}`, danger tint, with an alert glyph.
- `{components.status-idle}`, muted, neutral fill.

Live "running" presence uses 2px equalizer bars or a pinging dot; both have a full reduced-motion fallback (bars settle at ~70% height, ping stops). Never a blank surface, never a reveal that fails to fire on a hidden tab.

### Navigation
- Desktop: a ~248px `CcSidebar` rail (collapses to a ~64px icon rail) under a frosted top bar. Active item = white panel chip with a 3px accent indicator bar on its left edge.
- Brand lockup = the `.mark` 3×3 mosaic + wordmark.

### Supporting
`{components.badge}` (mono uppercase, surface fill), eyebrow (mono label + accent rule), `{components.kbd}` (mono key caps), search field with a `⌘K` hint, count chips (mono on `{colors.hover-strong}`), right-drawer + scrim and bottom-center toast (both on golden float), dropdown menus / popovers (white, golden float), and DAG nodes/edges for pipelines (2px nodes, `{colors.line-strong}` arrowed edges, failed node tinted `{colors.danger-soft}`).

### Signature brand components
- **Block mosaic (`.mark`).** The 3×3 amber→burnt-orange logo grid, the one place the full sunshine scale appears at small size. Keep it orange-dominant.
- **Golden-hour horizon.** A faint ridge + lake + low sun in SVG at the bottom of a hero, masked to ~40–50% opacity. The *one* warm brand moment per page, and the hook for subtle, us-controlled regional cues. Never a page wash.
- **Sunset CTA.** A dark `{colors.fg}` band with a top-left radial of `{colors.sunshine-700}` fading to black, the page literally sets like the sun at the final call to action.
- **Product window.** A faithful slice of the live dashboard inside a traffic-light titlebar, on golden float, the hero visual instead of a stock screenshot.

### Motion
`CcMotion` tokens: `fast` 120ms (hover/press washes), `normal` 180ms (dropdown / popover / tooltip), `slow` 240ms (sidebar collapse, drawer). Easing: `standard` = ease-out, `emphasized` = ease-out-cubic (no bounce, no elastic). `CcMotion.resolve(context, …)` collapses every duration to zero under reduced motion. Motion must report real state, never animate for flourish.

### Implementation & gallery
This spec is shipped by **`cc_ui`** (`packages/cc_ui/`), a Material-/Cupertino-free system built on `flutter/widgets.dart`; read tokens via `context.designSystem`, never hardcode a value this document names.

| This spec | Code (`cc_ui`) |
|---|---|
| Colors (`{colors.*}`) | `DesignSystemTokens`, `canvas`/`surface`/`panel`/`fg`/`muted`/`accent`/`success`/`warn`/`danger`/… (`.light()` & `.dark()`). |
| Typography | `CcTypography`, `displayHero`/`display`/`title`/`body`/`bodySm`/`caption`/`label`/`monoNum`; families via `CcFonts`. |
| Spacing (4px base) | `AppSpacing`, `xxs`(2) → `xxxl`(48) + gap widgets. |
| Rounded (2px / 4px / pill) | `AppRadii`, 2px standard, 4px large, `pill` 999. |
| Elevation (warm amber shadows) | `AppShadows.golden` / `.soft`, `CcElevation` z-index scale. |
| Motion + reduced-motion | `CcMotion` (`fast`/`normal`/`slow`, `standard`/`emphasized`, `.resolve`). |
| Focus ring | `FocusRing` + `FocusModality` (keyboard-only `:focus-visible`). |
| Components | 35 `Cc*` widgets, `CcButton`, `CcSelect`, `CcCard`, `CcSidebar`, `CcDialog`, … |

The living reference is **`apps/cc_gallery`** (Widgetbook): interactive use-cases across Components and Foundations, with a Light/Dark theme toggle. Before designing or reviewing UI, open the gallery and read the relevant component's states; authoring a new component means adding its states as `@widgetbook.UseCase` builders there.

## 6. Do's and Don'ts

### Do:
- **Do** keep the canvas near-white (`{colors.bg}`) and let **ink-black** (`{colors.fg}`) be the structural color; reserve pure white (`{colors.panel}`) for data surfaces.
- **Do** confine all warm gold to **bounded graphics** (mosaic, horizon, sunset CTA) and amber elevation shadows.
- **Do** ration `{colors.accent}` to **two uses per screen**; default primary buttons to dark and let orange arrive on hover.
- **Do** pair every status with an icon/shape **and** a text label, never color alone.
- **Do** target **AAA contrast (7:1)** for body and essential text; keep `{colors.muted}` as the lightest color you trust for meaningful text, and AA (4.5:1) as the hard floor.
- **Do** keep one family at weight 400 (the mono `label` 500 is the only exception); build hierarchy from size and color.
- **Do** hold corners at 2px (4px for large panels; pills excepted).
- **Do** make warm, lower-left, amber-tinted shadows, and only on genuinely floating surfaces.
- **Do** set numerics, IDs, counts, and timestamps in mono with tabular figures.
- **Do** ship a real reduced-motion path for every animated/presence element, and keep the 2px accent focus ring visible on every interactive element.
- **Do** design every surface for its platform: dense + keyboard-first on desktop, ≥44px touch targets and no hover-only affordances on the phone remote, and verify both light and dark themes.

### Don't:
- **Don't** let any surface read as a **generic SaaS dashboard**. No gradient hero-metric cards, no identical rounded card grids repeated down a page, no decorative charts, no purple gradients.
- **Don't** ship the **default component-kit / template look**. Distinction comes from making the model (agents, meetings, conversations) legible, not from decoration.
- **Don't** use ivory/cream as a full-bleed surface. That's the "ugly yellow" the near-white canvas exists to fix.
- **Don't** use pure `#000`, cool grays, or cool/symmetric drop shadows.
- **Don't** introduce blue/green/purple chrome or any cool gradient (status hues excepted, and always shape-paired).
- **Don't** add a bold weight or a second display typeface.
- **Don't** carry meaningful text in `{colors.placeholder}` or `{colors.idle}`. They clear the disabled bar, not the 4.5:1 body bar.
- **Don't** round corners "to feel friendlier," or add radius to hero imagery; sharpness is the point.
- **Don't** spend the accent on decoration. It is a signal, not a highlight; and never lead the block mosaic with yellow.
- **Don't** nest a card inside a card, and don't let color be the only carrier of meaning (status, validation, diffs).
