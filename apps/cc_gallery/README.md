# cc_gallery

The **living catalogue of the Control Center design system** (`cc_ui`), built
with [Widgetbook](https://docs.widgetbook.io/). Every component and design token
has a navigable, interactive entry here — this is the reference you read before
designing or reviewing any UI, and the place a new component proves itself in
isolation (all variants, states, and edge cases) before it ships in the app.

It is a workspace member of the Control Center pub workspace, alongside `cc_ui`
(the design system) and the root `control_center` app.

## Run it

```sh
# from apps/cc_gallery
flutter run -d macos      # or: -d chrome / -d windows / -d linux
```

The gallery is **Material-free** — `cc_ui` is built directly on
`package:flutter/widgets.dart`, so the preview Workbench uses a custom
`ccAppBuilder` (`lib/main.dart`) that supplies a `pageRouteBuilder` instead of
Material's `MaterialApp`.

## How it's wired (annotation-driven)

The navigation tree is **generated**, not hand-maintained. It follows the
[recommended Widgetbook setup](https://docs.widgetbook.io/):

- `lib/main.dart` holds the `@widgetbook.App()`-annotated `CcGalleryApp`, the
  addons (Light/Dark theme, desktop viewports, alignment, text-scale, inspector),
  and the `GalleryFrame` that wraps every preview in a `CcTheme` + canvas.
- Each component's states live in `lib/use_cases/<component>_use_cases.dart` as
  `@widgetbook.UseCase`-annotated builder functions.
- `widgetbook_generator` scans those annotations and emits the navigation tree
  into `lib/main.directories.g.dart` (the `directories` list `main.dart`
  consumes).

### Regenerate after adding or editing use-cases

```sh
# from apps/cc_gallery
flutter pub run build_runner build
```

(`--delete-conflicting-outputs` is the default in the pinned build_runner and is
no longer needed.)

## Adding a use-case

Create or edit `lib/use_cases/<component>_use_cases.dart` following the
`cc_button_use_cases.dart` exemplar:

```dart
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart'; // only when using context.knobs
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _path = '[Components]/Buttons';

@widgetbook.UseCase(name: 'Variants', type: CcButton, path: _path)
Widget ccButtonVariantsUseCase(BuildContext context) {
  return const Center(child: CcButton(onPressed: _noop, child: Text('Primary')));
}
```

Conventions (enforced by review, not lint):

- Import the annotation **aliased as `widgetbook`** (per the docs); import the
  main `package:widgetbook/widgetbook.dart` only when a use-case reads
  `context.knobs`.
- `type:` is the **public `cc_ui` component class** (bare name even for generics,
  e.g. `type: CcSelect`). It drives the component node in the navigation.
- `path:` uses bracketed category + folder segments, e.g.
  `'[Components]/Inputs'` → **Components** (category) → **Inputs** (folder).
- **Return the component directly** — do *not* wrap it in `CcTheme` or set a
  background. The theme addon supplies the environment, so Light/Dark and the
  viewport addons work for free.
- **Never hardcode colors.** Read tokens from `context.designSystem` (the
  `DesignSystemTokens`) or use `CcTypography` / `AppSpacing` / `AppRadii`.
- Cover the full state space: every enum variant, every size, default vs.
  selected vs. disabled vs. loading vs. error — plus an interactive **Playground**
  driven by `context.knobs` where the props warrant it.
- Sentence case for all user-facing strings; use real Control Center domain
  language in samples (agents, pull requests, workspaces, pipelines, Claude
  models) so previews read like the product.

Then run `build_runner` and the new entry appears in the tree.

## Navigation taxonomy

```
Components/
  Buttons              CcButton, CcIconButton
  Inputs               CcTextField, CcTextArea, CcTextFormField, CcSelect,
                       CcMultiSelect, CcAutocomplete, CcSwitch, CcCheckbox, CcRadio
  Feedback             CcAlert, CcBadge, CcSpinner, CcProgressBar, CcTooltip, CcToastScope
  Containers           CcCard, CcTile, CcChip, CcAvatar, CcKbd, CcEmptyState, CcDivider
  Navigation & Overlays CcTabs, CcTabView, CcMenu, CcPopover, CcDialog, CcBreadcrumb, CcSidebar
  Layout               CcResizable
Foundations/
  Tokens               Colors, Typography, Spacing, Radius, Elevation, Motion
  Primitives           SegmentedToggle, FocusRing
```

The Foundations specimens (`ColorTokens`, `TypeScale`, `SpacingScale`,
`RadiusScale`, `ElevationScale`, `MotionSpecimen`) render the design tokens live
from the active theme — toggle the **Light/Dark** theme addon to audit both
palettes at once.

## Tests

`test/gallery_smoke_test.dart` boots the gallery, renders the preview path
through `ccAppBuilder`, and asserts the generated catalogue stays complete
(≈130 use-cases across both categories). Run with `flutter test`.
