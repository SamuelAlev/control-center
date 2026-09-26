---
name: impeccable
description: Design, redesign, critique, audit, and polish frontend UI for this Flutter app or Astro site. Use for visual hierarchy, accessibility, typography, responsive layouts, motion, UX copy, and design-system work.
version: 3.5.0
user-invocable: true
argument-hint: "[craft|shape|audit|critique|animate|bolder|colorize|delight|layout|overdrive|quieter|typeset|adapt|clarify|distill|harden|onboard|optimize|polish|init|document|extract|live] [target]"
license: Apache 2.0
---

# Impeccable

## Start

1. Run `node .agents/skills/impeccable/scripts/context.mjs` once per session; follow its output. If it reports `NO_PRODUCT_MD`, complete [init](reference/init.md) before continuing. If it reports `UPDATE_AVAILABLE`, ask once about updating but do not block the task. Preserve existing PRODUCT.md and DESIGN.md decisions.
2. Read the reference for an invoked or clearly intended command. It owns that command's flow and any user approval gates. Read an existing component/theme file before changing UI.
3. For marketing, landing, portfolio, and long-form pages, read [brand](reference/brand.md); for app UI, dashboard, and tools, read [product](reference/product.md). Decide from the task and surface before falling back to PRODUCT.md register.
4. Only in a new project without established brand colors, run `node .agents/skills/impeccable/scripts/palette.mjs`. Existing tokens take precedence. Use the project's actual platform and components rather than introducing a parallel style system.

## Working rules

- Ship complete, functional UI and inspect the rendered result at relevant widths and states. Preserve real content, navigation, keyboard/focus behavior and error/empty/loading states.
- Verify text contrast (4.5:1 body, 3:1 large text), readable line length and wrapping, and reduced-motion alternatives. Do not gate visible content on a scroll reveal. Avoid clipping overlays within scrolling containers.
- Pick typography, spacing, color strategy, and motion from the product context. Avoid reflexive gradient text, decorative glass, identical card grids, colored side stripes, eyebrow labels on every section, fake metrics, generic copy, and placeholder imagery. Neither warm-neutral nor dark mode is a default. See the register references for specific critique criteria.
- Prefer clear button labels and self-contained link text. Avoid stock marketing phrasing. Visual style must not override established design tokens or accessibility.

## Command references

| Command | Purpose |
| --- | --- |
| [craft](reference/craft.md), [shape](reference/shape.md) | Design and build; confirm direction at the gates specified by the reference |
| [init](reference/init.md), [document](reference/document.md), [extract](reference/extract.md) | Project context, existing design system, reusable patterns |
| [critique](reference/critique.md), [audit](reference/audit.md), [polish](reference/polish.md) | Review, technical assessment, targeted remediation |
| [bolder](reference/bolder.md), [quieter](reference/quieter.md), [distill](reference/distill.md) | Adjust design intensity and complexity |
| [harden](reference/harden.md), [onboard](reference/onboard.md) | Edge cases and first-run flows |
| [animate](reference/animate.md), [colorize](reference/colorize.md), [typeset](reference/typeset.md), [layout](reference/layout.md), [delight](reference/delight.md), [overdrive](reference/overdrive.md) | Focused visual changes |
| [clarify](reference/clarify.md), [adapt](reference/adapt.md), [optimize](reference/optimize.md) | Copy, device adaptation, performance |
| [live](reference/live.md) | In-browser variant workflow and its cleanup protocol |

For a bare `/impeccable` invocation with no command or target, run `node .agents/skills/impeccable/scripts/context-signals.mjs`; if it returns scan targets, run `node .agents/skills/impeccable/scripts/detect.mjs --json <targets>` (unless unavailable). Recommend 2–3 relevant commands with reasons; do not run one without user direction. A clear command or intent routes to its reference; otherwise work from the general rules and the user's requested surface. For `craft`, [craft.md](reference/craft.md) controls its user gates. `teach` maps to `init` for existing invocations.

To create or remove a standalone command shortcut, run `node .agents/skills/impeccable/scripts/pin.mjs <pin|unpin> <command>`; these shortcuts are not separate design skills.
