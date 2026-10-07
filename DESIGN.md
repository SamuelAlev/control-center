---
version: alpha
name: Control Center
description: >-
  Near-white, ink-structured operator UI with bounded warm graphics, square
  geometry, light/dark themes and status conveyed beyond color.

# Light-theme ARGB values. Runtime light/dark tokens live in packages/cc_ui/lib/src/tokens/.
colors:
  # Surface ladder, near-white canvas, warm-neutral surface, pure-white data
  bg: "#fcfbf9" # canvas, the true page background (gray50)
  surface: "#f2f0e9" # warm-neutral, secondary buttons, soft chips (gray100)
  panel: "#ffffff" # pure white, the contrast / data surface
  sidebar: "#f7f5f0" # faint neutral rail (app shell)
  rail: "#faf9f5" # group-header rail inside panels

  # Foreground, Ink black, never pure #000; warm-tinted neutrals only
  fg: "#1f1f1f" # primary text + dark button / footer surface (gray900)
  muted: "#3d3d3d" # secondary text, metadata (gray600)
  placeholder: "#726c5e" # placeholder / quaternary text — clears 4.5:1 on all surfaces (gray500 #8c8578 is sub-AA)
  idle: "#1f1f1f61" # fg @ 38%, disabled ONLY (WCAG-exempt), faint dots

  # Borders, warm-neutral hairlines so panels never read yellow
  border: "#e8e5dc" # default hairline (gray200)
  border-soft: "#efece4" # softest hairline
  line-strong: "#1f1f1f29" # fg @ 16%, DAG edges, dividers that must show
  hover: "#1f1f1f0d" # fg @ 5%, row / nav hover wash
  hover-strong: "#1f1f1f14" # fg @ 8%, count chips, pressed states

  # Functional orange; bright #fa500f is for decorative brand graphics only.
  accent: "#b0370c" # Signal orange (functional), used <= twice/screen; white on it = 6.2:1
  accent-on: "#ffffff" # text/icon on accent
  accent-hover: "#c03e0f" # hover warm-up (brand800), white = 5.3:1
  accent-active: "#a6360c" # pressed (brand900), white = 6.7:1
  accent-soft: "#b0370c1f" # accent @ 12%, tinted backgrounds, active chips

  # Status, distinguishable from the warm palette; always paired w/ a shape.
  # `success`/`warn`/`danger` are the dot/border hues (>=3:1 non-text); colored
  # STATUS TEXT uses the darker text-* tokens (green700/yellow800/red700) so it
  # clears 4.5:1 on its own soft tint.
  success: "#17a34a"
  success-soft: "#17a34a24" # success @ 14%
  warn: "#b8780a" # gold — clears the 3:1 non-text floor on canvas (bright yellow #eab308 is 1.9:1)
  warn-soft: "#b8780a33" # warn @ 20%
  danger: "#dc2626"
  danger-soft: "#dc26261f" # danger @ 12%

  # Sunshine scale, reserved for the bounded golden-hour brand graphics only
  sunshine-900: "#ff8a00"
  sunshine-700: "#ffa110"
  sunshine-500: "#ffb83e"
  sunshine-300: "#ffd06a"
  bright-yellow: "#ffd900"
  block-edge: "#c03e0f" # burnt-orange terminus of the brand-mark gradient

# Manrope UI/body, Fira Code machine values. Script companions load for active locale.
# Web-only weight mapping compensates for lighter Flutter rasterization.
typography:
  display-hero:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "40px"
    fontWeight: 600
    lineHeight: 1.15
  display:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "28px"
    fontWeight: 600
    lineHeight: 1.286 # 36/28
  title:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.333 # 24/18
  body:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.429 # 20/14
    letterSpacing: "0.16px"
  body-sm:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.385 # 18/13
    letterSpacing: "0.16px"
  caption:
    fontFamily: "Manrope, ui-sans-serif, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.333 # 16/12
    letterSpacing: "0.32px"
  label:
    fontFamily: '"Fira Code", ui-monospace, "SF Mono", Menlo, Consolas, monospace'
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.333 # 16/12
    letterSpacing: "0.6px"
    fontFeature: '"tnum" 1' # tabular numerals (mono lane only)
    # rendered text-transform: uppercase (eyebrows, nav labels, status)
  mono-num:
    fontFamily: '"Fira Code", ui-monospace, "SF Mono", Menlo, Consolas, monospace'
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.385 # 18/13
    fontFeature: '"tnum" 1' # tabular numerals (mono lane only)

# ── ROUNDED ───────────────────────────────────────────────────────────────
# Zero is the dominant radius. Squared geometry vs. warm color is the tension.
rounded:
  sm: "0px" # all standard elements, buttons, inputs, chips, cards (xs/sm/md all = 0)
  md: "0px" # intentionally equal to sm; no mid rounding
  pill: "9999px" # pills + status capsules + live dots ONLY

# AppSpacing productive scale: 2/4/8/12/16/24/32/48.
spacing:
  xxs: "2px" # step-01 — hairline gaps
  xs: "4px" # step-02 — tight gaps
  sm: "8px" # step-03 — default small gap
  md: "12px" # step-04 — gap between controls
  lg: "16px" # step-05 — gap between groups
  xl: "24px" # step-06 — section padding
  xxl: "32px" # step-07 — between major sections
  xxxl: "48px" # step-09 — page-level breathing room

# Component token references use {section.token} notation.
components:
  # Buttons: 32/40/48px, default 40px matching fields.
  button-primary:
    backgroundColor: "{colors.fg}"
    textColor: "{colors.accent-on}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.sm}"
    padding: "0 16px"
  button-primary-hover:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.accent-on}"
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.fg}"
    rounded: "{rounded.sm}"
    padding: "0 16px"
  button-accent:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.accent-on}"
    rounded: "{rounded.sm}"
    padding: "0 16px"
  button-accent-hover:
    backgroundColor: "{colors.accent-hover}"
  button-line:
    backgroundColor: "{colors.panel}"
    textColor: "{colors.fg}"
    rounded: "{rounded.sm}"
    padding: "0 16px"
  button-sm:
    typography: "{typography.body-sm}"
    padding: "0 12px"
  panel:
    backgroundColor: "{colors.panel}"
    rounded: "{rounded.sm}"
  card:
    backgroundColor: "{colors.panel}"
    rounded: "{rounded.sm}"
    padding: "11px 12px"
  # Filled field, resting bottom underline; focus/error outlines do not shift layout.
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.fg}"
    rounded: "{rounded.sm}"
    padding: "10px 12px"
    typography: "{typography.body-sm}"
  status-run:
    backgroundColor: "{colors.success-soft}"
    textColor: "{colors.success}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "3px 8px"
  status-blocked:
    backgroundColor: "{colors.warn-soft}"
    textColor: "{colors.warn}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "3px 8px"
  status-failed:
    backgroundColor: "{colors.danger-soft}"
    textColor: "{colors.danger}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "3px 8px"
  status-idle:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.muted}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "3px 8px"
  badge:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.idle}"
    typography: "{typography.label}"
    rounded: "{rounded.sm}"
    padding: "3px 8px"
  kbd:
    backgroundColor: "{colors.bg}"
    textColor: "{colors.muted}"
    typography: "{typography.label}"
    rounded: "{rounded.sm}"
    padding: "1px 5px"
---

# Control Center design system

This is the visual contract for the client and site. [PRODUCT.md](PRODUCT.md) owns product direction; [ARCH.md](ARCH.md) owns implementation boundaries. The YAML above records light-theme design values; `packages/cc_ui/lib/src/tokens/` is the runtime source of truth, including dark-theme values. Read tokens through `context.designSystem`, not copied hex values. Review components in `apps/cc_gallery` in both themes before changing them.

## Color and contrast

- Near-white `{colors.bg}` is the canvas; warm-neutral `{colors.surface}` is for controls, pure-white `{colors.panel}` for data surfaces, ink `{colors.fg}` for structure. No full-page cream, pure-black text or cool-gray shadows.
- Functional orange `{colors.accent}` is limited to at most two elements per screen. Primary buttons rest in ink and warm to orange on hover. Bright orange and the sunshine scale belong only to bounded brand graphics (mark, horizon, sunset CTA), never body text or page backgrounds. Keep the logo gradient orange-led; a yellow-led small mark reads incorrectly.
- Choose colors by role, not raw hue. Derive translucent hover, selected and status fills from their base token in code; do not create unrelated state hues. Light and dark themes retain token names, with dark canvas near `#171614` and accent `#fb6224`.
- Body and essential text target 7:1 contrast; 4.5:1 for small text and 3:1 for large text and non-text are hard minimums. Use `{colors.muted}` for meaningful secondary text; never use `{colors.idle}` for it. Check any placeholder pairing against 4.5:1 when the placeholder communicates information. Pair status color with a shape/icon **and** a text label. Validation likewise needs a message and glyph, not just a tinted field.

## Typography and geometry

- UI and prose use Manrope; machine values and labels use Fira Code with tabular figures. `CcFonts.ui`/`CcFonts.code` provide fonts; use `AppFonts.code*` when setting numerics. `tnum` belongs to the mono lane, **not** the ambient Material text theme; explicit `fontFeatures` replaces that lane's features, so carry `AppFonts.codeFontFeatures` when toggling ligatures.
- Semibold 600 is for short headings/labels, regular 400 for running text. Use the productive sizes in the frontmatter (40/28/18 display/title; 14/13/12 body/caption; 12 label, 13 mono). Flutter web compensates for lighter rendering by mapping 400→500 and 500→600 without creating another perceived hierarchy.
- Script companions (Sarabun Thai, Rubik Hebrew, IBM Plex Sans Arabic for Arabic/Persian/Urdu) load only for the active locale as package assets, not `fonts:` entries that fetch at web startup. CJK uses platform UI fonts. Do not add a second display family or 700 weight.
- Spacing follows `AppSpacing` (2 through 48px). Controls, fields, cards and panels have zero radius; pills and state capsules are the exceptions. On desktop, a ~248px sidebar collapses to ~64px with a fluid, independently scrolling content area. Phone controls need ≥44px touch targets and no hover-only action; avoid horizontal overflow at 360/390/430/768/1024/1280/1440/1920px.
- Use directional layout and glyph mirroring for RTL chrome. Code, diffs, terminals, paths and diagram canvases remain LTR.

## Surface, focus and motion

- Default separation is a 1px warm hairline. A subtle amber soft shadow is for hover/sticky chrome; the lower-left amber golden float is for genuinely floating dialogs, menus and toasts, not ordinary cards. Avoid cool, symmetric shadows.
- Sidebar row hover may reveal trailing actions; each action paints its active wash only when its own target is hovered, pressed or open.
- Every interactive element retains a 2px accent focus outline at 2px offset and a 3px soft-accent halo or an equally visible replacement. Inputs are ~40px filled wells with a bottom underline, and use a whole-field 2px outline on focus/error/warning without shifting layout.
- `CcMotion` uses fast 80ms (exit 60), moderate 160ms (exit 120), slow 240ms (exit 160); standard/emphasized easing has no bounce. Reduced motion drops travel/scale but preserves a short state-signaling fade. Running bars/dots settle or stop; content never waits for an entrance animation to become readable. Motion and color report real state, not decoration.
- Expand/collapse animates its height on pointer input: `CcMotion.moderate` in, its exit token out, `CcMotion.standard` easing (`CcCollapsible`, or `CcMotion.resolveToggle` for custom render code such as the diff sliver). A keyboard-triggered toggle (Enter/Space on a header, arrow keys, a shortcut) always snaps. Read the modality in the build the toggle triggers, not in the callback: a focused button hears Enter before `FocusModality` does.

## Component conventions

- Reuse `Cc*` widgets rather than styling new primitives. Buttons are 32/40/48px, with 40px matching fields; a full-width label aligns to start. A signed approve/destructive pair uses success/danger with white labels; an unsigned third action stays neutral, while ordinary Save/Create uses the ink primary, not green.
- Panels are square data containers; status may tint a card **border**, not its entire fill. Do not nest cards. A desktop navigation selection needs legible inverted badges and synchronized fill/ink transitions. Use `assets/logo_with_background.svg` for the square brand mark, `logo.svg`/`logo_white.svg` for the figure alone.
- Settings kit (`lib/features/settings/presentation/widgets/kit/`) uses `SettingsPage` → `SectionCard` → `SettingsGroup` → field/toggle/entity row. Open with `SettingsSummary` (3–5 state facts), disclose expert controls while badging overrides, filter lists beyond roughly eight entities, and show `SettingsSaveBar` only when edits need committing. `SettingsCopyField` handles selectable values and `SettingsKeyValueEditor` handles maps.
- Code fences and Mermaid diagrams share a square framed surface. Labeled blocks get a kind/action header; unlabeled fences put Copy in the body. Diagrams add source, fenced copy, expandable pan/zoom and generated text alternatives. Theme diagram strokes from tokens; categorical color needs adjacent text. Preserve shape semantics, and collapse diagrams taller than ~340px.

## Checks when designing

Use the gallery's component states and review light/dark, keyboard focus, reduced motion, screen readers and touch. Status, diff and validation meaning must survive grayscale. Distinction comes from visible ownership/state/actions, not decorative dashboards, repeated rounded grids or gradients.
