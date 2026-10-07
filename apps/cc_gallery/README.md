# cc_gallery

Interactive [Widgetbook](https://docs.widgetbook.io/) catalogue of [`cc_ui`](../../packages/cc_ui/README.md) components, states and design tokens. Use it to review components in isolation before shipping UI; [DESIGN.md](../../DESIGN.md) holds the visual specification.

```sh
# from apps/cc_gallery
fvm flutter run -d macos                  # or chrome, windows, linux
fvm dart run build_runner build           # regenerate after changing stories
fvm flutter test --concurrency=2          # gallery smoke + coverage tests
```

The gallery runs on Widgetbook 4. `lib/main.dart` calls `runWidgetbook(galleryConfig)`; the `Config` holds the Light/Dark theme, viewport, alignment, text-direction (LTR/RTL, `lib/text_direction_addon.dart`), text-scale and accessibility-checker addons, the `GalleryFrame` supplying `CcTheme`, the chrome theme and brand header from `lib/gallery_chrome.dart`, and `orderedComponents`, which puts the Docs category and its Welcome page first and sorts the rest alphabetically. `ccAppBuilder` renders each preview in a `WidgetsApp` rather than a `MaterialApp`; the gallery and `cc_ui` are Material-free. Two Material libraries still reach the preview: `accessibility_tools` is built on `material_ui`, whose localizations `ccAppBuilder` registers, and Widgetbook's own viewport frame is built on the deprecated framework Material, which `MaterialUiCompatibilityBridge` re-provides a theme for. Widgetbook's chrome is legacy Material too, so `gallery_chrome.dart` is the gallery's single deliberate import of `package:flutter/material.dart`.

Each component has one `lib/stories/<component>.stories.dart` file. Widgetbook's builders, which ship in the `widgetbook` package, generate its `<component>.stories.g.dart` part and the `lib/components.g.dart` list that `main.dart` loads. Both are committed. `build.yaml` turns off Widgetbook's build-time telemetry. `test/gallery_smoke_test.dart` checks the generated catalogue and the app builder; `test/gallery_coverage_test.dart` fails when an exported `Cc*` component appears in no story.

Widgetbook 4 derives a story from one widget constructor, and the story's builder must return that widget. Gallery stories are compositions such as variant grids, state matrices, token tables and docs pages, so every stories file targets `Showcase` (`lib/showcase.dart`), which renders whatever its `preview` builder returns. For a new component, follow `lib/stories/cc_button.stories.dart`:

- Add `part '<file>.stories.g.dart';`, a `const component = ComponentMeta(name: 'CcX', path: '[Components]/Inputs')` naming the public component class and a bracketed category path, and `const meta = Meta(Showcase.new);`.
- Add one top-level `final $StoryName = _Story(args: _Args.fixed(preview: builder));` per state, where `builder` is a `Widget Function(BuildContext)`. Pass `name:` when the label is not the variable name without its `$`, such as `'With icon'`. Stories appear in declaration order, so put the playground first.
- For an interactive playground, add `const playgroundMeta = Meta(Showcase.playground, argsType: CcXPlayground.new);` with a plain `CcXPlayground` class whose constructor parameters are the controls. The story is a `_PlaygroundStory` whose `_PlaygroundArgs` give each control a typed arg (`BoolArg`, `StringArg`, `EnumArg`, `SingleArg`, or `DoubleArg`/`IntArg` with a slider style), and whose `builder` returns `Showcase.playground((context) => playground(context, args))`.
- Return the component without a theme or background wrapper; the frame and addons supply both. Cover variants, sizes and selected, disabled, loading and error states. Use `context.designSystem`, `CcTypography`, `AppSpacing` and `AppRadii` rather than literal colors.
- Run `build_runner`, then inspect the Light and Dark previews and the component's generated Docs page.

Put fixtures that several stories files share in `lib/stories/support/`. A Docs page sets `docsBuilder: noDocs` on its `ComponentMeta` so it gets no generated docs node.
