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

## Adding a component

1. Build `lib/src/components/cc_<name>.dart` on `flutter/widgets.dart`, using `context.designSystem` or shared `CcCardTokens`/`CcInputTokens` resolvers.
2. Export it from `lib/cc_ui.dart` and add a component test under `test/components/`.
3. Add `apps/cc_gallery/lib/use_cases/cc_<name>_use_cases.dart` with `@widgetbook.UseCase` builders and regenerate its catalogue as described in [the gallery README](../../apps/cc_gallery/README.md).

From `packages/cc_ui`, run `fvm flutter test --concurrency=2` for component and foundation widget tests. The host app's architecture constraints enforce this package's Material and infrastructure isolation.
