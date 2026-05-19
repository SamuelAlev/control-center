import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font helpers for cc_ui — Manrope for UI text, Fira Code for code.
///
/// The base fonts are **bundled as host assets** by this package (see the
/// `fonts:` section of `pubspec.yaml`), so the default text NEVER touches the
/// network — important for deploys behind a strict CSP (the web client + the
/// cc_remote PWA). `google_fonts` is reached for one case only: when a call
/// site explicitly asks for a *different* family (a user-selected Google font).
///
/// This package is the SOLE owner of the bundled font files; the main app,
/// cc_remote, and cc_gallery all resolve them through [uiFamily] / [codeFamily]
/// rather than bundling their own copy. [uiFamily] is the single Dart token for
/// the UI family — `AppFonts.uiFamily` in the main app aliases it, so swapping
/// the font means changing this one constant (plus the matching `family:` name
/// in `pubspec.yaml`).
///
/// Pure [TextStyle] helpers only (no Material `TextTheme`), so cc_ui stays on
/// the widgets layer.
abstract final class CcFonts {
  const CcFonts._();

  /// Family name for the bundled UI font. Fonts declared in a package are
  /// resolved under `packages/<package>/<family>` — this is that resolved name,
  /// usable directly as a [TextStyle.fontFamily].
  static const uiFamily = 'packages/cc_ui/Manrope';

  /// Family name for the bundled monospace font (see [uiFamily]).
  static const codeFamily = 'packages/cc_ui/Fira Code';

  /// UI / body text in the bundled Manrope, or in [family] when given.
  static TextStyle ui({TextStyle? textStyle, String? family}) =>
      _resolve(textStyle: textStyle, family: family, bundled: uiFamily);

  /// Monospace text in the bundled Fira Code, or in [family] when given.
  static TextStyle code({TextStyle? textStyle, String? family}) =>
      _resolve(textStyle: textStyle, family: family, bundled: codeFamily);

  /// Resolves a [family] to a [TextStyle]:
  ///  * `null` — the bundled host font ([bundled]); no network, no google_fonts.
  ///  * a known Google Fonts family — fetched via google_fonts. This is the
  ///    user's explicit choice and the ONLY path that hits the network.
  ///  * any other family — applied verbatim (it was pre-loaded by the app).
  static TextStyle _resolve({
    required TextStyle? textStyle,
    required String? family,
    required String bundled,
  }) {
    if (family == null) {
      return (textStyle ?? const TextStyle()).copyWith(fontFamily: bundled);
    }
    if (GoogleFonts.asMap().containsKey(family)) {
      return GoogleFonts.getFont(family, textStyle: textStyle);
    }
    return (textStyle ?? const TextStyle()).copyWith(fontFamily: family);
  }
}
