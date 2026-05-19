import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/system_font_loader.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

/// Centralised font helpers — Manrope for UI, Fira Code for code.
///
/// The two defaults are **bundled as host assets by the `cc_ui` package** and
/// resolved by their `packages/cc_ui/<family>` name — the main app bundles no
/// fonts of its own (single-copy setup). So the default text NEVER touches the
/// network — important for the CSP-strict web + cc_remote clients. A fetch
/// happens ONLY when a call site asks for a *different* family (a user-selected
/// font), which [CcFontRegistry] resolves on demand through the host.
///
/// The bundled families are short-circuited in every dynamic helper (see
/// [_bundled]): they are already registered, so they must never be looked up.
class AppFonts {
  AppFonts._();

  /// Bundled UI font family. Aliases [CcFonts.uiFamily] (`packages/cc_ui/…`) so
  /// the family name has a single source of truth in the cc_ui package.
  static const uiFamily = CcFonts.uiFamily;

  /// Bundled monospace font family. Aliases [CcFonts.codeFamily].
  static const codeFamily = CcFonts.codeFamily;

  /// Families bundled as host assets. These are always applied verbatim and
  /// never fetched — even though `Fira Code` happens to also be downloadable.
  static const _bundled = {uiFamily, codeFamily};

  /// Platform emoji font for [TextStyle.fontFamilyFallback].
  ///
  /// The bundled families (Manrope / Fira Code) carry no emoji glyphs, so
  /// emoji resolve through the engine's implicit system fallback — which on
  /// macOS gives each emoji a phantom trailing advance (it selects as
  /// "emoji + space" and sits off-center in a centered table cell). Naming
  /// the platform emoji font explicitly lets the shaper pick it during
  /// layout, with correct advances.
  static List<String> get emojiFallback => switch (defaultTargetPlatform) {
    TargetPlatform.macOS || TargetPlatform.iOS => const ['Apple Color Emoji'],
    TargetPlatform.windows => const ['Segoe UI Emoji'],
    _ => const ['Noto Color Emoji'],
  };

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

  /// UI text style using the given font family (downloadable or system).
  static TextStyle uiDynamic(String family, {TextStyle? textStyle}) =>
      _dynamic(family, textStyle, fallback: uiFamily);

  /// Code text style using the given font family (downloadable or system).
  static TextStyle codeDynamic(String family, {TextStyle? textStyle}) =>
      _dynamic(family, textStyle, fallback: codeFamily);

  /// Resolves [family] against [textStyle]. Bundled families are already
  /// registered, so they apply by name; anything else goes through
  /// [CcFontRegistry], falling back to the surface's own bundled family
  /// ([fallback]) until the bytes land.
  static TextStyle _dynamic(
    String family,
    TextStyle? textStyle, {
    required String fallback,
  }) => _bundled.contains(family)
      ? (textStyle ?? const TextStyle()).copyWith(fontFamily: family)
      : CcFontRegistry.instance.apply(
          family,
          textStyle,
          fallbackFamily: fallback,
        );

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
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      backgroundColor: backgroundColor,
      height: height,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
    );
    return _dynamic(family, style, fallback: codeFamily);
  }

  /// Apply any font family to a TextTheme.
  ///
  /// Bundled families apply by name in one call. Everything else is resolved
  /// PER SLOT, because each slot carries its own weight and [CcFontRegistry]
  /// registers one real cut per weight — applying the family wholesale would
  /// leave every heading synthetically emboldened from the regular cut.
  static TextTheme textThemeFor(String family, TextTheme base) {
    if (_bundled.contains(family)) {
      return base.apply(fontFamily: family);
    }
    TextStyle? slot(TextStyle? style) => style == null
        ? null
        : CcFontRegistry.instance.apply(
            family,
            style,
            fallbackFamily: uiFamily,
          );
    return TextTheme(
      displayLarge: slot(base.displayLarge),
      displayMedium: slot(base.displayMedium),
      displaySmall: slot(base.displaySmall),
      headlineLarge: slot(base.headlineLarge),
      headlineMedium: slot(base.headlineMedium),
      headlineSmall: slot(base.headlineSmall),
      titleLarge: slot(base.titleLarge),
      titleMedium: slot(base.titleMedium),
      titleSmall: slot(base.titleSmall),
      bodyLarge: slot(base.bodyLarge),
      bodyMedium: slot(base.bodyMedium),
      bodySmall: slot(base.bodySmall),
      labelLarge: slot(base.labelLarge),
      labelMedium: slot(base.labelMedium),
      labelSmall: slot(base.labelSmall),
    );
  }

  /// Load a system font from a file path and register it with Flutter's
  /// `FontLoader`. Returns true if successful. On web there are no local
  /// system-font files, so this is a no-op that returns false (see the
  /// `system_font_loader.dart` seam).
  static Future<bool> loadSystemFont(String family, String filePath) =>
      loadSystemFontFromFile(family, filePath);
}
