import 'package:flutter/widgets.dart';

/// Typography tokens — the DESIGN.md type scale as font-family-agnostic
/// [TextStyle]s.
///
/// Hierarchy comes from size and color, never weight (the system has a single
/// UI weight of 400; the [label] eyebrow is the one tracked exception). These
/// styles set no `fontFamily`, so `Text` merges them with the ambient
/// `DefaultTextStyle` and inherits the app font (Manrope for UI, Fira
/// Code where a monospace style is applied explicitly via `CcFonts.code`).
abstract final class CcTypography {
  const CcTypography._();

  /// Hero display — earned brand moments only.
  static const TextStyle displayHero =
      TextStyle(fontSize: 40, height: 1.1, fontWeight: FontWeight.w400);

  /// Display heading.
  static const TextStyle display =
      TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w400);

  /// Section / card title.
  static const TextStyle title =
      TextStyle(fontSize: 18, height: 1.35, fontWeight: FontWeight.w400);

  /// Default body text.
  static const TextStyle body =
      TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w400);

  /// Small body / control text.
  static const TextStyle bodySm =
      TextStyle(fontSize: 13, height: 1.45, fontWeight: FontWeight.w400);

  /// Caption / metadata.
  static const TextStyle caption =
      TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w400);

  /// Signature eyebrow label — uppercase, tracked. Apply a monospace family
  /// (`CcFonts.code`) at the call site for the full effect.
  static const TextStyle label = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
  );

  /// Tabular numerics for aligned figures.
  static const TextStyle monoNum = TextStyle(
    fontSize: 13,
    height: 1.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
