// The CC shiki themes and the token-color adapter.
//
// FLUTTER-FREE ON PURPOSE: this file is imported by the PR-diff worker core,
// which `dart compile js` compiles into a Web Worker — no `package:flutter/`,
// `dart:ui`, or `dart:io` imports here (enforced by the "Web Worker cores are
// Flutter-free" group in test/core/architecture_constraints_test.dart).
// Brightness-typed conveniences live at the call sites; this module speaks
// `{required bool dark}`.

import 'package:control_center/shared/syntax/cc_shiki_theme_json.dart';
import 'package:shiki_flutter/engine.dart';

/// Identity of the CC theme pair. Part of every token cache key
/// (`'$themeId@$kCcThemeRevision'`): bump it whenever either JSON string in
/// cc_shiki_theme_json.dart changes, or stale colors will be served from the
/// highlight LRUs and the diff worker pool cache.
const int kCcThemeRevision = 1;

/// Theme id of the light CC theme (must match the `"name"` in its JSON).
const String kCcLightThemeId = 'cc-light';

/// Theme id of the dark CC theme (must match the `"name"` in its JSON).
const String kCcDarkThemeId = 'cc-dark';

/// The neutral foreground sentinel. Shiki assigns `editor.foreground` to every
/// token no theme rule matches; both CC themes set it to this exact hex, and
/// [ccArgbForTokenColor] maps it back to `null` so unmatched tokens inherit
/// the surface's base text style instead of flattening every surface to one
/// hard-coded color.
const String kCcNeutralForegroundHex = '#010203';

/// The light CC theme (GitHub-style light palette, see syntax_palette.dart).
const ShikiTheme ccLightTheme = ShikiTheme(
  id: kCcLightThemeId,
  type: 'light',
  json: ccLightThemeJson,
);

/// The dark CC theme (GitHub-style dark palette, see syntax_palette.dart).
const ShikiTheme ccDarkTheme = ShikiTheme(
  id: kCcDarkThemeId,
  type: 'dark',
  json: ccDarkThemeJson,
);

/// The CC theme id for [dark]. The cache-key form (with the revision baked in)
/// is [ccThemeCacheId].
String ccThemeId({required bool dark}) =>
    dark ? kCcDarkThemeId : kCcLightThemeId;

/// The CC theme for [dark].
ShikiTheme ccTheme({required bool dark}) => dark ? ccDarkTheme : ccLightTheme;

/// Theme identity for cache keys: `cc-dark@1`. Any cache keyed on this
/// invalidates when the theme JSON changes (via [kCcThemeRevision]).
String ccThemeCacheId({required bool dark}) =>
    '${ccThemeId(dark: dark)}@$kCcThemeRevision';

/// Registers both CC themes on [highlighter]. Idempotent and cheap (a set
/// lookup per call once loaded) — call it before every tokenize rather than
/// only at bootstrap, so widget tests that never run the app bootstrap still
/// get themed output.
void ensureCcThemes(ShikiHighlighter highlighter) {
  highlighter
    ..ensureShikiTheme(ccLightTheme)
    ..ensureShikiTheme(ccDarkTheme);
}

/// Memo of hex → ARGB conversions. The CC themes emit ~30 distinct values, so
/// this stays tiny; it is never cleared.
final Map<String, int?> _argbMemo = <String, int?>{};

/// Converts a [ThemedToken.color] hex string to an ARGB int, mapping the
/// neutral sentinel (and absent colors) to `null` — "inherit the base style".
///
/// Accepts `#RRGGBB` and `#RRGGBBAA` (shiki emits what the theme JSON
/// declares; CC themes only use 6-digit values, the 8-digit form is
/// defensive). Unparseable values resolve to `null` rather than throwing —
/// a bad color must never take down a render.
int? ccArgbForTokenColor(String? hex) {
  if (hex == null) {
    return null;
  }
  return _argbMemo.putIfAbsent(hex, () => _parseArgb(hex));
}

int? _parseArgb(String hex) {
  if (hex.toLowerCase() == kCcNeutralForegroundHex) {
    return null;
  }
  var h = hex;
  if (h.startsWith('#')) {
    h = h.substring(1);
  }
  if (h.length == 6) {
    final rgb = int.tryParse(h, radix: 16);
    return rgb == null ? null : (0xFF000000 | rgb);
  }
  if (h.length == 8) {
    // #RRGGBBAA → ARGB.
    final rgba = int.tryParse(h, radix: 16);
    if (rgba == null) {
      return null;
    }
    final alpha = rgba & 0xFF;
    return (alpha << 24) | (rgba >> 8);
  }
  if (h.length == 3) {
    final r = h[0], g = h[1], b = h[2];
    return _parseArgb('#$r$r$g$g$b$b');
  }
  return null;
}
