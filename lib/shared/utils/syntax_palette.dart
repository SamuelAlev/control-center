import 'dart:ui' show Brightness, Color;

/// Canonical GitHub-style syntax-highlighting palettes, keyed by the scope
/// class names emitted by `highlight.dart` (e.g. `keyword`, `string`,
/// `comment`).
///
/// Kept as ARGB ints (not [Color]s) so the maps can cross an isolate boundary
/// — the PR diff precompute pipeline tokenizes off the UI thread — without
/// depending on `flutter/material`.
///
/// Single source of truth shared by the PR diff viewer (`DiffPalette`) and the
/// markdown fenced-code-block renderer (`code_highlighter.dart`). The values
/// mirror GitHub's light/dark code themes.
const Map<String, int> lightSyntaxPalette = {
  'keyword': 0xFFCF222E,
  'literal': 0xFF0550AE,
  'symbol': 0xFFE36209,
  'name': 0xFF8250DF,
  'string': 0xFF0A3069,
  'subst': 0xFF0A3069,
  'regexp': 0xFF0A3069,
  'number': 0xFF0550AE,
  'comment': 0xFF6E7781,
  'doctag': 0xFF6E7781,
  'meta': 0xFFE36209,
  'type': 0xFFE36209,
  'class': 0xFFE36209,
  'title': 0xFF8250DF,
  'built_in': 0xFFE36209,
  'function': 0xFF8250DF,
  'tag': 0xFF116329,
  'attr': 0xFFE36209,
  'attribute': 0xFFE36209,
  'variable': 0xFF24292F,
  'params': 0xFF24292F,
  'selector-tag': 0xFF116329,
  'selector-id': 0xFF8250DF,
  'selector-class': 0xFF8250DF,
  'addition': 0xFF116329,
  'deletion': 0xFFCF222E,
};

/// Dark-mode counterpart to [lightSyntaxPalette].
const Map<String, int> darkSyntaxPalette = {
  'keyword': 0xFFFF7B72,
  'literal': 0xFF79C0FF,
  'symbol': 0xFFFFA657,
  'name': 0xFFD2A8FF,
  'string': 0xFFA5D6FF,
  'subst': 0xFFA5D6FF,
  'regexp': 0xFFA5D6FF,
  'number': 0xFF79C0FF,
  'comment': 0xFF8B949E,
  'doctag': 0xFF8B949E,
  'meta': 0xFFFFA657,
  'type': 0xFFFFA657,
  'class': 0xFFFFA657,
  'title': 0xFFD2A8FF,
  'built_in': 0xFFFFA657,
  'function': 0xFFD2A8FF,
  'tag': 0xFF7EE787,
  'attr': 0xFFFFA657,
  'attribute': 0xFFFFA657,
  'variable': 0xFFE6EDF3,
  'params': 0xFFE6EDF3,
  'selector-tag': 0xFF7EE787,
  'selector-id': 0xFFD2A8FF,
  'selector-class': 0xFFD2A8FF,
  'addition': 0xFF7EE787,
  'deletion': 0xFFFF7B72,
};

/// Returns the syntax palette matching [brightness].
Map<String, int> syntaxPaletteFor(Brightness brightness) =>
    brightness == Brightness.dark ? darkSyntaxPalette : lightSyntaxPalette;

/// Resolves the [Color] for the highlight scope [scope] in [palette], or
/// `null` when the scope is unmapped (the caller should fall back to the base
/// text color).
Color? syntaxColorFor(Map<String, int> palette, String scope) {
  final argb = palette[scope];
  return argb == null ? null : Color(argb);
}
