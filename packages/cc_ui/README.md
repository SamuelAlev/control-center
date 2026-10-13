# cc_ui

Control Center's token, theme and component library. [`cc_gallery`](../../apps/cc_gallery/README.md) is its interactive Widgetbook catalogue; [DESIGN.md](../../DESIGN.md) specifies the visual system. Public widgets use `package:flutter/widgets.dart`, not Material, Cupertino or infrastructure dependencies. Import the public barrel, not `lib/src/`:

```dart
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

CcTheme(
  data: CcThemeData.light(), // or .dark()
  child: Builder(builder: (context) {
    final tokens = context.designSystem!;
    return ColoredBox(color: tokens.canvas, child: const Text('Example'));
  }),
);
```

`context.designSystem` reads semantic colors from the nearest `CcTheme`; `context.ccTheme?.monoFontFamily` exposes the code font family. Do not hardcode colors. The token families are `DesignSystemTokens` (colors), `CcTypography` (type scale), `AppSpacing` (8px-based spacing and gap widgets), `AppRadii` (2px/4px/pill), `AppShadows`/`CcElevation` (shadows/overlay layers), `CcMotion` (enter/exit speeds, reduced-motion handling) and `CcFonts` (host-bundled Manrope/Fira Code). Type hierarchy uses size and color, not extra font weight; `CcMotion.resolve`/`resolveTravel` remove motion when reduced, while `resolveFade` retains opacity transitions.

Components under `lib/src/components/` cover buttons; text/select/toggle inputs; badges, alerts, progress and toasts; cards, tiles and avatars; tabs, menus, popovers, dialogs and sidebars; and resizable layout. See the gallery for actual component states rather than maintaining another component inventory here. Foundations include focus modality (`:focus-visible` style), token resolvers, tappable surfaces and overlay anchors.

Decorated single-line `CcTextField` inputs reserve their control height (~40px default, ~32px compact) before a conditional suffix appears; a 32px clear button does not resize the field as text changes. Multiline fields grow with their content, while chromeless fields leave sizing to their host.

`CcTextField` owns a distinct semantic field boundary with explicit enabled/read-only state. Keep that declaration when wrapping `EditableText`: Flutter web uses it to decide whether its accessibility input accepts typing.

Pass `presentation: CcDialogPresentation.immediate` to `showCcDialog` for keyboard-first command surfaces. It removes route transitions and backdrop blur without replacing the shared focus trap, Escape/barrier policy, text style or focus restoration. Standard dialogs retain their existing animation/reduced-motion policy.

`CcToastScope` starts each toast's dwell time when `show` enqueues it; hovering pauses the countdown. A timeout or returned dismisser used before the first rendered frame removes the queued toast without playing its entrance, so delayed rendering cannot resurrect a dismissed notification. Visible toasts remain dismissible through their close control while hovered.

## Adding a component

1. Build `lib/src/components/cc_<name>.dart` on `flutter/widgets.dart`, using `context.designSystem` or shared `CcCardTokens`/`CcInputTokens` resolvers.
2. Export it from `lib/cc_ui.dart` and add a component test under `test/components/`.
3. Add `apps/cc_gallery/lib/stories/cc_<name>.stories.dart` (a `ComponentMeta` plus `$`-prefixed stories) and regenerate its catalogue as described in [the gallery README](../../apps/cc_gallery/README.md).

From `packages/cc_ui`, run `fvm flutter test --concurrency=2` for component and foundation widget tests. The host app's architecture constraints enforce this package's Material and infrastructure isolation.
