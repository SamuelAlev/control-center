import 'package:flutter/widgets.dart';

/// Canonical corner-radius scale.
///
/// Zero radius is the identity of the design system: the contrast between
/// soft warm color and hard architectural geometry is deliberate. Standard
/// elements (buttons, inputs, chips, cards, nodes, badges, menu rows) and
/// large containers (panels, dialogs, product windows) are all square; only
/// true pills (status capsules, count chips, live dots, the active-nav bar)
/// use the fully-rounded value.
abstract final class AppRadii {
  const AppRadii._();

  /// 0px — standard element radius (square).
  static const double xs = 0;

  /// 0px — standard element radius (no separate small tier).
  static const double sm = 0;

  /// 0px — default control radius.
  static const double md = 0;

  /// 0px — large container / panel / surface radius (square, like controls).
  static const double lg = 0;

  /// 0px — large surfaces (no radius tier above large).
  static const double xl = 0;

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
