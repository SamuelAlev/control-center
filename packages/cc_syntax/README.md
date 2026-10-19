# cc_syntax

The Flutter-free syntax-highlighting core shared by the desktop/web app and
the phone client (`apps/cc_remote`):

- `cc_shiki_theme.dart` / `cc_shiki_theme_json.dart`: the CC light/dark shiki
  themes, the theme revision that keys every token cache, and the token-color
  adapter (the neutral sentinel maps to "inherit").
- `syntax_languages.dart`: the one language table (fence hints, paths,
  extensions, well-known filenames → shiki grammar ids) and the per-grammar
  weight classes.
- `curated_grammars.dart`: the curated eager grammar tier.
- `token_lines.dart`: carriage-return reattachment so token text round-trips
  to the source.

Every file imports only `package:shiki_flutter/engine.dart` /
`package:shiki_flutter/langs.dart`. No Flutter, `dart:ui` or `dart:io`: these
files compile into the app's diff Web Worker. The tokenizer seams themselves
stay with their clients (`lib/shared/syntax/` in the app,
`apps/cc_remote/lib/syntax/` on the phone).

Theme edits start in the app's `lib/shared/utils/syntax_palette.dart` and bump
`kCcThemeRevision`.
