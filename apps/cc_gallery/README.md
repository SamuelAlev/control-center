# cc_gallery

Interactive [Widgetbook](https://docs.widgetbook.io/) catalogue of [`cc_ui`](../../packages/cc_ui/README.md) components, states and design tokens. Use it to review components in isolation before shipping UI; [DESIGN.md](../../DESIGN.md) holds the visual specification.

```sh
# from apps/cc_gallery
fvm flutter run -d macos                  # or chrome, windows, linux
fvm dart run build_runner build           # regenerate after changing use-cases
fvm flutter test --concurrency=2          # gallery smoke test
```

`lib/main.dart` contains `@widgetbook.App()` on `CcGalleryApp`, the Light/Dark, viewport, alignment, text-scale and inspector addons, and the `GalleryFrame` supplying `CcTheme`. `ccAppBuilder` uses a custom page route rather than `MaterialApp`; this gallery and `cc_ui` are Material-free. `widgetbook_generator` turns `@widgetbook.UseCase` builders in `lib/use_cases/<component>_use_cases.dart` into the committed `lib/main.directories.g.dart` navigation tree. `test/gallery_smoke_test.dart` checks that generated catalogue and app builder.

For a new component, follow `lib/use_cases/cc_button_use_cases.dart`. Alias `widgetbook_annotation` as `widgetbook`; import `package:widgetbook/widgetbook.dart` only for `context.knobs`. Use the public component class in `type:` and a bracketed category path such as `'[Components]/Inputs'`. Return the component without a theme or background wrapper; the frame and addons supply both. Cover variants, sizes and selected/disabled/loading/error states, with knobs for useful interactive props. Use `context.designSystem`, `CcTypography`, `AppSpacing` and `AppRadii` rather than literal colors. Add the builder, regenerate and inspect Light/Dark previews.
