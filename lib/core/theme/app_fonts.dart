import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/system_font_loader.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised font helpers — Manrope for UI, Fira Code for code.
///
/// The two defaults are **bundled as host assets by the `cc_ui` package** and
/// resolved by their `packages/cc_ui/<family>` name — the main app bundles no
/// fonts of its own (single-copy setup). So the default text NEVER touches the
/// network — important for the CSP-strict web + cc_remote clients. They are
/// resolved by family name directly; `google_fonts` is reached ONLY when a call
/// site asks for a *different* family (a user-selected Google font).
///
/// Manrope is not a Google Font, so it cannot go through `google_fonts` at all;
/// the bundled families are therefore short-circuited in every dynamic helper
/// (see [_bundled]).
class AppFonts {
  AppFonts._();

  /// Bundled UI font family. Aliases [CcFonts.uiFamily] (`packages/cc_ui/…`) so
  /// the family name has a single source of truth in the cc_ui package.
  static const uiFamily = CcFonts.uiFamily;

  /// Bundled monospace font family. Aliases [CcFonts.codeFamily].
  static const codeFamily = CcFonts.codeFamily;

  /// Families bundled as host assets. These are always applied verbatim and
  /// never routed through `google_fonts` (which would hit the network) — even
  /// though `Fira Code` happens to also exist on Google Fonts.
  static const _bundled = {uiFamily, codeFamily};

  /// Friendly label for a family name in the settings UI. Strips the Flutter
  /// `packages/<pkg>/` prefix the bundled defaults carry (e.g.
  /// `packages/cc_ui/Manrope` → `Manrope`); other families pass through.
  static String displayName(String family) => family.split('/').last;

  /// OpenType features for code text given the user's ligature preference.
  /// Programming ligatures (Fira Code's `=>`, `!=`, `->`, …) live in the `calt`
  /// and `liga` features; disabling them renders code glyph-by-glyph. Applied
  /// at the code surfaces (diff viewer, markdown code) via the
  /// `codeFontLigaturesProvider`.
  static List<FontFeature> codeFontFeatures({required bool ligatures}) =>
      ligatures
          ? const [FontFeature.enable('liga'), FontFeature.enable('calt')]
          : const [FontFeature.disable('liga'), FontFeature.disable('calt')];

  // ── Default static helpers ──

  /// UI / body text in Manrope.
  static TextStyle ui({TextStyle? textStyle}) =>
      (textStyle ?? const TextStyle()).copyWith(fontFamily: uiFamily);

  /// Code / monospace text in Fira Code.
  static TextStyle code({TextStyle? textStyle}) =>
      (textStyle ?? const TextStyle()).copyWith(fontFamily: codeFamily);

  /// Convenience overload for the common shape — direct style fields without
  /// having to wrap them in a `TextStyle(...)` first.
  static TextStyle codeStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Color? backgroundColor,
    double? height,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: codeFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    backgroundColor: backgroundColor,
    height: height,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
  );

  /// Apply the UI font to every entry in [base] — used by the app theme.
  static TextTheme uiTextTheme(TextTheme base) =>
      base.apply(fontFamily: uiFamily);

  // ── Dynamic helpers for user-selected fonts ──

  /// Whether [family] should be resolved via `google_fonts` (a known Google
  /// family that is NOT one of our bundled host families).
  static bool _useGoogle(String family) =>
      !_bundled.contains(family) && GoogleFonts.asMap().containsKey(family);

  /// UI text style using the given font family (Google Fonts or system).
  static TextStyle uiDynamic(String family, {TextStyle? textStyle}) {
    if (_useGoogle(family)) {
      return GoogleFonts.getFont(family, textStyle: textStyle);
    }
    return (textStyle ?? const TextStyle()).copyWith(fontFamily: family);
  }

  /// Code text style using the given font family (Google Fonts or system).
  static TextStyle codeDynamic(String family, {TextStyle? textStyle}) {
    if (_useGoogle(family)) {
      return GoogleFonts.getFont(family, textStyle: textStyle);
    }
    return (textStyle ?? const TextStyle()).copyWith(fontFamily: family);
  }

  /// Code style dynamic.
  static TextStyle codeStyleDynamic(
    String family, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Color? backgroundColor,
    double? height,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) {
    if (_useGoogle(family)) {
      return GoogleFonts.getFont(
        family,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        backgroundColor: backgroundColor,
        height: height,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
      );
    }
    return TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      backgroundColor: backgroundColor,
      height: height,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
    );
  }

  /// Apply any font family to a TextTheme. Routes through Google Fonts only for
  /// non-bundled Google families; otherwise applies the family name directly
  /// (bundled host families and pre-loaded system fonts).
  static TextTheme textThemeFor(String family, TextTheme base) =>
      _useGoogle(family)
          ? GoogleFonts.getTextTheme(family, base)
          : base.apply(fontFamily: family);

  /// Load a system font from a file path and register it with Flutter's
  /// `FontLoader`. Returns true if successful. On web there are no local
  /// system-font files, so this is a no-op that returns false (see the
  /// `system_font_loader.dart` seam).
  static Future<bool> loadSystemFont(String family, String filePath) =>
      loadSystemFontFromFile(family, filePath);
}
