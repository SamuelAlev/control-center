# cc_ui

The **Control Center design system** — tokens, theme, foundation primitives, and
components. It is the single source of every visual surface in the app: the app
owns each component outright.

A pub-workspace member of the Control Center monorepo. Its living, interactive
catalogue is the [`cc_gallery`](../../apps/cc_gallery) Widgetbook app; the visual
specification it implements is the repo-root [`DESIGN.md`](../../DESIGN.md).

## No Material, no Cupertino

Every public widget is built directly on `package:flutter/widgets.dart`. The
package imports **no** `flutter/material.dart` or `flutter/cupertino.dart` — and
no infrastructure (dio, drift, …). This purity is enforced by
`test/core/architecture_constraints_test.dart` in the host app (the
"cc_ui design-system package purity" and "UI vendor isolation" cases). It keeps
the design system honest: styling comes only from tokens, never an inherited
Material `ThemeData`.

Consume the whole API through the single barrel:

```dart
import 'package:cc_ui/cc_ui.dart';
```

Everything under `lib/src/` is private to the package.

## Theme

Wrap the app (or any subtree) in a `CcTheme`; components resolve their tokens
from the nearest ancestor via the `context.designSystem` extension:

```dart
CcTheme(
  data: CcThemeData.light(), // or CcThemeData.dark()
  child: Builder(
    builder: (context) {
      final t = context.designSystem!;        // DesignSystemTokens
      final mono = context.ccTheme?.monoFontFamily;
      return ColoredBox(color: t.canvas, child: ...);
    },
  ),
)
```

`CcThemeData.light()` / `.dark()` carry the resolved `DesignSystemTokens` plus
the app's font families. Read tokens through `context.designSystem`; never
hardcode a hex.

## Tokens

| Token class | What it holds |
|---|---|
| `DesignSystemTokens` | Every semantic color. Curated aliases (`canvas`, `surface`, `panel`, `sidebar`, `fg`, `muted`, `accent` + `accentHover/Active/Soft`, `success`, `warn`, `danger`, …) over the full role scale (`bg*`, `text*`, `fg*`, `border*` families). The warm near-white / ink-black / single-orange system. |
| `CcTypography` | The type scale: `displayHero`, `display`, `title`, `body`, `bodySm`, `caption`, `label` (the tracked eyebrow), `monoNum`. One UI weight (400); hierarchy is **size + color, never weight**. |
| `AppSpacing` | 8px-based step scale `xxs`(2) → `xxxl`(48), plus `hGap*` / `vGap*` gap widgets. |
| `AppRadii` | A deliberately small radius set — `brSm`/`brMd` = 2px (the dominant radius), `brLg`/`brXl` = 4px (cards/overlays), `pill` = 999. |
| `AppShadows` / `CcElevation` | Two shadows — `golden` (floating overlays) and `soft` (raised surfaces) — plus the overlay z-index scale (`tooltip` → `dialog`). |
| `CcMotion` | Durations `instant`/`fast`(120ms)/`normal`(180ms)/`slow`(240ms) and curves `standard`(easeOut)/`emphasized`(easeOutCubic). `CcMotion.resolve(context, d)` collapses to zero under the platform reduce-motion setting — the built-in accessible alternative. |
| `CcFonts` | Family resolution: `CcFonts.ui(...)` (Manrope) and `CcFonts.code(...)` (JetBrains Mono) via google_fonts. |

## What's inside

```
lib/src/
├── tokens/        # design_system_palette, design_system_tokens, app_spacing, app_radii, app_shadows
├── theme/         # cc_theme (CcTheme + CcThemeData + context.designSystem), cc_fonts
├── foundation/    # cc_typography, cc_motion, cc_elevation, cc_component_tokens, cc_tappable, cc_overlay_anchor
├── primitives/    # segmented_toggle, focus_ring, focus_modality (keyboard-only :focus-visible)
└── components/    # 30+ Cc* components (see below)
```

### Components

- **Buttons** — `CcButton` (6 variants × sizes × loading), `CcIconButton`
- **Inputs** — `CcTextField`, `CcTextArea`, `CcTextFormField`, `CcSelect`,
  `CcMultiSelect`, `CcAutocomplete`, `CcSwitch`, `CcCheckbox`, `CcRadio`
- **Feedback** — `CcBadge`, `CcAlert`, `CcSpinner`, `CcProgressBar`, `CcTooltip`,
  `CcToaster` (`CcToastScope`)
- **Containers** — `CcCard`, `CcTile`, `CcChip`, `CcAvatar`, `CcKbd`,
  `CcEmptyState`, `CcDivider`
- **Navigation & overlays** — `CcTabs`, `CcTabView`, `CcMenu`, `CcPopover`,
  `CcDialog`, `CcBreadcrumb`, `CcSidebar` (+ `CcSidebarGroup`, `CcSidebarItem`)
- **Layout** — `CcResizable`

Each is catalogued with every meaningful state in [`cc_gallery`](../../apps/cc_gallery).

## Adding a component

1. Add `lib/src/components/cc_<name>.dart` built on `flutter/widgets.dart`, reading
   tokens via `context.designSystem` (or `CcCardTokens` / `CcInputTokens` in
   `cc_component_tokens.dart` for the shared component-token resolvers).
2. Export it from `lib/cc_ui.dart`.
3. Add a unit/widget test under `test/components/`.
4. Catalogue it in `cc_gallery` — add `apps/cc_gallery/lib/use_cases/cc_<name>_use_cases.dart`
   with `@widgetbook.UseCase` builders, then run `build_runner` there.

## Tests

`flutter test` from `packages/cc_ui` runs the per-component widget tests under
`test/components/` and the foundation tests under `test/foundation/`.
