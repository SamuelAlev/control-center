import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Typography tokens — the DESIGN.md type scale as font-family-agnostic
/// [TextStyle]s.
///
/// Hierarchy is carried by size **and weight**: headings and labels are
/// semibold (600), body and data text are regular (400). Line-heights and
/// letter-spacing follow the productive type scale (tighter than a marketing
/// scale, tuned for a dense operator deck). These styles set no `fontFamily`,
/// so `Text` merges them with the ambient `DefaultTextStyle` and inherits the
/// app font (Manrope for UI, Fira Code where a monospace style is applied
/// explicitly via `CcFonts.code`).
abstract final class CcTypography {
  const CcTypography._();

  /// Tabular figures, everywhere.
  ///
  /// Every digit in the product renders on one fixed advance width
  /// (`FontFeature.tabularFigures()`, OpenType `tnum`) so counts, durations,
  /// diffs, costs and timestamps align in columns and do not jitter as they
  /// tick — prose included. Both bundled families carry the feature (the
  /// Manrope VF ships `tnum`/`pnum`, Fira Code `tnum`/`onum`); fonts
  /// resolved through `CcFontRegistry` ignore it silently when missing.
  /// Opting a surface out takes an explicit `fontFeatures` override.
  static const List<FontFeature> numeralFeatures = [
    FontFeature.tabularFigures(),
  ];

  /// Regular body weight, optically compensated on Flutter web.
  ///
  /// SkWasm and CanvasKit rasterize every family more lightly than the native
  /// desktop engine at the same nominal weight. Moving regular text up one
  /// real cut on web restores perceived parity without changing font choice,
  /// size, spacing, or native rendering.
  static const FontWeight regularWeight = kIsWeb
      ? FontWeight.w500
      : FontWeight.w400;

  /// Medium emphasis weight, compensated alongside [regularWeight].
  static const FontWeight mediumWeight = kIsWeb
      ? FontWeight.w600
      : FontWeight.w500;

  /// Semibold weight used by every heading and label.
  ///
  /// This stays at 600 on web: raising it to 700 would add a third visual role
  /// and make compact headings shout rather than compensate.
  static const FontWeight semiboldWeight = FontWeight.w600;

  /// Hero display — earned brand moments only.
  static const TextStyle displayHero = TextStyle(
    fontSize: 40,
    height: 1.15,
    fontWeight: semiboldWeight,
    letterSpacing: 0,
    fontFeatures: numeralFeatures,
  );

  /// Display heading.
  static const TextStyle display = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: semiboldWeight,
    letterSpacing: 0,
    fontFeatures: numeralFeatures,
  );

  /// Section / card title.
  static const TextStyle title = TextStyle(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: semiboldWeight,
    letterSpacing: 0,
    fontFeatures: numeralFeatures,
  );

  /// Default body text.
  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: regularWeight,
    letterSpacing: 0.16,
    fontFeatures: numeralFeatures,
  );

  /// Small body / control text.
  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: regularWeight,
    letterSpacing: 0.16,
    fontFeatures: numeralFeatures,
  );

  /// Caption / metadata.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: regularWeight,
    letterSpacing: 0.32,
    fontFeatures: numeralFeatures,
  );

  /// Signature eyebrow label — uppercase, tracked, semibold. Apply a monospace
  /// family (`CcFonts.code`) at the call site for the full effect.
  static const TextStyle label = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: semiboldWeight,
    letterSpacing: 0.6,
    fontFeatures: numeralFeatures,
  );

  /// Tabular numerics for aligned figures.
  static const TextStyle monoNum = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: regularWeight,
    letterSpacing: 0,
    fontFeatures: numeralFeatures,
  );
}

/// The app's soft, always-on link underline for plain-[Text] link labels.
///
/// Flutter's text engine has no `text-decoration-skip-ink` and no way to offset
/// an inline underline (verified against the pinned SDK), so a full-strength
/// underline strikes hard through descenders — the tail of a `p`/`y`/`g`
/// crosses the line, which reads as cramped. Painting the underline in a
/// lightened tone of the link colour keeps a clear link affordance while
/// letting descenders read through it. Use [CcLinkUnderlineX.withLinkUnderline] to apply
/// it consistently at every link site.
///
/// Markdown links go further: cc_markdown's renderer strips the engine
/// underline and paints it BELOW the glyphs of each wrapped fragment (a real
/// offset, Carbon-style), reading this style's [TextStyle.decorationColor] as
/// the underline colour.
abstract final class CcLinkStyle {
  const CcLinkStyle._();

  /// Opacity of the underline colour relative to the link colour. Softens the
  /// stroke so descenders aren't cut by a full-strength line.
  static const double underlineOpacity = 0.5;

  /// Underline stroke thickness (a multiplier on the font's own thickness).
  static const double underlineThickness = 1.0;

  /// The softened underline colour for a link painted in [linkColor].
  static Color underlineColor(Color linkColor) =>
      linkColor.withValues(alpha: underlineOpacity);
}

/// Applies the app's soft link underline (see [CcLinkStyle]) to a [TextStyle].
extension CcLinkUnderlineX on TextStyle {
  /// Returns this style with a soft always-on underline in a lightened tone of
  /// [color] — defaulting to the style's own [TextStyle.color] (then black if
  /// that too is unset). The link colour itself is left untouched; only the
  /// decoration is added.
  TextStyle withLinkUnderline([Color? color]) {
    final base = color ?? this.color ?? const Color(0xFF000000);
    return copyWith(
      decoration: TextDecoration.underline,
      decorationColor: CcLinkStyle.underlineColor(base),
      decorationThickness: CcLinkStyle.underlineThickness,
    );
  }
}
