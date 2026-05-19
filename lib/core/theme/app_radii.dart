import 'package:flutter/widgets.dart';

/// Canonical corner-radius scale.
///
/// Near-zero radius is the identity of the design system: the contrast between
/// soft warm color and hard architectural geometry is deliberate. Standard
/// elements (buttons, inputs, chips, cards, nodes, badges, menu rows) are 2px;
/// large containers (panels, product windows, device frames) cap at 4px; only
/// true pills (status capsules, count chips, live dots, the active-nav bar)
/// use the fully-rounded value. There is no mid-rounding tier.
abstract final class AppRadii {
  const AppRadii._();

  /// 2px -standard element radius.
  static const double xs = 2;

  /// 2px -standard element radius (no separate small tier).
  static const double sm = 2;

  /// 2px -default control radius.
  static const double md = 2;

  /// 4px -large container / panel / surface radius.
  static const double lg = 4;

  /// 4px -large surfaces (no radius tier above large).
  static const double xl = 4;

  /// Fully rounded (pill / stadium) — status capsules & live dots only.
  static const double pill = 999;

  /// [BorderRadius] for [xs].
  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));

  /// [BorderRadius] for [sm].
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));

  /// [BorderRadius] for [md].
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));

  /// [BorderRadius] for [lg].
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));

  /// [BorderRadius] for [xl].
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
}
