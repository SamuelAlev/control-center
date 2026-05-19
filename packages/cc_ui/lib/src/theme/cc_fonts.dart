import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font helpers for cc_ui — Manrope for UI text, JetBrains Mono for code.
///
/// Pure [TextStyle] helpers only (no Material `TextTheme`), so cc_ui stays on
/// the widgets layer. Call sites pass style overrides and receive a [TextStyle]
/// with the correct family wired up via `google_fonts`. The host app's richer
/// `AppFonts` (which also builds Material `TextTheme`s and loads system fonts
/// from disk) stays in the app.
abstract final class CcFonts {
  const CcFonts._();

  /// UI / body text in Manrope, or in [family] when it is a known Google font.
  /// An unknown [family] is applied verbatim (it was pre-loaded by the app).
  static TextStyle ui({TextStyle? textStyle, String? family}) {
    if (family != null && GoogleFonts.asMap().containsKey(family)) {
      return GoogleFonts.getFont(family, textStyle: textStyle);
    }
    if (family != null) {
      return (textStyle ?? const TextStyle()).copyWith(fontFamily: family);
    }
    return GoogleFonts.manrope(textStyle: textStyle);
  }

  /// Monospace text in JetBrains Mono, or in [family] when given and known.
  static TextStyle code({TextStyle? textStyle, String? family}) {
    if (family != null && GoogleFonts.asMap().containsKey(family)) {
      return GoogleFonts.getFont(family, textStyle: textStyle);
    }
    if (family != null) {
      return (textStyle ?? const TextStyle()).copyWith(fontFamily: family);
    }
    return GoogleFonts.jetBrainsMono(textStyle: textStyle);
  }
}
